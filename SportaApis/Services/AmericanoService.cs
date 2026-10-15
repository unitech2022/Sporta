using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;
using MatchType = SportaApis.Enums.MatchType;

namespace SportaApis.Services;

public class AmericanoService : IAmericanoService
{
    private readonly AppDbContext _db;
    private readonly IWalletService _wallet;
    private readonly INotificationService _notifications;
    private readonly IPointsService _points;
    private readonly ITournamentService _tournaments;
    private readonly IWaitlistService _waitlist;
    private readonly IEventChatService _chat;
    private readonly IEventInviteService _invites;

    // Singles americano/tournament: the creator picks how many players take part
    // (partner rotation). Four is the floor — one full game — with no upper bound,
    // so a tournament can run with 20 or 50 players.
    private const int MinSinglesPlayers = 4;

    // A big roster would otherwise schedule N-1 rounds (49 rounds for 50 players),
    // far more than an event can actually play, so the schedule stops here.
    private const int MaxSinglesRounds = 10;

    // A teams americano is two players per team × the team count the creator
    // picks. Two teams are the floor — one game — with no upper bound, so a
    // tournament can host 10 or 30 teams.
    private const int PlayersPerTeam = 2;
    public const int MinTeams = 2;

    private readonly IMembershipService _memberships;

    public AmericanoService(
        AppDbContext db, IWalletService wallet, INotificationService notifications,
        IPointsService points, ITournamentService tournaments, IEventInviteService invites,
        IWaitlistService waitlist, IEventChatService chat, IMembershipService memberships)
    {
        _memberships = memberships;
        _chat = chat;
        _waitlist = waitlist;
        _invites = invites;
        _db = db;
        _wallet = wallet;
        _notifications = notifications;
        _points = points;
        _tournaments = tournaments;
    }

    // ── Create ──────────────────────────────────────────────────────────────────

