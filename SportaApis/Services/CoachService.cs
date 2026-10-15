using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

public class CoachService : ICoachService
{
    private readonly AppDbContext _db;
    private readonly IWalletService _wallet;
    private readonly INotificationService _notifications;

    private readonly IPointsService _points;
    private readonly ISettingsService _settings;
    private readonly IDiscountService _discounts;

    public CoachService(
        AppDbContext db, IWalletService wallet, INotificationService notifications,
        IPointsService points, ISettingsService settings, IDiscountService discounts)
    {
        _db = db;
        _wallet = wallet;
        _notifications = notifications;
        _points = points;
        _settings = settings;
        _discounts = discounts;
    }

    public async Task<PagedResult<CoachDto>> GetCoachesAsync(
        int currentUserId, string? city, string? gender = null,
        bool includeInactive = false, int page = 1, int pageSize = 20)
    {
        // Nearby filtering/sorting is per-row in memory, so the full filtered
        // list is built first and paged afterwards (same as courts/matches).
        var query = _db.CoachProfiles
            .Include(c => c.User).ThenInclude(u => u.CityRef)
            .Include(c => c.Sport)
            .Include(c => c.Offers)
            // الحساب المحذوف لا يظهر لأحد — ولا حتى في قائمة الأدمن.
            .Where(c => !c.User.IsDeleted)
            // من حُذف دور المدرب عن حسابه يختفي من القائمة وملفه محفوظ —
            // المرشّح العام على UserRole يستبعد الدور المحذوف ناعماً.
            .Where(c => c.User.Roles.Any(r => r.Role == UserType.Coach))
            .AsQueryable();

        // The app shows only active coaches; the admin dashboard opts into
        // seeing suspended accounts too (so they can be reactivated).
        // المدرب الذي لم يعتمد الأدمن حسابه بعد لا يظهر للاعبين إطلاقاً.
        if (!includeInactive)
            query = query.Where(c => c.User.IsActive && c.User.Roles.Any(r =>
                r.Role == UserType.Coach && r.IsApproved));

        if (!string.IsNullOrWhiteSpace(city))
            query = query.Where(c => c.User.City == city);

        if (TryParseGender(gender) is Gender g)
            query = query.Where(c => c.User.Gender == g);

        var unordered = await query.ToListAsync();
        var stats = await LoadStatsAsync(unordered.Select(c => c.Id).ToList());

        // Rating/sessions are computed live from bookings, so ordering happens
        // in memory on the computed values (the list is fully materialized
        // before paging anyway — see the nearby note above).
        var pairs = unordered
            .Select(c => (Coach: c, Dto: ToDto(c, stats.GetValueOrDefault(c.Id, CoachStats.Empty))))
            .OrderByDescending(p => p.Dto.Rating)
            .ThenByDescending(p => p.Dto.Students)
            .ToList();
        var coaches = pairs.Select(p => p.Coach).ToList();
        var dtos = pairs.Select(p => p.Dto).ToList();

        // The admin dashboard lists everyone regardless of the admin's location.
        if (!includeInactive)
            dtos = await ApplyNearbyAsync(currentUserId, coaches, dtos);

        dtos = await WithPlayerPricingAsync(dtos);
        return PagedResult<CoachDto>.Create(dtos, page, pageSize);
    }

    /// <summary>يضيف نسبة سبورتا فوق أسعار المدرب المعروضة للاعبين — المدرب
    /// يستلم سعره كاملاً واللاعب يدفع السعر + النسبة. ملف المدرب نفسه
    /// (coaches/me) يبقى بسعره الصافي حتى لا يتضاعف عند إعادة الحفظ.</summary>
    private async Task<List<CoachDto>> WithPlayerPricingAsync(List<CoachDto> dtos)
    {
        var pct = await _settings.GetCoachCommissionAsync();
        if (pct <= 0) return dtos;
        decimal Up(decimal v) => Math.Round(v * (1m + pct / 100m), 2);
        foreach (var d in dtos)
        {
            d.HourlyRate = Up(d.HourlyRate);
            d.HourlyRateAfterOffer = Up(d.HourlyRateAfterOffer);
            if (d.PackagePrice is decimal p) d.PackagePrice = Up(p);
        }
        return dtos;
    }

    /// <summary>When the player has a saved location, annotate each coach with
    /// their distance (from the coach's account location), drop coaches beyond
    /// the configured nearby radius (settings → nearby_distance_km), and sort
    /// nearest first. Coaches without a saved location are kept (listed last).</summary>
    private async Task<List<CoachDto>> ApplyNearbyAsync(
        int currentUserId, List<CoachProfile> coaches, List<CoachDto> dtos)
    {
        var user = await _db.Users
            .Where(u => u.Id == currentUserId)
            .Select(u => new { u.Latitude, u.Longitude })
            .FirstOrDefaultAsync();
        if (user?.Latitude == null || user?.Longitude == null) return dtos;

        var maxKm = await _settings.GetNearbyDistanceKmAsync();
        for (var i = 0; i < coaches.Count; i++)
        {
            var coachUser = coaches[i].User;
            if (coachUser.Latitude != null && coachUser.Longitude != null)
                dtos[i].DistanceKm = Math.Round(
                    GeoHelper.DistanceKm(
                        user.Latitude.Value, user.Longitude.Value,
                        coachUser.Latitude.Value, coachUser.Longitude.Value),
                    1);
        }

        return dtos
            .Where(d => d.DistanceKm == null || d.DistanceKm <= maxKm)
            .OrderBy(d => d.DistanceKm ?? double.MaxValue)
            .ThenByDescending(d => d.Rating)
            .ToList();
    }

    public async Task<CoachDto> GetCoachByIdAsync(int id)
    {
        var coach = await _db.CoachProfiles
            .Include(c => c.User).ThenInclude(u => u.CityRef)
            .Include(c => c.Sport)
            .Include(c => c.PreferredVenue)
            .Include(c => c.Specializations).ThenInclude(s => s.Specialization)
            .Include(c => c.Offers)
            .FirstOrDefaultAsync(c => c.Id == id)
            ?? throw new AuthException("Coach not found", "المدرب غير موجود", "COACH_NOT_FOUND");

        var dto = await ToDtoAsync(coach);
        return (await WithPlayerPricingAsync([dto]))[0];
    }

