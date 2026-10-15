using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

public class VenueService : IVenueService
{
    private readonly AppDbContext _db;
    private readonly IWalletService _wallet;
    private readonly INotificationService _notifications;
    private readonly ISettingsService _settings;
    private readonly IPointsService _points;
    private readonly IAdminContext _admin;

    public VenueService(
        AppDbContext db, IWalletService wallet, INotificationService notifications,
        ISettingsService settings, IPointsService points, IAdminContext admin)
    {
        _admin = admin;
        _db = db;
        _wallet = wallet;
        _notifications = notifications;
        _settings = settings;
        _points = points;
    }

    /// <summary>Court bookings across the owner's venues (paged + status filter).</summary>
    public async Task<PagedResult<VenueBookingDto>> GetVenueBookingsAsync(
        int ownerUserId, int page, int pageSize, string? status)
    {
        (page, pageSize) = Paging.Clamp(page, pageSize);
        var courtIds = await _db.Courts
            .NotDeleted()
            .Where(c => c.Venue.OwnerId == ownerUserId)
            .Select(c => c.Id)
            .ToListAsync();
        if (courtIds.Count == 0) return new PagedResult<VenueBookingDto>
        {
            Page = page,
            PageSize = pageSize,
        };

        var query = _db.Bookings
            .Include(b => b.Court).ThenInclude(c => c.Venue)
            .Include(b => b.User)
            .Where(b => courtIds.Contains(b.CourtId));

        if (!string.IsNullOrWhiteSpace(status) &&
            Enum.TryParse<BookingStatus>(status, ignoreCase: true, out var s))
            query = query.Where(b => b.Status == s);

        var total = await query.CountAsync();
        var bookings = await query
            .OrderByDescending(b => b.StartTime)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<VenueBookingDto>
        {
            Items = bookings.Select(ToVenueBookingDto).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    /// <summary>Owner approves (confirm) or rejects (cancel + refund) a booking.</summary>
    public async Task<VenueBookingDto> RespondToBookingAsync(
        int ownerUserId, int bookingId, bool approve)
    {
        var booking = await _db.Bookings
            .Include(b => b.Court).ThenInclude(c => c.Venue)
            .Include(b => b.User)
            .FirstOrDefaultAsync(b => b.Id == bookingId)
            ?? throw new AuthException(
                "Booking not found", "الحجز غير موجود", "BOOKING_NOT_FOUND");

        if (booking.Court.Venue.OwnerId != ownerUserId)
            throw new AuthException("Not your venue", "هذا الحجز ليس لملعبك", "NOT_OWNER");
        if (booking.Status != BookingStatus.Pending &&
            booking.Status != BookingStatus.Confirmed)
            throw new AuthException(
                "Already handled", "تمت معالجة الحجز مسبقًا", "ALREADY_HANDLED");

        if (approve)
        {
            var wasPending = booking.Status == BookingStatus.Pending;
            booking.Status = BookingStatus.Confirmed;
            booking.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            // Release the held amount to the owner — only on the first approval
            // (Pending → Confirmed) so re-confirming never double-credits.
            // The owner receives the base price; نسبة سبورتا stays with the platform.
            if (wasPending && booking.PaidFullAmount && booking.OwnerAmount > 0)
                await _wallet.CreditEarningAsync(
                    ownerUserId, booking.OwnerAmount, WalletTransactionType.VenueEarning,
                    $"حجز {booking.Court.Name} - {booking.Court.Venue.Name}", booking.Id);
            // نقاط مكافآت ثابتة (reward_points_booking) عند أول تأكيد لحجز مدفوع.
            if (wasPending && booking.PaidFullAmount)
                await _points.EarnActivityAsync(
                    booking.UserId, PointsTransactionType.BookingConfirmed, booking.Id,
                    $"نقاط حجز {booking.Court.Name} - {booking.Court.Venue.Name}");
            await _notifications.PushAsync(booking.UserId, "تم تأكيد حجزك",
                "أكّد الملعب حجزك", "booking_confirmed", booking.Id);
        }
        else
        {
            // حجز بدأ وقته يُلعب فعلاً (أو لُعب): رفضه الآن يردّ للاعب كامل
            // المبلغ (شاملاً نسبة سبورتا) عن ساعة تُستهلك أو استُهلكت.
            if (booking.StartTime <= AppClock.Now)
                throw new AuthException(
                    "Started or finished bookings cannot be rejected",
                    "لا يمكن رفض حجز بدأ أو انتهى", "BOOKING_FINISHED");

            var wasConfirmed = booking.Status == BookingStatus.Confirmed;
            booking.Status = BookingStatus.Cancelled;
            booking.CancelledAt = DateTime.UtcNow;
            booking.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            // Refund anything the player paid, and take back the earning that was
            // credited to the owner when the booking was confirmed.
            await BookingRefunds.RefundAsync(
                _wallet, booking, wasConfirmed, ownerUserId, "استرداد حجز ملعب ملغى");
            // لو كان الحجز مؤكدًا سابقًا فقد مُنحت عليه نقاط — تُعكس مع الاسترداد.
            await _points.ReverseAsync(
                booking.UserId, PointsTransactionType.BookingConfirmed, booking.Id,
                "عكس نقاط حجز مرفوض");
            await _notifications.PushAsync(booking.UserId, "تم رفض حجزك",
                "اعتذر الملعب عن حجزك", "booking_rejected", booking.Id);
        }

        return ToVenueBookingDto(booking);
    }

    private static VenueBookingDto ToVenueBookingDto(Booking b) => new()
    {
        Id = b.Id,
        CourtName = b.Court.Name,
        VenueName = b.Court.Venue.Name,
        PlayerName = $"{b.User.FirstName} {b.User.LastName}".Trim(),
        StartTime = b.StartTime,
        EndTime = b.EndTime,
        TotalPrice = b.TotalPrice,
        CourtType = b.Court.Type == CourtType.Outdoor ? "outdoor" : "indoor",
        Status = b.Status.ToString(),
    };

    // ── Match hosting requests ───────────────────────────────────────────────────

    /// <summary>Match-hosting requests on the owner's courts (paged + status filter).</summary>
    public async Task<PagedResult<VenueMatchRequestDto>> GetMatchRequestsAsync(
        int ownerUserId, int page, int pageSize, string? status, bool mine = false,
        string? kind = null)
    {
        (page, pageSize) = Paging.Clamp(page, pageSize);
        var courtIds = await _db.Courts
            .NotDeleted()
            .Where(c => c.Venue.OwnerId == ownerUserId)
            .Select(c => c.Id)
            .ToListAsync();
        if (courtIds.Count == 0) return new PagedResult<VenueMatchRequestDto>
        {
            Page = page,
            PageSize = pageSize,
        };

        var query = _db.Matches
            .Include(m => m.Court).ThenInclude(c => c!.Venue)
            .Include(m => m.Creator)
            // المسجّلون يُعدّون في البطاقة (يهمّ المضيف قبل الإلغاء).
            .Include(m => m.MatchPlayers)
            .Include(m => m.AmericanoMatch)
            .Where(m => m.CourtId != null && courtIds.Contains(m.CourtId.Value));

        // «مبارياتي»: ما أنشأه الملعب بنفسه (مباراة/أمريكانو/بطولة مستضافة).
        if (mine) query = query.Where(m => m.CreatorId == ownerUserId);

        // تبويبات التطبيق: مباراة عادية / أمريكانو / بطولة (كأس). الأمريكانو
        // والبطولة كلاهما AmericanoMatch؛ تفرّقهما IsTournament/Format.
        switch (kind?.Trim().ToLowerInvariant())
        {
            case "match":
                query = query.Where(m => m.AmericanoMatch == null);
                break;
            case "americano":
                query = query.Where(m => m.AmericanoMatch != null
                    && !m.AmericanoMatch.IsTournament
                    && m.AmericanoMatch.Format == null);
                break;
            case "tournament":
                query = query.Where(m => m.AmericanoMatch != null
                    && (m.AmericanoMatch.IsTournament || m.AmericanoMatch.Format != null));
                break;
        }

        // بلا status تُعاد كل الحالات — تبويب «الكل» في التطبيق لا يرسل الوسيط،
        // وكان الافتراض السابق (قيد الموافقة) يجعله يبدو فارغاً. تُقبل عدة
        // حالات مفصولة بفاصلة (مثلاً Open,Full = «مقبولة»).
        var statuses = (status ?? string.Empty)
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(x => Enum.TryParse<MatchStatus>(x, ignoreCase: true, out var s) ? s : (MatchStatus?)null)
            .Where(x => x != null)
            .Select(x => x!.Value)
            .ToList();
        if (statuses.Count == 1)
        {
            var only = statuses[0];
            query = query.Where(m => m.Status == only);
        }
        else if (statuses.Count > 1)
            query = query.Where(m => statuses.Contains(m.Status));

        var total = await query.CountAsync();
        // ما ينتظر قرار الملعب يتصدّر القائمة، ثم الأحدث إنشاءً.
        var matches = await query
            .OrderByDescending(m => m.Status == MatchStatus.PendingApproval)
            .ThenByDescending(m => m.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<VenueMatchRequestDto>
        {
            Items = matches.Select(ToMatchRequestDto).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    /// <summary>
    /// One match request in full — the card fields plus the joined players, the
    /// creator's contact, and what the owner nets if they approve. Owner-scoped:
    /// the match has to be on one of their courts.
    /// </summary>
    public async Task<VenueMatchRequestDetailDto> GetMatchRequestAsync(
        int ownerUserId, int matchId)
    {
        var match = await _db.Matches
            .Include(m => m.Court).ThenInclude(c => c!.Venue)
            .Include(m => m.Creator)
            .Include(m => m.MatchPlayers).ThenInclude(p => p.User)
                .ThenInclude(u => u.PlayerProfile)
            .FirstOrDefaultAsync(m => m.Id == matchId)
            ?? throw new AuthException(
                "Match not found", "المباراة غير موجودة", "MATCH_NOT_FOUND");

        if (match.Court?.Venue.OwnerId != ownerUserId)
            throw new AuthException(
                "Not your venue", "هذه المباراة ليست على ملعبك", "NOT_OWNER");

        var held = match.CreatorHeld();
        var players = match.MatchPlayers
            .OrderBy(p => p.JoinedAt)
            .Select(p => new VenueMatchPlayerDto
            {
                UserId = p.UserId,
                Name = $"{p.User.FirstName} {p.User.LastName}".Trim(),
                AvatarUrl = p.User.ProfileImageUrl,
                Level = p.User.PlayerProfile != null
                    ? (int)p.User.PlayerProfile.Level
                    : null,
                HasPaid = p.HasPaid,
                Status = p.Status switch
                {
                    MatchPlayerStatus.Pending => "pending",
                    MatchPlayerStatus.Invited => "invited",
                    _ => "approved",
                },
                IsCreator = p.UserId == match.CreatorId,
                JoinedAt = p.JoinedAt,
            })
            .ToList();

        var dto = ToMatchRequestDto(match);
        return new VenueMatchRequestDetailDto
        {
            Id = dto.Id,
            CourtName = dto.CourtName,
            VenueName = dto.VenueName,
            CreatorName = dto.CreatorName,
            ScheduledAt = dto.ScheduledAt,
            DurationMinutes = dto.DurationMinutes,
            MaxPlayers = dto.MaxPlayers,
            PricePerPlayer = dto.PricePerPlayer,
            PaymentMode = dto.PaymentMode,
            AmountHeld = dto.AmountHeld,
            Status = dto.Status,
            CreatorId = match.CreatorId,
            CreatorPhone = match.Creator.PhoneNumber,
            CreatorAvatarUrl = match.Creator.ProfileImageUrl,
            MatchType = match.MatchType.ToString().ToLowerInvariant(),
            Gender = match.Gender == Gender.Female ? "female" : "male",
            MinLevel = match.MinLevel,
            MaxLevel = match.MaxLevel,
            Notes = match.Notes,
            CreatedAt = match.CreatedAt,
            Players = players,
            CurrentPlayers = players.Count(p => p.Status == "approved"),
            TotalPrice = match.PricePerPlayer * match.MaxPlayers,
            SportaCommissionPercent = match.SportaCommissionPercent,
            OwnerEarning = match.NetOfCommission(held),
        };
    }

    /// <summary>Owner approves (open + credit) or rejects (cancel + refund creator) a match.</summary>
    public async Task<VenueMatchRequestDto> RespondToMatchRequestAsync(
        int ownerUserId, int matchId, bool approve)
    {
        // نفس قفل الانضمام/القبول: موافقة الملعب أو رفضه لا تتقاطع مع انضمامٍ
        // متزامن (حصة تُحجز بعد أن قرأنا قائمة اللاعبين فلا تُردّ ولا تُصرف).
        await using var gate = await MatchLock.AcquireAsync(_db, matchId);
        var match = await _db.Matches
            .Include(m => m.Court).ThenInclude(c => c!.Venue)
            .Include(m => m.Creator)
            .Include(m => m.MatchPlayers)
            .Include(m => m.AmericanoMatch)
            .FirstOrDefaultAsync(m => m.Id == matchId)
            ?? throw new AuthException("Match not found", "المباراة غير موجودة", "MATCH_NOT_FOUND");

        if (match.Court?.Venue.OwnerId != ownerUserId)
            throw new AuthException(
                "Not your venue", "هذه المباراة ليست على ملعبك", "NOT_OWNER");
        if (match.Status != MatchStatus.PendingApproval)
            throw new AuthException(
                "Already handled", "تمت معالجة الطلب مسبقًا", "ALREADY_HANDLED");

        var held = match.CreatorHeld();
        // حصص شركاء قبلوا دعوة المنشئ (أمريكانو/بطولة) قبل الموافقة: محجوزة
        // عندنا مثل حصته.
        var heldPartners = match.PricePerPlayer <= 0 ? new List<MatchPlayer>() : match.MatchPlayers
            .Where(p => p.UserId != match.CreatorId && p.HasPaid
                        && p.Status == MatchPlayerStatus.Approved)
            .ToList();

        if (approve)
        {
            // من انضم بدعوة المنشئ قبل الموافقة قد يكون أكمل العدد.
            match.Status = match.MatchPlayers.Count(p => p.Status == MatchPlayerStatus.Approved)
                           >= match.MaxPlayers
                ? MatchStatus.Full
                : MatchStatus.Open;
            match.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            // Release the creator's held payment to the owner — net of نسبة
            // سبورتا, which stays with the platform.
            if (held > 0)
                await _wallet.CreditEarningAsync(
                    ownerUserId, match.NetOfCommission(held),
                    WalletTransactionType.VenueEarning,
                    $"مباراة على {match.Court!.Name}", match.Id);
            foreach (var partner in heldPartners)
            {
                // «يدفع المنشئ الكل»: حصة الشريك تعوّض المنشئ؛ وإلا تذهب للمالك.
                if (match.PaymentMode == MatchPaymentMode.FullByCreator)
                    await _wallet.CreditEarningAsync(
                        match.CreatorId, match.ShareOf(partner),
                        WalletTransactionType.CreatorEarning, "حصة أمريكانو", match.Id);
                else
                    await _wallet.CreditEarningAsync(
                        ownerUserId, match.NetOfCommission(match.ShareOf(partner)),
                        WalletTransactionType.VenueEarning,
                        $"مباراة على {match.Court!.Name}", match.Id);
            }
            await _notifications.PushAsync(match.CreatorId, "تم قبول مباراتك",
                "وافق الملعب على استضافة مباراتك", "match_approved", match.Id);
        }
        else
        {
            match.Status = MatchStatus.Cancelled;
            match.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            // Refund what the creator paid up-front, and every held partner share.
            if (held > 0)
                await _wallet.RefundAsync(
                    match.CreatorId, held, "استرداد مباراة مرفوضة", match.Id);
            // طلبات انضمام معلّقة حُجزت حصصها (صديق قبل دعوة شريك) تُردّ كذلك،
            // فبعد الإلغاء يخفي التطبيق «إلغاء الطلب» ولا سبيل آخر لاستعادتها.
            var heldPending = match.PricePerPlayer <= 0 ? new List<MatchPlayer>() : match.MatchPlayers
                .Where(p => p.UserId != match.CreatorId && p.HasPaid
                            && p.Status == MatchPlayerStatus.Pending)
                .ToList();
            var refunded = heldPartners.Concat(heldPending).ToList();
            foreach (var partner in refunded)
                await _wallet.RefundAsync(
                    partner.UserId, match.ShareOf(partner), "استرداد حصة — رفض الملعب الاستضافة", match.Id);
            // المال رُدّ: لا يبقى سطر «مدفوع» يُردّ مرة ثانية برفضٍ أو انسحاب لاحق.
            foreach (var row in match.MatchPlayers.Where(p => p.HasPaid))
                row.HasPaid = false;
            await _db.SaveChangesAsync();
            var (rejectedType, rejectedRef) = EventNotificationTarget.For(match, "rejected");
            foreach (var partner in refunded)
                await _notifications.PushAsync(partner.UserId, "اعتذر الملعب عن الاستضافة",
                    "رفض الملعب استضافة الحدث الذي انضممت إليه، وأُعيدت حصتك إلى محفظتك.",
                    rejectedType, rejectedRef);
            await _notifications.PushAsync(match.CreatorId, "تم رفض مباراتك",
                "اعتذر الملعب عن استضافة مباراتك", rejectedType, rejectedRef);
        }

        return ToMatchRequestDto(match);
    }

    private static VenueMatchRequestDto ToMatchRequestDto(Match m) => new()
    {
        Id = m.Id,
        CourtName = m.Court?.Name ?? string.Empty,
        VenueName = m.Court?.Venue.Name ?? string.Empty,
        CreatorName = $"{m.Creator.FirstName} {m.Creator.LastName}".Trim(),
        ScheduledAt = m.ScheduledAt,
        DurationMinutes = m.DurationMinutes,
        MaxPlayers = m.MaxPlayers,
        PricePerPlayer = m.PricePerPlayer,
        PaymentMode = m.PaymentMode == MatchPaymentMode.FullByCreator ? "full" : "share",
        AmountHeld = m.CreatorHeld(),
        Status = m.Status.ToString(),
        IsVenueHosted = m.IsHostedByVenueOwner,
        RegisteredPlayers =
            m.MatchPlayers.Count(p => p.Status == MatchPlayerStatus.Approved),
        Kind = m.AmericanoMatch == null ? "match"
            : m.AmericanoMatch.IsTournament || m.AmericanoMatch.Format != null ? "tournament"
            : "americano",
        AmericanoId = m.AmericanoMatch?.Id,
        Title = m.AmericanoMatch?.Name,
    };

    /// <summary>
    /// يربط النادي بجداول الدول/المدن/الأحياء. كل نادٍ لا بد له من معرّف مدينة
    /// وحي (والدولة تُشتق من المدينة)، فبدونها لا يمكن فلترة اللاعبين حسب
    /// المدينة ولا حصر ما يراه الموظف في نطاقه. المعرّف هو المصدر؛ والاسم النصي
    /// يُوحَّد معه لتفادي تعدّد التهجئات. يُقبل الاسم النصي وحده فقط كمسار توافق
    /// للعملاء القدامى الذين لا يرسلون المعرّفات.
    /// </summary>
    private async Task LinkLocationAsync(Venue venue, int? cityId, int? districtId)
    {
        var city = cityId is int id
            ? await _db.Cities.FirstOrDefaultAsync(c => c.Id == id)
            : string.IsNullOrWhiteSpace(venue.City)
                ? null
                : await _db.Cities.FirstOrDefaultAsync(c =>
                    c.NameAr == venue.City || c.NameEn == venue.City);

        if (city is null)
            throw new AuthException(
                "City is required", "يجب اختيار المدينة من القائمة", "CITY_REQUIRED");

        var district = districtId is int did
            ? await _db.Districts.FirstOrDefaultAsync(d => d.Id == did)
            : string.IsNullOrWhiteSpace(venue.District)
                ? null
                : await _db.Districts.FirstOrDefaultAsync(d =>
                    d.CityId == city.Id &&
                    (d.NameAr == venue.District || d.NameEn == venue.District));

        if (district is null)
            throw new AuthException(
                "District is required", "يجب اختيار الحي من القائمة", "DISTRICT_REQUIRED");

        if (district.CityId != city.Id)
            throw new AuthException(
                "District does not belong to the selected city",
                "الحي المختار لا يتبع المدينة المختارة", "DISTRICT_CITY_MISMATCH");

        var country = await _db.Countries.FirstOrDefaultAsync(c => c.Id == city.CountryId);

        venue.CityId = city.Id;
        venue.DistrictId = district.Id;
        venue.CountryId = city.CountryId;
        // النصوص تبقى مصدر العرض؛ نوحّدها مع القوائم.
        venue.City = city.NameAr;
        venue.District = district.NameAr;
        if (country is not null) venue.Country = country.NameAr;
    }

    // ── Owner management ────────────────────────────────────────────────────────

    public async Task<List<OwnerVenueDto>> GetMyVenuesAsync(int ownerUserId)
    {
        var venues = await _db.Venues
            .NotDeleted()
            .Include(v => v.Courts).ThenInclude(c => c.PriceTiers)
            .Include(v => v.Courts).ThenInclude(c => c.OpeningHours)
            .Include(v => v.Courts).ThenInclude(c => c.PriceRules)
            .Include(v => v.Images)
            .Where(v => v.OwnerId == ownerUserId)
            .OrderBy(v => v.Name)
            .ToListAsync();

        return venues.Select(ToVenueDto).ToList();
    }

    /// <summary>Creates a venue together with its first court, seeded from the
    /// same form (name, count of internal courts, prices and photos).</summary>
    public async Task<OwnerVenueDto> CreateVenueAsync(int ownerUserId, CreateVenueRequest req)
    {
        // سمة الدور تمرّر من لا يملك الدور أصلاً، فالفحص هنا: إنشاء نادٍ
        // لأصحاب الملاعب فقط (والموافقة على الدور شرط آخر تفرضه السمة).
        if (!await _db.UserRoles.AnyAsync(r =>
                r.UserId == ownerUserId && r.Role == UserType.VenueOwner))
            throw new AuthException(
                "Only venue owners can create venues",
                "إضافة نادٍ لأصحاب الملاعب فقط", "VENUE_OWNER_ONLY");

        var cover = req.ImageUrls.FirstOrDefault();
        var venue = new Venue
        {
            OwnerId = ownerUserId,
            Name = req.Name.Trim(),
            NameEn = req.NameEn?.Trim(),
            Country = "السعودية",
            City = req.City?.Trim() ?? string.Empty,
            District = req.District?.Trim(),
            Address = req.Address.Trim(),
            Latitude = req.Latitude,
            Longitude = req.Longitude,
            ImageUrl = cover,
        };
        await LinkLocationAsync(venue, req.CityId, req.DistrictId);
        foreach (var url in req.ImageUrls)
            venue.Images.Add(new VenueImage { Url = url });

        var court = new Court
        {
            Name = req.Name.Trim(),
            NameEn = req.NameEn?.Trim(),
            Type = CourtType.Indoor,
            CourtCount = req.CourtCount < 1 ? 1 : req.CourtCount,
            PricePerHour = req.PricePerHour,
            ImageUrl = cover,
            Latitude = req.Latitude,
            Longitude = req.Longitude,
            SportaCommissionPercent = await _settings.GetDefaultCommissionAsync(),
        };
        foreach (var t in ToTiers(req.BookingTiers, CourtPriceKind.Booking))
            court.PriceTiers.Add(t);
        venue.Courts.Add(court);

        _db.Venues.Add(venue);
        await _db.SaveChangesAsync();
        return ToVenueDto(venue);
    }

    public async Task<OwnerCourtDto> AddCourtAsync(
        int ownerUserId, int venueId, CreateCourtRequest req)
    {
        var venue = await _db.Venues.NotDeleted().FirstOrDefaultAsync(v => v.Id == venueId)
            ?? throw new AuthException("Venue not found", "النادي غير موجود", "VENUE_NOT_FOUND");

        if (venue.OwnerId != ownerUserId)
            throw new AuthException("Not your venue", "هذا النادي ليس لك", "NOT_OWNER");

        var court = new Court
        {
            VenueId = venueId,
            Name = req.Name.Trim(),
            NameEn = req.NameEn?.Trim(),
            Type = req.Type.ToLowerInvariant() == "outdoor"
                ? CourtType.Outdoor
                : CourtType.Indoor,
            CourtCount = req.CourtCount < 1 ? 1 : req.CourtCount,
            PricePerHour = req.PricePerHour,
            ImageUrl = req.ImageUrl,
            Latitude = req.Latitude,
            Longitude = req.Longitude,
            // Seed نسبة سبورتا from the admin-managed default (falls back to the
            // hardcoded const when unset). Admins can override it per-court later.
            SportaCommissionPercent = await _settings.GetDefaultCommissionAsync(),
        };
        foreach (var t in ToTiers(req.BookingTiers, CourtPriceKind.Booking))
            court.PriceTiers.Add(t);

        // دوام الأسبوع وقواعد التسعير اختيارية عند الإنشاء — الفراغ يعني الدوام
        // الافتراضي وسعراً موحّداً، ويستطيع المالك ضبطهما لاحقاً من جدول الملعب.
        foreach (var h in CourtScheduleMapper.BuildOpeningHours(court, req.OpeningHours))
            court.OpeningHours.Add(h);
        foreach (var r in CourtScheduleMapper.BuildPriceRules(court, req.PriceRules))
            court.PriceRules.Add(r);

        _db.Courts.Add(court);
        await _db.SaveChangesAsync();
        return ToCourtDto(court);
    }

    /// <summary>حفظ دوام الأسبوع وقواعد التسعير معاً — شاشة "جدول الملعب".</summary>
    public async Task<OwnerCourtDto> UpdateCourtScheduleAsync(
        int ownerUserId, int courtId, UpdateCourtScheduleRequest req)
    {
        var court = await _db.Courts
            .NotDeleted()
            .Include(c => c.Venue)
            .Include(c => c.PriceTiers)
            .Include(c => c.OpeningHours)
            .Include(c => c.PriceRules)
            .FirstOrDefaultAsync(c => c.Id == courtId)
            ?? throw new AuthException("Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        if (court.Venue.OwnerId != ownerUserId)
            throw new AuthException("Not your court", "هذا الملعب ليس لك", "NOT_OWNER");

        ReplaceSchedule(court, req.OpeningHours, req.PriceRules);
        court.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return ToCourtDto(court);
    }

    /// <summary>يستبدل دوام الملعب وقواعده بالكامل بما أُرسل.</summary>
    private void ReplaceSchedule(
        Court court,
        IEnumerable<CourtOpeningHourInput>? openingHours,
        IEnumerable<CourtPriceRuleInput>? priceRules)
    {
        if (openingHours is not null)
        {
            var next = CourtScheduleMapper.BuildOpeningHours(court, openingHours);
            _db.CourtOpeningHours.RemoveRange(court.OpeningHours);
            court.OpeningHours.Clear();
            foreach (var h in next) court.OpeningHours.Add(h);
        }

        if (priceRules is not null)
        {
            var next = CourtScheduleMapper.BuildPriceRules(court, priceRules);
            // نطاقان متداخلان لنفس اليوم يجعلان السعر غامضاً — يُرفضان.
            if (CourtScheduleMapper.FindOverlap(next) is { } overlap)
                throw new AuthException(
                    $"Overlapping price ranges: {overlap}",
                    $"نطاقان متداخلان في الأسعار: {overlap}", "PRICE_RULES_OVERLAP");
            _db.CourtPriceRules.RemoveRange(court.PriceRules);
            court.PriceRules.Clear();
            foreach (var r in next) court.PriceRules.Add(r);
        }
    }

    public async Task<VenuePricingDto> GetVenuePricingAsync(int ownerUserId, int venueId)
    {
        var venue = await LoadVenueForPricingAsync(ownerUserId, venueId);
        return ToPricingDto(venue);
    }

    public async Task<VenuePricingDto> UpdateVenuePricingAsync(
        int ownerUserId, int venueId, UpdateVenuePriceRulesRequest req)
    {
        var venue = await LoadVenueForPricingAsync(ownerUserId, venueId);
        var targets = req.CourtIds.Count == 0
            ? venue.Courts.ToList()
            : venue.Courts.Where(c => req.CourtIds.Contains(c.Id)).ToList();
        if (targets.Count == 0)
            throw new AuthException("No courts selected", "اختر ملعباً واحداً على الأقل", "NO_COURTS");

        foreach (var court in targets)
        {
            ReplaceSchedule(court, null, req.PriceRules);
            court.UpdatedAt = DateTime.UtcNow;
        }
        await _db.SaveChangesAsync();
        return ToPricingDto(venue);
    }

    private async Task<Venue> LoadVenueForPricingAsync(int ownerUserId, int venueId)
    {
        var venue = await _db.Venues
            .Include(v => v.Courts.Where(c => !c.IsDeleted)).ThenInclude(c => c.PriceRules)
            .Include(v => v.Courts.Where(c => !c.IsDeleted)).ThenInclude(c => c.PriceTiers)
            .Include(v => v.Courts.Where(c => !c.IsDeleted)).ThenInclude(c => c.OpeningHours)
            .FirstOrDefaultAsync(v => v.Id == venueId && !v.IsDeleted)
            ?? throw new AuthException("Venue not found", "النادي غير موجود", "VENUE_NOT_FOUND");
        if (venue.OwnerId != ownerUserId)
            throw new AuthException("Not your venue", "هذا النادي ليس لك", "NOT_OWNER");
        return venue;
    }

    private static VenuePricingDto ToPricingDto(Venue venue) => new()
    {
        VenueId = venue.Id,
        VenueName = venue.Name,
        Courts = venue.Courts
            .OrderBy(c => c.Id)
            .Select(c => new VenuePricingCourtDto
            {
                Id = c.Id,
                Name = c.Name,
                NameEn = c.NameEn,
                BasePrice = CourtSchedule.BasePrice(c),
                SportaCommissionPercent = c.SportaCommissionPercent,
                OpeningHours = CourtScheduleMapper.OpeningHourDtos(c),
                PriceRules = CourtScheduleMapper.PriceRuleDtos(c),
            })
            .ToList(),
    };

    public async Task<OwnerCourtDto> UpdateCourtAsync(
        int ownerUserId, int courtId, UpdateCourtRequest req)
    {
        var court = await _db.Courts
            .NotDeleted()
            .Include(c => c.Venue)
            .Include(c => c.PriceTiers)
            .Include(c => c.OpeningHours)
            .Include(c => c.PriceRules)
            .FirstOrDefaultAsync(c => c.Id == courtId)
            ?? throw new AuthException("Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        if (court.Venue.OwnerId != ownerUserId)
            throw new AuthException("Not your court", "هذا الملعب ليس لك", "NOT_OWNER");

        court.CourtCount = req.CourtCount < 1 ? 1 : req.CourtCount;
        court.PricePerHour = req.PricePerHour;
        court.IsAvailable = req.IsAvailable;
        if (req.ImageUrl is not null) court.ImageUrl = req.ImageUrl;
        if (req.Latitude is not null) court.Latitude = req.Latitude;
        if (req.Longitude is not null) court.Longitude = req.Longitude;
        court.UpdatedAt = DateTime.UtcNow;

        // Replace a tier kind only when the client sent it (null = leave unchanged).
        if (req.BookingTiers is not null)
            ReplaceTiers(court, CourtPriceKind.Booking, req.BookingTiers);

        // نفس القاعدة للدوام والقواعد: null يعني "لا تغيّر".
        ReplaceSchedule(court, req.OpeningHours, req.PriceRules);

        await _db.SaveChangesAsync();
        return ToCourtDto(court);
    }

    public async Task<int> DeleteCourtAsync(int ownerUserId, int courtId)
    {
        var court = await _db.Courts
            .NotDeleted()
            .Include(c => c.Venue)
            .Include(c => c.PriceTiers)
            .Include(c => c.OpeningHours)
            .Include(c => c.PriceRules)
            .FirstOrDefaultAsync(c => c.Id == courtId)
            ?? throw new AuthException("Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        if (court.Venue.OwnerId != ownerUserId)
            throw new AuthException("Not your court", "هذا الملعب ليس لك", "NOT_OWNER");

        // الحذف ممنوع ما دام على الملعب شيء قادم: حجز، أو مباراة/أمريكانو/بطولة
        // (رئيسياً أو ملعباً إضافياً للبطولة)، أو جلسة تدريب — حذفه كان يُسقط
        // الملعب من الحدث المدفوع بلا ردّ لأحد. المواعيد محلية ساذجة فتقارَن
        // بساعة التطبيق.
        var now = AppClock.Now;
        var hasBookings = await _db.Bookings.AnyAsync(
            b => b.CourtId == courtId && b.Status != BookingStatus.Cancelled &&
                 b.EndTime > now);
        if (hasBookings)
            throw new AuthException(
                "Court has active bookings",
                "لا يمكن حذف ملعب لديه حجوزات نشطة",
                "COURT_HAS_BOOKINGS");

        var hasEvents = await _db.Matches.AnyAsync(m =>
            m.Status != MatchStatus.Cancelled &&
            (m.CourtId == courtId ||
             (m.AmericanoMatch != null && m.AmericanoMatch.Courts.Any(tc => tc.CourtId == courtId))) &&
            (m.ScheduledAt > now ||
             (m.AmericanoMatch != null && m.AmericanoMatch.EndDate != null &&
              m.AmericanoMatch.EndDate >= now.Date)));
        if (hasEvents)
            throw new AuthException(
                "Court has upcoming events",
                "لا يمكن حذف ملعب عليه مباريات أو بطولات قادمة",
                "COURT_HAS_EVENTS");

        var hasSessions = await _db.CoachSessions.AnyAsync(s =>
            s.CourtId == courtId && s.Status != CoachSessionStatus.Rejected &&
            s.ScheduledAt > now);
        if (hasSessions)
            throw new AuthException(
                "Court has upcoming coach sessions",
                "لا يمكن حذف ملعب عليه جلسات تدريب قادمة",
                "COURT_HAS_SESSIONS");

        // الحذف ناعم: قيد قاعدة البيانات على الحجوزات (ومنها الملغاة) يمنع مسح
        // الصف، والسجل المالي يبقى متماسكاً بعد اختفاء الملعب — كحذف الإدارة.
        var stamp = DateTime.UtcNow;
        court.IsDeleted = true;
        court.DeletedAt = stamp;
        court.IsAvailable = false;
        court.UpdatedAt = stamp;
        await _db.SaveChangesAsync();
        return court.VenueId;
    }

    public async Task<OwnerCourtSlotsDto> GetCourtSlotsAsync(
        int ownerUserId, int courtId, DateTime date)
    {
        await EnsureOwnedCourtAsync(ownerUserId, courtId);
        return await BuildSlotsAsync(courtId, date.Date);
    }

    public async Task<OwnerCourtSlotsDto> ToggleCourtSlotAsync(
        int ownerUserId, int courtId, DateTime date, int hour)
    {
        await EnsureOwnedCourtAsync(ownerUserId, courtId);
        var day = date.Date;

        // الساعة المشغولة (حجز أو مباراة أو جلسة يتقاطع معها ولو جزئياً) لا تُبدَّل.
        var slotStart = day.AddHours(hour);
        var booked = await CourtOccupancy.IsTakenAsync(
            _db, courtId, slotStart, slotStart.AddHours(1));
        if (booked)
            throw new AuthException(
                "Slot is booked", "هذا الوقت محجوز ولا يمكن تغييره", "SLOT_BOOKED");

        var existing = await _db.CourtBlockedSlots
            .FirstOrDefaultAsync(s => s.CourtId == courtId && s.Date == day && s.Hour == hour);
        if (existing is not null)
            _db.CourtBlockedSlots.Remove(existing);   // unblock → available
        else
            _db.CourtBlockedSlots.Add(new CourtBlockedSlot
            { CourtId = courtId, Date = day, Hour = hour });   // block → unavailable
        await _db.SaveChangesAsync();

        return await BuildSlotsAsync(courtId, day);
    }

    /// <summary>يوقف أو يتيح عدة مواعيد دفعة واحدة. المواعيد المحجوزة تُتخطى
    /// بصمت — حالتها تتبع الحجز الفعلي ولا يغيّرها المالك.</summary>
    public async Task<OwnerCourtSlotsDto> SetCourtSlotsAsync(
        int ownerUserId, int courtId, DateTime date, List<int> hours, bool available)
    {
        await EnsureOwnedCourtAsync(ownerUserId, courtId);
        var day = date.Date;
        var wanted = hours.Where(h => h is >= 0 and < 24).Distinct().ToList();
        if (wanted.Count == 0) return await BuildSlotsAsync(courtId, day);

        var existing = await _db.CourtBlockedSlots
            .Where(s => s.CourtId == courtId && s.Date == day && wanted.Contains(s.Hour))
            .ToListAsync();

        if (available)
        {
            _db.CourtBlockedSlots.RemoveRange(existing);
        }
        else
        {
            var bookedHours = await BookedHoursAsync(courtId, day);

            var alreadyBlocked = existing.Select(s => s.Hour).ToHashSet();
            foreach (var hour in wanted)
            {
                if (alreadyBlocked.Contains(hour)) continue;
                if (bookedHours.Contains(hour)) continue;
                _db.CourtBlockedSlots.Add(new CourtBlockedSlot
                { CourtId = courtId, Date = day, Hour = hour });
            }
        }

        await _db.SaveChangesAsync();
        return await BuildSlotsAsync(courtId, day);
    }

    private async Task EnsureOwnedCourtAsync(int ownerUserId, int courtId)
    {
        var owned = await _db.Courts
            .NotDeleted()
            .Include(c => c.Venue)
            .AnyAsync(c => c.Id == courtId && c.Venue.OwnerId == ownerUserId);
        if (!owned)
            throw new AuthException("Not your court", "هذا الملعب ليس لك", "NOT_OWNER");
    }

    private async Task<OwnerCourtSlotsDto> BuildSlotsAsync(int courtId, DateTime day)
    {
        var court = await _db.Courts
            .NotDeleted()
            .Include(c => c.OpeningHours)
            .FirstOrDefaultAsync(c => c.Id == courtId)
            ?? throw new AuthException("Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        var bookedHours = await BookedHoursAsync(courtId, day);
        var blockedHours = await _db.CourtBlockedSlots
            .Where(s => s.CourtId == courtId && s.Date == day)
            .Select(s => s.Hour)
            .ToListAsync();

        // المواعيد المعروضة للمالك تتبع دوام هذا اليوم — اليوم المغلق بلا مواعيد.
        var (openHour, closeHour, isClosed) = CourtSchedule.HoursOn(court, day);

        var slots = new List<OwnerCourtSlotDto>();
        for (var hour = openHour; !isClosed && hour < closeHour; hour++)
        {
            slots.Add(new OwnerCourtSlotDto
            {
                Hour = hour,
                Time = $"{hour:D2}:00",
                IsBooked = bookedHours.Contains(hour),
                IsBlocked = blockedHours.Contains(hour),
            });
        }
        return new OwnerCourtSlotsDto
        {
            CourtId = courtId,
            Date = day.ToString("yyyy-MM-dd"),
            IsClosed = isClosed,
            Slots = slots,
        };
    }

    /// <summary>
    /// ساعات اليوم المشغولة على الملعب بحجز أو مباراة/أمريكانو/بطولة أو جلسة
    /// تدريب (<see cref="CourtOccupancy"/>). الفترة التي تتقاطع مع ساعة ولو
    /// جزئياً تشغلها: حجز 10:30–11:30 يشغل الساعتين 10 و11، كما في
    /// <see cref="CourtSchedule.CoveredHours"/>. ما يمتد من اليوم السابق أو إلى
    /// التالي يُقصّ على حدود اليوم.
    /// </summary>
    private async Task<HashSet<int>> BookedHoursAsync(int courtId, DateTime day)
    {
        var nextDay = day.AddDays(1);
        var hours = new HashSet<int>();
        foreach (var (start, end) in await CourtOccupancy.ForCourtAsync(_db, courtId, day, nextDay))
        {
            var from = start < day ? day : start;
            var to = end > nextDay ? nextDay : end;
            if (to <= from) continue;
            hours.UnionWith(CourtSchedule.CoveredHours(from, (int)Math.Ceiling((to - from).TotalMinutes)));
        }
        return hours;
    }

    private static IEnumerable<CourtPriceTier> ToTiers(
        IEnumerable<CourtPriceTierInput> inputs, CourtPriceKind kind) =>
        inputs.Select(t => new CourtPriceTier
        {
            Kind = kind,
            DurationMinutes = t.DurationMinutes,
            Price = t.Price,
        });

    private void ReplaceTiers(
        Court court, CourtPriceKind kind, List<CourtPriceTierInput> inputs)
    {
        var existing = court.PriceTiers.Where(t => t.Kind == kind).ToList();
        _db.CourtPriceTiers.RemoveRange(existing);
        foreach (var t in existing) court.PriceTiers.Remove(t);
        foreach (var t in ToTiers(inputs, kind)) court.PriceTiers.Add(t);
    }

    private static OwnerVenueDto ToVenueDto(Venue v) => new()
    {
        Id = v.Id,
        Name = v.Name,
        NameEn = v.NameEn,
        Description = v.Description,
        City = v.City,
        CityId = v.CityId,
        District = v.District,
        DistrictId = v.DistrictId,
        CountryId = v.CountryId,
        Address = v.Address,
        Latitude = v.Latitude,
        Longitude = v.Longitude,
        GenderPolicy = v.GenderPolicy switch
        {
            VenueGenderPolicy.WomenOnly => "womenOnly",
            VenueGenderPolicy.FamilyOnly => "familyOnly",
            _ => "men",
        },
        ImageUrl = v.ImageUrl,
        ImageUrls = v.Images.Select(i => i.Url).ToList(),
        IsApproved = v.IsApproved,
        Courts = v.Courts.OrderBy(c => c.Name).Select(ToCourtDto).ToList(),
    };

    private static OwnerCourtDto ToCourtDto(Court c) => new()
    {
        Id = c.Id,
        Name = c.Name,
        NameEn = c.NameEn,
        Type = c.Type == CourtType.Outdoor ? "outdoor" : "indoor",
        CourtCount = c.CourtCount,
        PricePerHour = c.PricePerHour,
        IsAvailable = c.IsAvailable,
        ImageUrl = c.ImageUrl,
        Latitude = c.Latitude,
        Longitude = c.Longitude,
        BookingTiers = TierInputs(c, CourtPriceKind.Booking),
        OpeningHours = CourtScheduleMapper.OpeningHourDtos(c),
        PriceRules = CourtScheduleMapper.PriceRuleDtos(c),
    };

    private static List<CourtPriceTierInput> TierInputs(Court c, CourtPriceKind kind) =>
        c.PriceTiers
            .Where(t => t.Kind == kind)
            .OrderBy(t => t.DurationMinutes)
            .Select(t => new CourtPriceTierInput
            {
                DurationMinutes = t.DurationMinutes,
                Price = t.Price,
            })
            .ToList();

    public async Task<List<VenueOptionDto>> GetOptionsAsync()
    {
        return await _db.Venues
            .NotDeleted()
            .Where(v => v.IsApproved)
            .OrderBy(v => v.Name)
            .Select(v => new VenueOptionDto { Id = v.Id, Name = v.Name, City = v.City })
            .ToListAsync();
    }

    public async Task<VenueDashboardDto> GetDashboardAsync(int ownerUserId)
    {
        var venueIds = await _db.Venues
            .NotDeleted()
            .Where(v => v.OwnerId == ownerUserId)
            .Select(v => v.Id)
            .ToListAsync();
        if (venueIds.Count == 0) return new VenueDashboardDto();

        var courts = await _db.Courts
            .NotDeleted()
            .Include(c => c.OpeningHours)
            .Where(c => venueIds.Contains(c.VenueId))
            .ToListAsync();
        var courtIds = courts.Select(c => c.Id).ToList();

        var now = AppClock.Now;
        var today = now.Date;
        var tomorrow = today.AddDays(1);
        var monthStart = new DateTime(now.Year, now.Month, 1);
        // Saudi week starts Saturday.
        var daysSinceSaturday = ((int)today.DayOfWeek - (int)DayOfWeek.Saturday + 7) % 7;
        var weekStart = today.AddDays(-daysSinceSaturday);

        var bookings = await _db.Bookings
            .Include(b => b.Court).ThenInclude(c => c.Venue)
            .Include(b => b.User)
            .Where(b => courtIds.Contains(b.CourtId))
            .ToListAsync();

        var active = bookings.Where(b => b.Status != BookingStatus.Cancelled).ToList();
        var todaysActive = active.Where(b => b.StartTime >= today && b.StartTime < tomorrow).ToList();

        // نسبة الحجز — today's booked hours ÷ total bookable hours across every
        // owned court (each court's CourtCount identical physical courts), حسب
        // دوام كل ملعب اليوم — الملعب المغلق اليوم لا يدخل في الطاقة الاستيعابية.
        var capacityHoursToday = courts.Sum(c =>
        {
            var (open, close, closed) = CourtSchedule.HoursOn(c, today);
            return closed ? 0 : c.CourtCount * (close - open);
        });
        var bookedHoursToday = todaysActive
            .Where(b => b.Status is BookingStatus.Confirmed or BookingStatus.Completed)
            .Sum(b => (b.EndTime - b.StartTime).TotalHours);
        var bookingRate = capacityHoursToday > 0
            ? Math.Min(100, bookedHoursToday / capacityHoursToday * 100)
            : 0;

        // حالة الملاعب الآن — live status per court.
        var liveStatuses = courts.Select(c =>
        {
            if (c.IsSuspended || !c.IsAvailable)
                return new CourtLiveStatusDto
                { Id = c.Id, Name = c.Name, Type = c.Type == CourtType.Outdoor ? "outdoor" : "indoor", Status = "maintenance" };

            var current = todaysActive.FirstOrDefault(b =>
                b.CourtId == c.Id && b.Status == BookingStatus.Confirmed &&
                b.StartTime <= now && b.EndTime > now);
            if (current is not null)
                return new CourtLiveStatusDto
                {
                    Id = c.Id,
                    Name = c.Name,
                    Type = c.Type == CourtType.Outdoor ? "outdoor" : "indoor",
                    Status = "booked",
                    TimeRangeLabel = TimeRangeLabel(current.StartTime, current.EndTime),
                };

            return new CourtLiveStatusDto
            { Id = c.Id, Name = c.Name, Type = c.Type == CourtType.Outdoor ? "outdoor" : "indoor", Status = "available" };
        }).ToList();

        // إحصائيات هذا الأسبوع — confirmed/completed bookings, play hours and
        // average owner rate, Saturday through Friday.
        var weekBookings = active
            .Where(b => (b.Status == BookingStatus.Confirmed || b.Status == BookingStatus.Completed) &&
                        b.StartTime >= weekStart && b.StartTime < weekStart.AddDays(7))
            .ToList();
        var weekPlayHours = weekBookings.Sum(b => (b.EndTime - b.StartTime).TotalHours);

        return new VenueDashboardDto
        {
            VenuesCount = venueIds.Count,
            CourtsCount = courtIds.Count,
            TodayBookings = todaysActive.Count,
            // What the owner actually earns: the base price, net of نسبة سبورتا.
            // الإيراد من المؤكَّد/المكتمل فقط — المعلّق لم يُقيَّد للمالك بعد
            // (نفس شرط تقرير الإيرادات).
            MonthRevenue = active
                .Where(b => b.PaidFullAmount &&
                            (b.Status == BookingStatus.Confirmed || b.Status == BookingStatus.Completed) &&
                            b.StartTime >= monthStart)
                .Sum(b => b.OwnerAmount),
            WeekRevenue = weekBookings
                .Where(b => b.PaidFullAmount)
                .Sum(b => b.OwnerAmount),
            BookingRatePercent = Math.Round(bookingRate, 1),
            WeekBookingsCount = weekBookings.Count,
            WeekPlayHours = Math.Round(weekPlayHours, 1),
            WeekAvgHourlyPrice = weekBookings.Count > 0
                ? Math.Round(weekBookings.Average(b => b.Court.PricePerHour), 0)
                : 0,
            LiveCourtStatuses = liveStatuses,
            RecentBookings = bookings
                .OrderByDescending(b => b.CreatedAt)
                .Take(8)
                .Select(ToVenueBookingDto)
                .ToList(),
            UpcomingBookings = active
                .Where(b => b.Status == BookingStatus.Confirmed && b.StartTime > now)
                .OrderBy(b => b.StartTime)
                .Take(5)
                .Select(ToVenueBookingDto)
                .ToList(),
        };
    }

    private static string TimeRangeLabel(DateTime start, DateTime end)
    {
        string Fmt(DateTime d)
        {
            var h12 = d.Hour % 12 == 0 ? 12 : d.Hour % 12;
            var period = d.Hour < 12 ? "ص" : "م";
            return d.Minute == 0 ? $"{h12} {period}" : $"{h12}:{d.Minute:D2} {period}";
        }
        return $"{Fmt(start)} - {Fmt(end)}";
    }

    private static readonly string[] ArabicMonths =
    [
        "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
        "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر",
    ];

    private static readonly string[] ArabicWeekdaysShort =
        ["سبت", "أحد", "اثن", "ثلا", "أرب", "خمي", "جمع"];

    public async Task<VenueRevenueReportDto> GetRevenueReportAsync(
        int ownerUserId, string periodType, int offset)
    {
        var isWeek = periodType.Equals("week", StringComparison.OrdinalIgnoreCase);

        var venueIds = await _db.Venues
            .Where(v => v.OwnerId == ownerUserId)
            .Select(v => v.Id)
            .ToListAsync();
        var courtIds = await _db.Courts
            .Where(c => venueIds.Contains(c.VenueId))
            .Select(c => c.Id)
            .ToListAsync();

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

        var relevantBookings = await _db.Bookings
            .Include(b => b.Court)
            .Include(b => b.User)
            .Where(b => courtIds.Contains(b.CourtId) &&
                        b.PaidFullAmount &&
                        (b.Status == BookingStatus.Confirmed || b.Status == BookingStatus.Completed) &&
                        b.StartTime >= prevStart && b.StartTime < periodEnd)
            .ToListAsync();

        var periodBookings = relevantBookings
            .Where(b => b.StartTime >= periodStart && b.StartTime < periodEnd)
            .ToList();
        var prevTotal = relevantBookings
            .Where(b => b.StartTime >= prevStart && b.StartTime < prevEnd)
            .Sum(b => b.OwnerAmount);

        var total = periodBookings.Sum(b => b.OwnerAmount);

        var bars = buckets
            .Select(bk => new RevenueBarDto
            {
                Label = bk.label,
                Amount = periodBookings
                    .Where(b => b.StartTime >= bk.from && b.StartTime < bk.to)
                    .Sum(b => b.OwnerAmount),
            })
            .ToList();

        var courtBreakdown = periodBookings
            .GroupBy(b => b.Court.Name)
            .Select(g => new CourtRevenueDto
            {
                CourtName = g.Key,
                Total = g.Sum(b => b.OwnerAmount),
                BookingsCount = g.Count(),
                Percent = total > 0 ? (double)(g.Sum(b => b.OwnerAmount) / total * 100) : 0,
            })
            .OrderByDescending(c => c.Total)
            .ToList();

        var transactions = periodBookings
            .OrderByDescending(b => b.StartTime)
            .Take(50)
            .Select(b => new RevenueTransactionDto
            {
                CourtName = b.Court.Name,
                TimeRangeLabel = TimeRangeLabel(b.StartTime, b.EndTime),
                PlayerName = $"{b.User.FirstName} {b.User.LastName}".Trim(),
                Amount = b.OwnerAmount,
                Date = b.StartTime,
            })
            .ToList();

        return new VenueRevenueReportDto
        {
            PeriodType = isWeek ? "week" : "month",
            PeriodLabel = periodLabel,
            Total = total,
            ChangePercent = prevTotal > 0 ? (double)((total - prevTotal) / prevTotal * 100) : null,
            Bars = bars,
            CourtBreakdown = courtBreakdown,
            Transactions = transactions,
        };
    }

    // ── Admin ────────────────────────────────────────────────────────────────

    public async Task<PagedResult<AdminVenueDto>> GetAllVenuesAsync(
        string? search, int page, int pageSize)
    {
        var query = _db.Venues
            .NotDeleted()
            .Include(v => v.Owner)
            .Include(v => v.Courts.Where(c => !c.IsDeleted))
            .Include(v => v.Images)
            .InScope(await _admin.GetScopeAsync())
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(v =>
                v.Name.Contains(s) ||
                v.Owner.FirstName.Contains(s) ||
                v.Owner.LastName.Contains(s) ||
                v.Owner.PhoneNumber.Contains(s));
        }

        var venues = await query
            .OrderByDescending(v => v.CreatedAt)
            .ToListAsync();

        return PagedResult<AdminVenueDto>.Create(
            venues.Select(v => ToAdminVenueDto(v)).ToList(), page, pageSize);
    }

    public async Task<AdminVenueDto?> GetVenueByIdAsync(int id)
    {
        var venue = await _db.Venues
            .NotDeleted()
            .Include(v => v.Owner)
            .Include(v => v.Courts.Where(c => !c.IsDeleted))
            .Include(v => v.Images)
            .InScope(await _admin.GetScopeAsync())
            .FirstOrDefaultAsync(v => v.Id == id);

        // صفحة التفاصيل تعرض ملاعب النادي داخلها، فالقسم واحد في اللوحة.
        return venue is null ? null : ToAdminVenueDto(venue, includeCourts: true);
    }

    private static AdminVenueDto ToAdminVenueDto(Venue v, bool includeCourts = false) => new()
    {
        Id = v.Id,
        Name = v.Name,
        NameEn = v.NameEn,
        Description = v.Description,
        Country = v.Country,
        CountryId = v.CountryId,
        City = v.City,
        CityId = v.CityId,
        District = v.District,
        DistrictId = v.DistrictId,
        Address = v.Address,
        Latitude = v.Latitude,
        Longitude = v.Longitude,
        GenderPolicy = v.GenderPolicy switch
        {
            VenueGenderPolicy.WomenOnly => "womenOnly",
            VenueGenderPolicy.FamilyOnly => "familyOnly",
            _ => "men",
        },
        IsActive = v.Owner.IsActive,
        IsApproved = v.IsApproved,
        CourtsCount = v.Courts.Count,
        CreatedAt = v.CreatedAt,
        OwnerId = v.OwnerId,
        OwnerName = $"{v.Owner.FirstName} {v.Owner.LastName}".Trim(),
        OwnerPhone = v.Owner.PhoneNumber,
        CommercialRegistrationImageUrl = v.CommercialRegistrationImageUrl,
        NationalAddressImageUrl = v.NationalAddressImageUrl,
        OwnerIdImageUrl = v.OwnerIdImageUrl,
        TaxCertificateUrl = v.TaxCertificateUrl,
        ImageUrls = v.Images.Select(i => i.Url).ToList(),
        Courts = includeCourts
            ? v.Courts.OrderBy(c => c.Name).Select(ToAdminVenueCourtDto).ToList()
            : [],
    };

    private static AdminVenueCourtDto ToAdminVenueCourtDto(Court c) => new()
    {
        Id = c.Id,
        Name = c.Name,
        Type = c.Type == CourtType.Indoor ? "indoor" : "outdoor",
        CourtCount = c.CourtCount < 1 ? 1 : c.CourtCount,
        BasePrice = CourtSchedule.BasePrice(c),
        SportaCommissionPercent = c.SportaCommissionPercent,
        PeakHourPrice = CourtSchedule.EffectivePeakPrice(c),
        IsAvailable = c.IsAvailable,
        IsSuspended = c.IsSuspended,
        ImageUrl = c.ImageUrl,
    };
}