    public async Task<AmericanoDto> CreateAsync(int creatorId, CreateAmericanoRequest req)
    {
        var isTeams = req.Type.ToLowerInvariant() == "teams";
        var type = isTeams ? MatchType.AmericanTeam : MatchType.American;

        // موعد مضى لا تُنشأ عليه مباراة — قائمة المواعيد تخفي ما فات، وهذا
        // يمنع نداءً مباشراً من تجاوزها.
        if (req.ScheduledAt <= AppClock.Now)
            throw new AuthException(
                "Selected time has already passed",
                "الوقت المختار مضى — اختر موعداً قادماً", "SLOT_IN_PAST");

        // Tournaments may span several days; the end date can never precede day one.
        DateTime? endDate = null;
        if (req.IsTournament && req.EndDate is DateTime end)
        {
            if (end.Date < req.ScheduledAt.Date)
                throw new AuthException(
                    "Tournament end date cannot be before its start date",
                    "تاريخ نهاية البطولة لا يمكن أن يسبق تاريخ بدايتها",
                    "TOURNAMENT_BAD_END_DATE");

            // الفحص والتسعير وقائمة المواعيد تتوقف كلها عند هذا السقف، فبطولة
            // أطول منه كانت تُسعَّر وتُفحص جزئياً ثم تتعثر في يوم بعيد.
            if ((end.Date - req.ScheduledAt.Date).TotalDays
                > CourtSchedule.MaxMultiDayRangeDays)
                throw new AuthException(
                    $"A tournament cannot span more than {CourtSchedule.MaxMultiDayRangeDays} days",
                    $"مدة البطولة لا تتجاوز {CourtSchedule.MaxMultiDayRangeDays} يوماً",
                    "TOURNAMENT_TOO_LONG");

            if (end.Date > req.ScheduledAt.Date) endDate = end.Date;
        }

        // Teams americano: the creator picks how many fixed teams take part
        // (2 by default); singles picks a player count instead.
        var teamCount = isTeams ? req.TeamCount : 0;
        if (isTeams && teamCount < MinTeams)
            throw new AuthException(
                $"Teams americano needs at least {MinTeams} teams",
                $"عدد الفرق لا يقل عن {MinTeams}", "AMERICANO_TEAM_COUNT");

        // Singles capacity is the creator's own number (creator included).
        if (!isTeams && req.PlayerCount < MinSinglesPlayers)
            throw new AuthException(
                $"Singles americano needs at least {MinSinglesPlayers} players",
                $"عدد اللاعبين يجب ألا يقل عن {MinSinglesPlayers}", "AMERICANO_PLAYER_COUNT");

        var capacity = isTeams ? teamCount * PlayersPerTeam : req.PlayerCount;

        // قفل الملعب نفسه الذي يأخذه الحجز العادي: فحص المواعيد ثم الإنشاء لا
        // يتقاطعان مع حجز أو مباراة متزامنة على الملعب ذاته.
        await using var courtGate = req.CourtId is int lockedCourtId
            ? await DbLocks.AcquireAsync(_db, $"court:{lockedCourtId}")
            : null;

        var court = await LoadCourtOrNullAsync(req.CourtId);

        // استضافة من حساب الملعب (بطلب صريح): ملعبه، فهو المنظّم لا لاعب —
        // كل المقاعد (أو الفرق) مفتوحة، ولا يدفع ولا ينتظر موافقة نفسه.
        // من حساب اللاعب يُعامل صاحب الملعب كأي لاعب حتى على ملعبه.
        var hostedByOwner = req.HostedByVenue;
        if (hostedByOwner && (court == null || court.Venue.OwnerId != creatorId))
            throw new AuthException(
                "Hosting is only allowed on your own courts",
                "الاستضافة متاحة على ملاعبك فقط", "NOT_OWNER");

        // ملعب أخفاه البحث (نادٍ غير نشط أو اشتراكه منتهٍ) لا يُحجز بالمعرّف مباشرة.
        if (court != null && !hostedByOwner &&
            !await VenueBookability.IsBookableAsync(_db, court.Id))
            throw new AuthException(
                "Court is not available", "الملعب غير متاح للحجز", "COURT_UNAVAILABLE");

        var match = new Match
        {
            CreatorId = creatorId,
            CourtId = req.CourtId,
            MatchType = type,
            ScheduledAt = req.ScheduledAt,
            DurationMinutes = req.DurationMinutes,
            MaxPlayers = capacity,
            MinLevel = req.MinLevel,
            MaxLevel = req.MaxLevel,
        };

        int? invitedPartnerId = null;

        if (hostedByOwner)
        {
            // لا لاعبين عند الإنشاء: المقاعد كلها معروضة، ويملؤها المنضمّون.
        }
        else if (isTeams)
        {
            // Fixed-teams americano: the creator captains one team; the rest of the
            // roster fills in as opponents join and partners accept invites.
            var creatorTeam =
                req.CreatorTeam >= 1 && req.CreatorTeam <= teamCount ? req.CreatorTeam : 1;
            match.MatchPlayers.Add(new MatchPlayer
            {
                UserId = creatorId,
                Status = MatchPlayerStatus.Approved,
                Team = creatorTeam,
                HasPaid = court != null,
            });

            if (req.PartnerId is int pid && pid != creatorId)
            {
                await ValidatePartnerAsync(creatorId, pid);
                match.MatchPlayers.Add(new MatchPlayer
                {
                    UserId = pid,
                    Status = MatchPlayerStatus.Invited,
                    Team = creatorTeam,
                    InvitedById = creatorId,
                });
                invitedPartnerId = pid;
            }
        }
        else
        {
            // Singles americano: creator + the (de-duped) roster, all approved.
            var playerIds = new List<int> { creatorId };
            foreach (var id in req.PlayerIds)
                if (!playerIds.Contains(id)) playerIds.Add(id);

            if (playerIds.Count < 1 || playerIds.Count > capacity)
                throw new AuthException(
                    $"Americano allows between 1 and {capacity} players",
                    $"العدد المختار يسمح بين لاعب و{capacity} لاعبين", "AMERICANO_PLAYER_RANGE");

            var existing = await _db.Users
                .Where(u => playerIds.Contains(u.Id)).Select(u => u.Id).ToListAsync();
            if (existing.Count != playerIds.Count)
                throw new AuthException(
                    "Some players were not found", "بعض اللاعبين غير موجودين", "PLAYERS_NOT_FOUND");

            foreach (var id in playerIds)
                match.MatchPlayers.Add(new MatchPlayer
                {
                    UserId = id,
                    Status = MatchPlayerStatus.Approved,
                    HasPaid = court != null && id == creatorId,
                });
        }

        if (court != null)
        {
            // البطولة تمتد أياماً وتشغل الملعب في نفس الوقت من كل يوم، فيُفحص
            // كل يوم منها لا يوم البداية وحده (الأمريكانو العادي يوم واحد).
            var firstDay = req.ScheduledAt.Date;
            var lastDay = endDate?.Date ?? firstDay;
            var timeOfDay = req.ScheduledAt.TimeOfDay;

            var occupied = await CourtOccupancy.ForCourtAsync(
                _db, court.Id, req.ScheduledAt,
                lastDay.Add(timeOfDay).AddMinutes(req.DurationMinutes));

            var blockedSlots = await _db.CourtBlockedSlots
                .Where(s => s.CourtId == court.Id
                            && s.Date >= firstDay && s.Date <= lastDay)
                .Select(s => new { s.Date, s.Hour })
                .ToListAsync();

            // البطولة تحجز الملعب في كل يوم من أيامها، فسعرها مجموع أسعار
            // تلك الأيام لا سعر يوم البداية وحده (والسعر قد يختلف بين يوم
            // وآخر حسب قواعد تسعير المالك).
            var total = 0m;

            for (var day = firstDay; day <= lastDay; day = day.AddDays(1))
            {
                var dayStart = day.Add(timeOfDay);
                var dayEnd = dayStart.AddMinutes(req.DurationMinutes);
                total += CourtSchedule.BookingPrice(court, dayStart, req.DurationMinutes);

                // الأمريكانو على ملعب يحجزه فعلياً، فيخضع لدوام يومه كأي حجز.
                if (!CourtSchedule.IsWithinOpeningHours(court, dayStart, req.DurationMinutes))
                    throw new AuthException(
                        "Selected time is outside opening hours",
                        "الوقت المختار خارج ساعات عمل الملعب", "OUTSIDE_OPENING_HOURS");

                // والموعد يجب أن يكون فارغاً فعلاً: حجز عادي أو مباراة أخرى أو
                // جلسة تدريب تشغل الملعب — نفس ما تعتمده قائمة المواعيد المتاحة.
                if (CourtOccupancy.Overlaps(occupied, dayStart, dayEnd))
                    throw new AuthException(
                        "This slot is already booked", "هذا الموعد محجوز بالفعل", "SLOT_TAKEN");

                // الساعات التي أغلقها صاحب الملعب غير متاحة كذلك.
                var coveredHours = CourtSchedule.CoveredHours(
                    dayStart, (int)(dayEnd - dayStart).TotalMinutes);
                if (blockedSlots.Any(s => s.Date == day && coveredHours.Contains(s.Hour)))
                    throw new AuthException(
                        "Slot is unavailable", "هذا الموعد غير متاح", "SLOT_UNAVAILABLE");
            }

            match.PricePerPlayer = Math.Round(total / capacity, 2);
            match.SportaCommissionPercent = court.SportaCommissionPercent;

            if (hostedByOwner)
            {
                // كل لاعب يدفع حصته لصاحب الملعب (صافيةً من نسبة سبورتا)،
                // والحدث يُفتح فوراً للتسجيل.
                match.PaymentMode = MatchPaymentMode.SharePerPlayer;
                match.Status = MatchStatus.Open;
            }
            else
            {
                // الدفع فرديّ كالمباراة: المنشئ يدفع حصته وحدها، وكل منضمّ يدفع
                // حصته، والجميع يذهب لصاحب الملعب. يبقى الحدث بانتظار موافقته.
                match.PaymentMode = MatchPaymentMode.SharePerPlayer;
                match.Status = MatchStatus.PendingApproval;

                // عضو النادي يدفع حصته بعد خصم عضويته (المدة × أيام الحدث).
                var days = ((endDate ?? req.ScheduledAt).Date - req.ScheduledAt.Date).Days + 1;
                var charge = (await _memberships.QuoteShareAsync(creatorId, court.VenueId,
                    match.PricePerPlayer, req.DurationMinutes * days, req.ScheduledAt)).Amount;
                var wallet = await _db.Wallets.FirstOrDefaultAsync(w => w.UserId == creatorId);
                if (charge > 0 && (wallet == null || wallet.Balance < charge))
                    throw new AuthException(
                        "Insufficient wallet balance",
                        "رصيد المحفظة غير كافٍ، يرجى شحن المحفظة والمحاولة مجدداً",
                        "INSUFFICIENT_BALANCE");
            }
        }
        else
        {
            // Court-less americano: free, opens immediately.
            match.PaymentMode = MatchPaymentMode.SharePerPlayer;
            var approved = match.MatchPlayers.Count(p => p.Status == MatchPlayerStatus.Approved);
            match.Status = approved >= capacity ? MatchStatus.Full : MatchStatus.Open;
        }

        _db.Matches.Add(match);
        await _db.SaveChangesAsync();

        var americano = new AmericanoMatch
        {
            MatchId = match.Id,
            AmericanoType = type,
            IsTournament = req.IsTournament,
            EndDate = endDate,
            MinAllowedLevel = req.MinLevel,
            MaxAllowedLevel = req.MaxLevel,
            // Fixed teams play a full round robin (one game per pair of teams);
            // singles rotate partners over the rounds their roster allows.
            TotalRounds = isTeams
                ? teamCount * (teamCount - 1) / 2
                : SinglesRoundCount(capacity),
        };
        _db.AmericanoMatches.Add(americano);
        await _db.SaveChangesAsync();

        if (court != null && !hostedByOwner)
        {
            var share = await _memberships.QuoteEventShareAsync(creatorId, match);
            // الفحص المسبق للرصيد لا يحجز شيئاً: خصمٌ فشل (رصيد نقص بطلب متزامن)
            // كان يترك المنشئ «مدفوعاً» بلا خصم. يُحذف الحدث ويُرفض الطلب.
            if (share.Amount > 0 && !await _wallet.TryChargeAsync(
                    creatorId, share.Amount, WalletTransactionType.MatchPayment,
                    "دفع أمريكانو", match.Id))
            {
                _db.AmericanoMatches.Remove(americano);
                _db.Matches.Remove(match);
                await _db.SaveChangesAsync();
                throw new AuthException(
                    "Insufficient wallet balance",
                    "رصيد المحفظة غير كافٍ، يرجى شحن المحفظة والمحاولة مجدداً",
                    "INSUFFICIENT_BALANCE");
            }
            if (match.MatchPlayers.FirstOrDefault(p => p.UserId == creatorId) is { } creator)
            {
                share.ApplyTo(creator);
                await _db.SaveChangesAsync();
            }

            await _notifications.PushAsync(court.Venue.OwnerId,
                "طلب مباراة جديد على ملعبك",
                $"طلب استضافة أمريكانو على {court.Name} بانتظار موافقتك",
                "match_request", match.Id);
        }

        if (invitedPartnerId is int partner)
            await NotifyPartnerInvitedAsync(partner, americano.Id);

        // نقاط مكافآت للمنظّم (تنظيم أمريكانو / تنظيم بطولة) — مرة لكل حدث.
        await _points.EarnActivityAsync(
            creatorId,
            req.IsTournament
                ? PointsTransactionType.TournamentOrganized
                : PointsTransactionType.AmericanoOrganized,
            match.Id, null);

        // A court-less singles americano that filled at creation gets its rounds now;
        // otherwise rounds are generated lazily once the roster completes.
        await EnsureRoundsAsync(americano.Id);

        return await GetByIdAsync(americano.Id);
    }

    // ── Join ────────────────────────────────────────────────────────────────────