    public async Task<CoachSessionDto> BookSessionAsync(
        int playerId, int coachId, CreateCoachSessionRequest req)
    {
        var coach = await _db.CoachProfiles
            .Include(c => c.User).ThenInclude(u => u.CityRef)
            .Include(c => c.Offers)
            .FirstOrDefaultAsync(c => c.Id == coachId)
            ?? throw new AuthException("Coach not found", "المدرب غير موجود", "COACH_NOT_FOUND");

        // مدرب لم يُعتمد بعد لا يُحجز معه (لا يظهر في البحث أصلاً، وهذا يغلق
        // الحجز بمعرّف مباشر).
        if (!await _db.UserRoles.AnyAsync(r =>
                r.UserId == coach.UserId && r.Role == UserType.Coach && r.IsApproved))
            throw new AuthException(
                "Coach is pending approval", "حساب المدرب قيد المراجعة", "COACH_PENDING_APPROVAL");

        // ScheduledAt is naive KSA wall-clock time, so compare with AppClock
        // (UTC+3), not DateTime.UtcNow — otherwise the threshold is 3h off.
        if (req.ScheduledAt < AppClock.Now.AddMinutes(-1))
            throw new AuthException(
                "Session time is in the past",
                "موعد الجلسة في الماضي", "SESSION_TIME_PAST");

        // Reject double-booking the same coach at an overlapping time.
        var end = req.ScheduledAt.AddMinutes(req.DurationMinutes);
        var overlaps = await _db.CoachSessions.AnyAsync(s =>
            s.CoachProfileId == coach.Id &&
            s.Status == CoachSessionStatus.Confirmed &&
            !s.IsCompleted &&
            s.ScheduledAt < end &&
            s.ScheduledAt.AddMinutes(s.DurationMinutes) > req.ScheduledAt);
        if (overlaps)
            throw new AuthException(
                "Coach is already booked at this time",
                "المدرب محجوز في هذا الوقت", "COACH_SLOT_TAKEN");

        // حجز الجلسة فردي دائماً، فيسري عليه أفضل عرض «فردي» أو «للكل».
        var basePrice = Math.Round(coach.HourlyRate * req.DurationMinutes / 60m, 2);
        var offerPercent = BestOfferPercent(coach.Offers, "individual");
        var price = ApplyOffer(basePrice, offerPercent);

        // نسبة سبورتا تُضاف فوق سعر المدرب وتُلتقط عند الطلب، فيُعرض على اللاعب
        // المبلغ النهائي نفسه الذي سيُخصم عند تأكيد المدرب. «بالنسبة» من اشتراك
        // المدرب تستبدل نسبة المنصة، وخصومات العمولة تخفّضها (Peek — حجز مقعد
        // عروض «أول N» يقع عند التأكيد لا عند الطلب).
        var (subDiscount, subOverride) =
            await _points.GetActiveCommissionTermsAsync(coach.UserId);
        var commissionPercent = subOverride ?? await _settings.GetCoachCommissionAsync();
        var commissionDiscount = await _discounts.PeekPercentAsync(
            DiscountTarget.CoachCommission, coach.UserId);
        var finalCommissionPercent = Math.Round(
            commissionPercent * (1m - commissionDiscount / 100m) *
            (1m - subDiscount / 100m), 2);

        var description = (req.Domains is { Count: > 0 })
            ? string.Join("، ", req.Domains)
            : null;

        // A booking is a *request* awaiting the coach's approval — the wallet
        // is only charged once the coach confirms it.
        var session = new CoachSession
        {
            CoachProfileId = coach.Id,
            PlayerId = playerId,
            CourtId = req.CourtId,
            Title = "جلسة تدريبية",
            Description = description,
            TargetLevel = req.TargetLevel ?? string.Empty,
            ScheduledAt = req.ScheduledAt,
            DurationMinutes = req.DurationMinutes,
            Price = price,
            BasePrice = basePrice,
            OfferDiscountPercent = offerPercent,
            SportaCommissionPercent = finalCommissionPercent,
            Status = CoachSessionStatus.Pending,
        };

        await InsertSessionAsync(session, end);

        var playerName = await _db.Users
            .Where(u => u.Id == playerId)
            .Select(u => (u.FirstName + " " + u.LastName).Trim())
            .FirstOrDefaultAsync() ?? "لاعب";
        await _notifications.PushAsync(coach.UserId, "طلب حجز جديد",
            $"طلب {playerName} حجز جلسة تدريب معك", "coach_session_request",
            session.Id);

        return ToSessionDto(session, coach);
    }

    /// <summary>
    /// يحفظ طلب الجلسة تحت قفل ملعبها (إن وُجد): فحص صلاحية الملعب وإشغاله ثم
    /// الحفظ لا يتخلّلها طلب متزامن. يُحرَّر القفل عند العودة قبل الإشعار.
    /// </summary>
    private async Task InsertSessionAsync(CoachSession session, DateTime end)
    {
        // الملعب المختار يجب أن يقبل الحجز أصلاً (نفس شروط حجز الملاعب) وأن تقع
        // الجلسة داخل دوامه — وإلا حجزت جلسةٌ معلّقة أي ملعب بلا قيد.
        await using var courtLock = session.CourtId is int lockCourtId
            ? await DbLocks.AcquireAsync(_db, $"court:{lockCourtId}")
            : null;
        if (session.CourtId is int sessionCourtId)
        {
            var court = await _db.Courts
                .NotDeleted()
                .Include(c => c.OpeningHours)
                .FirstOrDefaultAsync(c => c.Id == sessionCourtId);
            if (court == null || !court.IsAvailable ||
                !await VenueBookability.IsBookableAsync(_db, sessionCourtId))
                throw new AuthException(
                    "Court is not available", "الملعب غير متاح للحجز", "COURT_UNAVAILABLE");
            if (!CourtSchedule.IsWithinOpeningHours(court, session.ScheduledAt, session.DurationMinutes))
                throw new AuthException(
                    "Selected time is outside opening hours",
                    "الوقت المختار خارج ساعات عمل الملعب", "OUTSIDE_OPENING_HOURS");

            // والملعب المختار للجلسة يجب أن يكون فارغاً هو الآخر — حجز أو مباراة
            // أو جلسة أخرى تشغله (نفس ما تعتمده قائمة المواعيد المتاحة). القفل
            // أعلاه يمنع طلبين متزامنين من المرور معاً بين الفحص والحفظ.
            if (await CourtOccupancy.IsTakenAsync(_db, sessionCourtId, session.ScheduledAt, end))
                throw new AuthException(
                    "This slot is already booked", "هذا الموعد محجوز بالفعل", "SLOT_TAKEN");
        }

        _db.CoachSessions.Add(session);
        await _db.SaveChangesAsync();
    }

