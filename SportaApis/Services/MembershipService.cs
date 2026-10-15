using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

public interface IMembershipService
{
    // صاحب النادي
    Task<VenueMembersDto> GetVenueAdminAsync(int ownerId, int venueId);
    Task<MembershipPlanDto> CreatePlanAsync(int ownerId, int venueId, SaveMembershipPlanRequest req);
    Task<MembershipPlanDto> UpdatePlanAsync(int ownerId, int planId, SaveMembershipPlanRequest req);
    Task DeletePlanAsync(int ownerId, int planId);
    Task<VenueMembersDto> SetBookingWindowAsync(int ownerId, int venueId, int? days);

    // اللاعب
    Task<VenueMembershipDto> GetForVenueAsync(int userId, int venueId);
    Task<MembershipDto> SubscribeAsync(int userId, int planId, bool autoRenew);
    Task<MembershipDto> SetAutoRenewAsync(int userId, int membershipId, bool autoRenew);
    Task<List<MembershipDto>> GetMineAsync(int userId);

    // للحجز — eventStart: بداية الحجز/الحدث بالتوقيت المحلي (KSA)؛ الخصم لا
    // يسري إلا إن غطّت فترة العضوية تلك البداية. null = الآن (للتوافق).
    Task<ActiveMemberTerms?> GetActiveTermsAsync(int userId, int venueId, DateTime? eventStart = null);
    Task<int?> GetBookingWindowDaysAsync(int userId, Venue venue);

    // حصص المباريات والأمريكانو والبطولات
    Task<MemberShare> QuoteShareAsync(int userId, int venueId, decimal price, int minutes,
        DateTime? eventStart = null);
    Task<MemberShare> QuoteEventShareAsync(int userId, Match match);
    Task<MemberShareDto> GetEventShareAsync(int userId, int? matchId, int? americanoId);
    Task<MemberShareDto> GetCourtShareAsync(int userId, int courtId, decimal price, int minutes,
        DateTime? eventStart = null);
}

/// <summary>
/// حصة لاعب في حدث على ملعب بعد خصم عضويته في النادي. <see cref="Amount"/> ما
/// يُخصم من محفظته؛ الخصم من نصيب المالك ونسبة سبورتا معاً بالتناسب، فصافي
/// المالك = سعره بعد نسبة الخصم (كما في حجز الملعب).
/// </summary>
public sealed record MemberShare(
    decimal Amount, decimal Discount, int? MembershipId, string? PlanName, int Minutes)
{
    public static MemberShare Full(decimal price) => new(price, 0m, null, null, 0);

    /// <summary>يسجّل الحصة على سطر اللاعب (يُستدعى بعد نجاح الخصم).</summary>
    public void ApplyTo(MatchPlayer player)
    {
        player.PaidAmount = Amount;
        player.MembershipId = MembershipId;
        player.MemberDiscountMinutes = Minutes;
    }
}

/// <summary>شروط عضوية سارية للتسعير: نسبة الخصم والدقائق المتبقية من السقف.</summary>
public sealed record ActiveMemberTerms(int MembershipId, string PlanName,
    decimal DiscountPercent, int? RemainingMinutes);

/// <summary>
/// عضويات الأندية: صاحب النادي ينشئ خططاً شهرية (خصم على الحجز + أيام أولوية)،
/// واللاعب يشترك من محفظته. يُحوَّل المبلغ لمحفظة المالك بعد نسبة سبورتا
/// (membership_commission_percent، افتراضياً 10٪). خصم العضوية يُموَّل من سعر
/// المالك؛ نسبة سبورتا على الحجز تُحسب على السعر بعد الخصم.
/// </summary>
public class MembershipService : IMembershipService
{
    public const string FeeSettingKey = "membership_commission_percent";
    private const decimal DefaultFeePercent = 10m;

    private readonly AppDbContext _db;
    private readonly IWalletService _wallet;
    private readonly INotificationService _notifications;

    public MembershipService(AppDbContext db, IWalletService wallet, INotificationService notifications)
    {
        _db = db;
        _wallet = wallet;
        _notifications = notifications;
    }

