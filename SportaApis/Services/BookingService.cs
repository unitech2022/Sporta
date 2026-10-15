using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

public class BookingService : IBookingService
{
    private readonly AppDbContext _db;
    private readonly IWalletService _wallet;
    private readonly INotificationService _notifications;
    private readonly IPointsService _points;
    private readonly IDiscountService _discounts;
    private readonly IMembershipService _memberships;

    public BookingService(
        AppDbContext db, IWalletService wallet, INotificationService notifications,
        IPointsService points, IDiscountService discounts, IMembershipService memberships)
    {
        _memberships = memberships;
        _db = db;
        _wallet = wallet;
        _notifications = notifications;
        _points = points;
        _discounts = discounts;
    }

    /// <summary>
    /// تسعير حجز واحد: السعر الأساسي، خصومات اللاعب المطبَّقة عليه، والإجمالي
    /// وعمولة سبورتا بعد الخصوم. مصدر وحيد للحقيقة يستخدمه الإنشاء والعرض معاً.
    /// <paramref name="commit"/> = true عند إنشاء الحجز فعلاً: يحجز مقاعد عروض
    /// «أول N». العرض المسبق (quote) يمرّر false فلا يستهلك مقعداً بمجرد التصفح.
    /// </summary>
    private async Task<(decimal Base, decimal DiscountPercent, decimal DiscountAmount,
        decimal Total, decimal Commission, MemberDiscount? Member)> PriceAsync(
        Court court, int userId, DateTime start, int durationMinutes, bool commit)
    {
        // سعر المالك — يستلمه كاملاً دائماً، ونسبة سبورتا تُضاف فوقه فيدفع
        // اللاعب المجموع. تُلتقط النسبة كلقطة حتى لا يؤثر تغييرها لاحقًا.
        var fullBase = CourtSchedule.BaseBookingPrice(court, start, durationMinutes);

        // خصم عضوية النادي — يُموَّل من سعر المالك (يستلم السعر بعد الخصم)،
        // ونسبة سبورتا تُحسب على السعر المخفَّض. السقف الشهري يُطبَّق بالتناسب:
        // حجز 90 دقيقة وبقي من السقف 60 ⇒ الخصم على ثلثيه فقط.
        MemberDiscount? member = null;
        // العضوية يجب أن تغطي موعد الحجز نفسه، لا لحظة الحجز فقط.
        var terms = await _memberships.GetActiveTermsAsync(userId, court.VenueId, start);
        if (terms != null && durationMinutes > 0)
        {
            var minutes = terms.RemainingMinutes is int left
                ? Math.Min(left, durationMinutes) : durationMinutes;
            if (minutes > 0)
            {
                var amount = Math.Round(
                    fullBase * terms.DiscountPercent / 100m * minutes / durationMinutes, 2);
                member = new MemberDiscount(terms.MembershipId, terms.PlanName, amount, minutes);
            }
        }
        var basePrice = fullBase - (member?.Amount ?? 0m);

        // شروط عمولة سبورتا الآتية من اشتراك المالك الساري: نسبة بديلة كاملة
        // (اشتراك «بالنسبة») أو تخفيض على نسبة الملعب.
        var (ownerSubDiscount, ownerSubOverride) =
            await _points.GetActiveCommissionTermsAsync(court.Venue.OwnerId);

        decimal CommissionFor(decimal price) => ownerSubOverride is decimal overridePercent
            ? Math.Round(price * overridePercent / 100m, 2)
            : CourtSchedule.CommissionOn(court, price);
        var commission = CommissionFor(basePrice);
        var fullCommission = CommissionFor(fullBase);

        // خصم على العمولة يخص مالك هذا الملعب (عرض عام أو مخصص له) — يخفّض
        // نصيب سبورتا المضاف فينخفض ما يدفعه اللاعب على هذا الملعب.
        var ownerPercent = commit
            ? await _discounts.GetPercentAsync(
                DiscountTarget.VenueCommission, court.Venue.OwnerId)
            : await _discounts.PeekPercentAsync(
                DiscountTarget.VenueCommission, court.Venue.OwnerId);
        if (ownerPercent > 0)
        {
            commission = Math.Round(commission * (1m - ownerPercent / 100m), 2);
            fullCommission = Math.Round(fullCommission * (1m - ownerPercent / 100m), 2);
        }

        // تخفيض العمولة الآتي من اشتراك المالك (شهري/سنوي) — يُطبَّق فوق خصم
        // العروض، فيبقى صافي مستحقات المالك أعلى طوال مدة اشتراكه.
        if (ownerSubDiscount > 0)
        {
            commission = Math.Round(commission * (1m - ownerSubDiscount / 100m), 2);
            fullCommission = Math.Round(fullCommission * (1m - ownerSubDiscount / 100m), 2);
        }

        // ما كان اللاعب سيدفعه قبل خصوماته: سعر المالك + نصيب سبورتا.
        var grossTotal = basePrice + commission;

        // خصومات اللاعب (باقة الاشتراك + عروض المنصة): نسبتها تُحسب من نصيب
        // سبورتا وتُقتطع منه وحده — مثال: سعر 120 ونسبة 20 وخصم منصة 50٪ ←
        // يدفع اللاعب 130 والمالك يستلم 120 كاملة.
        var (_, packagePercent) = await _points.GetActiveBenefitsAsync(userId);
        var platformPercent = commit
            ? await _discounts.GetPercentAsync(DiscountTarget.PlayerBooking, userId)
            : await _discounts.PeekPercentAsync(DiscountTarget.PlayerBooking, userId);

        var requestedPercent = Math.Clamp(packagePercent + platformPercent, 0m, 100m);
        var discount = requestedPercent <= 0
            ? 0m
            : Math.Round(commission * requestedPercent / 100m, 2);

        // النسبة المعادة هي نسبة الخصم من إجمالي ما يدفعه اللاعب، لا النسبة
        // المطلوبة من نصيب سبورتا — وإلا عرض التطبيق «خصم ٥٠٪» بجانب مبلغ زهيد.
        // الإجمالي قبل كل الخصوم (بلا عضوية) هو ما يُعرض مشطوباً.
        var originalTotal = fullBase + fullCommission;

        // ما يوفّره اللاعب بفضل العضوية بالذات (خصم المالك + نقص العمولة عليه)
        // — يُعرض في التسعير سطراً مستقلاً عن خصم الباقة.
        if (member != null)
            member = member with { PlayerSaving = originalTotal - grossTotal };
        var total = grossTotal - discount;
        var allDiscount = originalTotal - total;
        var effectivePercent = originalTotal <= 0
            ? 0m
            : Math.Round(allDiscount / originalTotal * 100m, 2);

        return (originalTotal, effectivePercent, allDiscount,
            total, commission - discount, member);
    }

