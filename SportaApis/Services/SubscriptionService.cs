using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Models;

namespace SportaApis.Services;

public class SubscriptionService : ISubscriptionService
{
    private readonly AppDbContext _db;
    private readonly IWalletService _wallet;
    private readonly IPackageService _packages;
    private readonly IPointsService _points;
    private readonly IDiscountService _discounts;

    public SubscriptionService(
        AppDbContext db, IWalletService wallet, IPackageService packages,
        IPointsService points, IDiscountService discounts)
    {
        _db = db;
        _wallet = wallet;
        _packages = packages;
        _points = points;
        _discounts = discounts;
    }

    public async Task<SubscriptionDto> GetAsync(int userId)
    {
        var sub = await GetOrCreateAsync(userId);
        return await ToDtoAsync(sub);
    }

    public async Task<List<PackageDto>> GetPackagesAsync(int userId)
    {
        var packages = await _packages.GetActiveAsync();
        var percent = await _discounts.PeekPercentAsync(DiscountTarget.PlayerSubscription, userId);
        foreach (var p in packages)
        {
            p.DiscountPercent = percent;
            p.PriceAfterDiscount = Math.Round(p.Price * (1m - percent / 100m), 2);
        }
        return packages;
    }

    public async Task<SubscriptionDto> SubscribeAsync(int userId, int? packageId)
    {
        var sub = await GetOrCreateAsync(userId);
        var package = await _packages.ResolveForSubscribeAsync(packageId);

        // «بالنسبة» بلا رسوم مقدَّمة وبلا تاريخ انتهاء — مقابله نسبة سبورتا من
        // كل عملية، فلا نمسّ المحفظة عند الاشتراك.
        var pricePaid = 0m;
        if (!package.Period.IsOpenEnded())
        {
            // خصم «خدمات اللاعبين المدفوعة» (عام أو مخصص) يُطبَّق على سعر الباقة.
            pricePaid = await _discounts.ApplyAsync(
                DiscountTarget.PlayerSubscription, userId, package.Price);

            var charged = await _wallet.TryChargeAsync(
                userId, pricePaid, WalletTransactionType.Subscription,
                $"اشتراك {package.Name}", null);
            if (!charged)
                throw new AuthException(
                    "Insufficient balance", "الرصيد غير كافٍ، يرجى الشحن",
                    "INSUFFICIENT_BALANCE");
        }

        sub.Plan = SubscriptionPlan.SportaPlus;
        // لقطة الشروط وقت الشراء — تعديل الأدمن لاحقًا لا يمسّ هذا المشترك.
        sub.SnapshotFrom(package, pricePaid);
        sub.StartDate = DateTime.UtcNow;
        sub.EndDate = package.Period.IsOpenEnded()
            ? null
            : DateTime.UtcNow.AddDays(package.DurationDays);
        sub.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        // نقاط ترحيبية للباقة (بلا مضاعف) — عن كل عملية اشتراك مدفوعة.
        if (package.WelcomePoints > 0)
            await _points.GrantAsync(
                userId, package.WelcomePoints, PointsTransactionType.SubscriptionBonus,
                null, $"نقاط ترحيبية لاشتراك {package.Name}");

        return await ToDtoAsync(sub);
    }

    public async Task<SubscriptionDto> CancelAsync(int userId)
    {
        var sub = await GetOrCreateAsync(userId);
        sub.Plan = SubscriptionPlan.Free;
        sub.EndDate = null;
        sub.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return await ToDtoAsync(sub);
    }

    // ── helpers ────────────────────────────────────────────────────────────────

    private async Task<Subscription> GetOrCreateAsync(int userId)
    {
        var sub = await _db.Subscriptions.FirstOrDefaultAsync(s => s.UserId == userId);
        if (sub == null)
        {
            sub = new Subscription { UserId = userId, Plan = SubscriptionPlan.Free };
            _db.Subscriptions.Add(sub);
            await _db.SaveChangesAsync();
        }
        return sub;
    }

    private async Task<SubscriptionDto> ToDtoAsync(Subscription s)
    {
        var discountPercent = await _discounts.PeekPercentAsync(
            DiscountTarget.PlayerSubscription, s.UserId);

        var isPlus = s.Plan == SubscriptionPlan.SportaPlus &&
                     (s.EndDate == null || s.EndDate > DateTime.UtcNow);

        // النوع المعروض للسعر/المميزات: الباقة التي اشترك بها إن وُجدت، وإلا
        // الافتراضية. مصدر السعر دائمًا الباقة الحالية (سعر «اشترك مجددًا»).
        var package = s.PackageId is int pid
            ? await _db.Packages.FirstOrDefaultAsync(p => p.Id == pid)
            : await _packages.ResolveForSubscribeAsync(null);

        // للمشترك الساري: الشروط المعروضة هي لقطته وقت الشراء، لا الشروط
        // الحالية للباقة (فقد يعدّلها الأدمن بعد اشتراكه).
        var period = isPlus ? s.Period : package?.Period ?? SubscriptionPeriod.Monthly;
        var price = package?.Price ?? 0m;

        return new SubscriptionDto
        {
            Plan = isPlus ? "plus" : "free",
            IsActive = isPlus,
            EndDate = s.EndDate,
            PackageName = (isPlus ? s.PackageName : null) ?? package?.Name ?? string.Empty,
            PackageId = isPlus ? s.PackageId : null,
            Period = period.Wire(),
            // المميزات تُعرض كما أدخلها الأدمن في لوحة التحكم — لا نص ثابت في التطبيق.
            Features = string.IsNullOrWhiteSpace(package?.FeaturesText)
                ? []
                : package.FeaturesText
                    .Split('\n', StringSplitOptions.RemoveEmptyEntries |
                                 StringSplitOptions.TrimEntries)
                    .ToList(),
            MonthlyPrice = price,
            DiscountPercent = discountPercent,
            MonthlyPriceAfterDiscount =
                Math.Round(price * (1m - discountPercent / 100m), 2),
            PointsMultiplier =
                isPlus ? s.PointsMultiplier : package?.PointsMultiplier ?? 1m,
            BookingDiscountPercent = isPlus
                ? s.BookingDiscountPercent
                : package?.BookingDiscountPercent ?? 0m,
            WelcomePoints = isPlus ? s.WelcomePoints : package?.WelcomePoints ?? 0,
            CommissionDiscountPercent = isPlus
                ? s.CommissionDiscountPercent
                : package?.CommissionDiscountPercent ?? 0m,
            CommissionPercent =
                isPlus ? s.CommissionPercent : package?.CommissionPercent ?? 0m,
        };
    }
}
