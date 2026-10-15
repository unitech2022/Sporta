using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.Enums;

namespace SportaApis.Services;

/// <summary>
/// تجديد عضويات الأندية كل ساعة: تذكير قبل الانتهاء بثلاثة أيام، ثم عند
/// الانتهاء يُخصم الشهر التالي من المحفظة (والخطة ما زالت متاحة) ويُحوَّل دخل
/// المالك، وإلا تنتهي العضوية ويصل إشعار. السعر هو لقطة وقت الاشتراك.
/// </summary>
public class MembershipRenewalService : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromHours(1);
    private readonly IServiceScopeFactory _scopes;
    private readonly ILogger<MembershipRenewalService> _logger;

    public MembershipRenewalService(IServiceScopeFactory scopes, ILogger<MembershipRenewalService> logger)
    {
        _scopes = scopes;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        using var timer = new PeriodicTimer(Interval);
        do
        {
            try { await TickAsync(ct); }
            catch (Exception ex) { _logger.LogError(ex, "Membership renewal tick failed"); }
        }
        while (await timer.WaitForNextTickAsync(ct));
    }

    private async Task TickAsync(CancellationToken ct)
    {
        using var scope = _scopes.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var wallet = scope.ServiceProvider.GetRequiredService<IWalletService>();
        var push = scope.ServiceProvider.GetRequiredService<INotificationService>();
        var svc = (MembershipService)scope.ServiceProvider.GetRequiredService<IMembershipService>();
        var now = DateTime.UtcNow;

        // تذكير قبل نهاية الفترة بثلاثة أيام: من فعّل التجديد يتأكد من رصيده،
        // ومن لم يفعّله يعرف أن عضويته ستنتهي فيجدّد إن شاء.
        var soon = await db.Memberships.Include(m => m.Venue)
            .Where(m => !m.IsEnded && m.RenewalReminderSentAt == null
                        && m.PeriodEnd > now && m.PeriodEnd <= now.AddDays(3))
            .ToListAsync(ct);
        foreach (var m in soon)
        {
            if (m.AutoRenew)
                await push.PushAsync(m.UserId, "تجديد عضويتك قريباً",
                    $"تتجدد عضوية «{m.PlanName}» في {m.Venue.Name} خلال 3 أيام بـ {m.Price:0.##} ر.س — تأكّد من رصيد محفظتك",
                    "membership_renewal_soon", m.VenueId);
            else
                await push.PushAsync(m.UserId, "عضويتك تنتهي قريباً",
                    $"تنتهي عضوية «{m.PlanName}» في {m.Venue.Name} خلال 3 أيام — فعّل التجديد التلقائي من «عضويات الأندية» إن أردت الاستمرار",
                    "membership_ending_soon", m.VenueId);
            m.RenewalReminderSentAt = now;
        }

        // ما انتهت فترته.
        var due = await db.Memberships.Include(m => m.Venue).Include(m => m.Plan)
            .Where(m => !m.IsEnded && m.PeriodEnd <= now)
            .ToListAsync(ct);
        foreach (var m in due)
        {
            var renewable = m.AutoRenew && !m.Plan.IsDeleted && m.Plan.IsActive;
            if (renewable && await wallet.TryChargeAsync(m.UserId, m.Price,
                    WalletTransactionType.MembershipPayment,
                    $"تجديد عضوية {m.Venue.Name} — {m.PlanName}", m.PlanId))
            {
                // الشهر الجديد يبدأ من نهاية السابق كي لا تنزاح المواعيد، إلا إن
                // توقّف الخادم أكثر من شهر فيبدأ الآن — لا يُخصم شهر عن كل شهر فات.
                m.PeriodStart = m.PeriodEnd.AddMonths(1) > now ? m.PeriodEnd : now;
                m.PeriodEnd = m.PeriodStart.AddMonths(1);
                m.RenewalReminderSentAt = null;
                await svc.PayOwnerAsync(m.Venue, m);
                await push.PushAsync(m.UserId, "تجدّدت عضويتك",
                    $"تجدّدت عضوية «{m.PlanName}» في {m.Venue.Name} لشهر جديد",
                    "membership_renewed", m.VenueId);
            }
            else
            {
                m.IsEnded = true;
                await push.PushAsync(m.UserId, "انتهت عضويتك",
                    renewable
                        ? $"لم تتجدد عضوية «{m.PlanName}» في {m.Venue.Name} لعدم كفاية الرصيد"
                        : $"انتهت عضوية «{m.PlanName}» في {m.Venue.Name}",
                    "membership_ended", m.VenueId);
            }
            m.UpdatedAt = now;
        }
        await db.SaveChangesAsync(ct);
        if (due.Count > 0) _logger.LogInformation("Processed {Count} membership renewal(s)", due.Count);
    }
}
