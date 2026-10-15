using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;
using MatchType = SportaApis.Enums.MatchType;

namespace SportaApis.Services;

public class MatchService : IMatchService
{
    private readonly AppDbContext _db;
    private readonly IWalletService _wallet;
    private readonly INotificationService _notifications;
    private readonly ISettingsService _settings;
    private readonly IPointsService _points;
    private readonly IEventInviteService _invites;
    private readonly IWaitlistService _waitlist;
    private readonly IEventChatService _chat;
    private readonly IMembershipService _memberships;

    public MatchService(
        AppDbContext db, IWalletService wallet,
        INotificationService notifications, ISettingsService settings,
        IPointsService points, IEventInviteService invites, IWaitlistService waitlist,
        IEventChatService chat, IMembershipService memberships)
    {
        _memberships = memberships;
        _chat = chat;
        _waitlist = waitlist;
        _db = db;
        _wallet = wallet;
        _notifications = notifications;
        _settings = settings;
        _points = points;
        _invites = invites;
    }

    public async Task<PagedResult<MatchDto>> GetMatchesAsync(
        int currentUserId, string? city, string? gender, int page = 1, int pageSize = 20)
    {
        var dtos = await GetMatchesListAsync(currentUserId, city, gender);
        return PagedResult<MatchDto>.Create(dtos, page, pageSize);
    }

    // Nearby filtering/sorting happens in memory (distance is computed per row),
    // so the full filtered list is built first and paged afterwards.
    private async Task<List<MatchDto>> GetMatchesListAsync(
        int currentUserId, string? city, string? gender)
    {
        var query = _db.Matches
            .Include(m => m.Court).ThenInclude(c => c!.Venue).ThenInclude(v => v.CityRef)
            .Include(m => m.Court).ThenInclude(c => c!.Venue).ThenInclude(v => v.DistrictRef)
            .Include(m => m.MatchPlayers).ThenInclude(p => p.User).ThenInclude(u => u.PlayerProfile)
            // Exclude americano events — they live in the americano tab.
            .Where(m => m.AmericanoMatch == null)
            // A court match waits for the venue owner, but its creator has
            // already paid for it — hiding it until approval makes the match
            // look lost. It stays invisible to everyone else.
            .Where(m => m.Status == MatchStatus.Open
                     || m.Status == MatchStatus.Full
                     || (m.Status == MatchStatus.PendingApproval
                         && m.CreatorId == currentUserId))
            // الخاصة لا تظهر إلا لمنشئها ومن انضم إليها أو دُعي إليها.
            .Where(m => !m.IsPrivate || m.CreatorId == currentUserId
                     || m.MatchPlayers.Any(p => p.UserId == currentUserId))
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(city))
            query = query.Where(m => m.Court != null && m.Court.Venue.City == city);

        if (TryParseGender(gender) is Gender g)
            query = query.Where(m => m.Gender == g);

        var matches = await query
            .OrderBy(m => m.ScheduledAt)
            .ToListAsync();

        var dtos = matches.Select(m => ToDto(m, currentUserId)).ToList();

        // Nearby: when the user has a saved location, annotate distance, drop
        // matches beyond the configured radius, and sort nearest first.
        var user = await _db.Users
            .Where(u => u.Id == currentUserId)
            .Select(u => new { u.Latitude, u.Longitude })
            .FirstOrDefaultAsync();
        if (user?.Latitude == null || user?.Longitude == null) return dtos;

        var maxKm = await _settings.GetNearbyDistanceKmAsync();
        for (var i = 0; i < matches.Count; i++)
        {
            var venue = matches[i].Court?.Venue;
            if (venue?.Latitude != null && venue?.Longitude != null)
                dtos[i].DistanceKm = Math.Round(
                    Helpers.GeoHelper.DistanceKm(
                        user.Latitude.Value, user.Longitude.Value,
                        venue.Latitude.Value, venue.Longitude.Value),
                    1);
        }