    public async Task<AmericanoDto> JoinAsync(int userId, int americanoId, JoinAmericanoRequest? req)
    {
        // الانضمام يُسلسَل لكل حدث: نقرتان كانتا تخصمان الحصة مرتين (الثانية
        // يرفضها الفهرس الفريد بعد خصمها)، وطلبان متزامنان يتجاوزان المقاعد.
        // التحميل والفحوص كلها داخل القفل على بيانات طازجة.
        await using var gate = await LockAsync(americanoId);
        var americano = await LoadForMutationAsync(americanoId);
        var match = americano.Match;
        var isTeams = americano.AmericanoType == MatchType.AmericanTeam;

        EnsureJoinable(match);
        if (match.MatchPlayers.Any(p => p.UserId == userId))
            throw new AuthException(
                "You already joined this americano", "أنت مشارك بالفعل", "ALREADY_JOINED");
        await EnsureLevelAllowedAsync(userId, americano);

        if (isTeams)
        {
            // يختار المنضمّ فريقه (وفيه مقعد شاغر)، أو يضعه النظام تلقائياً:
            // وحده ← يُكمل فريقاً ناقصاً أولاً؛ مع شريك ← فريق فارغ كاملاً.
            var teamCount = TeamCountOf(match);
            var withPartner = req?.PartnerId is int wp && wp != userId;
            int team;
            if (req?.Team is int t && t >= 1 && t <= teamCount)
                team = t;
            else
                team = AutoTeam(match, teamCount, withPartner ? PlayersPerTeam : 1)
                    ?? throw (withPartner
                        ? new AuthException("No empty team for you and your partner",
                            "لا يوجد فريق فارغ لك ولشريكك — انضم وحدك لتُكمل فريقاً ناقصاً",
                            "NO_EMPTY_TEAM")
                        : new AuthException("No free seat", "لا يوجد مقعد شاغر", "AMERICANO_FULL"));
            if (match.MatchPlayers.Count(p => p.Team == team) >= PlayersPerTeam)
                throw new AuthException(
                    "This team is full", "هذا الفريق مكتمل", "TEAM_FULL");

            // دعوة الشريك تُفحص قبل الخصم والحفظ: رفضها بعدهما كان يترك
            // اللاعب منضمّاً ومخصوماً مع أن الطلب عاد بخطأ.
            if (req?.PartnerId is int partnerId && partnerId != userId)
                await EnsurePartnerInvitableAsync(match, userId, partnerId, team, joining: true);

            // الانضمام طلب ينتظر موافقة المنشئ، والحصة محجوزة حتى يقبل أو يرفض.
            var share = await HoldShareIfCourtAsync(match, userId);
            var joiner = new MatchPlayer
            {
                MatchId = match.Id,
                UserId = userId,
                Status = MatchPlayerStatus.Pending,
                Team = team,
                HasPaid = share != null,
            };
            share?.ApplyTo(joiner);
            match.MatchPlayers.Add(joiner);
            await _db.SaveChangesAsync();

            if (req?.PartnerId is int pid && pid != userId)
                await InvitePartnerInternalAsync(americano, match, userId, pid, team);
        }
        else
        {
            if (match.MatchPlayers.Count(p => p.Status == MatchPlayerStatus.Approved)
                >= match.MaxPlayers)
                throw new AuthException("Americano is full", "الأمريكانو مكتمل", "AMERICANO_FULL");

            // مقعد محجوز لمن جاء دوره في قائمة الانتظار — إلا لمن دعاه المنظّم.
            if (!await _invites.HasActiveInviteFromAsync(
                    match.CreatorId, userId, InviteKindOf(americano), americano.Id))
                await _waitlist.EnsureSeatAvailableAsync(match, userId);

            var share = await HoldShareIfCourtAsync(match, userId);
            var joiner = new MatchPlayer
            {
                MatchId = match.Id,
                UserId = userId,
                Status = MatchPlayerStatus.Pending,
                HasPaid = share != null,
            };
            share?.ApplyTo(joiner);
            match.MatchPlayers.Add(joiner);
            await _db.SaveChangesAsync();
        }

        // طلب انضمامه يحلّ محل مكانه في قائمة الانتظار (إن كان فيها).
        await _waitlist.RemoveEntryAsync(match.Id, userId);

        // من دعاه المنشئ نفسه يُقبل فوراً؛ وإلا يُبلَّغ المنشئ بالطلب.
        var request = match.MatchPlayers.First(p => p.UserId == userId);
        if (await _invites.HasActiveInviteFromAsync(
                match.CreatorId, userId, InviteKindOf(americano), americano.Id))
        {
            await ApproveRequestAsync(americano, request);
            await gate.ReleaseAsync();
        }
        else
        {
            await gate.ReleaseAsync();
            await NotifyJoinRequestAsync(americano, userId, null);
        }

        return await GetByIdAsync(americano.Id);
    }

    /// <summary>
    /// المنشئ يقبل طلب انضمام (فتُصرف الحصة المحجوزة ويكتمل الجدول إن اكتمل
    /// العدد) أو يرفضه (فتُردّ الحصة ويُحذف الطلب، ومعه دعوة شريك صاحبه).
    /// </summary>
    public async Task<AmericanoDto> RespondToJoinRequestAsync(
        int creatorId, int americanoId, int targetUserId, bool approve)
    {
        // القبول يشغل مقعداً والرفض يردّ حصة: يُسلسَلان مع بقية الانضمامات،
        // فلا يتجاوز قبولان متزامنان السعة ولا يردّ رفضان الحصة مرتين.
        await using var gate = await LockAsync(americanoId);
        var americano = await LoadForMutationAsync(americanoId);
        var match = americano.Match;
        if (match.CreatorId != creatorId)
            throw new AuthException(
                "Only the organizer can respond to requests",
                "فقط المنظّم يمكنه الرد على طلبات الانضمام", "NOT_OWNER");

        var request = match.MatchPlayers.FirstOrDefault(
            p => p.UserId == targetUserId && p.Status == MatchPlayerStatus.Pending)
            ?? throw new AuthException(
                "Request not found", "الطلب غير موجود", "REQUEST_NOT_FOUND");

        var label = IsTournament(americano) ? "البطولة" : "الأمريكانو";
        var type = IsTournament(americano) ? "tournament" : "americano";
        if (approve)
        {
            if (match.Status is MatchStatus.Cancelled or MatchStatus.Completed)
                throw new AuthException(
                    "Americano is not joinable", "لا يمكن الانضمام لهذا الأمريكانو", "MATCH_CLOSED");
            await ApproveRequestAsync(americano, request);
            await gate.ReleaseAsync();
            await _notifications.PushAsync(targetUserId, "تم قبول طلبك",
                $"قبل المنظّم انضمامك إلى {label}", $"{type}_join_approved", americano.Id);
        }
        else
        {
            if (request.HasPaid && match.PricePerPlayer > 0)
                await _wallet.RefundAsync(targetUserId, match.ShareOf(request),
                    $"استرداد حصة {label} — رُفض طلب الانضمام", match.Id);
            _db.MatchPlayers.Remove(request);

            // فريق لم يبقَ فيه إلا شريك مدعوّ: دعوته تسقط مع رفض صاحبها.
            if (request.Team is int team && !match.MatchPlayers.Any(p =>
                    p != request && p.Team == team && p.Status != MatchPlayerStatus.Invited))
                foreach (var orphan in match.MatchPlayers
                             .Where(p => p.Team == team && p.Status == MatchPlayerStatus.Invited)
                             .ToList())
                    _db.MatchPlayers.Remove(orphan);

            await _db.SaveChangesAsync();
            await gate.ReleaseAsync();
            await _notifications.PushAsync(targetUserId, "تم رفض طلبك",
                $"اعتذر المنظّم عن قبول انضمامك إلى {label}", $"{type}_join_rejected", americano.Id);
            await _waitlist.ProcessAsync(match.Id);
        }

        return await GetByIdAsync(americanoId);
    }

    /// <summary>قبول طلب: يصير اللاعب عضواً وتُصرف حصته، ثم يُولَّد الجدول إن اكتمل.</summary>
    private async Task ApproveRequestAsync(AmericanoMatch americano, MatchPlayer request)
    {
        var match = americano.Match;
        if (americano.AmericanoType != MatchType.AmericanTeam
            && match.MatchPlayers.Count(p => p.Status == MatchPlayerStatus.Approved)
               >= match.MaxPlayers)
            throw new AuthException("Americano is full", "الأمريكانو مكتمل", "AMERICANO_FULL");

        request.Status = MatchPlayerStatus.Approved;
        request.JoinedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        if (request.HasPaid) await ReleaseShareAsync(match, match.ShareOf(request));

        await _invites.MarkJoinedAsync(request.UserId, InviteKindOf(americano), americano.Id);
        await _chat.PostMemberEventAsync(match.Id, request.UserId, joined: true);
        await EnsureRoundsAsync(americano.Id);
    }

