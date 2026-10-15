using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.Enums;
using SportaApis.Helpers;

namespace SportaApis.Services;

/// <summary>
/// بعد انتهاء كل تجربة يُرسل لأطرافها إشعار «كيف كانت تجربتك؟» مرة واحدة:
/// لاعبو المباراة/الأمريكانو/البطولة (review_match)، صاحب حجز الملعب
/// (review_booking)، ولاعب ومدرب جلسة التدريب (review_session). صاحب الملعب لا
/// يُشعَر — قد تكون عشرات التجارب يومياً — ويجدها في بطاقة «قيّم تجاربك».
/// نبضة كل خمس دقائق؛ ما انتهى قبل أكثر من يوم يُختم بلا إشعار.
/// </summary>
public class ReviewPromptService : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(5);
    private static readonly TimeSpan MaxAge = TimeSpan.FromDays(1);

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<ReviewPromptService> _logger;

    public ReviewPromptService(IServiceScopeFactory scopeFactory, ILogger<ReviewPromptService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval);
        do
        {
            try
            {
                await TickAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Review prompt tick failed");
            }
        }
        while (await timer.WaitForNextTickAsync(stoppingToken));
    }

    private async Task TickAsync(CancellationToken ct)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var push = scope.ServiceProvider.GetRequiredService<INotificationService>();
        var now = AppClock.Now;
        var oldest = now - MaxAge;
        var sent = 0;

        // ── المباريات/الأمريكانو/البطولات ──
        var matches = await db.Matches
            .Include(m => m.Court!).ThenInclude(c => c.Venue)
            .Include(m => m.AmericanoMatch)
            .Include(m => m.MatchPlayers)
            .Where(m => m.RatingPromptSentAt == null)
            .Where(m => m.Status != MatchStatus.Cancelled && m.Status != MatchStatus.PendingApproval)
            .Where(m => m.ScheduledAt <= now && m.ScheduledAt >= oldest.AddDays(-30))
            .ToListAsync(ct);
        foreach (var m in matches)
        {
            var end = m.AmericanoMatch?.EndDate is { } d && d > m.ScheduledAt
                ? d : m.ScheduledAt.AddMinutes(m.DurationMinutes);
            if (end > now && m.Status != MatchStatus.Completed) continue;
            m.RatingPromptSentAt = DateTime.UtcNow;
            if (end < oldest) continue;

            var players = m.MatchPlayers
                .Where(p => p.Status == MatchPlayerStatus.Approved)
                .Select(p => p.UserId).Distinct().ToList();
            // لا شيء يقيّمه لاعب وحيد بلا ملعب.
            if (m.Court == null && players.Count < 2) continue;
            var what = m.Court == null ? "اللاعبين" : "الملعب واللاعبين";
            foreach (var userId in players)
                await push.PushAsync(userId, "كيف كانت تجربتك؟",
                    $"قيّم {what} بعد مباراتك واكسب نقاط مكافآت", "review_match", m.Id);
            sent++;
        }

        // ── حجوزات الملاعب ──
        var bookings = await db.Bookings
            .Include(b => b.Court).ThenInclude(c => c.Venue)
            .Where(b => b.ReviewPromptSentAt == null)
            .Where(b => b.Status == BookingStatus.Confirmed || b.Status == BookingStatus.Completed)
            .Where(b => b.EndTime <= now)
            .ToListAsync(ct);
        foreach (var b in bookings)
        {
            b.ReviewPromptSentAt = DateTime.UtcNow;
            if (b.EndTime < oldest || b.UserId == b.Court.Venue.OwnerId) continue;
            await push.PushAsync(b.UserId, "كيف كان الملعب؟",
                $"قيّم «{b.Court.Name}» في {b.Court.Venue.Name} واكسب نقاط مكافآت",
                "review_booking", b.Id);
            sent++;
        }

        // ── جلسات التدريب ──
        var sessions = await db.CoachSessions
            .Include(s => s.CoachProfile)
            .Where(s => s.ReviewPromptSentAt == null)
            .Where(s => s.Status == CoachSessionStatus.Confirmed && s.IsPaid)
            .Where(s => s.ScheduledAt <= now)
            .ToListAsync(ct);
        foreach (var s in sessions)
        {
            var end = s.ScheduledAt.AddMinutes(s.DurationMinutes);
            if (end > now) continue;
            s.ReviewPromptSentAt = DateTime.UtcNow;
            if (end < oldest) continue;
            await push.PushAsync(s.PlayerId, "كيف كانت جلستك؟",
                "قيّم المدرب والملعب بعد جلسة التدريب", "review_session", s.Id);
            await push.PushAsync(s.CoachProfile.UserId, "كيف كانت الجلسة؟",
                "قيّم اللاعب بعد جلسة التدريب", "review_session", s.Id);
            sent++;
        }

        await db.SaveChangesAsync(ct);
        if (sent > 0) _logger.LogInformation("Sent review prompts for {Count} experience(s)", sent);
    }
}