    public async Task<decimal> GetFeePercentAsync()
    {
        var raw = await _db.SystemSettings.Where(s => s.Key == FeeSettingKey)
            .Select(s => s.ValueEn).FirstOrDefaultAsync();
        return decimal.TryParse(raw, System.Globalization.NumberStyles.Number,
            System.Globalization.CultureInfo.InvariantCulture, out var v) && v is >= 0 and <= 100
            ? v : DefaultFeePercent;
    }

    // ── صاحب النادي ────────────────────────────────────────────────────────────

    private async Task<Venue> OwnedVenueAsync(int ownerId, int venueId)
    {
        var venue = await _db.Venues.FirstOrDefaultAsync(v => v.Id == venueId && !v.IsDeleted)
            ?? throw new AuthException("Venue not found", "النادي غير موجود", "VENUE_NOT_FOUND");
        if (venue.OwnerId != ownerId)
            throw new AuthException("Not your venue", "هذا النادي ليس لك", "NOT_OWNER");
        return venue;
    }

    public async Task<VenueMembersDto> GetVenueAdminAsync(int ownerId, int venueId)
    {
        var venue = await OwnedVenueAsync(ownerId, venueId);
        var now = DateTime.UtcNow;
        var plans = await _db.MembershipPlans
            .Where(p => p.VenueId == venueId && !p.IsDeleted)
            .OrderBy(p => p.SortOrder).ThenBy(p => p.MonthlyPrice)
            .ToListAsync();
        var members = await _db.Memberships
            .Include(m => m.User).ThenInclude(u => u.PlayerProfile)
            .Where(m => m.VenueId == venueId && !m.IsEnded && m.PeriodEnd > now)
            .OrderByDescending(m => m.CreatedAt)
            .ToListAsync();
        var usage = await UsageAsync(members);
        var fee = await GetFeePercentAsync();

        return new VenueMembersDto
        {
            VenueId = venueId,
            BookingWindowDays = venue.BookingWindowDays,
            SportaFeePercent = fee,
            Plans = plans.Select(p => ToPlanDto(p, members.Count(m => m.PlanId == p.Id))).ToList(),
            Members = members.Select(m => new VenueMemberDto
            {
                MembershipId = m.Id,
                UserId = m.UserId,
                Name = $"{m.User.FirstName} {m.User.LastName}".Trim(),
                AvatarUrl = m.User.ProfileImageUrl,
                Level = m.User.PlayerProfile != null ? (int)m.User.PlayerProfile.Level : null,
                PlanName = m.PlanName,
                PeriodEnd = m.PeriodEnd,
                AutoRenew = m.AutoRenew,
                UsedDiscountMinutes = usage.GetValueOrDefault(m.Id),
                MonthlyDiscountHours = m.MonthlyDiscountHours,
            }).ToList(),
            MonthlyRevenue = Math.Round(members.Sum(m => m.Price) * (1m - fee / 100m), 2),
        };
    }

    public async Task<MembershipPlanDto> CreatePlanAsync(int ownerId, int venueId, SaveMembershipPlanRequest req)
    {
        await OwnedVenueAsync(ownerId, venueId);
        var plan = new MembershipPlan { VenueId = venueId };
        Apply(plan, req);
        _db.MembershipPlans.Add(plan);
        await _db.SaveChangesAsync();
        return ToPlanDto(plan, 0);
    }

    public async Task<MembershipPlanDto> UpdatePlanAsync(int ownerId, int planId, SaveMembershipPlanRequest req)
    {
        var plan = await _db.MembershipPlans.FirstOrDefaultAsync(p => p.Id == planId && !p.IsDeleted)
            ?? throw new AuthException("Plan not found", "الخطة غير موجودة", "PLAN_NOT_FOUND");
        await OwnedVenueAsync(ownerId, plan.VenueId);
        // تعديل الخطة لا يمسّ المشتركين الحاليين (لقطة) — يسري على الجدد والتجديد القادم لا.
        Apply(plan, req);
        plan.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        var count = await _db.Memberships.CountAsync(m =>
            m.PlanId == plan.Id && !m.IsEnded && m.PeriodEnd > DateTime.UtcNow);
        return ToPlanDto(plan, count);
    }

    public async Task DeletePlanAsync(int ownerId, int planId)
    {
        var plan = await _db.MembershipPlans.FirstOrDefaultAsync(p => p.Id == planId && !p.IsDeleted)
            ?? throw new AuthException("Plan not found", "الخطة غير موجودة", "PLAN_NOT_FOUND");
        await OwnedVenueAsync(ownerId, plan.VenueId);
        // حذف ناعم: المشتركون الحاليون يكملون فترتهم ولا تتجدد.
        plan.IsDeleted = true;
        plan.IsActive = false;
        await _db.SaveChangesAsync();
    }