    private async Task NotifyJoinRequestAsync(AmericanoMatch americano, int userId, int? inviterId)
    {
        var name = await _db.Users.Where(u => u.Id == userId)
            .Select(u => (u.FirstName + " " + u.LastName).Trim())
            .FirstOrDefaultAsync() ?? "لاعب";
        var label = IsTournament(americano) ? "بطولتك" : "الأمريكانو";
        var type = IsTournament(americano) ? "tournament" : "americano";
        await _notifications.PushAsync(americano.Match.CreatorId, "طلب انضمام جديد",
            inviterId == null
                ? $"طلب {name} الانضمام إلى {label} — اقبل الطلب أو ارفضه"
                : $"قبل {name} دعوة شريكه ويطلب الانضمام إلى {label} — اقبل الطلب أو ارفضه",
            $"{type}_join_request", americano.Id);
    }

    private static bool IsTournament(AmericanoMatch a) => a.IsTournament || a.Format != null;

    /// <summary>البطولة (بنظام الأمريكانو أو الإقصائية) تُدعى إليها كبطولة.</summary>
    private static EventInviteKind InviteKindOf(AmericanoMatch a) =>
        a.IsTournament || a.Format != null ? EventInviteKind.Tournament : EventInviteKind.Americano;

    // ── Partner invites (teams only) ──────────────────────────────────────────────

    public async Task<AmericanoDto> InvitePartnerAsync(int inviterId, int americanoId, int targetId)
    {
        // مقاعد الفريق تُفحص وتُشغل داخل قفل الحدث كبقية الانضمامات.
        await using var gate = await LockAsync(americanoId);
        var americano = await LoadForMutationAsync(americanoId);
        var match = americano.Match;

        if (americano.AmericanoType != MatchType.AmericanTeam)
            throw new AuthException(
                "Not a teams americano", "هذا الأمريكانو ليس من نوع الفرق", "NOT_TEAMS_AMERICANO");

        EnsureJoinable(match);

        var me = match.MatchPlayers.FirstOrDefault(
            p => p.UserId == inviterId && p.Status == MatchPlayerStatus.Approved)
            ?? throw new AuthException(
                "You are not part of this americano", "لست ضمن هذا الأمريكانو", "NOT_A_PLAYER");

        await InvitePartnerInternalAsync(americano, match, inviterId, targetId, me.Team ?? 1);
        return await GetByIdAsync(americanoId);
    }

    public async Task<AmericanoDto> RespondToPartnerInviteAsync(
        int userId, int americanoId, bool accept)
    {
        // القبول يخصم ويشغل مقعداً: يُسلسَل مع بقية الانضمامات على الحدث.
        await using var gate = await LockAsync(americanoId);
        var americano = await LoadForMutationAsync(americanoId);
        var match = americano.Match;

        var invite = match.MatchPlayers.FirstOrDefault(
            p => p.UserId == userId && p.Status == MatchPlayerStatus.Invited)
            ?? throw new AuthException(
                "No pending invite for you", "لا توجد دعوة معلّقة لك", "NO_INVITE");

        // The teammate who captains the invitee's team is the one to notify back.
        var captainId = match.MatchPlayers.FirstOrDefault(
            p => p.Team == invite.Team && p.Status == MatchPlayerStatus.Approved
                 && p.UserId != userId)?.UserId ?? match.CreatorId;

        if (accept)
        {
            if (match.Status == MatchStatus.Cancelled || match.Status == MatchStatus.Completed)
                throw new AuthException(
                    "Americano is not joinable", "لا يمكن الانضمام لهذا الأمريكانو", "MATCH_CLOSED");

            // دعوة من غير المنشئ: القبول يصير طلب انضمام ينتظر موافقته والحصة محجوزة.
            // دعوة قديمة بلا داعٍ معروف تُعامل كدعوة من غير المنشئ.
            if (invite.InvitedById != match.CreatorId)
            {
                var inviter = invite.InvitedById;
                var heldShare = await HoldShareIfCourtAsync(match, userId);
                invite.HasPaid = heldShare != null;
                heldShare?.ApplyTo(invite);
                invite.Status = MatchPlayerStatus.Pending;
                invite.JoinedAt = DateTime.UtcNow;
                await _db.SaveChangesAsync();
                await gate.ReleaseAsync();

                await _notifications.PushAsync(captainId, "تم قبول الدعوة",
                    "قبل صديقك الانضمام إلى فريقك — بانتظار موافقة المنظّم",
                    "americano_invite_accepted", americano.Id);
                await NotifyJoinRequestAsync(americano, userId, inviter);
                return await GetByIdAsync(americanoId);
            }

            var paidShare = await ChargeShareIfCourtAsync(match, userId);
            invite.Status = MatchPlayerStatus.Approved;
            invite.HasPaid = paidShare != null;
            paidShare?.ApplyTo(invite);
            invite.JoinedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            await _invites.MarkJoinedAsync(userId, InviteKindOf(americano), americano.Id);
            await _chat.PostMemberEventAsync(match.Id, userId, joined: true);
            await EnsureRoundsAsync(americano.Id);
            await gate.ReleaseAsync();

            await _notifications.PushAsync(captainId, "تم قبول الدعوة",
                "قبل صديقك الانضمام إلى فريقك في الأمريكانو",
                "americano_invite_accepted", americano.Id);
        }
        else
        {
            _db.MatchPlayers.Remove(invite);
            await _db.SaveChangesAsync();
            await gate.ReleaseAsync();

            await _notifications.PushAsync(captainId, "تم رفض الدعوة",
                "اعتذر صديقك عن الانضمام إلى فريقك في الأمريكانو",
                "americano_invite_rejected", americano.Id);
        }

        return await GetByIdAsync(americanoId);
    }

    /// <summary>Adds an Invited partner row on a team and notifies them. Shared by
    /// create, join-with-partner and the standalone invite endpoint.</summary>
    private async Task InvitePartnerInternalAsync(
        AmericanoMatch americano, Match match, int inviterId, int targetId, int team)
    {
        await EnsurePartnerInvitableAsync(match, inviterId, targetId, team, joining: false);

        match.MatchPlayers.Add(new MatchPlayer
        {
            MatchId = match.Id,
            UserId = targetId,
            Status = MatchPlayerStatus.Invited,
            Team = team,
            InvitedById = inviterId,
        });
        await _db.SaveChangesAsync();

        await NotifyPartnerInvitedAsync(targetId, americano.Id);
    }

    /// <summary>شروط دعوة شريك إلى فريق. <paramref name="joining"/>: الداعي لم
    /// يُضَف بعد، فيجب أن يتّسع الفريق له وللمدعو معاً.</summary>
    private async Task EnsurePartnerInvitableAsync(
        Match match, int inviterId, int targetId, int team, bool joining)
    {
        if (targetId == inviterId)
            throw new AuthException(
                "You cannot invite yourself", "لا يمكنك دعوة نفسك", "INVALID_PARTNER");
        if (match.MatchPlayers.Any(p => p.UserId == targetId))
            throw new AuthException(
                "Player already in this americano", "اللاعب مشارك بالفعل", "ALREADY_JOINED");
        if (match.MatchPlayers.Count(p => p.Team == team) + (joining ? 1 : 0) >= PlayersPerTeam)
            throw new AuthException("This team is full", "هذا الفريق مكتمل", "TEAM_FULL");

        await ValidatePartnerAsync(inviterId, targetId);
    }

    private Task NotifyPartnerInvitedAsync(int targetId, int americanoId) =>
        _notifications.PushAsync(targetId, "دعوة للانضمام لفريق أمريكانو",
            "دعاك صديقك للانضمام إلى فريقه في مباراة أمريكانو — راجع التفاصيل وردّ بالقبول أو الرفض",
            "americano_invite", americanoId);

    // ── Rounds ────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Generates the schedule once the roster is complete (every seat approved) and
    /// the event is open. Teams → a fixed-teams round robin; singles → the partner
    /// rotation. No-op if not full, not open, or rounds already exist.
    /// </summary>
    private async Task EnsureRoundsAsync(int americanoId)
    {
        var a = await _db.AmericanoMatches
            .Include(x => x.Match).ThenInclude(m => m.MatchPlayers)
            .Include(x => x.Rounds)
            .FirstOrDefaultAsync(x => x.Id == americanoId);
        if (a is null) return;

        // البطولة الإقصائية لا جولات لها: قرعتها ومبارياتها عند خدمة البطولة.
        if (a.Format != null)
        {
            await _tournaments.TryDrawAsync(americanoId);
            return;
        }

        var m = a.Match;
        var approved = m.MatchPlayers
            .Where(p => p.Status == MatchPlayerStatus.Approved).ToList();
        var open = m.Status is MatchStatus.Open or MatchStatus.Full;
        if (approved.Count < m.MaxPlayers || !open || a.Rounds.Count > 0) return;

        if (m.Status != MatchStatus.Full)
        {
            m.Status = MatchStatus.Full;
            await _db.SaveChangesAsync();
        }

        if (a.AmericanoType == MatchType.AmericanTeam)
            await GenerateTeamsRoundsAsync(americanoId, approved, TeamCountOf(m));
        else
            await GenerateRoundsAsync(americanoId, approved.Select(p => p.UserId).ToList());
    }