        // مباراتي (أنشأتها أو انضممت إليها) تظهر مهما بعُدت.
        return dtos
            .Where(d => d.DistanceKm == null || d.DistanceKm <= maxKm
                        || d.CreatorId == currentUserId || d.HasJoined)
            .OrderBy(d => d.DistanceKm ?? double.MaxValue)
            .ToList();
    }

    public async Task<MatchDto> GetByIdAsync(int currentUserId, int id)
    {
        var match = await LoadFull().FirstOrDefaultAsync(m => m.Id == id)
            ?? throw new AuthException("Match not found", "المباراة غير موجودة", "MATCH_NOT_FOUND");
        // الخاصة لا تُقرأ إلا لمن له علاقة بها؛ لغيره كأنها غير موجودة.
        if (match.IsPrivate && !await CanSeePrivateAsync(match, currentUserId))
            throw new AuthException("Match not found", "المباراة غير موجودة", "MATCH_NOT_FOUND");
        return ToDto(match, currentUserId);
    }

    /// <summary>
    /// من يرى المباراة الخاصة: منشئها، ومن له صف فيها (لاعب/طلب/دعوة)،
    /// وصاحب ملعبها، ومن عنده دعوة سارية إليها (EventInvite).
    /// </summary>
    private async Task<bool> CanSeePrivateAsync(Match match, int userId)
    {
        if (userId == 0) return false;
        if (match.CreatorId == userId || match.MatchPlayers.Any(p => p.UserId == userId))
            return true;
        if (match.Court?.Venue.OwnerId == userId) return true;
        var now = AppClock.Now;
        return await _db.EventInvites.AnyAsync(i =>
            i.Kind == EventInviteKind.Match && i.TargetId == match.Id
            && i.ReceiverId == userId && i.Status == EventInviteStatus.Pending
            && i.ExpiresAt > now);
    }

    public async Task<MatchDto> CreateAsync(int userId, CreateMatchRequest req)
    {
        if (req.MinLevel > req.MaxLevel)
            throw new AuthException(
                "Invalid level range", "نطاق المستوى غير صحيح", "INVALID_LEVEL_RANGE");

        // موعد مضى لا تُنشأ عليه مباراة — قائمة المواعيد تخفي ما فات، وهذا
        // يمنع نداءً مباشراً من تجاوزها.
        if (req.ScheduledAt <= AppClock.Now)
            throw new AuthException(
                "Selected time has already passed",
                "الوقت المختار مضى — اختر موعداً قادماً", "SLOT_IN_PAST");

        var match = new Match
        {
            CreatorId = userId,
            CourtId = req.CourtId,
            MatchType = ParseMatchType(req.MatchType),
            Gender = TryParseGender(req.Gender) ?? throw new AuthException(
                "Players gender is required (male or female)",
                "يجب تحديد نوع اللاعبين المنضمين: رجال أو نساء", "GENDER_REQUIRED"),
            ScheduledAt = req.ScheduledAt,
            DurationMinutes = req.DurationMinutes,
            MaxPlayers = req.MaxPlayers,
            MinLevel = req.MinLevel,
            MaxLevel = req.MaxLevel,
            Notes = req.Notes,
            IsPrivate = req.IsPrivate,
        };

        // قفل الملعب نفسه الذي يأخذه الحجز العادي: فحص الموعد ثم الإنشاء لا
        // يتقاطعان مع حجز أو مباراة متزامنة على الموعد ذاته.
        await using var courtGate = req.CourtId is int lockedCourtId
            ? await DbLocks.AcquireAsync(_db, $"court:{lockedCourtId}")
            : null;

        Court? court = null;
        var hostedByOwner = false;
        if (req.CourtId is int courtId)
        {
            court = await _db.Courts
                .NotDeleted()
                .Include(c => c.Venue)
                .Include(c => c.PriceTiers)
                .Include(c => c.OpeningHours)
                .Include(c => c.PriceRules)
                .FirstOrDefaultAsync(c => c.Id == courtId && c.Venue.IsApproved)
                ?? throw new AuthException(
                    "Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

            // المباراة تحجز الملعب فعلياً، فتخضع لدوام يومه كأي حجز.
            if (!CourtSchedule.IsWithinOpeningHours(court, req.ScheduledAt, req.DurationMinutes))
                throw new AuthException(
                    "Selected time is outside opening hours",
                    "الوقت المختار خارج ساعات عمل الملعب", "OUTSIDE_OPENING_HOURS");

            // الموعد يجب أن يكون فارغاً فعلاً: حجز عادي أو مباراة أخرى أو جلسة
            // تدريب تشغل الملعب — نفس ما تعتمده قائمة المواعيد المتاحة.
            var slotEnd = req.ScheduledAt.AddMinutes(req.DurationMinutes);
            if (await CourtOccupancy.IsTakenAsync(_db, courtId, req.ScheduledAt, slotEnd))
                throw new AuthException(
                    "This slot is already booked", "هذا الموعد محجوز بالفعل", "SLOT_TAKEN");

            // الساعات التي أغلقها صاحب الملعب غير متاحة كذلك (60 دقيقة من
            // 10:30 تلمس 10 و11 — نفس صيغة الحجز وقائمة المواعيد).
            var coveredHours = CourtSchedule.CoveredHours(req.ScheduledAt, req.DurationMinutes);
            if (await _db.CourtBlockedSlots.AnyAsync(s =>
                    s.CourtId == courtId && s.Date == req.ScheduledAt.Date &&
                    coveredHours.Contains(s.Hour)))
                throw new AuthException(
                    "Slot is unavailable", "هذا الموعد غير متاح", "SLOT_UNAVAILABLE");

            // استضافة من حساب الملعب (بطلب صريح): ملعبه، فلا يدفع ولا ينتظر
            // موافقة نفسه، ولا يُحسب لاعباً — المقاعد كلها مفتوحة للاعبين.
            // من حساب اللاعب يُعامل صاحب الملعب كأي لاعب حتى على ملعبه.
            hostedByOwner = req.HostedByVenue;
            if (hostedByOwner && court.Venue.OwnerId != userId)
                throw new AuthException(
                    "Hosting is only allowed on your own courts",
                    "الاستضافة متاحة على ملاعبك فقط", "NOT_OWNER");

            // ملعب أخفاه البحث (نادٍ غير نشط أو اشتراكه منتهٍ) لا يُحجز بمباراة
            // يُنشئها لاعب بالمعرّف مباشرة — كالحجز العادي.
            if (!hostedByOwner && !await VenueBookability.IsBookableAsync(_db, courtId))
                throw new AuthException(
                    "Court is not available", "الملعب غير متاح للحجز", "COURT_UNAVAILABLE");

            // Matches use the same price as a regular court booking for the
            // chosen duration, split evenly across the players.
            if (CourtSchedule.HasTiers(court, CourtPriceKind.Booking) &&
                CourtSchedule.TierPrice(court, CourtPriceKind.Booking, req.DurationMinutes) is null)
                throw new AuthException(
                    "Duration not offered for this court",
                    "هذه المدة غير متاحة لهذا الملعب", "DURATION_UNAVAILABLE");

            var totalPrice = CourtSchedule.BookingPrice(court, req.ScheduledAt, req.DurationMinutes);
            match.PricePerPlayer = Math.Round(totalPrice / req.MaxPlayers, 2);
            // Snapshot نسبة سبورتا so payouts stay consistent if it changes later.
            match.SportaCommissionPercent = court.SportaCommissionPercent;

            if (hostedByOwner)
            {
                // كل لاعب يدفع حصته وتذهب لصاحب الملعب (صافيةً من نسبة سبورتا)،
                // والمباراة تُفتح فوراً: لا موافقة ينتظرها المالك من نفسه.
                match.PaymentMode = MatchPaymentMode.SharePerPlayer;
                match.Status = MatchStatus.Open;
            }
            else
            {
                // الدفع فرديّ: كل لاعب يدفع حصته وحده — الاستثناء الوحيد هو
                // حجز الملعب العادي، حيث يدفع الحاجز كامل قيمته.
                match.PaymentMode = MatchPaymentMode.SharePerPlayer;
                // Court matches must be approved by the owner before opening for joins.
                match.Status = MatchStatus.PendingApproval;

                // The creator pays up-front; verify funds before persisting.
                // عضو النادي يدفع حصته بعد خصم عضويته.
                var charge = (await _memberships.QuoteShareAsync(
                    userId, court.VenueId, match.PricePerPlayer, req.DurationMinutes,
                    req.ScheduledAt)).Amount;
                var wallet = await _db.Wallets.FirstOrDefaultAsync(w => w.UserId == userId);
                if (charge > 0 && (wallet == null || wallet.Balance < charge))
                    throw new AuthException(
                        "Insufficient wallet balance",
                        "رصيد المحفظة غير كافٍ، يرجى شحن المحفظة والمحاولة مجدداً",
                        "INSUFFICIENT_BALANCE");
            }
        }
        else
        {
            // مباراة بلا ملعب: لا مستفيد داخل التطبيق يتسلّم الحصص (لا مالك ولا
            // تحويل للمنشئ)، فكانت حصص المنضمّين تُخصم وتضيع. لا دفع فيها.
            match.PricePerPlayer = 0;
            match.PaymentMode = MatchPaymentMode.SharePerPlayer;
            match.Status = MatchStatus.Open;
        }

        // The creator is the first (approved) player — and has paid for court matches.
        // إلا صاحب الملعب المستضيف: هو المنظّم لا لاعب، فتبقى كل المقاعد شاغرة.
        if (!hostedByOwner)
            match.MatchPlayers.Add(new MatchPlayer
            {
                UserId = userId,
                Status = MatchPlayerStatus.Approved,
                // بلا ملعب لا شيء مستحق عليه.
                HasPaid = true,
            });

        _db.Matches.Add(match);
        await _db.SaveChangesAsync();

        if (court != null && !hostedByOwner)
        {
            var share = await _memberships.QuoteEventShareAsync(userId, match);
            // الفحص المسبق للرصيد لا يحجز شيئاً: خصمٌ فشل (رصيد نقص بطلب متزامن)
            // كان يترك المنشئ «مدفوعاً» بلا خصم. تُحذف المباراة ويُرفض الطلب.
            if (share.Amount > 0 && !await _wallet.TryChargeAsync(
                    userId, share.Amount, WalletTransactionType.MatchPayment,
                    "دفع مباراة", match.Id))
            {
                _db.Matches.Remove(match);
                await _db.SaveChangesAsync();
                throw new AuthException(
                    "Insufficient wallet balance",
                    "رصيد المحفظة غير كافٍ، يرجى شحن المحفظة والمحاولة مجدداً",
                    "INSUFFICIENT_BALANCE");
            }
            if (match.MatchPlayers.FirstOrDefault(p => p.UserId == userId) is { } creator)
            {
                share.ApplyTo(creator);
                await _db.SaveChangesAsync();
            }

            await _notifications.PushAsync(court.Venue.OwnerId,
                "طلب مباراة جديد على ملعبك",
                $"طلب استضافة مباراة على {court.Name} بانتظار موافقتك",
                "match_request", match.Id);
        }

        // نقاط مكافآت لمنشئ المباراة (reward_points_match_created).
        await _points.EarnActivityAsync(
            userId, PointsTransactionType.MatchCreated, match.Id, null);

        return await GetByIdAsync(userId, match.Id);
    }

    public async Task<MatchDto> JoinAsync(int userId, int matchId)
    {
        // الانضمام يُسلسَل لكل مباراة: نقرتان متتاليتان كانتا تخصمان الحصة
        // مرتين (الثانية يرفضها الفهرس الفريد بعد خصمها)، وطلبان متزامنان كانا
        // يتجاوزان السعة. كل الفحوص تُعاد داخل القفل على بيانات طازجة.
        Match match;
        bool invitedByCreator;
        await using (await MatchLock.AcquireAsync(_db, matchId))
            (match, invitedByCreator) = await JoinLockedAsync(userId, matchId);

        if (!invitedByCreator)
        {
            var name = await UserNameAsync(userId);
            await _notifications.PushAsync(match.CreatorId, "طلب انضمام جديد",
                $"طلب {name} الانضمام إلى مباراتك", "match_join_request", match.Id);
        }

        return await GetByIdAsync(userId, match.Id);
    }

    /// <summary>جسم <see cref="JoinAsync"/> داخل قفل المباراة.</summary>
    private async Task<(Match Match, bool InvitedByCreator)> JoinLockedAsync(int userId, int matchId)
    {
        var match = await _db.Matches
            .Include(m => m.MatchPlayers)
            .Include(m => m.Court).ThenInclude(c => c!.Venue)
            .FirstOrDefaultAsync(m => m.Id == matchId)
            ?? throw new AuthException("Match not found", "المباراة غير موجودة", "MATCH_NOT_FOUND");

        // من دعاه المنشئ ينضم حتى قبل موافقة الملعب، وحصته محجوزة عندنا
        // (تُصرف للمالك عند موافقته أو تُردّ عند رفضه — VenueService).
        var invitedByCreator = await _invites.HasActiveInviteFromAsync(
            match.CreatorId, userId, EventInviteKind.Match, match.Id);

        // الخاصة بدعوة المنشئ فقط (يحوّلها عامةً ليفتحها للجميع).
        if (match.IsPrivate && !invitedByCreator)
            throw new AuthException(
                "This match is private", "هذه المباراة خاصة — بدعوة من المنظّم فقط",
                "MATCH_PRIVATE");

        if (match.Status == MatchStatus.PendingApproval && !invitedByCreator)
            throw new AuthException(
                "Match is awaiting venue approval",
                "المباراة بانتظار موافقة الملعب", "MATCH_PENDING_APPROVAL");

        if (match.Status == MatchStatus.Cancelled || match.Status == MatchStatus.Completed)
            throw new AuthException(
                "Match is not joinable", "لا يمكن الانضمام لهذه المباراة", "MATCH_CLOSED");

        if (match.MatchPlayers.Any(p => p.UserId == userId))
            throw new AuthException(
                "Already joined this match", "لديك طلب أو انضمام بالفعل لهذه المباراة",
                "ALREADY_JOINED");

        await EnsureGenderAllowedAsync(match, userId);
        await EnsureLevelAllowedAsync(match, userId);

        if (match.MatchPlayers.Count(p => p.Status == MatchPlayerStatus.Approved)
            >= match.MaxPlayers)
            throw new AuthException(
                "Match is full", "المباراة مكتملة العدد", "MATCH_FULL");

        // مقعد شاغر محجوز لمن جاء دوره في قائمة الانتظار لا يأخذه غيره —
        // إلا من دعاه المنشئ نفسه: الدعوة قراره.
        if (!invitedByCreator)
            await _waitlist.EnsureSeatAvailableAsync(match, userId);

        // The player's share is held up-front and refunded if the creator rejects
        // the request. When the creator paid the match in full, this share is
        // later paid back to the creator instead of the venue owner.
        var share = await _memberships.QuoteEventShareAsync(userId, match);
        var hasPaid = await _wallet.TryChargeAsync(
            userId, share.Amount, WalletTransactionType.MatchPayment,
            "حصة مباراة", match.Id);
        if (!hasPaid)
            throw new AuthException(
                "Insufficient wallet balance",
                "رصيد المحفظة غير كافٍ، يرجى شحن المحفظة والمحاولة مجدداً",
                "INSUFFICIENT_BALANCE");

        // الانضمام *طلب* ينتظر موافقة المنشئ (ومنه صاحب الملعب المستضيف)،
        // والحصة محجوزة عندنا حتى يقبل أو يرفض. من دعاه المنشئ نفسه يُقبل فوراً.
        var request = new MatchPlayer
        {
            MatchId = match.Id,
            UserId = userId,
            Status = MatchPlayerStatus.Pending,
            HasPaid = hasPaid,
        };
        share.ApplyTo(request);
        match.MatchPlayers.Add(request);
        await _db.SaveChangesAsync();
        // طلب انضمامه يحلّ محل مكانه في قائمة الانتظار.
        await _waitlist.RemoveEntryAsync(match.Id, userId);

        if (invitedByCreator)
            await ApproveRequestAsync(match, request);

        return (match, invitedByCreator);
    }

    /// <summary>
    /// مباراة أنشأها صاحب الملعب على ملعبه: هو المنظّم لا لاعب، والتسجيل فيها
    /// مفتوح بلا موافقة، وحصص اللاعبين تذهب إليه مباشرة.
    /// </summary>
    private static bool IsVenueHosted(Match match) => match.IsHostedByVenueOwner;

    public async Task<MatchDto> MakePublicAsync(int userId, int matchId)
    {
        await using var gate = await MatchLock.AcquireAsync(_db, matchId);
        var match = await _db.Matches.FirstOrDefaultAsync(m => m.Id == matchId)
            ?? throw new AuthException("Match not found", "المباراة غير موجودة", "MATCH_NOT_FOUND");
        if (match.CreatorId != userId)
            throw new AuthException("Not your match", "هذه المباراة ليست لك", "NOT_OWNER");
        if (match.Status is MatchStatus.Cancelled or MatchStatus.Completed or MatchStatus.InProgress)
            throw new AuthException(
                "Match is not open", "المباراة غير متاحة", "MATCH_CLOSED");
        if (!match.IsPrivate)
            throw new AuthException(
                "Match is already public", "المباراة عامة بالفعل", "ALREADY_PUBLIC");

        match.IsPrivate = false;
        await _db.SaveChangesAsync();
        await gate.ReleaseAsync();
        return await GetByIdAsync(userId, matchId);
    }

    public async Task<MatchDto> InviteAsync(int inviterId, int matchId, int targetId)
    {
        var match = await _db.Matches
            .Include(m => m.MatchPlayers)
            .FirstOrDefaultAsync(m => m.Id == matchId)
            ?? throw new AuthException("Match not found", "المباراة غير موجودة", "MATCH_NOT_FOUND");

        // اللاعبون يدعون رفاقهم، والمنظّم كذلك — صاحب الملعب المستضيف منظّمٌ
        // لا لاعب، وكانت دعوته تُرفض فتضيع صامتةً في التطبيق.
        // لاعب معتمد فقط — صاحب طلب معلّق أو دعوة لم يقبلها ليس من اللاعبين.
        if (!match.MatchPlayers.Any(p => p.UserId == inviterId && p.Status == MatchPlayerStatus.Approved)
            && match.CreatorId != inviterId)
            throw new AuthException(
                "Only players or the organizer can invite",
                "فقط لاعبو المباراة أو منظّمها يمكنهم الدعوة", "NOT_A_PLAYER");

        // الخاصة يدعو إليها منشئها وحده، فلا يوسّع اللاعبون دائرتها.
        if (match.IsPrivate && match.CreatorId != inviterId)
            throw new AuthException(
                "Only the organizer can invite to a private match",
                "المباراة خاصة — الدعوة للمنظّم وحده", "MATCH_PRIVATE");

        if (targetId == inviterId || match.MatchPlayers.Any(p => p.UserId == targetId))
            throw new AuthException(
                "Player already in the match", "اللاعب منضم بالفعل", "ALREADY_JOINED");

        if (match.Status == MatchStatus.Cancelled || match.Status == MatchStatus.Completed)
            throw new AuthException(
                "Match is not open", "المباراة غير متاحة", "MATCH_CLOSED");

        if (match.MatchPlayers.Count(p => p.Status == MatchPlayerStatus.Approved)
            >= match.MaxPlayers)
            throw new AuthException(
                "Match is full", "المباراة مكتملة العدد", "MATCH_FULL");

        if (!await _db.Users.AnyAsync(u => u.Id == targetId))
            throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        await EnsureGenderAllowedAsync(match, targetId);
        await EnsureLevelAllowedAsync(match, targetId);

        // Invitations are for friends only.
        if (!await AreFriendsAsync(inviterId, targetId))
            throw new AuthException(
                "You can only invite friends", "يمكنك دعوة الأصدقاء فقط", "NOT_FRIENDS");

        // The invited player is added as a pending invite; they must accept it
        // before becoming a member (handled by RespondToInviteAsync).
        match.MatchPlayers.Add(new MatchPlayer
        {
            MatchId = match.Id,
            UserId = targetId,
            Status = MatchPlayerStatus.Invited,
            InvitedById = inviterId,
        });
        await _db.SaveChangesAsync();

        var inviterName = await _db.Users
            .Where(u => u.Id == inviterId)
            .Select(u => (u.FirstName + " " + u.LastName).Trim())
            .FirstOrDefaultAsync() ?? "لاعب";
        await _notifications.PushAsync(targetId, "دعوة لمباراة",
            $"دعاك {inviterName} للانضمام إلى مباراة", "match_invite", match.Id);

        return await GetByIdAsync(inviterId, match.Id);
    }

    public async Task<MatchDto> RespondToInviteAsync(int userId, int matchId, bool accept)
    {
        // القبول يخصم ويشغل مقعداً: يُسلسَل مع بقية الانضمامات على المباراة
        // (نقرتان تخصمان مرتين، وقبولان متزامنان يتجاوزان السعة).
        await using var gate = await MatchLock.AcquireAsync(_db, matchId);
        var match = await _db.Matches
            .Include(m => m.MatchPlayers)
            .Include(m => m.Court).ThenInclude(c => c!.Venue).ThenInclude(v => v.CityRef)
            .Include(m => m.Court).ThenInclude(c => c!.Venue).ThenInclude(v => v.DistrictRef)
            .FirstOrDefaultAsync(m => m.Id == matchId)
            ?? throw new AuthException("Match not found", "المباراة غير موجودة", "MATCH_NOT_FOUND");

        var invite = match.MatchPlayers.FirstOrDefault(
            p => p.UserId == userId && p.Status == MatchPlayerStatus.Invited)
            ?? throw new AuthException(
                "Invitation not found", "الدعوة غير موجودة", "INVITE_NOT_FOUND");

        var name = await _db.Users
            .Where(u => u.Id == userId)
            .Select(u => (u.FirstName + " " + u.LastName).Trim())
            .FirstOrDefaultAsync() ?? "لاعب";

        if (accept)
        {
            if (match.Status == MatchStatus.Cancelled || match.Status == MatchStatus.Completed)
                throw new AuthException(
                    "Match is not joinable", "لا يمكن الانضمام لهذه المباراة", "MATCH_CLOSED");

            if (match.MatchPlayers.Count(p => p.Status == MatchPlayerStatus.Approved)
                >= match.MaxPlayers)
                throw new AuthException(
                    "Match is full", "المباراة مكتملة العدد", "MATCH_FULL");

            // دعوة من لاعب غير المنشئ: القبول يصير طلب انضمام ينتظر موافقة
            // المنشئ، والحصة تُحجز حتى يقبل (وتُردّ إن رفض).
            // دعوة قديمة بلا داعٍ معروف تُعامل كدعوة من غير المنشئ (طلب ينتظر موافقته).
            if (invite.InvitedById != match.CreatorId)
            {
                var heldShare = await _memberships.QuoteEventShareAsync(userId, match);
                var held = await _wallet.TryChargeAsync(
                    userId, heldShare.Amount, WalletTransactionType.MatchPayment,
                    "حصة مباراة", match.Id);
                if (!held)
                    throw new AuthException(
                        "Insufficient wallet balance",
                        "رصيد المحفظة غير كافٍ، يرجى شحن المحفظة والمحاولة مجدداً",
                        "INSUFFICIENT_BALANCE");
                invite.Status = MatchPlayerStatus.Pending;
                invite.HasPaid = held;
                heldShare.ApplyTo(invite);
                invite.JoinedAt = DateTime.UtcNow;
                await _db.SaveChangesAsync();
                await gate.ReleaseAsync();
                await _notifications.PushAsync(match.CreatorId, "طلب انضمام جديد",
                    $"قبل {name} دعوة صديقه ويطلب الانضمام إلى مباراتك",
                    "match_join_request", match.Id);
                return await GetByIdAsync(userId, match.Id);
            }

            // الحصة تُخصم *قبل* الاعتماد (بعد خصم عضويته إن وُجدت): رصيد لا يكفي
            // يُبقي الدعوة كما هي ولا يجعله عضواً معتمداً يشغل مقعداً بلا دفع.
            var inviteShare = await _memberships.QuoteEventShareAsync(userId, match);
            var charged = await _wallet.TryChargeAsync(
                userId, inviteShare.Amount, WalletTransactionType.MatchPayment,
                "حصة مباراة", match.Id);
            if (!charged)
                throw new AuthException(
                    "Insufficient wallet balance",
                    "رصيد المحفظة غير كافٍ، يرجى شحن المحفظة والمحاولة مجدداً",
                    "INSUFFICIENT_BALANCE");
            invite.HasPaid = true;
            inviteShare.ApplyTo(invite);

            var awaitingVenue = match.Status == MatchStatus.PendingApproval;
            invite.Status = MatchPlayerStatus.Approved;
            invite.JoinedAt = DateTime.UtcNow;
            if (!awaitingVenue &&
                match.MatchPlayers.Count(p => p.Status == MatchPlayerStatus.Approved)
                >= match.MaxPlayers)
                match.Status = MatchStatus.Full;

            await _db.SaveChangesAsync();
            await _chat.PostMemberEventAsync(match.Id, userId, joined: true);
            // Court matches: route the collected share to the venue owner (net
            // of نسبة سبورتا), or back to the creator in full when they paid
            // the whole match up-front (a reimbursement, not an earning).
            // قبل موافقة الملعب تبقى محجوزة — VenueService يصرفها أو يردّها.
            if (!awaitingVenue && invite.HasPaid && match.PricePerPlayer > 0 && match.Court != null)
            {
                if (match.PaymentMode == MatchPaymentMode.FullByCreator)
                    await _wallet.CreditEarningAsync(
                        match.CreatorId, match.ShareOf(invite),
                        WalletTransactionType.CreatorEarning, "حصة مباراة", match.Id);
                else
                    await _wallet.CreditEarningAsync(
                        match.Court.Venue.OwnerId,
                        match.NetOfCommission(match.ShareOf(invite)),
                        WalletTransactionType.VenueEarning, "حصة مباراة", match.Id);
            }
            await _db.SaveChangesAsync();
            await gate.ReleaseAsync();

            await _notifications.PushAsync(match.CreatorId, "تم قبول الدعوة",
                $"انضم {name} إلى مباراتك", "match_invite_accepted", match.Id);
        }
        else
        {
            _db.Set<MatchPlayer>().Remove(invite);
            await _db.SaveChangesAsync();
            await gate.ReleaseAsync();
            await _notifications.PushAsync(match.CreatorId, "تم رفض الدعوة",
                $"اعتذر {name} عن دعوة المباراة", "match_invite_rejected", match.Id);
        }

        return await GetByIdAsync(userId, match.Id);
    }

    private async Task<bool> AreFriendsAsync(int a, int b) => await _db.Friendships.AnyAsync(f =>
        f.Status == FriendshipStatus.Accepted &&
        ((f.SenderId == a && f.ReceiverId == b) || (f.SenderId == b && f.ReceiverId == a)));

    public async Task<PagedResult<MatchDto>> GetMyMatchesAsync(
        int userId, int page, int pageSize, string? status, bool activeOnly = false,
        bool matchesOnly = false, bool newestFirst = false, bool finishedOnly = false)
    {
        (page, pageSize) = Paging.Clamp(page, pageSize);

        // «مبارياتي» = ما ألعبه أو ما أنظّمه — صاحب الملعب الذي يستضيف مباراة
        // ليس لاعباً فيها، وكانت تختفي عنه تماماً.
        var query = LoadFull()
            .Where(m => m.MatchPlayers.Any(p => p.UserId == userId)
                     || m.CreatorId == userId);

        if (!string.IsNullOrWhiteSpace(status) &&
            Enum.TryParse<MatchStatus>(status, ignoreCase: true, out var s))
            query = query.Where(m => m.Status == s);

        // قسم «مبارياتي» في صفحة المباريات: الحالية فقط — لا المنتهية ولا الملغاة.
        // «انتهى» = اكتملت أو أُلغيت أو مضى وقتها (الموعد + المدة بتوقيت
        // السعودية) — مباراة مرّ موعدها وبقيت «مكتملة العدد» بلا نتيجة كانت
        // تبقى بين الحالية.
        var now = AppClock.Now;
        if (activeOnly)
            query = query.Where(m => m.Status != MatchStatus.Completed
                                  && m.Status != MatchStatus.Cancelled
                                  && m.ScheduledAt.AddMinutes(m.DurationMinutes) > now);

        // صفحة «المنتهية»: ما انتهى أو أُلغي — يُفتح من زرّ مستقل.
        if (finishedOnly)
            query = query.Where(m => m.Status == MatchStatus.Completed
                                  || m.Status == MatchStatus.Cancelled
                                  || m.ScheduledAt.AddMinutes(m.DurationMinutes) <= now);

        // تبويب المباريات: المباريات العادية وحدها — الأمريكانو والبطولات لها
        // تبويباتها. الملف الشخصي وسجل الحجوزات يريدان الكل فلا يمرّرانه.
        if (matchesOnly)
            query = query.Where(m => m.AmericanoMatch == null);

        var total = await query.CountAsync();
        // قسم «مبارياتي» وصفحة «عرض الكل»: الأحدث إنشاءً أولاً (ما أنشأه للتو
        // في الصدارة)؛ وإلا الترتيب القديم بالموعد.
        var ordered = newestFirst
            ? query.OrderByDescending(m => m.Id)
            : query.OrderByDescending(m => m.ScheduledAt);
        var matches = await ordered
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<MatchDto>
        {
            Items = matches.Select(m => ToDto(m, userId)).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    public async Task<List<MatchDto>> GetUpcomingAsync(int userId)
    {
        var now = AppClock.Now;
        // The reminder window opens 30 minutes before kick-off; the card stays
        // up until the match is over (start + duration). Only matches the user
        // is an approved member of, and that are still live.
        var windowStart = now.AddMinutes(30);

        var matches = await LoadFull()
            .Where(m => m.MatchPlayers.Any(
                p => p.UserId == userId && p.Status == MatchPlayerStatus.Approved))
            .Where(m => m.Status == MatchStatus.Open
                     || m.Status == MatchStatus.Full
                     || m.Status == MatchStatus.InProgress)
            .Where(m => m.ScheduledAt <= windowStart)
            .OrderBy(m => m.ScheduledAt)
            .ToListAsync();

        // Drop matches that have already finished (start + duration in the past).
        return matches
            .Where(m => m.ScheduledAt.AddMinutes(m.DurationMinutes) >= now)
            .Select(m => ToDto(m, userId))
            .ToList();
    }

    /// <summary>
    /// أي لاعب من الفريقين يُدخل النتيجة فتُحفظ مقترحةً، ولا تُعتمد حتى يؤكدها
    /// لاعب من الفريق الآخر (<see cref="RespondResultAsync"/>). إن أدخل لاعب من
    /// الفريق الآخر النتيجة والتوزيع نفسيهما عُدّ ذلك تأكيداً.
    /// </summary>
    public async Task<MatchDto> SubmitResultAsync(
        int userId, int matchId, SubmitMatchResultRequest req)
    {
        var match = await LoadForResultAsync(matchId);
        var approved = match.MatchPlayers
            .Where(p => p.Status == MatchPlayerStatus.Approved)
            .ToList();
        if (!approved.Any(p => p.UserId == userId)) throw ScoreProposals.NotAPlayer();
        if (match.Status is MatchStatus.Cancelled or MatchStatus.PendingApproval)
            throw new AuthException(
                "This match can't take a result", "لا يمكن إدخال نتيجة لهذه المباراة", "MATCH_CLOSED");
        // النتيجة لفريقين مكتملين: مباراة ناقصة لم تُلعب كما أُنشئت (وتُلغى
        // تلقائياً قبل موعدها إن بقيت ناقصة).
        if (approved.Count < match.MaxPlayers)
            throw new AuthException(
                "The match roster is not complete",
                "لم يكتمل عدد لاعبي المباراة — لا يمكن إدخال نتيجتها", "MATCH_INCOMPLETE");
        if (req.Team1Score is not int s1 || req.Team2Score is not int s2)
            throw new AuthException(
                "Enter both teams' scores", "أدخل نتيجة الفريقين", "RESULT_SCORES_REQUIRED");

        // توزيع الفريقين: من أُرسل في الفريق الأول والباقون في الثاني، وإلا
        // التوزيع المحفوظ. بدونه لا يُعرف «الفريق الآخر» الذي يؤكد.
        var split = TeamSplit(approved, req.Team1PlayerIds);

        await SaveRatingsAsync(match, userId, req.Ratings);

        // لاعب من الطرف الآخر أدخل النتيجة والتوزيع نفسيهما ⇐ تأكيد.
        var sameSplit = approved.All(p => p.Team == split[p.UserId]);
        var proposerSide = SideOf(match, match.ProposedById);
        if (sameSplit && match.IsSameAsProposal(s1, s2) && proposerSide != split[userId])
            return await ConfirmAsync(match, userId);

        foreach (var p in approved) p.Team = split[p.UserId];
        match.Propose(userId, s1, s2);
        match.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        var side = split[userId];
        var name = await UserNameAsync(userId);
        foreach (var p in approved.Where(p => p.Team != side))
            await _notifications.PushAsync(p.UserId, "أكّد نتيجة المباراة",
                $"أدخل {name} النتيجة {s1} - {s2} — أكّدها أو ارفضها",
                "match_result_proposed", match.Id);

        return await GetByIdAsync(userId, match.Id);
    }

    /// <summary>لاعب من الفريق الآخر يؤكد النتيجة المقترحة (فتُعتمد) أو يرفضها.</summary>
    public async Task<MatchDto> RespondResultAsync(int userId, int matchId, RespondResultRequest req)
    {
        var match = await LoadForResultAsync(matchId);
        ScoreProposals.EnsureCanRespond(
            match, SideOf(match, userId), SideOf(match, match.ProposedById), req);

        await SaveRatingsAsync(match, userId, req.Ratings);
        if (req.Accept) return await ConfirmAsync(match, userId);

        var proposerId = match.ProposedById!.Value;
        match.Reject();
        match.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        var rejecter = await UserNameAsync(userId);
        await _notifications.PushAsync(proposerId, "رُفضت نتيجة المباراة",
            $"رفض {rejecter} النتيجة التي أدخلتها — أدخلوا النتيجة الصحيحة أو يحسمها المنظّم",
            "match_result_rejected", match.Id);
        if (match.CreatorId != userId && match.CreatorId != proposerId)
            await _notifications.PushAsync(match.CreatorId, "خلاف على نتيجة المباراة",
                $"رفض {rejecter} النتيجة المقترحة — يمكنك حسم النتيجة كمنظّم",
                "match_result_disputed", match.Id);
        return await GetByIdAsync(userId, match.Id);
    }

    /// <summary>
    /// المنظّم يحسم خلافاً (بعد رفض نتيجة مقترحة) بإدخال النتيجة نهائيةً بلا
    /// تأكيد، ويُبلَّغ اللاعبون.
    /// </summary>
    public async Task<MatchDto> ResolveResultAsync(int userId, int matchId, ResolveResultRequest req)
    {
        var match = await LoadForResultAsync(matchId);
        ScoreProposals.EnsureCanResolve(match, userId, match.CreatorId);

        var approved = match.MatchPlayers
            .Where(p => p.Status == MatchPlayerStatus.Approved)
            .ToList();
        var split = TeamSplit(approved, req.Team1PlayerIds);
        foreach (var p in approved) p.Team = split[p.UserId];

        match.Propose(userId, req.Team1Score, req.Team2Score);
        var dto = await ConfirmAsync(match, userId);

        foreach (var p in approved.Where(p => p.UserId != userId))
            await _notifications.PushAsync(p.UserId, "حسم المنظّم نتيجة المباراة",
                $"اعتمد المنظّم النتيجة النهائية {req.Team1Score} - {req.Team2Score}",
                "match_result_resolved", match.Id);
        return dto;
    }

    /// <summary>
    /// توزيع الفريقين: من أُرسل في الفريق الأول والباقون في الثاني، وإلا
    /// التوزيع المحفوظ. بدونه لا يُعرف «الفريق الآخر».
    /// </summary>
    private static Dictionary<int, int> TeamSplit(List<MatchPlayer> approved, List<int> team1PlayerIds)
    {
        var ids = approved.Select(p => p.UserId).ToHashSet();
        var team1Ids = team1PlayerIds.Where(ids.Contains).ToHashSet();
        if (team1Ids.Count > 0 && team1Ids.Count < approved.Count)
            return approved.ToDictionary(p => p.UserId, p => team1Ids.Contains(p.UserId) ? 1 : 2);
        if (approved.All(p => p.Team is 1 or 2)
            && approved.Any(p => p.Team == 1) && approved.Any(p => p.Team == 2))
            return approved.ToDictionary(p => p.UserId, p => p.Team!.Value);
        throw new AuthException(
            "Pick the players of each team", "حدّد لاعبي كل فريق", "RESULT_TEAMS_REQUIRED");
    }

    /// <summary>اعتماد النتيجة المقترحة: تُكتب نهائيةً وتُحتسب النقاط.</summary>
    private async Task<MatchDto> ConfirmAsync(Match match, int confirmerId)
    {
        var s1 = match.ProposedTeam1Score!.Value;
        var s2 = match.ProposedTeam2Score!.Value;
        var proposerId = match.ProposedById!.Value;
        var isCorrection = match.Status == MatchStatus.Completed;

        match.Team1Score = s1;
        match.Team2Score = s2;
        match.Status = MatchStatus.Completed;
        match.ClearProposal();
        match.IsDisputed = false;
        match.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        var approved = match.MatchPlayers
            .Where(p => p.Status == MatchPlayerStatus.Approved)
            .ToList();

        // نقاط إتمام المباراة لكل لاعب معتمد — مرة واحدة لكل مباراة حتى لو
        // صُحّحت النتيجة (الحماية داخل PointsService بمفتاح النوع+المرجع).
        foreach (var p in approved)
            await _points.EarnMatchCompletedAsync(p.UserId, match.Id);

        // نقاط المستوى: تصحيح النتيجة يلغي السابقة ثم يحتسب الجديدة.
        if (isCorrection)
            await _points.ReverseLevelPointsAsync(PointsTransactionType.LevelMatchResult, match.Id);
        var team1 = approved.Where(p => p.Team == 1).Select(p => p.UserId).ToList();
        var team2 = approved.Where(p => p.Team == 2).Select(p => p.UserId).ToList();
        await _points.ApplyLevelPointsAsync(
            team1, team2, s1, s2,
            PointsTransactionType.LevelMatchResult, match.Id, "نقاط مستوى — نتيجة مباراة");

        if (proposerId != confirmerId)
            await _notifications.PushAsync(proposerId, "اعتُمدت نتيجة المباراة",
                $"أكّد {await UserNameAsync(confirmerId)} النتيجة {s1} - {s2}",
                "match_result_confirmed", match.Id);

        return await GetByIdAsync(confirmerId, match.Id);
    }

    /// <summary>
    /// المباراة لإدخال نتيجتها أو تأكيدها أو حسمها — ولا شيء من ذلك قبل موعدها:
    /// نتيجة تُدخل وتُؤكَّد قبل اللعب كانت تمنح نقاط الإتمام والمستوى مقدّماً.
    /// </summary>
    private async Task<Match> LoadForResultAsync(int matchId)
    {
        var match = await _db.Matches
            .Include(m => m.MatchPlayers)
            .Include(m => m.Ratings)
            .FirstOrDefaultAsync(m => m.Id == matchId)
            ?? throw new AuthException("Match not found", "المباراة غير موجودة", "MATCH_NOT_FOUND");
        // الموعد محلي ساذج (توقيت السعودية)، فيُقارن بساعة التطبيق.
        if (match.ScheduledAt > AppClock.Now)
            throw new AuthException(
                "The match hasn't started yet",
                "لم يبدأ موعد المباراة بعد — تُدخل النتيجة بعد اللعب", "MATCH_NOT_STARTED");
        return match;
    }

    /// <summary>طرف اللاعب المعتمد في المباراة (1 أو 2)، أو null.</summary>
    private static int? SideOf(Match match, int? userId) => userId is int id
        ? match.MatchPlayers.FirstOrDefault(
            p => p.UserId == id && p.Status == MatchPlayerStatus.Approved)?.Team
        : null;

    private async Task<string> UserNameAsync(int userId) =>
        await _db.Users.Where(u => u.Id == userId)
            .Select(u => (u.FirstName + " " + u.LastName).Trim())
            .FirstOrDefaultAsync() ?? "لاعب";

    /// <summary>تقييمات اللاعب لزملائه مع إدخال النتيجة — مرة لكل (مقيِّم، مقيَّم)
    /// في المباراة، تُكتب في جدول التقييمات الموحّد وتُعدّل سمعة المقيَّم.</summary>
    private async Task SaveRatingsAsync(Match match, int userId, List<MatchRatingInput> ratings)
    {
        var playerIds = match.MatchPlayers
            .Where(p => p.Status == MatchPlayerStatus.Approved)
            .Select(p => p.UserId).ToHashSet();
        if (!playerIds.Contains(userId)) return;
        foreach (var input in ratings)
        {
            if (input.RatedUserId == userId || !playerIds.Contains(input.RatedUserId)) continue;
            if (input.Score is < 1 or > 5) continue;
            await ReviewStore.UpsertAsync(
                _db, userId, ReviewerRole.Player, ReviewTargetType.Player, input.RatedUserId,
                ReviewContextType.Match, match.Id, input.Score, null, null, overwrite: false);
        }
    }

    // ── helpers ────────────────────────────────────────────────────────────────

    /// <summary>
    /// المباراة مخصصة لرجال أو نساء — يُمنع الانضمام/الدعوة عند اختلاف نوع
    /// اللاعب المعروف (اللاعبون بدون نوع محدد لا يُحجبون).
    /// </summary>
    /// <summary>
    /// المباراة تحدد نطاق مستوى (<see cref="Match.MinLevel"/>..<see cref="Match.MaxLevel"/>)،
    /// فيُمنع من هو خارجه من الانضمام. لاعب بلا ملف/مستوى محدد لا يُمنع — نفس سلوك
    /// <c>AmericanoService.EnsureLevelAllowedAsync</c>.
    /// </summary>
    private async Task EnsureLevelAllowedAsync(Match match, int userId)
    {
        var level = await _db.Users
            .Where(u => u.Id == userId)
            .Select(u => u.PlayerProfile != null ? (int?)u.PlayerProfile.Level : null)
            .FirstOrDefaultAsync();

        if (level is int lvl && (lvl < match.MinLevel || lvl > match.MaxLevel))
            throw new AuthException(
                $"Your level ({lvl}) is outside this match's range "
                    + $"({match.MinLevel:0.##}-{match.MaxLevel:0.##})",
                $"مستواك ({lvl}) خارج نطاق هذه المباراة "
                    + $"({match.MinLevel:0.##} - {match.MaxLevel:0.##})",
                "LEVEL_NOT_ALLOWED");
    }

    private async Task EnsureGenderAllowedAsync(Match match, int userId)
    {
        var userGender = await _db.Users
            .Where(u => u.Id == userId)
            .Select(u => u.Gender)
            .FirstOrDefaultAsync();
        if (userGender != null && userGender != match.Gender)
            throw new AuthException(
                match.Gender == Gender.Female
                    ? "This match is for women only"
                    : "This match is for men only",
                match.Gender == Gender.Female
                    ? "هذه المباراة مخصصة للنساء فقط"
                    : "هذه المباراة مخصصة للرجال فقط",
                "GENDER_NOT_ALLOWED");
    }

    private static Gender? TryParseGender(string? value) =>
        value?.Trim().ToLowerInvariant() switch
        {
            "male" or "men" or "m" or "رجال" => Gender.Male,
            "female" or "women" or "f" or "نساء" => Gender.Female,
            _ => null,
        };

    private IQueryable<Match> LoadFull() => _db.Matches
        .Include(m => m.Court).ThenInclude(c => c!.Venue).ThenInclude(v => v.CityRef)
            .Include(m => m.Court).ThenInclude(c => c!.Venue).ThenInclude(v => v.DistrictRef)
        .Include(m => m.MatchPlayers).ThenInclude(p => p.User).ThenInclude(u => u.PlayerProfile);

    private static MatchDto ToDto(Match m, int currentUserId)
    {
        var approved =
            m.MatchPlayers.Where(p => p.Status == MatchPlayerStatus.Approved).ToList();
        return new()
        {
            Id = m.Id,
            CreatorId = m.CreatorId,
            MatchType = m.MatchType.ToString().ToLowerInvariant(),
            Status = m.Status.ToString(),
            IsVenueHosted = IsVenueHosted(m),
            Gender = m.Gender == Gender.Female ? "female" : "male",
            ScheduledAt = m.ScheduledAt,
            DurationMinutes = m.DurationMinutes,
            MaxPlayers = m.MaxPlayers,
            CurrentPlayers = approved.Count,
            MinLevel = m.MinLevel,
            MaxLevel = m.MaxLevel,
            PricePerPlayer = m.PricePerPlayer,
            PaymentMode = m.PaymentMode == MatchPaymentMode.FullByCreator ? "full" : "share",
            CreatorPaidFull = m.PaymentMode == MatchPaymentMode.FullByCreator,
            Team1Score = m.Team1Score,
            Team2Score = m.Team2Score,
            PendingResult = ScoreProposals.ToDto(
                m, SideOf(m, m.ProposedById), PlayerName(m, m.ProposedById)),
            IsResultDisputed = m.IsDisputed,
            CanResolveResult = m.IsDisputed && currentUserId == m.CreatorId,
            CanConfirmResult = m.HasProposal()
                && SideOf(m, currentUserId) is int mySide
                && mySide != SideOf(m, m.ProposedById),
            Notes = m.Notes,
            IsPrivate = m.IsPrivate,
            CanMakePublic = m.IsPrivate && currentUserId == m.CreatorId
                && m.Status is MatchStatus.Open or MatchStatus.Full or MatchStatus.PendingApproval,
            CourtId = m.CourtId,
            VenueName = m.Court?.Venue.Name,
            VenueNameEn = m.Court?.Venue.NameEn,
            City = m.Court?.Venue.City,
            CityEn = m.Court?.Venue.CityRef?.NameEn,
            District = m.Court?.Venue.District,
            DistrictEn = m.Court?.Venue.DistrictRef?.NameEn,
            Neighborhood = m.Court?.Venue.Address,
            HasJoined = approved.Any(p => p.UserId == currentUserId),
            WithdrawalFreeUntil = WithdrawalPolicy.FreeUntil(m.ScheduledAt, isEvent: false),
            CanWithdrawDirectly = WithdrawalPolicy.IsFree(m.ScheduledAt, isEvent: false),
            WithdrawalRequested = approved.Any(
                p => p.UserId == currentUserId && p.WithdrawalRequestedAt != null),
            WithdrawalRequestCount = currentUserId == m.CreatorId
                ? approved.Count(p => p.WithdrawalRequestedAt != null)
                : 0,
            HasPendingRequest = m.MatchPlayers.Any(
                p => p.UserId == currentUserId && p.Status == MatchPlayerStatus.Pending),
            HasInvite = m.MatchPlayers.Any(
                p => p.UserId == currentUserId && p.Status == MatchPlayerStatus.Invited),
            PendingCount = currentUserId == m.CreatorId
                ? m.MatchPlayers.Count(p => p.Status == MatchPlayerStatus.Pending)
                : 0,
            // Members list shows approved players only.
            Players = approved.Select(ToPlayerDto).ToList(),
            // المدعوون الذين لم يردّوا: للمنشئ ولأعضاء المباراة فقط.
            InvitedPlayers = currentUserId == m.CreatorId || approved.Any(p => p.UserId == currentUserId)
                ? m.MatchPlayers.Where(p => p.Status == MatchPlayerStatus.Invited)
                    .OrderBy(p => p.JoinedAt).Select(ToPlayerDto).ToList()
                : [],
        };
    }

    private static string PlayerName(Match m, int? userId) =>
        m.MatchPlayers.FirstOrDefault(p => p.UserId == userId)?.User is { } u
            ? $"{u.FirstName} {u.LastName}".Trim()
            : string.Empty;

    private static MatchPlayerDto ToPlayerDto(MatchPlayer p) => new()
    {
        UserId = p.UserId,
        Name = $"{p.User.FirstName} {p.User.LastName}".Trim(),
        AvatarUrl = p.User.ProfileImageUrl,
        Level = p.User.PlayerProfile != null ? (int)p.User.PlayerProfile.Level : null,
        HasPaid = p.HasPaid,
        PaidAmount = p.HasPaid ? p.PaidAmount : null,
        Team = p.Team,
        WithdrawalRequested = p.WithdrawalRequestedAt != null,
        Status = p.Status switch
        {
            MatchPlayerStatus.Pending => "pending",
            MatchPlayerStatus.Invited => "invited",
            _ => "approved",
        },
    };

    public async Task<List<MatchPlayerDto>> GetJoinRequestsAsync(int userId, int matchId)
    {
        var match = await LoadFull().FirstOrDefaultAsync(m => m.Id == matchId)
            ?? throw new AuthException("Match not found", "المباراة غير موجودة", "MATCH_NOT_FOUND");
        if (match.CreatorId != userId)
            throw new AuthException("Not your match", "هذه المباراة ليست لك", "NOT_OWNER");

        return match.MatchPlayers
            .Where(p => p.Status == MatchPlayerStatus.Pending)
            .OrderBy(p => p.JoinedAt)
            .Select(ToPlayerDto)
            .ToList();
    }

    public async Task<MatchDto> RespondToJoinRequestAsync(
        int userId, int matchId, int targetUserId, bool approve)
    {
        // القبول يشغل مقعداً والرفض يردّ حصة: يُسلسَلان مع بقية الانضمامات،
        // فلا يتجاوز قبولان متزامنان السعة ولا يردّ رفضان الحصة مرتين.
        await using var gate = await MatchLock.AcquireAsync(_db, matchId);
        var match = await _db.Matches
            .Include(m => m.MatchPlayers)
            .Include(m => m.Court).ThenInclude(c => c!.Venue).ThenInclude(v => v.CityRef)
            .Include(m => m.Court).ThenInclude(c => c!.Venue).ThenInclude(v => v.DistrictRef)
            .FirstOrDefaultAsync(m => m.Id == matchId)
            ?? throw new AuthException("Match not found", "المباراة غير موجودة", "MATCH_NOT_FOUND");
        if (match.CreatorId != userId)
            throw new AuthException("Not your match", "هذه المباراة ليست لك", "NOT_OWNER");

        var request = match.MatchPlayers.FirstOrDefault(
            p => p.UserId == targetUserId && p.Status == MatchPlayerStatus.Pending)
            ?? throw new AuthException(
                "Request not found", "الطلب غير موجود", "REQUEST_NOT_FOUND");

        // لا عضو جديد في حدث ملغى أو منتهٍ (الرفض مسموح لتنظيف الطلبات المعلّقة).
        if (approve && match.Status is MatchStatus.Cancelled or MatchStatus.Completed)
            throw new AuthException(
                "Match is not joinable", "لا يمكن الانضمام لهذه المباراة", "MATCH_CLOSED");

        // Any player whose share was held (any payment mode) has a
        // refundable/creditable amount.
        var sharePaid = request.HasPaid && match.PricePerPlayer > 0;

        if (approve)
        {
            await ApproveRequestAsync(match, request);
            await gate.ReleaseAsync();
            await _notifications.PushAsync(targetUserId, "تم قبول طلبك",
                "تم قبول طلب انضمامك للمباراة", "match_join_approved", match.Id);
        }
        else
        {
            // Refund the share held when the request was created.
            if (sharePaid)
                await _wallet.RefundAsync(targetUserId, match.ShareOf(request),
                    "استرداد حصة مباراة مرفوضة", match.Id);
            _db.Set<MatchPlayer>().Remove(request);
            await _db.SaveChangesAsync();
            await gate.ReleaseAsync();
            await _notifications.PushAsync(targetUserId, "تم رفض طلبك",
                "تم رفض طلب انضمامك للمباراة", "match_join_rejected", match.Id);
            // مقعد كان ينتظره هذا الطلب: يُعرض على التالي في قائمة الانتظار.
            await _waitlist.ProcessAsync(match.Id);
        }

        return await GetByIdAsync(userId, match.Id);
    }

    /// <summary>
    /// قبول طلب انضمام: يصير اللاعب عضواً، وتُصرف حصته المحجوزة — لمالك
    /// الملعب (صافية من نسبة سبورتا) أو للمنشئ حين دفع المباراة كاملة.
    /// </summary>
    private async Task ApproveRequestAsync(Match match, MatchPlayer request)
    {
        if (match.MatchPlayers.Count(p => p.Status == MatchPlayerStatus.Approved)
            >= match.MaxPlayers)
            throw new AuthException(
                "Match is full", "المباراة مكتملة العدد", "MATCH_FULL");

        // قبل موافقة الملعب تبقى الحالة «بانتظار الموافقة» والحصة محجوزة
        // عندنا؛ موافقة الملعب تصرفها وتضبط «مكتملة» (VenueService).
        var awaitingVenue = match.Status == MatchStatus.PendingApproval;
        request.Status = MatchPlayerStatus.Approved;
        if (!awaitingVenue &&
            match.MatchPlayers.Count(p => p.Status == MatchPlayerStatus.Approved)
            >= match.MaxPlayers)
            match.Status = MatchStatus.Full;
        await _db.SaveChangesAsync();

        if (!awaitingVenue && request.HasPaid && match.PricePerPlayer > 0 && match.Court != null)
        {
            if (match.PaymentMode == MatchPaymentMode.FullByCreator)
                await _wallet.CreditEarningAsync(
                    match.CreatorId, match.ShareOf(request),
                    WalletTransactionType.CreatorEarning, "حصة مباراة", match.Id);
            else
                await _wallet.CreditEarningAsync(
                    match.Court.Venue.OwnerId,
                    match.NetOfCommission(match.ShareOf(request)),
                    WalletTransactionType.VenueEarning, "حصة مباراة", match.Id);
        }

        // من انضم بدعوة صديق: تُعلَّم دعوته مقبولة ويُبلَّغ من دعاه.
        await _invites.MarkJoinedAsync(request.UserId, EventInviteKind.Match, match.Id);
        await _chat.PostMemberEventAsync(match.Id, request.UserId, joined: true);
    }

    // ── إلغاء وحذف ───────────────────────────────────────────────────────────

    public async Task DeleteAsync(int matchId, string reasonAr)
    {
        var match = await _db.Matches
            .Include(m => m.MatchPlayers)
            .Include(m => m.AmericanoMatch)
            .FirstOrDefaultAsync(m => m.Id == matchId)
            ?? throw new AuthException(
                "Match not found", "المباراة غير موجودة", "MATCH_NOT_FOUND");

        // الأمريكانو له شاشته وحساباته الخاصة — لا يُحذف من قائمة المباريات.
        if (match.AmericanoMatch != null)
            throw new AuthException(
                "Americano events are managed from their own screen",
                "مباريات الأمريكانو تُدار من شاشتها", "AMERICANO_MATCH");

        await RefundHeldSharesAsync(match, "استرداد حصة مباراة محذوفة");

        var recipients = Recipients(match);

        // MatchPlayers والتقييمات تسقط بالتتابع (Cascade)، وحركات المحفظة تبقى
        // سجلاً مالياً — مرجعها رقم لا مفتاح أجنبي.
        _db.Matches.Remove(match);
        await _db.SaveChangesAsync();

        // بلا مرجع: المباراة لم تعد موجودة فلا شاشة يفتحها الإشعار.
        foreach (var userId in recipients)
            await _notifications.PushAsync(
                userId, "أُلغيت المباراة", reasonAr, "match_deleted", null);
    }

    /// <summary>
    /// إلغاء حدث يستضيفه صاحب الملعب. حصص المسجّلين وصلته فعلاً، فالإلغاء
    /// يردّها إليهم كاملةً ويخصم منه ما استلمه — ولا يُسمح به إن كان رصيده
    /// أقل من ذلك: لاعبٌ دفع ولم يلعب ولم يُردّ إليه ماله أسوأ من إلغاء مرفوض.
    /// نسبة سبورتا تُردّ للاعب أيضاً وتتحمّلها المنصة؛ الإلغاء قرار المضيف.
    /// </summary>
    public async Task<MatchDto> CancelHostedAsync(int userId, int matchId)
    {
        // لا انضمام أو قبول يتسلل بين ردّ الحصص وتعليم الحدث ملغى.
        await using var gate = await MatchLock.AcquireAsync(_db, matchId);
        var match = await LoadFull()
            .Include(m => m.AmericanoMatch)
            .FirstOrDefaultAsync(m => m.Id == matchId)
            ?? throw new AuthException(
                "Match not found", "المباراة غير موجودة", "MATCH_NOT_FOUND");

        if (!IsVenueHosted(match) || match.CreatorId != userId)
            throw new AuthException(
                "Not your hosted event",
                "هذا الحدث ليس من استضافتك", "NOT_HOST");

        if (match.Status is MatchStatus.Cancelled or MatchStatus.Completed
            or MatchStatus.InProgress)
            throw new AuthException(
                "Event can no longer be cancelled",
                "لا يمكن إلغاء هذا الحدث الآن", "MATCH_NOT_CANCELLABLE");

        var paid = match.MatchPlayers
            .Where(p => p.HasPaid && p.Status == MatchPlayerStatus.Approved)
            .ToList();
        // كل لاعب بما دفعه فعلاً (قد يختلف بخصم العضوية).
        var owed = paid.Sum(p => match.NetOfCommission(match.ShareOf(p)));

        if (owed > 0)
        {
            var wallet = await _db.Wallets.FirstOrDefaultAsync(w => w.UserId == userId);
            if (wallet == null || wallet.Balance < owed)
                throw new AuthException(
                    "Insufficient balance to refund players",
                    $"رصيدك لا يكفي لردّ حصص المسجّلين ({owed:0.##} ر.س)",
                    "INSUFFICIENT_BALANCE");
        }

        var label = match.AmericanoMatch != null ? "أمريكانو" : "مباراة";
        foreach (var player in paid)
        {
            // عكس أرباح لا خصم مشروط: الرصيد فُحص أعلاه، وإن تغيّر بين الفحص
            // والخصم يبقى الفرق ديناً على المالك لا على سبورتا.
            await _wallet.ReverseEarningAsync(
                userId, match.NetOfCommission(match.ShareOf(player)),
                WalletTransactionType.VenueEarning,
                $"ردّ حصة {label} ملغاة", match.Id);
            await _wallet.RefundAsync(
                player.UserId, match.ShareOf(player),
                $"استرداد حصة {label} ألغاها الملعب", match.Id);
        }

        // طلبات لم يُبتّ فيها: حصصها محجوزة عندنا لا عند المالك، فتُردّ مباشرة.
        foreach (var pending in match.MatchPlayers.Where(
                     p => p.HasPaid && p.Status == MatchPlayerStatus.Pending))
        {
            if (match.PricePerPlayer > 0)
                await _wallet.RefundAsync(pending.UserId, match.ShareOf(pending),
                    $"استرداد حصة {label} ألغاها الملعب", match.Id);
            paid.Add(pending);
        }

        // رُدّت كل الحصص: لا يبقى سطر «مدفوع» يُردّ مرة ثانية برفضٍ أو انسحاب.
        foreach (var player in paid)
            player.HasPaid = false;

        match.Status = MatchStatus.Cancelled;
        match.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        await gate.ReleaseAsync();
        await _chat.PostSystemAsync(match.Id, $"ألغى الملعب {(match.AmericanoMatch != null ? "الأمريكانو" : "المباراة")} — الدردشة للقراءة فقط");

        var (cancelType, cancelRef) = EventNotificationTarget.For(match, "cancelled");
        foreach (var player in match.MatchPlayers.Select(p => p.UserId).Distinct())
            await _notifications.PushAsync(player,
                $"أُلغي {label} على الملعب",
                paid.Any(p => p.UserId == player)
                    ? "ألغى الملعب الحدث، وأُعيدت حصتك إلى محفظتك."
                    : "ألغى الملعب الحدث.",
                cancelType, cancelRef);

        return await GetByIdAsync(userId, match.Id);
    }

    /// <summary>
    /// يلغي كل مباراة/أمريكانو لم يكتمل عدده ويقترب موعده بأقل من
    /// <paramref name="lead"/>، ويعيد لكل من دفع كامل ما دفعه.
    ///
    /// الانتظار حتى يفوت الموعد يترك الملعب محجوزاً لحدثٍ لن يقوم، ويترك
    /// اللاعبين يرتّبون يومهم على مباراة ناقصة. الإلغاء المسبق يحرّر الاثنين:
    /// الملعب يعود للحجز، واللاعب يعرف مبكراً وماله في محفظته.
    ///
    /// <paramref name="lead"/> صفر = السلوك القديم: تنظيف ما فات موعده فقط.
    /// </summary>
    public async Task<int> CancelIncompleteBeforeStartAsync(
        TimeSpan lead, CancellationToken ct = default)
    {
        // ScheduledAt وقت محلي ساذج، فيقارَن بساعة التطبيق لا بساعة الخادم.
        var cutoff = AppClock.Now.Add(lead);

        var candidates = await _db.Matches
            .Include(m => m.MatchPlayers)
            .Include(m => m.Court).ThenInclude(c => c!.Venue)
            .Include(m => m.AmericanoMatch)
            // المكتملة والجارية والمنتهية لا تُمسّ — هذه أحداث قامت فعلاً.
            .Where(m => m.Status == MatchStatus.Open ||
                        m.Status == MatchStatus.PendingApproval)
            .Where(m => m.ScheduledAt <= cutoff)
            .ToListAsync(ct);

        // الاكتمال يُقاس بالمقاعد المعتمدة: حدثٌ اكتمل عدده لا يُلغى مهما اقترب.
        var incomplete = candidates
            .Where(m => m.MatchPlayers.Count(p => p.Status == MatchPlayerStatus.Approved)
                        < m.MaxPlayers)
            .ToList();

        // البطولة الإقصائية لا تُلغى تلقائياً: منظّمها يقرر — يبدأ بالفرق
        // المكتملة، أو يؤجّل، أو يلغي — فيُبلَّغ مرة واحدة ويُترك له القرار.
        foreach (var t in incomplete.Where(m => m.AmericanoMatch?.Format != null).ToList())
        {
            incomplete.Remove(t);
            var a = t.AmericanoMatch!;
            if (a.IncompleteNoticeSentAt != null) continue;
            a.IncompleteNoticeSentAt = DateTime.UtcNow;
            await _db.SaveChangesAsync(ct);
            await _notifications.PushAsync(
                t.CreatorId,
                "لم يكتمل عدد فرق البطولة",
                $"اقترب موعد «{a.Name}» ولم يكتمل عدد الفرق — ابدأ بالفرق المكتملة، أو أجّل، أو ألغِ",
                "tournament_incomplete",
                a.Id);
        }
        if (incomplete.Count == 0) return 0;

        var cancelledCount = 0;
        foreach (var match in incomplete)
        {
            // قفل الحدث: انضمام تزامن مع الإلغاء إمّا يسبقه (فتُردّ حصته هنا بعد
            // إعادة تحميل اللاعبين) أو يليه (فيرى الحدث ملغى ويُرفض).
            await using var gate = await MatchLock.AcquireAsync(_db, match.Id);
            await _db.Entry(match).ReloadAsync(ct);
            var players = _db.Entry(match).Collection(m => m.MatchPlayers);
            players.IsLoaded = false;
            await players.LoadAsync(ct);
            if (match.Status is not (MatchStatus.Open or MatchStatus.PendingApproval)
                || match.MatchPlayers.Count(p => p.Status == MatchPlayerStatus.Approved)
                   >= match.MaxPlayers)
                continue;

            var isAmericano = match.AmericanoMatch != null;
            // «المباراة» مؤنثة و«الأمريكانو» مذكّر، فالجملة كاملة لا كلمة تُحشر.
            var cancelled = isAmericano ? "أُلغي الأمريكانو" : "أُلغيت المباراة";
            await RefundAllPaidAsync(
                match, $"استرداد حصة {(isAmericano ? "أمريكانو" : "مباراة")} لم تكتمل");

            var recipients = Recipients(match);

            match.Status = MatchStatus.Cancelled;
            match.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync(ct);
            cancelledCount++;
            await gate.ReleaseAsync();
            await _chat.PostSystemAsync(match.Id, $"{cancelled} لعدم اكتمال العدد — الدردشة للقراءة فقط");

            // صاحب الملعب لا يلعب في حدثٍ يستضيفه ولم يدفع حصة، فخبره مختلف:
            // موعده تحرّر وما وصله استُرجع. أما إن كان لاعباً فهو كبقية اللاعبين.
            var ownerId = match.Court?.Venue.OwnerId;
            var ownerIsPlayer = ownerId is int o &&
                match.MatchPlayers.Any(p => p.UserId == o);
            var notifyOwnerSeparately = ownerId is int && !ownerIsPlayer;

            var (expiredType, expiredRef) = EventNotificationTarget.For(match, "expired");
            foreach (var userId in recipients)
            {
                if (notifyOwnerSeparately && userId == ownerId) continue;
                await _notifications.PushAsync(
                    userId,
                    cancelled,
                    $"لم يكتمل عدد اللاعبين قبل الموعد، ف{cancelled} وأُعيد ما دفعته إلى محفظتك.",
                    expiredType,
                    expiredRef);
            }

            if (notifyOwnerSeparately)
                await _notifications.PushAsync(
                    ownerId!.Value,
                    $"{cancelled} على ملعبك",
                    "لم يكتمل عدد اللاعبين قبل الموعد، فتحرّر الموعد وأُعيدت الحصص إلى اللاعبين.",
                    expiredType,
                    expiredRef);
        }

        return cancelledCount;
    }

    /// <summary>
    /// يعيد لكل مشارك دفع كامل ما خرج من محفظته، ويسترد من صاحب الملعب ما
    /// وصله. الحصة تصل المالك لحظة الاعتماد، فلا يكفي ردّ «المحجوز» وحده:
    /// لاعبٌ اعتُمد ودفع يجب أن يُردّ إليه ماله وإن كان قد صُرف.
    /// نسبة سبورتا تُردّ للاعب كذلك وتتحمّلها المنصة — الإلغاء ليس خطأه.
    /// </summary>
    public async Task RefundAllPaidAsync(Match match, string reason)
    {
        if (match.PricePerPlayer <= 0) return;

        // قبل موافقة صاحب الملعب لم يصله شيء، فالمبالغ ما زالت محجوزة عندنا.
        var ownerWasCredited =
            match.CourtId != null && match.Status != MatchStatus.PendingApproval;
        var ownerId = match.Court?.Venue.OwnerId;
        var fullByCreator = match.PaymentMode == MatchPaymentMode.FullByCreator;

        // كم استُرجع للمنشئ من حصص المنضمّين (نمط «يدفع المنشئ الكل» القديم).
        // قبل الموافقة تبقى حصص الشركاء محجوزة ولا يُعوَّض منها المنشئ.
        var joinersPaidBack = fullByCreator && ownerWasCredited
            ? match.MatchPlayers.Where(p => p.UserId != match.CreatorId
                                            && p.HasPaid
                                            && p.Status == MatchPlayerStatus.Approved)
                .Sum(match.ShareOf)
            : 0m;

        var paidPlayers = match.MatchPlayers.Where(p => p.HasPaid).ToList();
        foreach (var player in paidPlayers)
        {
            // كلٌّ بما دفعه فعلاً (قد يختلف بخصم العضوية).
            var paid = player.UserId == match.CreatorId
                ? match.CreatorHeld() - joinersPaidBack
                : match.ShareOf(player);
            if (paid <= 0) continue;

            await _wallet.RefundAsync(player.UserId, paid, reason, match.Id);

            // ما وصل صاحب الملعب من هذه الحصة يُستردّ منه.
            if (ownerWasCredited && ownerId is int owner)
            {
                var credited = player.Status == MatchPlayerStatus.Approved
                    ? match.NetOfCommission(
                        fullByCreator && player.UserId == match.CreatorId
                            ? match.CreatorCharge()
                            : match.ShareOf(player))
                    : 0m;
                // عكس أرباح لا خصم مشروط بالرصيد: ما وصل المالك يُستردّ دائماً
                // ولو صار رصيده سالباً، وإلا دفعت سبورتا الفرق من حصتها.
                if (credited > 0)
                    await _wallet.ReverseEarningAsync(
                        owner, credited, WalletTransactionType.VenueEarning,
                        reason, match.Id);
            }
        }

        // المال رُدّ: لا يبقى أي سطر «مدفوعاً»، وإلا ردّ رفضُ طلبٍ معلّق أو
        // انسحابُ صاحبه حصتَه مرة ثانية، أو صرفها قبولُه لمالك الملعب بعد الإلغاء.
        // المستدعون يحفظون السياق بعد تغيير الحالة.
        foreach (var player in paidPlayers)
            player.HasPaid = false;
    }

    /// <summary>منشئ المباراة ولاعبوها جميعاً — بلا تكرار.</summary>
    private static List<int> Recipients(Match match) => match.MatchPlayers
        .Select(p => p.UserId)
        .Append(match.CreatorId)
        .Distinct()
        .ToList();

    /// <summary>
    /// يعيد الحصص المدفوعة التي لم تُصرف لأحد بعد. حصة اللاعب تُصرف لمالك
    /// الملعب (أو لمنشئ المباراة حين يدفعها كاملة) لحظة قبوله، فالمقبول في
    /// مباراة على ملعب لا يُعاد له شيء؛ أما المعلّق فحصته محجوزة عندنا، وكذلك
    /// حصص المباريات بلا ملعب — لا جهة صُرفت لها أصلاً.
    /// </summary>
    private async Task RefundHeldSharesAsync(Match match, string reason)
    {
        if (match.PricePerPlayer > 0)
        {
            foreach (var player in match.MatchPlayers)
            {
                if (!player.HasPaid) continue;
                // ما دفعه المنشئ مقدّماً حالةٌ منفصلة تُعالَج أدناه.
                if (player.UserId == match.CreatorId) continue;

                // قبل موافقة الملعب لا يُصرف شيء: الحصة محجوزة عندنا فتُعاد.
                var alreadyCredited = player.Status == MatchPlayerStatus.Approved &&
                                      match.CourtId != null &&
                                      match.Status != MatchStatus.PendingApproval;
                if (alreadyCredited) continue;

                await _wallet.RefundAsync(
                    player.UserId, match.ShareOf(player), reason, match.Id);
            }
        }

        // ما دفعه المنشئ عند الإنشاء يُصرف لمالك الملعب لحظة موافقته على
        // الاستضافة، فلا يُعاد إلا إن كانت المباراة ما زالت تنتظر تلك الموافقة.
        if (match.CourtId != null && match.Status == MatchStatus.PendingApproval)
        {
            var held = match.CreatorHeld();
            if (held > 0)
                await _wallet.RefundAsync(match.CreatorId, held, reason, match.Id);
        }
    }

    private static MatchType ParseMatchType(string value) =>
        Enum.TryParse<MatchType>(value, ignoreCase: true, out var t) ? t : MatchType.Social;
}