    public async Task<VenueMembersDto> SetBookingWindowAsync(int ownerId, int venueId, int? days)
    {
        var venue = await OwnedVenueAsync(ownerId, venueId);
        venue.BookingWindowDays = days is > 0 ? Math.Min(days.Value, 365) : null;
        await _db.SaveChangesAsync();
        return await GetVenueAdminAsync(ownerId, venueId);
    }

    private static void Apply(MembershipPlan p, SaveMembershipPlanRequest r)
    {
        if (string.IsNullOrWhiteSpace(r.Name))
            throw new AuthException("Name required", "اكتب اسم الخطة", "PLAN_NAME_REQUIRED");
        if (r.MonthlyPrice <= 0)
            throw new AuthException("Price required", "حدّد سعراً شهرياً", "PLAN_PRICE_REQUIRED");
        if (r.DiscountPercent <= 0 && r.PriorityDays <= 0)
            throw new AuthException("Plan has no benefit",
                "أضف خصماً أو أيام أولوية — الخطة بلا مزايا", "PLAN_NO_BENEFIT");
        p.Name = r.Name.Trim();
        p.NameEn = string.IsNullOrWhiteSpace(r.NameEn) ? null : r.NameEn.Trim();
        p.Description = string.IsNullOrWhiteSpace(r.Description) ? null : r.Description.Trim();
        p.MonthlyPrice = Math.Round(r.MonthlyPrice, 2);
        p.DiscountPercent = Math.Clamp(Math.Round(r.DiscountPercent, 2), 0m, 100m);
        p.MonthlyDiscountHours = r.MonthlyDiscountHours is > 0 ? r.MonthlyDiscountHours : null;
        p.PriorityDays = Math.Clamp(r.PriorityDays, 0, 60);
        p.IsActive = r.IsActive;
    }

    // ── اللاعب ─────────────────────────────────────────────────────────────────

    /// <summary>
    /// العضوية السارية الآن. مع <paramref name="eventStart"/> (وقت محلي KSA
    /// كمواعيد الحجوزات والمباريات) يُشترط أيضاً أن تمتد فترتها (UTC) إلى ما
    /// بعد بداية الحدث: عضوية تنتهي قبل الحدث لا تخصم منه.
    /// </summary>
    private Task<Membership?> ActiveAsync(int userId, int venueId, DateTime? eventStart = null)
    {
        var now = DateTime.UtcNow;
        // PeriodEnd بالتوقيت العالمي ومواعيد الأحداث محلية: تُحوَّل البداية إلى UTC.
        var startUtc = eventStart?.AddHours(-AppClock.OffsetHours);
        var coverUntil = startUtc > now ? startUtc.Value : now;
        return _db.Memberships
            .Include(m => m.Venue)
            .Where(m => m.UserId == userId && m.VenueId == venueId && !m.IsEnded
                        && m.PeriodEnd > coverUntil)
            .OrderByDescending(m => m.PeriodEnd)
            .FirstOrDefaultAsync();
    }

    public async Task<VenueMembershipDto> GetForVenueAsync(int userId, int venueId)
    {
        var venue = await _db.Venues.FirstOrDefaultAsync(v => v.Id == venueId && !v.IsDeleted)
            ?? throw new AuthException("Venue not found", "النادي غير موجود", "VENUE_NOT_FOUND");
        var plans = await _db.MembershipPlans
            .Where(p => p.VenueId == venueId && !p.IsDeleted && p.IsActive)
            .OrderBy(p => p.SortOrder).ThenBy(p => p.MonthlyPrice)
            .ToListAsync();
        var mine = userId == 0 ? null : await ActiveAsync(userId, venueId);
        var usage = mine == null ? new Dictionary<int, int>() : await UsageAsync([mine]);

        return new VenueMembershipDto
        {
            VenueId = venue.Id,
            VenueName = venue.Name,
            VenueNameEn = venue.NameEn,
            BookingWindowDays = venue.BookingWindowDays,
            MyBookingWindowDays = venue.BookingWindowDays is int w
                ? w + (mine?.PriorityDays ?? 0) : null,
            Plans = plans.Select(p => ToPlanDto(p, 0)).ToList(),
            MyMembership = mine == null ? null : ToDto(mine, usage.GetValueOrDefault(mine.Id)),
            IsOwnVenue = userId != 0 && venue.OwnerId == userId,
        };
    }

