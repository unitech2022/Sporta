using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

/// <summary>
/// اشتراك مالك الملعب: تسعيرة متدرّجة بعدد ملاعبه، تُخصم من محفظته وتُمدَّد من
/// نهاية اشتراكه القائم.
/// </summary>
public class VenueSubscriptionService : IVenueSubscriptionService
{
    private readonly AppDbContext _db;
    private readonly IWalletService _wallet;
    private readonly IDiscountService _discounts;

    public VenueSubscriptionService(
        AppDbContext db, IWalletService wallet, IDiscountService discounts)
    {
        _db = db;
        _wallet = wallet;
        _discounts = discounts;
    }

    public async Task<VenueSubscriptionPricingDto> GetPricingAsync() =>
        ToDto(await GetOrCreatePricingAsync());

    public async Task<VenueSubscriptionPricingDto> SavePricingAsync(
        SaveVenueSubscriptionPricingRequest req)
    {
        var pricing = await GetOrCreatePricingAsync();
        pricing.MonthlyOneCourt = req.MonthlyOneCourt;
        pricing.MonthlyTwoCourts = req.MonthlyTwoCourts;
        pricing.MonthlyExtraCourt = req.MonthlyExtraCourt;
        pricing.YearlyOneCourt = req.YearlyOneCourt;
        pricing.YearlyTwoCourts = req.YearlyTwoCourts;
        pricing.YearlyExtraCourt = req.YearlyExtraCourt;
        pricing.IsActive = req.IsActive;
        pricing.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return ToDto(pricing);
    }

    public Task<VenueSubscriptionQuoteDto> QuoteAsync(int ownerId, bool yearly) =>
        BuildQuoteAsync(ownerId, yearly, reserveDiscountSlot: false);

    /// <summary>
    /// يبني عرض السعر. <paramref name="reserveDiscountSlot"/> يحجز مقعد المالك في
    /// العروض ذات السقف — يُفعَّل عند الشراء فقط، لا عند مجرد عرض السعر.
    /// </summary>
    private async Task<VenueSubscriptionQuoteDto> BuildQuoteAsync(
        int ownerId, bool yearly, bool reserveDiscountSlot)
    {
        var pricing = await GetOrCreatePricingAsync();
        var courtCount = await CountCourtsAsync(ownerId);

        var basePrice = pricing.PriceFor(courtCount, yearly);
        var percent = reserveDiscountSlot
            ? await _discounts.GetPercentAsync(DiscountTarget.VenueSubscription, ownerId)
            : await _discounts.PeekPercentAsync(DiscountTarget.VenueSubscription, ownerId);
        var total = Math.Round(basePrice * (1m - percent / 100m), 2);

        return new VenueSubscriptionQuoteDto
        {
            CourtCount = courtCount,
            IsYearly = yearly,
            BasePrice = basePrice,
            DiscountPercent = percent,
            DiscountAmount = Math.Round(basePrice - total, 2),
            Total = total,
        };
    }

    public async Task<VenueSubscriptionDto?> GetCurrentAsync(int ownerId)
    {
        var now = DateTime.UtcNow;
        var current = await _db.VenueSubscriptions
            .Include(s => s.Owner)
            .Where(s => s.OwnerId == ownerId && s.EndsAt > now)
            .OrderByDescending(s => s.EndsAt)
            .FirstOrDefaultAsync();
        return current is null ? null : ToDto(current, now);
    }