    /// <summary>Fixed teams: a full round robin — every team meets every other
    /// team once, one game per round, ordered so no team plays back to back.</summary>
    private async Task GenerateTeamsRoundsAsync(
        int americanoId, List<MatchPlayer> approved, int teamCount)
    {
        var rosters = new Dictionary<int, List<int>>();
        for (var team = 1; team <= teamCount; team++)
        {
            var ids = approved.Where(p => p.Team == team).Select(p => p.UserId).ToList();
            if (ids.Count < PlayersPerTeam) return; // uneven roster — skip until balanced
            rosters[team] = ids;
        }

        var number = 1;
        foreach (var (t1, t2) in RoundRobinPairs(teamCount))
            _db.AmericanoRounds.Add(new AmericanoRound
            {
                AmericanoMatchId = americanoId,
                RoundNumber = number++,
                Team1Player1Id = rosters[t1][0],
                Team1Player2Id = rosters[t1][1],
                Team2Player1Id = rosters[t2][0],
                Team2Player2Id = rosters[t2][1],
            });
        await _db.SaveChangesAsync();
    }

    /// <summary>Round-robin pairings (circle method): every team meets every other
    /// once. Odd team counts get a bye each round. Two teams → a single game.</summary>
    private static List<(int Team1, int Team2)> RoundRobinPairs(int teamCount)
    {
        // 0 is the bye placeholder that balances an odd number of teams.
        var teams = Enumerable.Range(1, teamCount).ToList();
        if (teams.Count % 2 == 1) teams.Add(0);

        var n = teams.Count;
        var pairs = new List<(int, int)>();
        for (var round = 0; round < n - 1; round++)
        {
            for (var i = 0; i < n / 2; i++)
            {
                var (a, b) = (teams[i], teams[n - 1 - i]);
                if (a != 0 && b != 0) pairs.Add((a, b));
            }

            // Rotate every team but the first — the circle method.
            var last = teams[n - 1];
            teams.RemoveAt(n - 1);
            teams.Insert(1, last);
        }
        return pairs;
    }

    /// <summary>Singles schedule for any roster size: each round splits the players
    /// into games of four, so 20 players play 5 games at once. Four players give the
    /// classic 3-round rotation.</summary>
    private async Task GenerateRoundsAsync(int americanoId, IReadOnlyList<int> playerIds)
    {
        foreach (var (roundNumber, game) in SinglesSchedule(playerIds))
            _db.AmericanoRounds.Add(new AmericanoRound
            {
                AmericanoMatchId = americanoId,
                RoundNumber = roundNumber,
                Team1Player1Id = game.T1P1,
                Team1Player2Id = game.T1P2,
                Team2Player1Id = game.T2P1,
                Team2Player2Id = game.T2P2,
            });
        await _db.SaveChangesAsync();
    }

    /// <summary>How many rounds a singles roster plays: the circle rotation runs
    /// for (roster size - 1) rounds (3 for the classic four). An odd roster is
    /// padded with a bye, so it needs playerCount rounds for everyone to sit out
    /// exactly once (5 players → 5 rounds, not 4). Capped so a large tournament
    /// gets a schedule it can finish.</summary>
    private static int SinglesRoundCount(int playerCount) =>
        Math.Clamp(PaddedRosterSize(playerCount) - 1, 1, MaxSinglesRounds);

    /// <summary>Roster size after the bye placeholder that balances an odd roster.</summary>
    private static int PaddedRosterSize(int playerCount) =>
        playerCount % 2 == 1 ? playerCount + 1 : playerCount;

    /// <summary>The whole singles schedule: (round number, game) pairs. Partnerships
    /// come from the circle method — every player partners a different one each round
    /// — and consecutive partnerships are matched against each other as games. With a
    /// roster that is not a multiple of four, the leftover players sit the round out,
    /// and the rotation hands the rest out to different players each round.</summary>
    private static List<(int RoundNumber, (int T1P1, int T1P2, int T2P1, int T2P2) Game)>
        SinglesSchedule(IReadOnlyList<int> playerIds)
    {
        // 0 is the bye placeholder that balances an odd roster.
        var players = playerIds.ToList();
        if (players.Count % 2 == 1) players.Add(0);

        var n = players.Count;
        var schedule = new List<(int, (int, int, int, int))>();

        for (var round = 1; round <= SinglesRoundCount(playerIds.Count); round++)
        {
            // Pair the circle's two ends inwards: those are this round's partnerships.
            var pairs = new List<(int A, int B)>();
            for (var i = 0; i < n / 2; i++)
            {
                var (a, b) = (players[i], players[n - 1 - i]);
                if (a != 0 && b != 0) pairs.Add((a, b));
            }

            // Two partnerships make one game; an odd partnership sits this round out.
            for (var i = 0; i + 1 < pairs.Count; i += 2)
                schedule.Add((round,
                    (pairs[i].A, pairs[i].B, pairs[i + 1].A, pairs[i + 1].B)));

            // Rotate every player but the first — the circle method.
            var last = players[n - 1];
            players.RemoveAt(n - 1);
            players.Insert(1, last);
        }

        return schedule;
    }

    // ── Reads ─────────────────────────────────────────────────────────────────────