    public async Task<MembershipDto> SubscribeAsync(int userId, int planId, bool autoRenew)
    {
        var plan = await _db.MembershipPlans.Include(p => p.Venue)
            .FirstOrDefaultAsync(p => p.Id == planId && !p.IsDeleted && p.IsActive)
            ?? throw new AuthException("Plan not available", "الخطة غير متاحة", "PLAN_NOT_FOUND");
        if (plan.Venue.OwnerId == userId)
            throw new AuthException("Own venue", "لا يمكنك الاشتراك في ناديك", "MEMBERSHIP_OWN_VENUE");

        // ضغطتان متزامنتان كانتا تمرّان كلتاهما من فحص «عضوية سارية» ثم تخصمان
        // مرتين: الفحص والخصم والإنشاء تحت قفل واحد لكل لاعب.
        await using var _ = await DbLocks.AcquireAsync(_db, $"membership:{userId}");
        if (await ActiveAsync(userId, plan.VenueId) != null)
            throw new AuthException("Already a member",
                "لديك عضوية سارية في هذا النادي", "MEMBERSHIP_EXISTS");

        var charged = await _wallet.TryChargeAsync(userId, plan.MonthlyPrice,
            WalletTransactionType.MembershipPayment,
            $"عضوية {plan.Venue.Name} — {plan.Name}", plan.Id);
        if (!charged)
            throw new AuthException("Insufficient balance",
                "رصيد المحفظة غير كافٍ، يرجى شحن المحفظة والمحاولة مجدداً", "INSUFFICIENT_BALANCE");

        var now = DateTime.UtcNow;
        var m = new Membership
        {
            PlanId = plan.Id,
            VenueId = plan.VenueId,
            UserId = userId,
            PlanName = plan.Name,
            Price = plan.MonthlyPrice,
            DiscountPercent = plan.DiscountPercent,
            MonthlyDiscountHours = plan.MonthlyDiscountHours,
            PriorityDays = plan.PriorityDays,
            PeriodStart = now,
            PeriodEnd = now.AddMonths(1),
            // التجديد اختيار اللاعب عند الاشتراك (مطفأ افتراضياً)، ويغيّره لاحقاً.
            AutoRenew = autoRenew,
        };
        _db.Memberships.Add(m);
        await _db.SaveChangesAsync();

        await PayOwnerAsync(plan.Venue, m);
        var name = await _db.Users.Where(u => u.Id == userId)
            .Select(u => u.FirstName).FirstOrDefaultAsync();
        await _notifications.PushAsync(plan.Venue.OwnerId, "عضو جديد في ناديك",
            $"اشترك {name ?? "لاعب"} في «{plan.Name}»", "membership_new", plan.VenueId);

        m.Venue = plan.Venue;
        return ToDto(m, 0);
    }

    /// <summary>دخل المالك من فترة عضوية: السعر ناقص نسبة سبورتا.</summary>
    internal async Task PayOwnerAsync(Venue venue, Membership m)
    {
        var fee = await GetFeePercentAsync();
        var net = Math.Round(m.Price * (1m - fee / 100m), 2);
        if (net > 0)
            await _wallet.CreditEarningAsync(venue.OwnerId, net,
                WalletTransactionType.MembershipEarning,
                $"عضوية «{m.PlanName}» (بعد نسبة سبورتا {fee:0.##}٪)", m.Id);
    }

    public async Task<MembershipDto> SetAutoRenewAsync(int userId, int membershipId, bool autoRenew)
    {
        var m = await _db.Memberships.Include(x => x.Venue)
            .FirstOrDefaultAsync(x => x.Id == membershipId && x.UserId == userId)
            ?? throw new AuthException("Not found", "العضوية غير موجودة", "MEMBERSHIP_NOT_FOUND");
        if (!m.IsActiveAt(DateTime.UtcNow))
            throw new AuthException("Ended", "انتهت هذه العضوية", "MEMBERSHIP_ENDED");
        m.AutoRenew = autoRenew;
        m.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        var usage = await UsageAsync([m]);
        return ToDto(m, usage.GetValueOrDefault(m.Id));
    }