    public async Task<VenueSubscriptionDto> SubscribeAsync(int ownerId, bool yearly)
    {
        var isOwner = await _db.Venues.NotDeleted().AnyAsync(v => v.OwnerId == ownerId);
        if (!isOwner)
            throw new AuthException(
                "Not a venue owner", "هذا الحساب لا يملك ملاعب", "NOT_VENUE_OWNER");

        // حجز مقعد الخصم والخصم من المحفظة وإدراج الاشتراك في معاملة واحدة:
        // فشل الدفع يُرجع المقعد المحجوز فلا يُستهلك عرض محدود بلا شراء.
        await using var tx = await _db.Database.BeginTransactionAsync();

        var quote = await BuildQuoteAsync(ownerId, yearly, reserveDiscountSlot: true);

        var charged = await _wallet.TryChargeAsync(
            ownerId, quote.Total, WalletTransactionType.Subscription,
            yearly ? "اشتراك سنوي للملاعب" : "اشتراك شهري للملاعب", null);

        if (!charged)
        {
            await tx.RollbackAsync();
            throw new AuthException(
                "Insufficient wallet balance",
                "رصيد المحفظة غير كافٍ لدفع الاشتراك",
                "INSUFFICIENT_BALANCE");
        }

        // التجديد يبدأ من نهاية الاشتراك القائم حتى لا تضيع أيام مدفوعة.
        var now = DateTime.UtcNow;
        var currentEnd = await _db.VenueSubscriptions
            .Where(s => s.OwnerId == ownerId && s.EndsAt > now)
            .MaxAsync(s => (DateTime?)s.EndsAt);
        var startsAt = currentEnd ?? now;

        var subscription = new VenueSubscription
        {
            OwnerId = ownerId,
            IsYearly = yearly,
            CourtCount = quote.CourtCount,
            BasePrice = quote.BasePrice,
            DiscountPercent = quote.DiscountPercent,
            PaidAmount = quote.Total,
            StartsAt = startsAt,
            EndsAt = yearly ? startsAt.AddYears(1) : startsAt.AddMonths(1),
        };
        _db.VenueSubscriptions.Add(subscription);
        await _db.SaveChangesAsync();
        await tx.CommitAsync();

        return ToDto(subscription, now);
    }

    public async Task<PagedResult<VenueSubscriptionDto>> GetAllAsync(int page, int pageSize)
    {
        (page, pageSize) = Paging.Clamp(page, pageSize);
        var now = DateTime.UtcNow;

        var query = _db.VenueSubscriptions.Include(s => s.Owner);
        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(s => s.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<VenueSubscriptionDto>
        {
            Items = items.Select(s => ToDto(s, now)).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    /// <summary>عدد الملاعب الفعلية للمالك — مجموع CourtCount لكل ملاعبه.</summary>
    private async Task<int> CountCourtsAsync(int ownerId)
    {
        var count = await _db.Courts
            .NotDeleted()
            .Where(c => c.Venue.OwnerId == ownerId)
            .SumAsync(c => (int?)c.CourtCount) ?? 0;
        return Math.Max(count, 1);
    }

    private async Task<VenueSubscriptionPricing> GetOrCreatePricingAsync()
    {
        var pricing = await _db.VenueSubscriptionPricings.FirstOrDefaultAsync();
        if (pricing is not null) return pricing;

        pricing = new VenueSubscriptionPricing();
        _db.VenueSubscriptionPricings.Add(pricing);
        await _db.SaveChangesAsync();
        return pricing;
    }

    private static VenueSubscriptionPricingDto ToDto(VenueSubscriptionPricing p) => new()
    {
        MonthlyOneCourt = p.MonthlyOneCourt,
        MonthlyTwoCourts = p.MonthlyTwoCourts,
        MonthlyExtraCourt = p.MonthlyExtraCourt,
        YearlyOneCourt = p.YearlyOneCourt,
        YearlyTwoCourts = p.YearlyTwoCourts,
        YearlyExtraCourt = p.YearlyExtraCourt,
        IsActive = p.IsActive,
    };

    private static VenueSubscriptionDto ToDto(VenueSubscription s, DateTime now) => new()
    {
        Id = s.Id,
        OwnerId = s.OwnerId,
        OwnerName = s.Owner is null ? string.Empty : $"{s.Owner.FirstName} {s.Owner.LastName}".Trim(),
        IsYearly = s.IsYearly,
        CourtCount = s.CourtCount,
        BasePrice = s.BasePrice,
        DiscountPercent = s.DiscountPercent,
        PaidAmount = s.PaidAmount,
        StartsAt = s.StartsAt,
        EndsAt = s.EndsAt,
        IsCurrent = s.IsCurrent(now),
    };
}