    public async Task<PagedResult<AmericanoDto>> GetAllAsync(
        int page = 1, int pageSize = 20, string? kind = null, int viewerId = 0)
    {
        (page, pageSize) = Paging.Clamp(page, pageSize);

        // الملغى (ومنه ما رفضه الملعب) لا يُعرض، وما ينتظر موافقة الملعب لا
        // يراه إلا منشئه — كلاهما كان يظهر «مفتوحاً» بزر انضمام لا يعمل.
        // والمنتهي (أو ما مضى وقته) لا يُعرض في القائمة العامة كذلك — صاحبه
        // يجده في «المنتهية».
        var nowKsa = AppClock.Now;
        var query = _db.AmericanoMatches
            .Where(a => a.Match.Status != MatchStatus.Cancelled)
            .Where(a => !a.IsCompleted && a.Match.Status != MatchStatus.Completed)
            .Where(a => a.EndDate != null && a.EndDate > a.Match.ScheduledAt
                ? a.EndDate > nowKsa
                : a.Match.ScheduledAt.AddMinutes(a.Match.DurationMinutes) > nowKsa)
            .Where(a => a.Match.Status != MatchStatus.PendingApproval || a.Match.CreatorId == viewerId);

        // kind: "tournament" → tournaments only; "americano" → americano only;
        // anything else → both.
        switch (kind?.ToLowerInvariant())
        {
            case "tournament": query = query.Where(a => a.IsTournament); break;
            case "americano": query = query.Where(a => !a.IsTournament); break;
        }

        var total = await query.CountAsync();
        var ids = await query
            .OrderByDescending(a => a.Id)
            .Select(a => a.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        // GetByIdAsync also lazily generates rounds, so it is fetched per id;
        // paging bounds the per-request cost.
        var list = new List<AmericanoDto>();
        foreach (var id in ids)
            list.Add(await GetByIdAsync(id));

        return new PagedResult<AmericanoDto>
        {
            Items = list,
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    /// <summary>
    /// «أمريكانو/بطولاتي»: ما أنشأه المستخدم أو هو فيه (معتمداً أو بطلب معلّق أو
    /// مدعوّاً). <paramref name="activeOnly"/> يُسقط المنتهي والملغى — قسم
    /// صفحة المباريات يعرض الحالية فقط، وصفحة «عرض الكل» تعرض كل شيء.
    /// </summary>
    public async Task<PagedResult<AmericanoDto>> GetMineAsync(
        int userId, int page = 1, int pageSize = 20, string? kind = null, bool activeOnly = false,
        bool finishedOnly = false)
    {
        (page, pageSize) = Paging.Clamp(page, pageSize);

        var query = _db.AmericanoMatches
            .Where(a => a.Match.CreatorId == userId
                     || a.Match.MatchPlayers.Any(p => p.UserId == userId));

        switch (kind?.ToLowerInvariant())
        {
            case "tournament": query = query.Where(a => a.IsTournament || a.Format != null); break;
            case "americano": query = query.Where(a => !a.IsTournament && a.Format == null); break;
        }

        // «انتهى» = مكتمل أو ملغى أو مضى وقته: نهاية البطولة إن وُجدت، وإلا
        // الموعد + المدة (بتوقيت السعودية) — كما في تقييم الملعب.
        var now = AppClock.Now;
        if (activeOnly)
            query = query.Where(a => !a.IsCompleted
                                  && a.Match.Status != MatchStatus.Completed
                                  && a.Match.Status != MatchStatus.Cancelled
                                  && (a.EndDate != null && a.EndDate > a.Match.ScheduledAt
                                        ? a.EndDate > now
                                        : a.Match.ScheduledAt.AddMinutes(a.Match.DurationMinutes) > now));

        // صفحة «المنتهية»: ما انتهى أو أُلغي أو مضى وقته.
        if (finishedOnly)
            query = query.Where(a => a.IsCompleted
                                  || a.Match.Status == MatchStatus.Completed
                                  || a.Match.Status == MatchStatus.Cancelled
                                  || (a.EndDate != null && a.EndDate > a.Match.ScheduledAt
                                        ? a.EndDate <= now
                                        : a.Match.ScheduledAt.AddMinutes(a.Match.DurationMinutes) <= now));

        var total = await query.CountAsync();
        var ids = await query
            .OrderByDescending(a => a.Id)
            .Select(a => a.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var list = new List<AmericanoDto>();
        foreach (var id in ids)
            list.Add(await GetByIdAsync(id));

        return new PagedResult<AmericanoDto>
        {
            Items = list,
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    public async Task<AmericanoDto> GetByIdAsync(int id)
    {
        // A court americano approved by the owner (PendingApproval → Open) may be
        // full already; generate its rounds lazily the first time it's fetched.
        await EnsureRoundsAsync(id);

        var americano = await _db.AmericanoMatches
            .Include(a => a.Match).ThenInclude(m => m.Court)
                .ThenInclude(c => c!.Venue).ThenInclude(v => v.CityRef)
            .Include(a => a.Match).ThenInclude(m => m.MatchPlayers).ThenInclude(p => p.User)
                .ThenInclude(u => u.PlayerProfile)
            .Include(a => a.Rounds)
            .FirstOrDefaultAsync(a => a.Id == id)
            ?? throw new AuthException(
                "Americano not found", "الأمريكانو غير موجود", "AMERICANO_NOT_FOUND");

        var players = americano.Match.MatchPlayers.ToDictionary(
            p => p.UserId,
            p => new AmericanoPlayerDto
            {
                UserId = p.UserId,
                Name = $"{p.User.FirstName} {p.User.LastName}".Trim(),
                Level = p.User.PlayerProfile != null ? (int)p.User.PlayerProfile.Level : null,
                AvatarUrl = p.User.ProfileImageUrl,
                Team = p.Team,
                WithdrawalRequested = p.WithdrawalRequestedAt != null,
                Status = p.Status switch
                {
                    MatchPlayerStatus.Invited => "invited",
                    MatchPlayerStatus.Pending => "pending",
                    _ => "approved",
                },
            });

        AmericanoPlayerDto P(int uid) =>
            players.TryGetValue(uid, out var dto) ? dto : new AmericanoPlayerDto { UserId = uid };

        var rounds = americano.Rounds
            .OrderBy(r => r.RoundNumber)
            .Select(r => new AmericanoRoundDto
            {
                Id = r.Id,
                RoundNumber = r.RoundNumber,
                Team1 = [P(r.Team1Player1Id), P(r.Team1Player2Id)],
                Team2 = [P(r.Team2Player1Id), P(r.Team2Player2Id)],
                Team1Score = r.Team1Score,
                Team2Score = r.Team2Score,
                IsCompleted = r.IsCompleted,
                IsDisputed = r.IsDisputed,
                PendingResult = ScoreProposals.ToDto(
                    r, RoundSide(r, r.ProposedById),
                    r.ProposedById is int pid ? P(pid).Name : string.Empty),
            })
            .ToList();

        // Standings only count confirmed (approved) players.
        var approvedPlayers = americano.Match.MatchPlayers
            .Where(p => p.Status == MatchPlayerStatus.Approved)
            .Select(p => p.UserId)
            .Where(players.ContainsKey)
            .ToDictionary(uid => uid, uid => players[uid]);

        return new AmericanoDto
        {
            Id = americano.Id,
            MatchId = americano.MatchId,
            CreatorId = americano.Match.CreatorId,
            Type = americano.AmericanoType == MatchType.AmericanTeam ? "teams" : "singles",
            IsTournament = americano.IsTournament,
            EndDate = americano.EndDate,
            Name = americano.Name,
            Format = americano.Format switch
            {
                TournamentFormat.Knockout => "knockout",
                TournamentFormat.GroupsKnockout => "groups",
                _ => null,
            },
            ScheduledAt = americano.Match.ScheduledAt,
            DurationMinutes = americano.Match.DurationMinutes,
            TotalRounds = americano.TotalRounds,
            MaxPlayers = americano.Match.MaxPlayers,
            TeamCount = americano.AmericanoType == MatchType.AmericanTeam
                ? TeamCountOf(americano.Match)
                : 0,
            IsCompleted = americano.IsCompleted,
            IsVenueHosted = americano.Match.IsHostedByVenueOwner,
            MatchStatus = americano.Match.Status switch
            {
                Enums.MatchStatus.PendingApproval => "pendingApproval",
                Enums.MatchStatus.Open => "open",
                Enums.MatchStatus.Full => "full",
                Enums.MatchStatus.InProgress => "inProgress",
                Enums.MatchStatus.Completed => "completed",
                _ => "cancelled",
            },
            MinLevel = americano.MinAllowedLevel,
            MaxLevel = americano.MaxAllowedLevel,
            CourtId = americano.Match.CourtId,
            VenueName = americano.Match.Court?.Venue.Name,
            VenueNameEn = americano.Match.Court?.Venue.NameEn,
            City = americano.Match.Court?.Venue.City,
            CityEn = americano.Match.Court?.Venue.CityRef?.NameEn,
            PricePerPlayer =
                americano.Match.CourtId == null ? 0m : americano.Match.PricePerPlayer,
            WithdrawalFreeUntil = WithdrawalPolicy.FreeUntil(americano.Match.ScheduledAt, isEvent: true),
            CanWithdrawDirectly = WithdrawalPolicy.IsFree(americano.Match.ScheduledAt, isEvent: true),
            Players = players.Values.ToList(),
            Rounds = rounds,
            Standings = BuildStandings(
                americano.Rounds, approvedPlayers,
                teams: americano.AmericanoType == MatchType.AmericanTeam),
        };
    }

    /// <summary>
    /// أحد لاعبي الجولة الأربعة يُدخل نتيجتها فتُحفظ مقترحةً، ولا تُعتمد حتى
    /// يؤكدها لاعب من الفريق الآخر. إدخال الفريق الآخر للنتيجة نفسها تأكيد.
    /// </summary>
    public async Task<AmericanoDto> SubmitRoundScoreAsync(
        int roundId, SubmitRoundScoreRequest req, int userId)
    {
        var round = await LoadRoundAsync(roundId);
        var side = RoundSide(round, userId) ?? throw ScoreProposals.NotAPlayer();

        if (round.IsSameAsProposal(req.Team1Score, req.Team2Score)
            && RoundSide(round, round.ProposedById) != side)
            return await ConfirmRoundAsync(round, userId);

        round.Propose(userId, req.Team1Score, req.Team2Score);
        await _db.SaveChangesAsync();

        var name = await UserNameAsync(userId);
        foreach (var uid in RoundTeam(round, side == 1 ? 2 : 1))
            await _notifications.PushAsync(uid, "أكّد نتيجة الجولة",
                $"أدخل {name} نتيجة الجولة {round.RoundNumber}: {req.Team1Score} - {req.Team2Score} — أكّدها أو ارفضها",
                "americano_result_proposed", round.AmericanoMatchId);

        return await GetByIdAsync(round.AmericanoMatchId);
    }

    /// <summary>لاعب من الفريق الآخر في الجولة يؤكد النتيجة المقترحة أو يرفضها.</summary>
    public async Task<AmericanoDto> RespondRoundScoreAsync(int roundId, RespondResultRequest req, int userId)
    {
        var round = await LoadRoundAsync(roundId);
        ScoreProposals.EnsureCanRespond(
            round, RoundSide(round, userId), RoundSide(round, round.ProposedById), req);

        if (req.Accept) return await ConfirmRoundAsync(round, userId);

        var proposerId = round.ProposedById!.Value;
        round.Reject();
        await _db.SaveChangesAsync();
        var rejecter = await UserNameAsync(userId);
        await _notifications.PushAsync(proposerId, "رُفضت نتيجة الجولة",
            $"رفض {rejecter} نتيجة الجولة {round.RoundNumber} — أدخلوا النتيجة الصحيحة أو يحسمها المنظّم",
            "americano_result_rejected", round.AmericanoMatchId);
        var organizerId = round.AmericanoMatch.Match.CreatorId;
        if (organizerId != userId && organizerId != proposerId)
            await _notifications.PushAsync(organizerId, "خلاف على نتيجة جولة",
                $"رفض {rejecter} نتيجة الجولة {round.RoundNumber} — يمكنك حسمها كمنظّم",
                "americano_result_disputed", round.AmericanoMatchId);
        return await GetByIdAsync(round.AmericanoMatchId);
    }

    /// <summary>المنظّم يحسم خلافاً على نتيجة جولة بإدخالها نهائيةً بلا تأكيد.</summary>
    public async Task<AmericanoDto> ResolveRoundScoreAsync(int roundId, ResolveResultRequest req, int userId)
    {
        var round = await LoadRoundAsync(roundId);
        ScoreProposals.EnsureCanResolve(round, userId, round.AmericanoMatch.Match.CreatorId);

        round.Propose(userId, req.Team1Score, req.Team2Score);
        var dto = await ConfirmRoundAsync(round, userId);

        foreach (var uid in RoundTeam(round, 1).Concat(RoundTeam(round, 2)).Where(u => u != userId))
            await _notifications.PushAsync(uid, "حسم المنظّم نتيجة الجولة",
                $"اعتمد المنظّم نتيجة الجولة {round.RoundNumber}: {req.Team1Score} - {req.Team2Score}",
                "americano_result_resolved", round.AmericanoMatchId);
        return dto;
    }

    /// <summary>اعتماد نتيجة الجولة المقترحة: تُكتب نهائيةً وتُحتسب الترتيب والنقاط.</summary>
    private async Task<AmericanoDto> ConfirmRoundAsync(AmericanoRound round, int confirmerId)
    {
        var s1 = round.ProposedTeam1Score!.Value;
        var s2 = round.ProposedTeam2Score!.Value;
        var proposerId = round.ProposedById!.Value;
        var isCorrection = round.IsCompleted;

        round.Team1Score = s1;
        round.Team2Score = s2;
        round.IsCompleted = true;
        round.ClearProposal();
        round.IsDisputed = false;

        var americanoId = round.AmericanoMatchId;
        var allDone = !await _db.AmericanoRounds
            .AnyAsync(r => r.AmericanoMatchId == americanoId && r.Id != round.Id && !r.IsCompleted);

        if (allDone)
        {
            round.AmericanoMatch.IsCompleted = true;
            round.AmericanoMatch.Match.Status = MatchStatus.Completed;
        }

        await _db.SaveChangesAsync();

        // نقاط المستوى لكل جولة: فريقا الجولة معروفان، فتُحتسب زوجياً بمتوسط
        // مستوى كل فريق. تصحيح النتيجة يلغي السابقة ثم يحتسب الجديدة.
        if (isCorrection)
            await _points.ReverseLevelPointsAsync(PointsTransactionType.LevelAmericanoRound, round.Id);
        await _points.ApplyLevelPointsAsync(
            RoundTeam(round, 1), RoundTeam(round, 2), s1, s2,
            PointsTransactionType.LevelAmericanoRound, round.Id,
            $"نقاط مستوى — جولة {round.RoundNumber}");

        if (proposerId != confirmerId)
            await _notifications.PushAsync(proposerId, "اعتُمدت نتيجة الجولة",
                $"أكّد {await UserNameAsync(confirmerId)} نتيجة الجولة {round.RoundNumber}: {s1} - {s2}",
                "americano_result_confirmed", americanoId);

        return await GetByIdAsync(americanoId);
    }

    private async Task<AmericanoRound> LoadRoundAsync(int roundId)
    {
        var round = await _db.AmericanoRounds
            .Include(r => r.AmericanoMatch).ThenInclude(a => a.Match)
            .FirstOrDefaultAsync(r => r.Id == roundId)
            ?? throw new AuthException("Round not found", "الجولة غير موجودة", "ROUND_NOT_FOUND");
        if (round.AmericanoMatch.Match.Status == MatchStatus.Cancelled)
            throw new AuthException("Americano is cancelled", "الأمريكانو ملغى", "MATCH_CLOSED");
        // لا نتيجة جولة قبل موعد الحدث (محلي ساذج ← ساعة التطبيق): الجولات
        // تُولَّد عند اكتمال العدد، وكانت تُسجَّل وتُعتمد نقاطها قبل اللعب.
        if (round.AmericanoMatch.Match.ScheduledAt > AppClock.Now)
            throw new AuthException(
                "The event hasn't started yet",
                $"لم يبدأ موعد {(IsTournament(round.AmericanoMatch) ? "البطولة" : "الأمريكانو")} بعد — تُدخل نتائج الجولات بعد اللعب",
                "MATCH_NOT_STARTED");
        return round;
    }

    /// <summary>طرف اللاعب في الجولة (1 أو 2)، أو null إن لم يلعبها.</summary>
    private static int? RoundSide(AmericanoRound r, int? userId) =>
        userId == r.Team1Player1Id || userId == r.Team1Player2Id ? 1
        : userId == r.Team2Player1Id || userId == r.Team2Player2Id ? 2
        : null;

    private static List<int> RoundTeam(AmericanoRound r, int side) => side == 1
        ? [r.Team1Player1Id, r.Team1Player2Id]
        : [r.Team2Player1Id, r.Team2Player2Id];

    private async Task<string> UserNameAsync(int userId) =>
        await _db.Users.Where(u => u.Id == userId)
            .Select(u => (u.FirstName + " " + u.LastName).Trim())
            .FirstOrDefaultAsync() ?? "لاعب";

    // ── Helpers ─────────────────────────────────────────────────────────────────

    private async Task<Court?> LoadCourtOrNullAsync(int? courtId)
    {
        if (courtId is not int id) return null;
        return await _db.Courts
            .NotDeleted()
            .Include(c => c.Venue)
            .Include(c => c.PriceTiers)
            .Include(c => c.OpeningHours)
            .Include(c => c.PriceRules)
            .FirstOrDefaultAsync(c => c.Id == id && c.Venue.IsApproved)
            ?? throw new AuthException("Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");
    }

    /// <summary>قفل الحدث (<see cref="MatchLock"/>) بمعرّف مباراته.</summary>
    private async Task<MatchLock> LockAsync(int americanoId)
    {
        var matchId = await _db.AmericanoMatches
            .Where(a => a.Id == americanoId)
            .Select(a => (int?)a.MatchId)
            .FirstOrDefaultAsync()
            ?? throw new AuthException(
                "Americano not found", "الأمريكانو غير موجود", "AMERICANO_NOT_FOUND");
        return await MatchLock.AcquireAsync(_db, matchId);
    }

    private async Task<AmericanoMatch> LoadForMutationAsync(int id) =>
        await _db.AmericanoMatches
            .Include(a => a.Match).ThenInclude(m => m.MatchPlayers)
            .Include(a => a.Match).ThenInclude(m => m.Court)
                .ThenInclude(c => c!.Venue).ThenInclude(v => v.CityRef)
            .FirstOrDefaultAsync(a => a.Id == id)
        ?? throw new AuthException(
            "Americano not found", "الأمريكانو غير موجود", "AMERICANO_NOT_FOUND");

    /// <summary>How many fixed teams a teams americano has (2 players each).</summary>
    private static int TeamCountOf(Match match) =>
        Math.Max(MinTeams, match.MaxPlayers / PlayersPerTeam);

    /// <summary>الفريق الذي يوضع فيه المنضمّ تلقائياً ويتسع لـ [seats] مقاعد:
    /// لمقعد واحد يُفضَّل فريق ناقص (يكتمل به) ثم فريق فارغ؛ ولمقعدين فريق
    /// فارغ. null = لا مكان.</summary>
    private static int? AutoTeam(Match match, int teamCount, int seats)
    {
        int Count(int team) => match.MatchPlayers.Count(p => p.Team == team);
        var withRoom = Enumerable.Range(1, teamCount)
            .Where(team => PlayersPerTeam - Count(team) >= seats)
            .ToList();
        if (withRoom.Count == 0) return null;
        return withRoom.OrderByDescending(Count).ThenBy(team => team).First();
    }

    private static void EnsureJoinable(Match match)
    {
        if (match.Status == MatchStatus.PendingApproval)
            throw new AuthException(
                "Americano is awaiting venue approval",
                "الأمريكانو بانتظار موافقة الملعب", "MATCH_PENDING_APPROVAL");
        if (match.Status == MatchStatus.Cancelled || match.Status == MatchStatus.Completed)
            throw new AuthException(
                "Americano is not joinable", "لا يمكن الانضمام لهذا الأمريكانو", "MATCH_CLOSED");
    }

    private async Task EnsureLevelAllowedAsync(int userId, AmericanoMatch americano)
    {
        var level = await _db.Users
            .Where(u => u.Id == userId)
            .Select(u => u.PlayerProfile != null ? (int?)u.PlayerProfile.Level : null)
            .FirstOrDefaultAsync();
        if (level is int lvl &&
            (lvl < americano.MinAllowedLevel || lvl > americano.MaxAllowedLevel))
            throw new AuthException(
                "Your level is outside the allowed range",
                "مستواك خارج النطاق المسموح", "LEVEL_NOT_ALLOWED");
    }

    private async Task ValidatePartnerAsync(int inviterId, int targetId)
    {
        if (!await _db.Users.AnyAsync(u => u.Id == targetId))
            throw new AuthException("Player not found", "اللاعب غير موجود", "PLAYER_NOT_FOUND");
        if (!await AreFriendsAsync(inviterId, targetId))
            throw new AuthException(
                "You can only invite your friends",
                "يمكنك دعوة أصدقائك فقط", "NOT_FRIENDS");
    }

    /// <summary>Court americano: the joining/accepting player pays their share,
    /// reimbursing the creator (who fronted the full court price).</summary>
    private async Task<MemberShare?> ChargeShareIfCourtAsync(Match match, int userId)
    {
        var share = await HoldShareIfCourtAsync(match, userId);
        if (share != null) await ReleaseShareAsync(match, share.Amount);
        return share;
    }

    /// <summary>
    /// يخصم حصة اللاعب (بعد خصم عضويته في النادي إن وُجدت) ويحجزها عندنا —
    /// لم تُصرف لأحد بعد. null = لا شيء يُدفع (أمريكانو بلا ملعب أو مجاني).
    /// </summary>
    private async Task<MemberShare?> HoldShareIfCourtAsync(Match match, int userId)
    {
        if (match.CourtId == null || match.PricePerPlayer <= 0) return null;

        var share = await _memberships.QuoteEventShareAsync(userId, match);
        var hasPaid = await _wallet.TryChargeAsync(
            userId, share.Amount, WalletTransactionType.MatchPayment,
            "حصة أمريكانو", match.Id);
        if (!hasPaid)
            throw new AuthException(
                "Insufficient wallet balance",
                "رصيد المحفظة غير كافٍ، يرجى شحن المحفظة والمحاولة مجدداً",
                "INSUFFICIENT_BALANCE");
        return share;
    }

    /// <summary>
    /// يصرف حصة محجوزة لعضو معتمد (<paramref name="paid"/> = ما دفعه فعلاً):
    /// للمنشئ حين دفع كاملاً، وإلا لمالك الملعب.
    /// </summary>
    private async Task ReleaseShareAsync(Match match, decimal paid)
    {
        // قبل موافقة الملعب تبقى الحصة محجوزة عندنا كحصة المنشئ، وتُصرف عند
        // الموافقة أو تُردّ عند الرفض/الإلغاء.
        if (match.Status == MatchStatus.PendingApproval) return;

        if (match.PaymentMode == MatchPaymentMode.FullByCreator)
            await _wallet.CreditEarningAsync(
                match.CreatorId, paid,
                WalletTransactionType.CreatorEarning, "حصة أمريكانو", match.Id);
        else if (match.Court != null)
            await _wallet.CreditEarningAsync(
                match.Court.Venue.OwnerId,
                match.NetOfCommission(paid),
                WalletTransactionType.VenueEarning, "حصة أمريكانو", match.Id);
    }

    private async Task<bool> AreFriendsAsync(int a, int b) => await _db.Friendships.AnyAsync(f =>
        f.Status == FriendshipStatus.Accepted &&
        ((f.SenderId == a && f.ReceiverId == b) || (f.SenderId == b && f.ReceiverId == a)));

    // ── Standings ─────────────────────────────────────────────────────────────────

    /// <summary>
    /// جدول الترتيب. الصف لاعبٌ في الفردي، و<b>فريقٌ</b> في أمريكانو الفرق —
    /// لاعبا الفريق الثابت يجمعان نفس النقاط دائماً، فترتيبهما فرادى كان يعطي
    /// 16 صفاً لثمانية فرق ويضع الفريق الواحد في مركزين. الترتيب: النقاط
    /// المسجَّلة، ثم الانتصارات، ثم فارق النقاط.
    /// </summary>
    private static List<AmericanoStandingDto> BuildStandings(
        IEnumerable<AmericanoRound> rounds,
        IReadOnlyDictionary<int, AmericanoPlayerDto> players,
        bool teams)
    {
        // مفتاح الصف: رقم الفريق في الفرق، ومعرّف اللاعب في الفردي.
        int KeyOf(int userId) =>
            teams && players.TryGetValue(userId, out var p) && p.Team is int t ? t : userId;

        var rows = new Dictionary<int, AmericanoStandingDto>();
        foreach (var p in players.Values)
        {
            var key = KeyOf(p.UserId);
            if (!rows.TryGetValue(key, out var row))
            {
                row = new AmericanoStandingDto
                {
                    UserId = p.UserId,
                    Team = teams ? p.Team : null,
                };
                rows[key] = row;
            }
            row.UserIds.Add(p.UserId);
            row.Name = string.IsNullOrEmpty(row.Name) ? p.Name : $"{row.Name} و {p.Name}";
        }

        var points = rows.Keys.ToDictionary(k => k, _ => 0);
        var against = rows.Keys.ToDictionary(k => k, _ => 0);
        var wins = rows.Keys.ToDictionary(k => k, _ => 0);
        var played = rows.Keys.ToDictionary(k => k, _ => 0);

        foreach (var r in rounds.Where(r => r.IsCompleted && r.Team1Score != null && r.Team2Score != null))
        {
            var s1 = r.Team1Score!.Value;
            var s2 = r.Team2Score!.Value;
            var side1 = new[] { r.Team1Player1Id, r.Team1Player2Id };
            var side2 = new[] { r.Team2Player1Id, r.Team2Player2Id };

            // في الفرق يُحتسب الفريق مرة واحدة لا مرة لكل لاعب.
            foreach (var key in side1.Select(KeyOf).Distinct())
            { Add(points, key, s1); Add(against, key, s2); Add(played, key, 1); if (s1 > s2) Add(wins, key, 1); }
            foreach (var key in side2.Select(KeyOf).Distinct())
            { Add(points, key, s2); Add(against, key, s1); Add(played, key, 1); if (s2 > s1) Add(wins, key, 1); }
        }

        return rows
            .Select(kv =>
            {
                var row = kv.Value;
                row.Points = points[kv.Key];
                row.Wins = wins[kv.Key];
                row.Played = played[kv.Key];
                row.Diff = points[kv.Key] - against[kv.Key];
                return row;
            })
            .OrderByDescending(s => s.Points)
            .ThenByDescending(s => s.Wins)
            .ThenByDescending(s => s.Diff)
            .ThenBy(s => s.Team ?? s.UserId)
            .Select((s, i) => { s.Rank = i + 1; return s; })
            .ToList();
    }

    private static void Add(Dictionary<int, int> map, int key, int value)
    {
        if (map.ContainsKey(key)) map[key] += value;
    }
}