    public async Task<List<MembershipDto>> GetMineAsync(int userId)
    {
        var now = DateTime.UtcNow;
        var list = await _db.Memberships.Include(m => m.Venue)
            .Where(m => m.UserId == userId && !m.IsEnded && m.PeriodEnd > now)
            .OrderBy(m => m.PeriodEnd)
            .ToListAsync();
        var usage = await UsageAsync(list);
        return list.Select(m => ToDto(m, usage.GetValueOrDefault(m.Id))).ToList();
    }

    // ── للحجز ──────────────────────────────────────────────────────────────────

    public async Task<ActiveMemberTerms?> GetActiveTermsAsync(
        int userId, int venueId, DateTime? eventStart = null)
    {
        if (userId == 0) return null;
        var m = await ActiveAsync(userId, venueId, eventStart);
        if (m == null || m.DiscountPercent <= 0) return null;
        int? remaining = null;
        if (m.MonthlyDiscountHours is int hours)
        {
            var used = (await UsageAsync([m])).GetValueOrDefault(m.Id);
            remaining = Math.Max(0, hours * 60 - used);
        }
        return new ActiveMemberTerms(m.Id, m.PlanName, m.DiscountPercent, remaining);
    }

    public async Task<int?> GetBookingWindowDaysAsync(int userId, Venue venue)
    {
        if (venue.BookingWindowDays is not int w) return null;
        if (userId == 0) return w;
        var m = await ActiveAsync(userId, venue.Id);
        return w + (m?.PriorityDays ?? 0);
    }

    public async Task<MemberShare> QuoteShareAsync(
        int userId, int venueId, decimal price, int minutes, DateTime? eventStart = null)
    {
        if (price <= 0 || minutes <= 0) return MemberShare.Full(price);
        var terms = await GetActiveTermsAsync(userId, venueId, eventStart);
        if (terms == null) return MemberShare.Full(price);

        // السقف الشهري بالتناسب كالحجز: بقي من السقف 60 دقيقة وحدث 90 ⇒
        // الخصم على ثلثي الحصة فقط.
        var used = terms.RemainingMinutes is int left ? Math.Min(left, minutes) : minutes;
        if (used <= 0) return MemberShare.Full(price);
        var discount = Math.Round(price * terms.DiscountPercent / 100m * used / minutes, 2);
        return new MemberShare(price - discount, discount, terms.MembershipId, terms.PlanName, used);
    }

    public async Task<MemberShare> QuoteEventShareAsync(int userId, Match match)
    {
        if (match.CourtId == null || match.PricePerPlayer <= 0
            || match.PaymentMode == MatchPaymentMode.FullByCreator)
            return MemberShare.Full(match.PricePerPlayer);
        var venueId = match.Court?.VenueId ?? await _db.Courts
            .Where(c => c.Id == match.CourtId).Select(c => c.VenueId).FirstAsync();
        // الخصم لعضوية تغطي موعد الحدث نفسه، لا لحظة الانضمام فقط.
        return await QuoteShareAsync(userId, venueId, match.PricePerPlayer,
            await EventMinutesAsync(match), match.ScheduledAt);
    }

    /// <summary>حصة المستخدم في حدث قائم قبل الانضمام (للعرض في التطبيق).</summary>
    public async Task<MemberShareDto> GetEventShareAsync(int userId, int? matchId, int? americanoId)
    {
        var id = matchId ?? await _db.AmericanoMatches
            .Where(a => a.Id == americanoId).Select(a => (int?)a.MatchId).FirstOrDefaultAsync()
            ?? throw new AuthException("Event not found", "الحدث غير موجود", "MATCH_NOT_FOUND");
        var match = await _db.Matches.Include(m => m.Court).Include(m => m.AmericanoMatch)
            .FirstOrDefaultAsync(m => m.Id == id)
            ?? throw new AuthException("Event not found", "الحدث غير موجود", "MATCH_NOT_FOUND");
        return ToShareDto(match.PricePerPlayer, await QuoteEventShareAsync(userId, match));
    }