    public async Task<PagedResult<CoachSessionDto>> GetSessionRequestsAsync(
        int coachUserId, int page, int pageSize)
    {
        var coach = await _db.CoachProfiles
            .FirstOrDefaultAsync(c => c.UserId == coachUserId)
            ?? throw new AuthException(
                "Coach profile not found", "ملف المدرب غير موجود", "NOT_COACH");

        var query = _db.CoachSessions
            .Include(s => s.CoachProfile).ThenInclude(c => c.User)
            .Include(s => s.Player)
            .Where(s => s.CoachProfileId == coach.Id &&
                        s.Status == CoachSessionStatus.Pending);

        var total = await query.CountAsync();
        var sessions = await query
            .OrderBy(s => s.ScheduledAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<CoachSessionDto>
        {
            Items = sessions.Select(s => ToSessionDto(s, s.CoachProfile)).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    public async Task<PagedResult<CoachSessionDto>> GetCoachBookingsAsync(
        int coachUserId, int page, int pageSize, string? status)
    {
        var coach = await _db.CoachProfiles
            .FirstOrDefaultAsync(c => c.UserId == coachUserId)
            ?? throw new AuthException(
                "Coach profile not found", "ملف المدرب غير موجود", "NOT_COACH");

        var query = _db.CoachSessions
            .Include(s => s.CoachProfile).ThenInclude(c => c.User)
            .Include(s => s.Player)
            .Where(s => s.CoachProfileId == coach.Id);

        // status: "pending" | "confirmed" | "completed" | "rejected"
        query = (status?.ToLowerInvariant()) switch
        {
            "pending" => query.Where(s =>
                s.Status == CoachSessionStatus.Pending && !s.IsCompleted),
            "confirmed" => query.Where(s =>
                s.Status == CoachSessionStatus.Confirmed && !s.IsCompleted),
            "completed" => query.Where(s => s.IsCompleted),
            "rejected" => query.Where(s => s.Status == CoachSessionStatus.Rejected),
            _ => query,
        };

        var total = await query.CountAsync();
        var sessions = await query
            // Pending requests first, then the most recent.
            .OrderBy(s => s.Status == CoachSessionStatus.Pending ? 0 : 1)
            .ThenByDescending(s => s.ScheduledAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<CoachSessionDto>
        {
            Items = sessions.Select(s => ToSessionDto(s, s.CoachProfile)).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    public async Task<CoachDto> GetMyCoachProfileAsync(int coachUserId)
    {
        var coach = await _db.CoachProfiles
            .Include(c => c.User).ThenInclude(u => u.CityRef)
            .Include(c => c.Sport)
            .Include(c => c.PreferredVenue)
            .Include(c => c.Specializations).ThenInclude(s => s.Specialization)
            .Include(c => c.Offers)
            .FirstOrDefaultAsync(c => c.UserId == coachUserId)
            ?? throw new AuthException(
                "Coach profile not found", "ملف المدرب غير موجود", "NOT_COACH");

        return await ToDtoAsync(coach);
    }

    private static readonly HashSet<string> ValidDayKeys =
        ["sat", "sun", "mon", "tue", "wed", "thu", "fri"];

    private static CoachExperienceLevel ParseExperienceLevel(string value) => value switch
    {
        "lessThanYear" => CoachExperienceLevel.LessThanYear,
        "oneToThree" => CoachExperienceLevel.OneToThree,
        "threeToFive" => CoachExperienceLevel.ThreeToFive,
        "moreThanFive" => CoachExperienceLevel.MoreThanFive,
        _ => throw new AuthException(
            "Invalid experience level", "سنوات الخبرة غير صحيحة", "INVALID_EXPERIENCE_LEVEL"),
    };

    private static CoachResidency ParseResidency(string value) => value switch
    {
        "saudi" => CoachResidency.Saudi,
        "resident" => CoachResidency.Resident,
        _ => throw new AuthException(
            "Invalid residency", "الجنسية غير صحيحة", "INVALID_RESIDENCY"),
    };

    private static Gender ParseTargetGender(string value) => value switch
    {
        "male" => Gender.Male,
        "female" => Gender.Female,
        _ => throw new AuthException(
            "Invalid target gender", "الفئة المستهدفة غير صحيحة", "INVALID_TARGET_GENDER"),
    };

    public async Task<CoachDto> UpdateMyCoachProfileAsync(
        int coachUserId, UpdateCoachProfileRequest req)
    {
        var coach = await _db.CoachProfiles
            .Include(c => c.User).ThenInclude(u => u.CityRef)
            .Include(c => c.Sport)
            .Include(c => c.Specializations)
            .Include(c => c.Offers)
            .FirstOrDefaultAsync(c => c.UserId == coachUserId)
            ?? throw new AuthException(
                "Coach profile not found", "ملف المدرب غير موجود", "NOT_COACH");

        var user = coach.User;
        if (!string.IsNullOrWhiteSpace(req.FirstName)) user.FirstName = req.FirstName.Trim();
        if (!string.IsNullOrWhiteSpace(req.LastName)) user.LastName = req.LastName.Trim();
        if (req.City != null) user.City = req.City.Trim();
        if (req.Bio != null) coach.Bio = req.Bio.Trim();
        if (req.Specialization != null) coach.Specialization = req.Specialization.Trim();
        if (req.SportId is int sportId)
        {
            if (!await _db.Sports.AnyAsync(s => s.Id == sportId && s.IsActive))
                throw new AuthException(
                    "Invalid sport", "اللعبة المختارة غير موجودة", "INVALID_SPORT");
            coach.SportId = sportId;
        }
        if (req.HourlyRate is decimal rate && rate >= 0) coach.HourlyRate = rate;

        if (req.Certifications != null)
            coach.Certifications = string.IsNullOrWhiteSpace(req.Certifications)
                ? null : req.Certifications.Trim();
        if (req.ExperienceLevel != null)
            coach.ExperienceLevel = ParseExperienceLevel(req.ExperienceLevel);
        if (req.TargetGender != null)
            coach.TargetGender = ParseTargetGender(req.TargetGender);
        if (req.PackagePrice is decimal pkg && pkg >= 0) coach.PackagePrice = pkg;
        if (req.Residency != null) coach.Residency = ParseResidency(req.Residency);
        if (req.NationalIdFrontUrl != null) coach.NationalIdFrontUrl = req.NationalIdFrontUrl.Trim();
        if (req.NationalIdBackUrl != null) coach.NationalIdBackUrl = req.NationalIdBackUrl.Trim();

        if (req.PreferredVenueId is int venueId)
        {
            if (venueId == 0)
            {
                coach.PreferredVenueId = null;
            }
            else
            {
                if (!await _db.Venues.NotDeleted().AnyAsync(v => v.Id == venueId))
                    throw new AuthException(
                        "Venue not found", "الملعب المختار غير موجود", "VENUE_NOT_FOUND");
                coach.PreferredVenueId = venueId;
            }
        }

        if (req.AvailableDays != null)
        {
            var days = req.AvailableDays.Select(d => d.Trim().ToLowerInvariant()).Distinct().ToList();
            if (days.Count == 0 || days.Any(d => !ValidDayKeys.Contains(d)))
                throw new AuthException(
                    "Invalid available days", "الأيام المتاحة للتدريب غير صحيحة", "INVALID_AVAILABLE_DAYS");
            coach.AvailableDays = string.Join(',', days);
        }

        if (req.SpecializationIds != null)
        {
            var specializationIds = req.SpecializationIds.Distinct().ToList();
            var validCount = await _db.CoachSpecializations
                .CountAsync(s => specializationIds.Contains(s.Id) && s.IsActive);
            if (specializationIds.Count == 0 || validCount != specializationIds.Count)
                throw new AuthException(
                    "Invalid specializations", "التخصصات المختارة غير صحيحة", "INVALID_SPECIALIZATIONS");

            coach.Specializations.Clear();
            foreach (var id in specializationIds)
                coach.Specializations.Add(new CoachProfileSpecialization { SpecializationId = id });
        }

        user.UpdatedAt = DateTime.UtcNow;
        coach.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        // Refresh navigations so the DTO reflects just-changed values.
        await _db.Entry(coach).Reference(c => c.Sport).LoadAsync();
        await _db.Entry(coach).Reference(c => c.PreferredVenue).LoadAsync();
        await _db.Entry(coach).Collection(c => c.Specializations).LoadAsync();
        await _db.Entry(coach).Collection(c => c.Offers).LoadAsync();
        foreach (var s in coach.Specializations)
            await _db.Entry(s).Reference(x => x.Specialization).LoadAsync();

        return await ToDtoAsync(coach);
    }

    public async Task<CoachDto> UpdateIdDocumentAsync(int coachUserId, string relativeUrl)
    {
        var coach = await _db.CoachProfiles
            .Include(c => c.User).ThenInclude(u => u.CityRef)
            .Include(c => c.Sport)
            .Include(c => c.Offers)
            .FirstOrDefaultAsync(c => c.UserId == coachUserId)
            ?? throw new AuthException(
                "Coach profile not found", "ملف المدرب غير موجود", "NOT_COACH");

        coach.IdDocumentUrl = relativeUrl;
        coach.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return await ToDtoAsync(coach);
    }

    public async Task<CoachSessionDto> RespondToSessionAsync(
        int coachUserId, int sessionId, bool approve)
    {
        var session = await _db.CoachSessions
            .Include(s => s.CoachProfile).ThenInclude(c => c.User)
            .Include(s => s.Player)
            .FirstOrDefaultAsync(s => s.Id == sessionId)
            ?? throw new AuthException(
                "Session not found", "الجلسة غير موجودة", "SESSION_NOT_FOUND");

        if (session.CoachProfile.UserId != coachUserId)
            throw new AuthException("Not your session", "ليست جلستك", "NOT_OWNER");
        if (session.Status != CoachSessionStatus.Pending)
            throw new AuthException(
                "Already handled", "تمت معالجة الطلب مسبقًا", "ALREADY_HANDLED");

        if (approve)
        {
            var clashing = await ConfirmSessionAsync(session);
            foreach (var other in clashing)
                await NotifyAutoRejectedAsync(other);

            // حجز مقعد عروض «أول N» على عمولة المدربين الآن — لحظة وقوع الرسم
            // فعلاً (الطلب يستخدم Peek فلا يستهلك مقعداً).
            await _discounts.GetPercentAsync(
                DiscountTarget.CoachCommission, session.CoachProfile.UserId);

            // نقاط مكافآت ثابتة (reward_points_coach_session) عن جلسة مدفوعة مؤكدة.
            await _points.EarnActivityAsync(
                session.PlayerId, PointsTransactionType.CoachSessionConfirmed, session.Id,
                "نقاط جلسة تدريب مؤكدة");

            await _notifications.PushAsync(session.PlayerId, "تم قبول حجزك",
                "أكّد المدرب جلسة التدريب", "coach_session_approved", session.Id);
        }
        else
        {
            session.Status = CoachSessionStatus.Rejected;
            await _db.SaveChangesAsync();
            await _notifications.PushAsync(session.PlayerId, "تم رفض حجزك",
                "اعتذر المدرب عن جلسة التدريب", "coach_session_rejected", session.Id);
        }

        return ToSessionDto(session, session.CoachProfile);
    }

    /// <summary>
    /// تأكيد طلب جلسة تحت قفل المدرب والملعب: إعادة فحص التعارض، الخصم من
    /// اللاعب، والتأكيد. يُعيد طلبات المدرب المعلّقة المتداخلة التي رُفضت بسببه
    /// (لم يُبلَّغ أصحابها بعد — الإشعار بعد تحرير القفل).
    /// </summary>
    private async Task<List<CoachSession>> ConfirmSessionAsync(CoachSession session)
    {
        // قفل المدرب ثم الملعب (بهذا الترتيب دائماً): موافقتان متزامنتان على
        // طلبين متداخلين لا تمرّان معاً من إعادة الفحص.
        await using var coachLock = await DbLocks.AcquireAsync(
            _db, $"coach:{session.CoachProfileId}");
        await using var courtLock = session.CourtId is int lockCourtId
            ? await DbLocks.AcquireAsync(_db, $"court:{lockCourtId}")
            : null;

        // الطلب يُقرأ ثانيةً تحت القفل: ربما عالجه نداء متزامن.
        await _db.Entry(session).ReloadAsync();
        if (session.Status != CoachSessionStatus.Pending)
            throw new AuthException(
                "Already handled", "تمت معالجة الطلب مسبقًا", "ALREADY_HANDLED");

        // طلب مضى موعده أو صار يتعارض مع جلسة مؤكدة للمدرب أو مع إشغال الملعب
        // لا يمكن تأكيده أبداً: يُرفض تلقائياً فيحرّر الملعب ويُبلَّغ اللاعب.
        var conflict = await SessionConflictAsync(session);
        if (conflict is not null)
        {
            await AutoRejectAsync(session);
            throw conflict;
        }

        // النسبة أُلتقطت عند الطلب — اللاعب يدفع (سعر المدرب + نسبة سبورتا)
        // كما عُرض عليه بالضبط.
        var playerTotal = session.PlayerTotal();

        // الخصم أولاً (ذرّياً) ثم التأكيد في المعاملة نفسها: رصيد لا يكفي لا
        // يترك جلسة مؤكدة «مدفوعة» لم يُخصم ثمنها.
        await using (var tx = await _db.Database.BeginTransactionAsync())
        {
            var charged = await _wallet.TryChargeAsync(
                session.PlayerId, playerTotal, WalletTransactionType.CoachPayment,
                $"جلسة مع {session.CoachProfile.User.FirstName} {session.CoachProfile.User.LastName}".Trim(),
                session.Id);
            if (!charged)
            {
                await tx.RollbackAsync();
                throw new AuthException(
                    "Player has insufficient balance",
                    "رصيد اللاعب غير كافٍ لدفع الجلسة",
                    "INSUFFICIENT_BALANCE");
            }

            session.Status = CoachSessionStatus.Confirmed;
            session.IsPaid = true;
            await _db.SaveChangesAsync();

            // قيد أرباح المدرب في المعاملة نفسها: فشلٌ بعد الخصم لا يترك جلسة
            // مدفوعة مؤكدة بلا أرباح. المدرب يستلم سعره كاملاً — نسبة سبورتا
            // دفعها اللاعب فوق السعر.
            await _wallet.CreditEarningAsync(
                session.CoachProfile.UserId, session.CoachNetAmount(),
                WalletTransactionType.CoachEarning,
                $"أرباح جلسة مع {session.Player?.FirstName ?? "لاعب"}".Trim(),
                session.Id);
            await tx.CommitAsync();
        }

        // الطلبات المعلّقة الأخرى للمدرب في الوقت نفسه صارت مستحيلة التأكيد:
        // تُرفض الآن بدل أن تحجز ملاعبها حتى يمضي موعدها.
        var end = session.ScheduledAt.AddMinutes(session.DurationMinutes);
        var clashing = await _db.CoachSessions
            .Where(s => s.CoachProfileId == session.CoachProfileId &&
                        s.Id != session.Id &&
                        s.Status == CoachSessionStatus.Pending &&
                        s.ScheduledAt < end &&
                        s.ScheduledAt.AddMinutes(s.DurationMinutes) > session.ScheduledAt)
            .ToListAsync();
        foreach (var other in clashing)
            other.Status = CoachSessionStatus.Rejected;
        await _db.SaveChangesAsync();
        return clashing;
    }

    /// <summary>
    /// سبب يمنع تأكيد طلب جلسة معلّق، أو null: موعد مضى، أو جلسة مؤكدة أخرى
    /// للمدرب تتداخل معه، أو إشغال للملعب (غير الطلب نفسه) في وقته.
    /// </summary>
    private async Task<AuthException?> SessionConflictAsync(CoachSession session)
    {
        if (session.ScheduledAt <= AppClock.Now)
            return new AuthException(
                "Session time has passed — the request was rejected",
                "مضى موعد الجلسة قبل الموافقة، فرُفض الطلب تلقائياً", "SESSION_EXPIRED");

        var start = session.ScheduledAt;
        var end = start.AddMinutes(session.DurationMinutes);

        var coachBusy = await _db.CoachSessions.AnyAsync(s =>
            s.CoachProfileId == session.CoachProfileId &&
            s.Id != session.Id &&
            s.Status == CoachSessionStatus.Confirmed &&
            !s.IsCompleted &&
            s.ScheduledAt < end &&
            s.ScheduledAt.AddMinutes(s.DurationMinutes) > start);
        if (coachBusy)
            return new AuthException(
                "Coach is already booked at this time — the request was rejected",
                "لديك جلسة مؤكدة في هذا الوقت، فرُفض الطلب تلقائياً", "COACH_SLOT_TAKEN");

        if (session.CourtId is int courtId)
        {
            // الطلب المعلّق نفسه يشغل الملعب في حساب الإشغال، فتُطرح فترته مرة واحدة.
            var ranges = await CourtOccupancy.ForCourtAsync(_db, courtId, start, end);
            ranges.Remove((start, end));
            if (ranges.Count > 0)
                return new AuthException(
                    "The court is no longer free at this time — the request was rejected",
                    "الملعب لم يعد متاحاً في هذا الوقت، فرُفض الطلب تلقائياً", "SLOT_TAKEN");
        }

        return null;
    }

    /// <summary>رفض تلقائي لطلب معلّق لم يعد ممكن التأكيد، مع إبلاغ اللاعب.</summary>
    private async Task AutoRejectAsync(CoachSession session)
    {
        session.Status = CoachSessionStatus.Rejected;
        await _db.SaveChangesAsync();
        await NotifyAutoRejectedAsync(session);
    }

    private Task NotifyAutoRejectedAsync(CoachSession session) =>
        _notifications.PushAsync(session.PlayerId, "تم رفض حجزك",
            "تعذّر تأكيد جلسة التدريب في موعدها", "coach_session_rejected", session.Id);

    public async Task<PagedResult<CoachSessionDto>> GetMySessionsAsync(
        int playerId, int page, int pageSize, string? status)
    {
        var query = _db.CoachSessions
            .Include(s => s.CoachProfile)
            .ThenInclude(c => c.User)
            .Where(s => s.PlayerId == playerId);

        // status: "upcoming" | "completed"
        if (string.Equals(status, "upcoming", StringComparison.OrdinalIgnoreCase))
            query = query.Where(s => !s.IsCompleted);
        else if (string.Equals(status, "completed", StringComparison.OrdinalIgnoreCase))
            query = query.Where(s => s.IsCompleted);

        var total = await query.CountAsync();
        var sessions = await query
            .OrderByDescending(s => s.ScheduledAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<CoachSessionDto>
        {
            Items = sessions.Select(s => ToSessionDto(s, s.CoachProfile)).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    public async Task<CoachDashboardDto> GetDashboardAsync(int coachUserId)
    {
        var coach = await _db.CoachProfiles
            .Include(c => c.User).ThenInclude(u => u.CityRef)
            .FirstOrDefaultAsync(c => c.UserId == coachUserId);
        if (coach == null) return new CoachDashboardDto();

        var sessions = await _db.CoachSessions
            .Include(s => s.Player)
            .Where(s => s.CoachProfileId == coach.Id)
            .ToListAsync();

        // Sessions store naive KSA wall-clock ScheduledAt, so compare with AppClock.
        var now = AppClock.Now;
        var monthStart = new DateTime(now.Year, now.Month, 1);
        var weekEnd = now.AddDays(7);

        var upcoming = sessions
            .Where(s => s.ScheduledAt >= now && !s.IsCompleted)
            .OrderBy(s => s.ScheduledAt)
            .Take(5)
            .Select(s => ToSessionDto(s, coach))
            .ToList();

        // التقييم يُحسب حيًا من تقييمات اللاعبين للجلسات (لا من حقل مخزّن).
        var playerRatings = sessions
            .Where(s => s.PlayerRating != null)
            .Select(s => s.PlayerRating!.Value)
            .ToList();

        var recentRatings = sessions
            .Where(s => s.PlayerRating != null)
            .OrderByDescending(s => s.ScheduledAt)
            .Take(5)
            .Select(s => new CoachRatingDto
            {
                SessionId = s.Id,
                PlayerName = s.Player != null
                    ? $"{s.Player.FirstName} {s.Player.LastName}".Trim()
                    : "لاعب",
                Rating = s.PlayerRating!.Value,
                Review = s.PlayerReview,
                ScheduledAt = s.ScheduledAt,
            })
            .ToList();

        return new CoachDashboardDto
        {
            // الطالب النشط من له جلسة مؤكدة — الطلبات المعلّقة والمرفوضة لا تُحسب.
            ActiveStudents = sessions
                .Where(s => s.Status == CoachSessionStatus.Confirmed)
                .Select(s => s.PlayerId).Distinct().Count(),
            Rating = playerRatings.Count == 0
                ? 0f
                : (float)Math.Round(playerRatings.Average(), 1),
            TotalSessions = sessions.Count,
            MonthRevenue = sessions
                .Where(s => s.IsPaid && s.ScheduledAt >= monthStart)
                .Sum(s => s.Price),
            TotalRevenue = sessions.Where(s => s.IsPaid).Sum(s => s.Price),
            WeekSessions = sessions.Count(s => s.ScheduledAt >= now && s.ScheduledAt < weekEnd),
            UpcomingSessions = upcoming,
            RecentRatings = recentRatings,
        };
    }

    /// <summary>A coach rating at or above this raises the player one level.</summary>
    private const int GoodRatingThreshold = 4;

    public async Task<CoachSessionDto> RateSessionAsync(
        int coachUserId, int sessionId, int rating, string? review)
    {
        var session = await _db.CoachSessions
            .Include(s => s.CoachProfile).ThenInclude(c => c.User)
            .Include(s => s.Player)
            .FirstOrDefaultAsync(s => s.Id == sessionId)
            ?? throw new AuthException("Session not found", "الجلسة غير موجودة", "SESSION_NOT_FOUND");

        if (session.CoachProfile.UserId != coachUserId)
            throw new AuthException(
                "Only the session coach can rate the player",
                "فقط مدرب الجلسة يمكنه تقييم اللاعب", "NOT_SESSION_COACH");

        if (session.Status != CoachSessionStatus.Confirmed)
            throw new AuthException(
                "Session is not confirmed", "الجلسة غير مؤكدة", "SESSION_NOT_CONFIRMED");

        if (!session.IsPaid)
            throw new AuthException(
                "Session is not paid yet",
                "لا يمكن التقييم قبل دفع الجلسة", "SESSION_NOT_PAID");

        // ScheduledAt is naive KSA wall-clock time, so compare with AppClock.
        if (AppClock.Now < session.ScheduledAt.AddMinutes(session.DurationMinutes))
            throw new AuthException(
                "Session has not ended yet",
                "لا يمكن التقييم قبل انتهاء الجلسة", "SESSION_NOT_ENDED");

        if (session.CoachRating != null)
            throw new AuthException(
                "Session already rated", "تم تقييم الجلسة مسبقًا", "ALREADY_RATED");

        session.CoachRating = rating;
        session.CoachReview = review;
        session.IsCompleted = true;
        session.UpdatedAt = DateTime.UtcNow;

        // تقييم جيد من المدرب يرفع مستوى اللاعب درجة واحدة (حتى النخبة).
        var leveledUp = false;
        if (rating >= GoodRatingThreshold)
        {
            var profile = await _db.PlayerProfiles
                .FirstOrDefaultAsync(p => p.UserId == session.PlayerId);
            if (profile != null && profile.Level < PlayerLevel.Elite)
            {
                profile.Level += 1;
                profile.UpdatedAt = DateTime.UtcNow;
                leveledUp = true;
            }
        }

        await _db.SaveChangesAsync();

        // نسخة في جدول التقييمات الموحّد (سمعة اللاعب) — مسار التطبيقات القديمة.
        await ReviewStore.UpsertAsync(
            _db, coachUserId, ReviewerRole.Coach, ReviewTargetType.Player, session.PlayerId,
            ReviewContextType.CoachSession, session.Id, rating, null, review, overwrite: false);

        await _notifications.PushAsync(session.PlayerId, "قيّمك المدرب",
            leveledUp
                ? $"منحك المدرب {rating} نجوم عن جلسة التدريب وارتفع مستواك درجة 🎉"
                : $"منحك المدرب {rating} نجوم عن جلسة التدريب",
            "coach_session_rated", session.Id);

        return ToSessionDto(session, session.CoachProfile);
    }

    public async Task<CoachSessionDto> RateCoachAsync(
        int playerId, int sessionId, int rating, string? review)
    {
        var session = await _db.CoachSessions
            .Include(s => s.CoachProfile).ThenInclude(c => c.User)
            .Include(s => s.Player)
            .FirstOrDefaultAsync(s => s.Id == sessionId)
            ?? throw new AuthException("Session not found", "الجلسة غير موجودة", "SESSION_NOT_FOUND");

        if (session.PlayerId != playerId)
            throw new AuthException(
                "Only the session player can rate the coach",
                "فقط لاعب الجلسة يمكنه تقييم المدرب", "NOT_SESSION_PLAYER");

        if (session.Status != CoachSessionStatus.Confirmed)
            throw new AuthException(
                "Session is not confirmed", "الجلسة غير مؤكدة", "SESSION_NOT_CONFIRMED");

        if (!session.IsPaid)
            throw new AuthException(
                "Session is not paid yet",
                "لا يمكن التقييم قبل دفع الجلسة", "SESSION_NOT_PAID");

        // ScheduledAt is naive KSA wall-clock time, so compare with AppClock.
        if (AppClock.Now < session.ScheduledAt.AddMinutes(session.DurationMinutes))
            throw new AuthException(
                "Session has not ended yet",
                "لا يمكن التقييم قبل انتهاء الجلسة", "SESSION_NOT_ENDED");

        if (session.PlayerRating != null)
            throw new AuthException(
                "Coach already rated", "تم تقييم المدرب مسبقًا", "ALREADY_RATED");

        session.PlayerRating = rating;
        session.PlayerReview = review;
        session.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        await ReviewStore.UpsertAsync(
            _db, playerId, ReviewerRole.Player, ReviewTargetType.Coach, session.CoachProfile.UserId,
            ReviewContextType.CoachSession, session.Id, rating, null, review, overwrite: false);

        // نقاط مكافآت للاعب على تقييم المدرب (reward_points_rate_coach).
        await _points.EarnActivityAsync(
            session.PlayerId, PointsTransactionType.CoachRated, session.Id,
            "نقاط تقييم مدرب");

        await _notifications.PushAsync(session.CoachProfile.UserId, "قيّمك لاعب",
            $"منحك {session.Player?.FirstName ?? "لاعب"} {rating} نجوم عن جلسة التدريب",
            "coach_rated_by_player", session.Id);

        return ToSessionDto(session, session.CoachProfile);
    }

    private static Gender? TryParseGender(string? value) =>
        value?.Trim().ToLowerInvariant() switch
        {
            "male" or "men" or "m" or "رجال" => Gender.Male,
            "female" or "women" or "f" or "نساء" => Gender.Female,
            _ => null,
        };

    // ── mapping ────────────────────────────────────────────────────────────────

    private static CoachSessionDto ToSessionDto(CoachSession s, CoachProfile coach) => new()
    {
        Id = s.Id,
        CoachId = coach.Id,
        CoachName = $"{coach.User.FirstName} {coach.User.LastName}".Trim(),
        ScheduledAt = s.ScheduledAt,
        DurationMinutes = s.DurationMinutes,
        // المعروض هو ما يدفعه اللاعب: سعر المدرب + نسبة سبورتا فوقه.
        Price = s.PlayerTotal(),
        // الجلسات المحجوزة قبل إضافة حقلي الخصم تُرجع صفراً، فنعرض السعر نفسه.
        BasePrice = Math.Round(
            (s.BasePrice > 0 ? s.BasePrice : s.Price) *
            (1m + s.SportaCommissionPercent / 100m), 2),
        OfferDiscountPercent = s.OfferDiscountPercent,
        Title = s.Title,
        Description = s.Description,
        IsPaid = s.IsPaid,
        CoachRating = s.CoachRating,
        CoachReview = s.CoachReview,
        PlayerRating = s.PlayerRating,
        PlayerReview = s.PlayerReview,
        Status = s.IsCompleted
            ? "Completed"
            : s.Status switch
            {
                CoachSessionStatus.Pending => "pending",
                CoachSessionStatus.Rejected => "rejected",
                _ => "Upcoming",
            },
        PlayerName = s.Player != null
            ? $"{s.Player.FirstName} {s.Player.LastName}".Trim()
            : null,
    };

    public async Task<PagedResult<LevelAssessmentDto>> GetPendingAssessmentsAsync(
        int coachUserId, int page = 1, int pageSize = 20)
    {
        (page, pageSize) = Paging.Clamp(page, pageSize);

        var query = _db.LevelAssessments
            .Include(a => a.Coach)
            .Include(a => a.PlayerProfile).ThenInclude(p => p.User)
            .Where(a => !a.IsCompleted &&
                        (a.Type == LevelAssessmentType.VideoUpload ||
                         (a.Type == LevelAssessmentType.CoachSession && a.CoachId == coachUserId)));

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(a => a.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<LevelAssessmentDto>
        {
            Items = items.Select(a => PlayerService.ToAssessmentDto(a, a.Coach)).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    public async Task<LevelAssessmentDto> AssignAssessmentLevelAsync(
        int coachUserId, int assessmentId, int level, string? notes)
    {
        var a = await _db.LevelAssessments
            .Include(x => x.Coach)
            .Include(x => x.PlayerProfile).ThenInclude(p => p.User)
            .FirstOrDefaultAsync(x => x.Id == assessmentId)
            ?? throw new AuthException("Assessment not found", "التقييم غير موجود", "ASSESSMENT_NOT_FOUND");

        if (a.IsCompleted)
            throw new AuthException("Already assessed", "تم التقييم بالفعل", "ALREADY_ASSESSED");

        if (a.Type == LevelAssessmentType.CoachSession && a.CoachId != coachUserId)
            throw new AuthException("Not assigned to you", "غير مُسند إليك", "NOT_ASSIGNED");

        // تقييم الفيديو يراجعه مدرب معتمد فقط — فحص ثانٍ بعد سمة الكنترولر لأن
        // السمة تمرّر من لا يملك الدور أصلاً.
        if (!await _db.UserRoles.AnyAsync(r =>
                r.UserId == coachUserId && r.Role == UserType.Coach && r.IsApproved))
            throw new AuthException(
                "Only approved coaches can assess players",
                "تقييم المستوى للمدربين المعتمدين فقط", "COACH_ONLY");

        if (a.Type == LevelAssessmentType.SelfAssessment)
            throw new AuthException("Not reviewable", "غير قابل للمراجعة", "NOT_REVIEWABLE");

        var lvl = (PlayerLevel)Math.Clamp(level, 1, 7);
        a.AssignedLevel = lvl;
        a.IsCompleted = true;
        a.Notes = notes;
        a.CoachId ??= coachUserId; // record the reviewing coach for video uploads
        a.PlayerProfile.Level = lvl;
        a.PlayerProfile.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return PlayerService.ToAssessmentDto(a, a.Coach);
    }

    // ── إحصائيات حية من الحجوزات والتقييمات ────────────────────────────────────

    /// <summary>عتبات الاعتماد التلقائي: يظهر المدرب "معتمدًا" متى أكمل هذا العدد
    /// من الجلسات المدفوعة وبلغ متوسط تقييمات اللاعبين له الحد الأدنى (بعدد
    /// تقييمات كافٍ). علم الأدمن IsVerifiedOnPlatform يبقى اعتمادًا يدويًا فوق ذلك.</summary>
    private const int VerifiedMinSessions = 10;
    private const int VerifiedMinRatings = 5;
    private const float VerifiedMinRating = 4.0f;

    private sealed record CoachStats(int Sessions, int Ratings, float Rating)
    {
        public static readonly CoachStats Empty = new(0, 0, 0f);
    }

    /// <summary>يحسب إحصائيات كل مدرب من جلساته الفعلية: الجلسات المحتسبة هي
    /// المؤكدة المدفوعة التي انتهى وقتها، والتقييم هو متوسط تقييمات اللاعبين.</summary>
    private async Task<Dictionary<int, CoachStats>> LoadStatsAsync(List<int> coachProfileIds)
    {
        if (coachProfileIds.Count == 0) return [];

        var rows = await _db.CoachSessions
            .Where(s => coachProfileIds.Contains(s.CoachProfileId) &&
                        s.Status == CoachSessionStatus.Confirmed &&
                        s.IsPaid)
            .Select(s => new { s.CoachProfileId, s.ScheduledAt, s.DurationMinutes, s.PlayerRating })
            .ToListAsync();

        // ScheduledAt is naive KSA wall-clock time, so compare with AppClock.
        var now = AppClock.Now;
        return rows
            .Where(r => r.ScheduledAt.AddMinutes(r.DurationMinutes) <= now)
            .GroupBy(r => r.CoachProfileId)
            .ToDictionary(
                g => g.Key,
                g =>
                {
                    var ratings = g.Where(r => r.PlayerRating != null)
                        .Select(r => r.PlayerRating!.Value)
                        .ToList();
                    return new CoachStats(
                        g.Count(),
                        ratings.Count,
                        ratings.Count == 0
                            ? 0f
                            : (float)Math.Round(ratings.Average(), 1));
                });
    }

    private async Task<CoachDto> ToDtoAsync(CoachProfile c)
    {
        var stats = await LoadStatsAsync([c.Id]);
        return ToDto(c, stats.GetValueOrDefault(c.Id, CoachStats.Empty));
    }

    private static CoachDto ToDto(CoachProfile c, CoachStats stats) => new()
    {
        Id = c.Id,
        UserId = c.UserId,
        Name = $"{c.User.FirstName} {c.User.LastName}".Trim(),
        NameEn = c.NameEn,
        AvatarUrl = c.User.ProfileImageUrl,
        Bio = c.Bio,
        Specialization = c.Specialization,
        Specialties = SplitSpecialties(c.Specialization),
        SportId = c.SportId,
        SportName = c.Sport?.NameAr,
        SportNameEn = c.Sport?.NameEn,
        HourlyRate = c.HourlyRate,
        OfferDiscountPercent = BestOfferPercent(c.Offers, "individual"),
        HourlyRateAfterOffer =
            ApplyOffer(c.HourlyRate, BestOfferPercent(c.Offers, "individual")),
        Rating = stats.Rating,
        Reviews = stats.Ratings,
        Students = stats.Sessions,
        City = c.User.City,
        CityEn = c.User.CityRef?.NameEn,
        IsVerified = c.IsVerifiedOnPlatform ||
                     (stats.Sessions >= VerifiedMinSessions &&
                      stats.Ratings >= VerifiedMinRatings &&
                      stats.Rating >= VerifiedMinRating),
        Gender = c.User.Gender switch
        {
            Gender.Male => "male",
            Gender.Female => "female",
            _ => "unknown",
        },
        Phone = c.User.PhoneNumber,
        IdDocumentUrl = c.IdDocumentUrl,
        IsActive = c.User.IsActive,
        JoinedAt = c.User.CreatedAt,
        Certifications = c.Certifications,
        ExperienceLevel = c.ExperienceLevel switch
        {
            CoachExperienceLevel.LessThanYear => "lessThanYear",
            CoachExperienceLevel.OneToThree => "oneToThree",
            CoachExperienceLevel.ThreeToFive => "threeToFive",
            _ => "moreThanFive",
        },
        TargetGender = c.TargetGender == Gender.Female ? "female" : "male",
        PackagePrice = c.PackagePrice,
        PreferredVenueId = c.PreferredVenueId,
        PreferredVenueName = c.PreferredVenue?.Name,
        AvailableDays = string.IsNullOrWhiteSpace(c.AvailableDays)
            ? []
            : c.AvailableDays.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList(),
        Residency = c.Residency == CoachResidency.Resident ? "resident" : "saudi",
        NationalIdFrontUrl = c.NationalIdFrontUrl,
        NationalIdBackUrl = c.NationalIdBackUrl,
        SpecializationIds = c.Specializations.Select(s => s.SpecializationId).ToList(),
        SpecializationNames = c.Specializations
            .Where(s => s.Specialization != null)
            .Select(s => s.Specialization.NameAr)
            .ToList(),
        // Only active, non-expired offers are surfaced publicly (players/coach card).
        Offers = c.Offers
            .Where(o => o.IsActive && o.ExpiresAt >= AppClock.Now)
            .OrderBy(o => o.ExpiresAt)
            .Select(o => new CoachOfferDto
            {
                Id = o.Id,
                Title = o.Title,
                DiscountPercent = o.DiscountPercent,
                TargetLabel = o.TargetLabel,
                ExpiresAt = o.ExpiresAt,
                IsActive = o.IsActive,
                IsExpired = false,
            })
            .ToList(),
    };

    private static List<string> SplitSpecialties(string? specialization)
    {
        if (string.IsNullOrWhiteSpace(specialization)) return [];
        return specialization
            .Split([',', '،', '/'], StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .ToList();
    }

    // ── إدارة الطلاب ─────────────────────────────────────────────────────────

    public async Task<PagedResult<CoachStudentDto>> GetStudentsAsync(
        int coachUserId, int page = 1, int pageSize = 20)
    {
        var coach = await _db.CoachProfiles
            .FirstOrDefaultAsync(c => c.UserId == coachUserId)
            ?? throw new AuthException(
                "Coach profile not found", "ملف المدرب غير موجود", "NOT_COACH");

        var sessions = await _db.CoachSessions
            .Include(s => s.Player)
            .Where(s => s.CoachProfileId == coach.Id && s.IsPaid)
            .ToListAsync();

        var students = sessions
            .GroupBy(s => s.PlayerId)
            .Select(g => new CoachStudentDto
            {
                PlayerId = g.Key,
                PlayerName = g.First().Player != null
                    ? $"{g.First().Player.FirstName} {g.First().Player.LastName}".Trim()
                    : "لاعب",
                AvatarUrl = g.First().Player?.ProfileImageUrl,
                SessionsCount = g.Count(),
                TotalSpent = g.Sum(s => s.Price),
                LastSessionAt = g.Max(s => s.ScheduledAt),
            })
            .OrderByDescending(s => s.LastSessionAt)
            .ToList();

        return PagedResult<CoachStudentDto>.Create(students, page, pageSize);
    }

    // ── التقارير المالية ─────────────────────────────────────────────────────

    private static readonly string[] ArabicMonths =
    [
        "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
        "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر",
    ];

    private static readonly string[] ArabicWeekdaysShort =
        ["سبت", "أحد", "اثن", "ثلا", "أرب", "خمي", "جمع"];

    public async Task<CoachRevenueReportDto> GetRevenueReportAsync(
        int coachUserId, string periodType, int offset)
    {
        var coach = await _db.CoachProfiles
            .FirstOrDefaultAsync(c => c.UserId == coachUserId)
            ?? throw new AuthException(
                "Coach profile not found", "ملف المدرب غير موجود", "NOT_COACH");

        var isWeek = periodType.Equals("week", StringComparison.OrdinalIgnoreCase);

        var now = AppClock.Now;
        var today = now.Date;
        DateTime periodStart, periodEnd, prevStart, prevEnd;
        string periodLabel;
        List<(DateTime from, DateTime to, string label)> buckets;

        if (isWeek)
        {
            var daysSinceSaturday = ((int)today.DayOfWeek - (int)DayOfWeek.Saturday + 7) % 7;
            var currentWeekStart = today.AddDays(-daysSinceSaturday);
            periodStart = currentWeekStart.AddDays(-7 * offset);
            periodEnd = periodStart.AddDays(7);
            prevStart = periodStart.AddDays(-7);
            prevEnd = periodStart;

            var lastDay = periodEnd.AddDays(-1);
            periodLabel = periodStart.Month == lastDay.Month
                ? $"{periodStart.Day}–{lastDay.Day} {ArabicMonths[periodStart.Month - 1]}"
                : $"{periodStart.Day} {ArabicMonths[periodStart.Month - 1]} – {lastDay.Day} {ArabicMonths[lastDay.Month - 1]}";

            buckets = Enumerable.Range(0, 7)
                .Select(i => (periodStart.AddDays(i), periodStart.AddDays(i + 1), ArabicWeekdaysShort[i]))
                .ToList();
        }
        else
        {
            var currentMonthStart = new DateTime(now.Year, now.Month, 1);
            periodStart = currentMonthStart.AddMonths(-offset);
            periodEnd = periodStart.AddMonths(1);
            prevStart = periodStart.AddMonths(-1);
            prevEnd = periodStart;
            periodLabel = $"{ArabicMonths[periodStart.Month - 1]} {periodStart.Year}";

            buckets = [];
            var weekNo = 1;
            for (var d = periodStart; d < periodEnd; d = d.AddDays(7))
            {
                var to = d.AddDays(7) > periodEnd ? periodEnd : d.AddDays(7);
                buckets.Add((d, to, $"الأسبوع {weekNo}"));
                weekNo++;
            }
        }

        var relevantSessions = await _db.CoachSessions
            .Include(s => s.Player)
            .Where(s => s.CoachProfileId == coach.Id &&
                        s.IsPaid &&
                        s.ScheduledAt >= prevStart && s.ScheduledAt < periodEnd)
            .ToListAsync();

        var periodSessions = relevantSessions
            .Where(s => s.ScheduledAt >= periodStart && s.ScheduledAt < periodEnd)
            .ToList();
        var prevTotal = relevantSessions
            .Where(s => s.ScheduledAt >= prevStart && s.ScheduledAt < prevEnd)
            .Sum(s => s.Price);

        var total = periodSessions.Sum(s => s.Price);

        var bars = buckets
            .Select(bk => new RevenueBarDto
            {
                Label = bk.label,
                Amount = periodSessions
                    .Where(s => s.ScheduledAt >= bk.from && s.ScheduledAt < bk.to)
                    .Sum(s => s.Price),
            })
            .ToList();

        var levelBreakdown = periodSessions
            .GroupBy(s => string.IsNullOrWhiteSpace(s.TargetLevel) ? "غير محدد" : s.TargetLevel)
            .Select(g => new CoachRevenueBreakdownDto
            {
                Label = g.Key,
                Total = g.Sum(s => s.Price),
                SessionsCount = g.Count(),
                Percent = total > 0 ? (double)(g.Sum(s => s.Price) / total * 100) : 0,
            })
            .OrderByDescending(b => b.Total)
            .ToList();

        var transactions = periodSessions
            .OrderByDescending(s => s.ScheduledAt)
            .Take(50)
            .Select(s => new CoachRevenueTransactionDto
            {
                PlayerName = s.Player != null
                    ? $"{s.Player.FirstName} {s.Player.LastName}".Trim()
                    : "لاعب",
                TargetLevel = s.TargetLevel,
                Amount = s.Price,
                Date = s.ScheduledAt,
            })
            .ToList();

        return new CoachRevenueReportDto
        {
            PeriodType = isWeek ? "week" : "month",
            PeriodLabel = periodLabel,
            Total = total,
            ChangePercent = prevTotal > 0 ? (double)((total - prevTotal) / prevTotal * 100) : null,
            Bars = bars,
            LevelBreakdown = levelBreakdown,
            Transactions = transactions,
        };
    }

    // ── العروض والخصومات ─────────────────────────────────────────────────────

    private static readonly HashSet<string> ValidOfferTargets = ["individual", "group", "all"];

    /// <summary>
    /// أعلى نسبة خصم بين عروض المدرب السارية على نوع الحجز المطلوب
    /// ([target] = "individual" أو "group"؛ عروض "all" تسري على الاثنين).
    /// العروض المتوقفة أو المنتهية تُستثنى. صفر حين لا عرض ساري.
    /// </summary>
    private static decimal BestOfferPercent(
        IEnumerable<CoachOffer>? offers, string target)
    {
        if (offers is null) return 0m;
        var now = AppClock.Now;
        var matching = offers.Where(o =>
            o.IsActive &&
            o.ExpiresAt >= now &&
            (o.TargetLabel == target || o.TargetLabel == "all"));
        return matching.Any() ? matching.Max(o => (decimal)o.DiscountPercent) : 0m;
    }

    /// <summary>يطبّق نسبة الخصم على السعر (النسبة مقيّدة بين ٠ و١٠٠).</summary>
    private static decimal ApplyOffer(decimal price, decimal percent)
    {
        if (percent <= 0) return price;
        var capped = Math.Min(percent, 100m);
        return Math.Round(price * (1m - capped / 100m), 2);
    }

    private static CoachOfferDto ToOfferDto(CoachOffer o) => new()
    {
        Id = o.Id,
        Title = o.Title,
        DiscountPercent = o.DiscountPercent,
        TargetLabel = o.TargetLabel,
        ExpiresAt = o.ExpiresAt,
        IsActive = o.IsActive,
        IsExpired = o.ExpiresAt < AppClock.Now,
    };

    private async Task<CoachProfile> GetOwnCoachProfileAsync(int coachUserId) =>
        await _db.CoachProfiles.FirstOrDefaultAsync(c => c.UserId == coachUserId)
        ?? throw new AuthException(
            "Coach profile not found", "ملف المدرب غير موجود", "NOT_COACH");

    public async Task<List<CoachOfferDto>> GetMyOffersAsync(int coachUserId)
    {
        var coach = await GetOwnCoachProfileAsync(coachUserId);
        var offers = await _db.CoachOffers
            .Where(o => o.CoachProfileId == coach.Id)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync();
        return offers.Select(ToOfferDto).ToList();
    }

    public async Task<CoachOfferDto> CreateOfferAsync(int coachUserId, CreateCoachOfferRequest req)
    {
        var coach = await GetOwnCoachProfileAsync(coachUserId);

        var target = req.TargetLabel.Trim().ToLowerInvariant();
        if (!ValidOfferTargets.Contains(target))
            throw new AuthException(
                "Invalid offer target", "الفئة المستهدفة للعرض غير صحيحة", "INVALID_OFFER_TARGET");

        if (req.ExpiresAt <= AppClock.Now)
            throw new AuthException(
                "Expiry date must be in the future",
                "تاريخ الانتهاء يجب أن يكون في المستقبل", "OFFER_EXPIRY_PAST");

        var offer = new CoachOffer
        {
            CoachProfileId = coach.Id,
            Title = req.Title.Trim(),
            DiscountPercent = req.DiscountPercent,
            TargetLabel = target,
            ExpiresAt = req.ExpiresAt,
            IsActive = true,
        };
        _db.CoachOffers.Add(offer);
        await _db.SaveChangesAsync();

        return ToOfferDto(offer);
    }

    public async Task<CoachOfferDto> SetOfferActiveAsync(int coachUserId, int offerId, bool isActive)
    {
        var coach = await GetOwnCoachProfileAsync(coachUserId);
        var offer = await _db.CoachOffers
            .FirstOrDefaultAsync(o => o.Id == offerId && o.CoachProfileId == coach.Id)
            ?? throw new AuthException("Offer not found", "العرض غير موجود", "OFFER_NOT_FOUND");

        offer.IsActive = isActive;
        offer.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return ToOfferDto(offer);
    }

    public async Task DeleteOfferAsync(int coachUserId, int offerId)
    {
        var coach = await GetOwnCoachProfileAsync(coachUserId);
        var offer = await _db.CoachOffers
            .FirstOrDefaultAsync(o => o.Id == offerId && o.CoachProfileId == coach.Id)
            ?? throw new AuthException("Offer not found", "العرض غير موجود", "OFFER_NOT_FOUND");

        _db.CoachOffers.Remove(offer);
        await _db.SaveChangesAsync();
    }
}