    public async Task<BookingQuoteDto> QuoteAsync(int userId, BookingQuoteRequest request)
    {
        var court = await _db.Courts
            .NotDeleted()
            .Include(c => c.Venue)
            .Include(c => c.PriceTiers)
            .Include(c => c.PriceRules)
            .FirstOrDefaultAsync(c => c.Id == request.CourtId)
            ?? throw new AuthException("Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        // مدى متعدد الأيام (بطولة تحجز الملعب في نفس الموعد من كل يوم): السعر
        // مجموع أيامه، لأن كل يوم يُسعَّر وحده بقواعد تسعير المالك وقد يختلف.
        var firstDay = request.StartTime.Date;
        var lastDay = request.EndDate?.Date ?? firstDay;
        if (lastDay < firstDay) lastDay = firstDay;
        if ((lastDay - firstDay).TotalDays > CourtSchedule.MaxMultiDayRangeDays)
            lastDay = firstDay.AddDays(CourtSchedule.MaxMultiDayRangeDays);
        var timeOfDay = request.StartTime.TimeOfDay;

        var baseTotal = 0m;
        var discountTotal = 0m;
        var total = 0m;
        var memberTotal = 0m;
        string? memberPlan = null;

        for (var day = firstDay; day <= lastDay; day = day.AddDays(1))
        {
            var q = await PriceAsync(
                court, userId, day.Add(timeOfDay), request.DurationMinutes, commit: false);
            baseTotal += q.Base;
            discountTotal += q.DiscountAmount;
            total += q.Total;
            memberTotal += q.Member?.PlayerSaving ?? 0m;
            memberPlan ??= q.Member?.PlanName;
        }

        return new BookingQuoteDto
        {
            BasePrice = baseTotal,
            DiscountPercent = baseTotal <= 0
                ? 0m
                : Math.Round(discountTotal / baseTotal * 100m, 2),
            DiscountAmount = discountTotal,
            Total = total,
            MemberDiscountAmount = memberTotal,
            MembershipPlanName = memberPlan,
        };
    }

    public async Task<BookingDto> CreateAsync(int userId, CreateBookingRequest request)
    {
        var court = await _db.Courts
            .NotDeleted()
            .Include(c => c.Venue)
            .Include(c => c.PriceTiers)
            .Include(c => c.OpeningHours)
            .Include(c => c.PriceRules)
            .FirstOrDefaultAsync(c => c.Id == request.CourtId)
            ?? throw new AuthException("Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        if (!court.Venue.IsApproved)
            throw new AuthException(
                "Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        if (court.IsSuspended)
            throw new AuthException(
                "Court is suspended", "هذا الملعب موقوف حالياً", "COURT_SUSPENDED");

        // نفس شروط بحث الملاعب (نادٍ مفعّل + اشتراك ساري للمالك): ملعب أخفاه
        // البحث لا يُحجز بمعرّفه من المفضّلة أو رابط قديم.
        if (!await VenueBookability.IsBookableAsync(_db, court.Id))
            throw new AuthException(
                "Court is not available", "الملعب غير متاح للحجز", "COURT_UNAVAILABLE");

        if (!court.IsAvailable)
            throw new AuthException(
                "Court is not available", "الملعب غير متاح للحجز", "COURT_UNAVAILABLE");

        // When the owner defined booking tiers, the chosen duration must match one.
        if (CourtSchedule.HasTiers(court, Enums.CourtPriceKind.Booking) &&
            CourtSchedule.TierPrice(
                court, Enums.CourtPriceKind.Booking, request.DurationMinutes) is null)
            throw new AuthException(
                "Duration not offered for this court",
                "هذه المدة غير متاحة لهذا الملعب", "DURATION_UNAVAILABLE");

        var start = request.StartTime;
        var end = start.AddMinutes(request.DurationMinutes);

        // موعد بدأ (أو مضى) لا يُحجز — قائمة المواعيد تخفيه، وهذا يمنع نداءً
        // مباشراً أو صفحةً قديمة في يد اللاعب من تجاوزها.
        if (start <= AppClock.Now)
            throw new AuthException(
                "Selected time has already passed",
                "الوقت المختار مضى — اختر موعداً قادماً", "SLOT_IN_PAST");

        // نافذة الحجز المسبق للنادي — العضو يحجز قبل غيره بأيام أولوية خطته.
        var window = await _memberships.GetBookingWindowDaysAsync(userId, court.Venue);
        if (window is int days && start.Date > AppClock.Now.Date.AddDays(days))
        {
            // العضو تجاوز نافذته الممتدة أصلاً — لا معنى لدعوته إلى العضوية.
            var hasPriority = days > (court.Venue.BookingWindowDays ?? 0);
            var aheadAr = days switch
            {
                1 => "بيوم واحد",
                2 => "بيومين",
                <= 10 => $"بـ {days} أيام",
                _ => $"بـ {days} يوماً",
            };
            throw new AuthException(
                $"Bookings open {days} days ahead",
                hasPriority
                    ? $"يمكنك بعضويتك الحجز في هذا النادي قبل الموعد {aheadAr} كحد أقصى"
                    : $"الحجز في هذا النادي يفتح قبل الموعد {aheadAr} كحد أقصى — الأعضاء يحجزون مبكراً",
                "BOOKING_WINDOW");
        }

        if (CourtSchedule.IsClosedOn(court, start))
            throw new AuthException(
                "The court is closed on this day",
                "الملعب مغلق في هذا اليوم", "COURT_CLOSED_TODAY");

        // الحجز يجب أن يبدأ وينتهي داخل دوام يومه — لا يتخطى ساعة الإغلاق.
        if (!CourtSchedule.IsWithinOpeningHours(court, start, request.DurationMinutes))
            throw new AuthException(
                "Selected time is outside opening hours",
                "الوقت المختار خارج ساعات عمل الملعب", "OUTSIDE_OPENING_HOURS");

        var booking = await ReserveAndChargeAsync(
            court, userId, start, end, request.DurationMinutes);

        // Notify the venue owner of a booking request awaiting their approval.
        await _notifications.PushAsync(court.Venue.OwnerId, "طلب حجز جديد على ملعبك",
            $"طلب حجز {court.Name} - {court.Venue.Name} بانتظار موافقتك",
            "booking_created", booking.Id);

        return ToDto(booking, court);
    }

    /// <summary>
    /// الجزء المتسلسل من إنشاء الحجز: تحت قفل الملعب يُفحص التعارض والحجب، ثم
    /// في معاملة واحدة يُسعَّر (باستهلاك الخصم) ويُحفظ الحجز ويُخصم المبلغ.
    /// يُحرَّر القفل عند العودة، قبل إشعار المالك.
    /// </summary>
    private async Task<Booking> ReserveAndChargeAsync(
        Court court, int userId, DateTime start, DateTime end, int durationMinutes)
    {
        // قفل الملعب من فحص التعارض حتى حفظ الحجز: بدونه يمرّ طلبان متزامنان
        // على نفس الموعد من الفحص ثم يُحفظ كلاهما.
        await using var courtLock = await DbLocks.AcquireAsync(_db, $"court:{court.Id}");

        // Reject overlapping use of the same court — حجزاً كان أم مباراة أم
        // جلسة تدريب (نفس ما تعتمده قائمة المواعيد المتاحة).
        var overlaps = await CourtOccupancy.IsTakenAsync(_db, court.Id, start, end);

        if (overlaps)
            throw new AuthException(
                "This slot is already booked", "هذا الموعد محجوز بالفعل", "SLOT_TAKEN");

        // Reject if the owner has blocked any hour the booking covers
        // (نفس صيغة قائمة المواعيد: 60 دقيقة من 10:30 تلمس 10 و11).
        var coveredHours = CourtSchedule.CoveredHours(start, durationMinutes);
        var blocked = await _db.CourtBlockedSlots.AnyAsync(s =>
            s.CourtId == court.Id && s.Date == start.Date && coveredHours.Contains(s.Hour));
        if (blocked)
            throw new AuthException(
                "Slot is unavailable", "هذا الموعد غير متاح", "SLOT_UNAVAILABLE");

        // Check wallet balance upfront with a non-committing quote — رصيد لا يكفي
        // لا يستهلك مقعداً في عروض «أول N».
        var peek = await PriceAsync(
            court, userId, start, durationMinutes, commit: false);
        var balance = await _db.Wallets
            .Where(w => w.UserId == userId)
            .Select(w => (decimal?)w.Balance)
            .FirstOrDefaultAsync();
        if (balance is null || balance < peek.Total)
            throw InsufficientBalance();

        // من هنا معاملة واحدة: استهلاك الخصم، الحجز، والخصم من المحفظة — إن فشل
        // الخصم (إنفاق متزامن من نفس المحفظة) يُلغى كل شيء ويعود مقعد العرض.
        await using var tx = await _db.Database.BeginTransactionAsync();

        // نفس الحساب الذي يعرضه GET /bookings/quote للاعب قبل التأكيد، حتى لا
        // يختلف المبلغ المعروض عمّا يُخصم فعلاً.
        var quote = await PriceAsync(
            court, userId, start, durationMinutes, commit: true);
        var totalPrice = quote.Total;
        var commission = quote.Commission;

        var booking = new Booking
        {
            CourtId = court.Id,
            UserId = userId,
            StartTime = start,
            EndTime = end,
            TotalPrice = totalPrice,
            SportaCommission = commission,
            Status = BookingStatus.Pending,
            MembershipId = quote.Member?.MembershipId,
            MemberDiscountAmount = quote.Member?.Amount ?? 0m,
            MemberDiscountMinutes = quote.Member?.Minutes ?? 0,
        };

        _db.Bookings.Add(booking);
        await _db.SaveChangesAsync();

        // Hold the full amount from the player's wallet until the owner responds.
        // The venue owner is credited only once they approve (see VenueService).
        var charged = await _wallet.TryChargeAsync(
            userId, totalPrice, WalletTransactionType.BookingPayment,
            $"حجز {court.Venue.Name} - {court.Name}", booking.Id);
        if (!charged)
        {
            await tx.RollbackAsync();
            throw InsufficientBalance();
        }

        booking.PaidFullAmount = true;
        await _db.SaveChangesAsync();
        await tx.CommitAsync();

        return booking;
    }

    public async Task<PagedResult<BookingDto>> GetMyBookingsAsync(
        int userId, int page, int pageSize, string? status)
    {
        (page, pageSize) = Paging.Clamp(page, pageSize);
        var query = _db.Bookings
            .Include(b => b.Court).ThenInclude(c => c.Venue).ThenInclude(v => v.CityRef)
            .Where(b => b.UserId == userId);

        if (!string.IsNullOrWhiteSpace(status) &&
            Enum.TryParse<BookingStatus>(status, ignoreCase: true, out var s))
            query = query.Where(b => b.Status == s);

        var total = await query.CountAsync();
        var bookings = await query
            .OrderByDescending(b => b.StartTime)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<BookingDto>
        {
            Items = bookings.Select(b => ToDto(b, b.Court)).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    public async Task<BookingDto> CancelAsync(int userId, int bookingId, string? reason)
    {
        var booking = await _db.Bookings
            .Include(b => b.Court).ThenInclude(c => c.Venue).ThenInclude(v => v.CityRef)
            .FirstOrDefaultAsync(b => b.Id == bookingId && b.UserId == userId)
            ?? throw new AuthException(
                "Booking not found", "الحجز غير موجود", "BOOKING_NOT_FOUND");

        if (booking.Status == BookingStatus.Cancelled)
            throw new AuthException(
                "Booking is already cancelled", "الحجز ملغى بالفعل", "ALREADY_CANCELLED");

        if (booking.Status == BookingStatus.Completed)
            throw new AuthException(
                "Completed bookings cannot be cancelled",
                "لا يمكن إلغاء حجز مكتمل", "BOOKING_COMPLETED");

        // لا يُلغى حجز بدأ أو انتهى: لا شيء يضع الحالة Completed تلقائياً، فبدون
        // هذا الفحص يستردّ اللاعب كامل المبلغ بعد أن لعب.
        if (booking.StartTime <= AppClock.Now)
            throw new AuthException(
                "Bookings cannot be cancelled after they start",
                "لا يمكن إلغاء حجز بدأ أو انتهى", "BOOKING_STARTED");

        var wasConfirmed = booking.Status == BookingStatus.Confirmed;
        booking.Status = BookingStatus.Cancelled;
        booking.CancelledAt = DateTime.UtcNow;
        booking.CancellationReason = reason;
        booking.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        // Refund a paid booking back to the wallet, and take back the owner's
        // earning if it was already credited on confirmation.
        await BookingRefunds.RefundAsync(
            _wallet, booking, wasConfirmed, booking.Court.Venue.OwnerId,
            $"استرداد حجز {booking.Court.Venue?.Name ?? ""}");

        // استرداد الحجز يعكس أي نقاط سبق كسبها عليه (مُنحت عند تأكيد المالك).
        await _points.ReverseAsync(
            userId, PointsTransactionType.BookingConfirmed, booking.Id,
            "عكس نقاط حجز ملغى");

        return ToDto(booking, booking.Court);
    }

    private static AuthException InsufficientBalance() => new(
        "Insufficient wallet balance",
        "رصيد المحفظة غير كافٍ، يرجى شحن المحفظة والمحاولة مجدداً",
        "INSUFFICIENT_BALANCE");

    // ── mapping ────────────────────────────────────────────────────────────────

    private static BookingDto ToDto(Booking b, Court court) => new()
    {
        Id = b.Id,
        CourtId = b.CourtId,
        CourtName = court.Name,
        CourtNameEn = court.NameEn,
        VenueName = court.Venue?.Name ?? string.Empty,
        VenueNameEn = court.Venue?.NameEn,
        City = court.Venue?.City ?? string.Empty,
        CityEn = court.Venue?.CityRef?.NameEn,
        StartTime = b.StartTime,
        EndTime = b.EndTime,
        DurationMinutes = (int)(b.EndTime - b.StartTime).TotalMinutes,
        TotalPrice = b.TotalPrice,
        Status = b.Status.ToString(),
        PaidFullAmount = b.PaidFullAmount,
    };
}

/// <summary>خصم عضوية مطبَّق على حجز: العضوية والمبلغ والدقائق من السقف.</summary>
public sealed record MemberDiscount(
    int MembershipId, string PlanName, decimal Amount, int Minutes, decimal PlayerSaving = 0m);