    /// <summary>حصة منشئ حدث جديد على ملعب (قبل إنشائه) بعد خصم عضويته.</summary>
    public async Task<MemberShareDto> GetCourtShareAsync(
        int userId, int courtId, decimal price, int minutes, DateTime? eventStart = null)
    {
        var venueId = await _db.Courts.Where(c => c.Id == courtId)
            .Select(c => (int?)c.VenueId).FirstOrDefaultAsync()
            ?? throw new AuthException("Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");
        return ToShareDto(price, await QuoteShareAsync(userId, venueId, price, minutes, eventStart));
    }

    private static MemberShareDto ToShareDto(decimal price, MemberShare s) => new()
    {
        Price = price,
        Amount = s.Amount,
        Discount = s.Discount,
        MembershipPlanName = s.PlanName,
    };

    /// <summary>
    /// دقائق الحدث من سقف العضوية: مدته في اليوم × أيامه (البطولة/الأمريكانو
    /// الممتد يشغل الملعب كل يوم من أيامه).
    /// </summary>
    private async Task<int> EventMinutesAsync(Match match)
    {
        var endDate = match.AmericanoMatch?.EndDate ?? await _db.AmericanoMatches
            .Where(a => a.MatchId == match.Id).Select(a => a.EndDate).FirstOrDefaultAsync();
        var days = endDate is DateTime end && end.Date > match.ScheduledAt.Date
            ? (end.Date - match.ScheduledAt.Date).Days + 1
            : 1;
        return match.DurationMinutes * days;
    }

    /// <summary>
    /// دقائق الخصم المستخدمة في الفترة الحالية لكل عضوية: الحجوزات غير الملغاة
    /// وحصص الأحداث المدفوعة (المباريات/الأمريكانو/البطولات) غير الملغاة.
    /// </summary>
    private async Task<Dictionary<int, int>> UsageAsync(IEnumerable<Membership> list)
    {
        var items = list.ToList();
        if (items.Count == 0) return [];
        var ids = items.Select(m => m.Id).ToList();
        var rows = await _db.Bookings
            .Where(b => b.MembershipId != null && ids.Contains(b.MembershipId.Value)
                        && b.Status != BookingStatus.Cancelled && b.MemberDiscountMinutes > 0)
            .Select(b => new { Id = b.MembershipId!.Value, Minutes = b.MemberDiscountMinutes, b.CreatedAt })
            .ToListAsync();
        rows.AddRange(await _db.MatchPlayers
            .Where(p => p.MembershipId != null && ids.Contains(p.MembershipId.Value)
                        && p.HasPaid && p.MemberDiscountMinutes > 0
                        && p.Match.Status != MatchStatus.Cancelled)
            .Select(p => new { Id = p.MembershipId!.Value, Minutes = p.MemberDiscountMinutes, p.CreatedAt })
            .ToListAsync());
        return items.ToDictionary(m => m.Id, m => rows
            .Where(r => r.Id == m.Id && r.CreatedAt >= m.PeriodStart)
            .Sum(r => r.Minutes));
    }

    // ── mapping ────────────────────────────────────────────────────────────────

    private static MembershipPlanDto ToPlanDto(MembershipPlan p, int members) => new()
    {
        Id = p.Id,
        VenueId = p.VenueId,
        Name = p.Name,
        NameEn = p.NameEn,
        Description = p.Description,
        MonthlyPrice = p.MonthlyPrice,
        DiscountPercent = p.DiscountPercent,
        MonthlyDiscountHours = p.MonthlyDiscountHours,
        PriorityDays = p.PriorityDays,
        IsActive = p.IsActive,
        ActiveMembers = members,
    };

    private static MembershipDto ToDto(Membership m, int used) => new()
    {
        Id = m.Id,
        PlanId = m.PlanId,
        VenueId = m.VenueId,
        VenueName = m.Venue?.Name ?? string.Empty,
        VenueNameEn = m.Venue?.NameEn,
        VenueImageUrl = m.Venue?.ImageUrl,
        PlanName = m.PlanName,
        Price = m.Price,
        DiscountPercent = m.DiscountPercent,
        MonthlyDiscountHours = m.MonthlyDiscountHours,
        PriorityDays = m.PriorityDays,
        PeriodStart = m.PeriodStart,
        PeriodEnd = m.PeriodEnd,
        AutoRenew = m.AutoRenew,
        IsActive = m.IsActiveAt(DateTime.UtcNow),
        UsedDiscountMinutes = used,
    };
}
