using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;
using MatchType = SportaApis.Enums.MatchType;

namespace SportaApis.Services;

public partial class TournamentService : ITournamentService
{
    private readonly AppDbContext _db;
    private readonly IWalletService _wallet;
    private readonly INotificationService _notifications;
    private readonly IPointsService _points;
    private readonly IMatchService _matches;
    private readonly IMembershipService _memberships;

    public TournamentService(
        AppDbContext db, IWalletService wallet, INotificationService notifications,
        IPointsService points, IMatchService matches, IMembershipService memberships)
    {
        _memberships = memberships;
        _db = db;
        _wallet = wallet;
        _notifications = notifications;
        _points = points;
        _matches = matches;
    }

    // ── Quote ─────────────────────────────────────────────────────────────────

    public async Task<TournamentQuoteDto> QuoteAsync(TournamentQuoteRequest req)
    {
        var format = ParseFormat(req.Format);
        var courts = await LoadCourtsAsync(req.CourtIds);
        var lastDay = req.EndDate?.Date ?? req.ScheduledAt.Date;
        if (lastDay < req.ScheduledAt.Date) lastDay = req.ScheduledAt.Date;

        var quote = BuildQuote(format, req.TeamCount, req.ScheduledAt, lastDay,
            req.DurationMinutes, req.MatchMinutes, courts.Count);

        var total = 0m;
        foreach (var court in courts)
            for (var day = req.ScheduledAt.Date; day <= lastDay; day = day.AddDays(1))
                total += CourtSchedule.BookingPrice(
                    court, day.Add(req.ScheduledAt.TimeOfDay), req.DurationMinutes);
        quote.TotalCourtPrice = total;
        quote.PricePerPlayer = Math.Round(
            total / (req.TeamCount * TournamentEngine.PlayersPerTeam), 2);
        return quote;
    }

    private static TournamentQuoteDto BuildQuote(
        TournamentFormat format, int teams, DateTime start, DateTime lastDay,
        int windowMinutes, int matchMinutes, int courtCount)
    {
        var q = new TournamentQuoteDto { TeamCount = teams };
        if (format == TournamentFormat.GroupsKnockout)
        {
            var plan = TournamentEngine.PlanGroups(teams);
            q.GroupCount = plan.GroupCount;
            q.GroupSizes = [.. plan.Sizes];
            q.KnockoutSize = plan.KnockoutSize;
            q.BestThirds = plan.BestThirds;
            q.GroupMatches = plan.GroupMatches;
            q.KnockoutMatches = plan.KnockoutMatches;
        }
        else
        {
            q.KnockoutSize = TournamentEngine.NextPowerOfTwo(teams);
            q.KnockoutMatches = Math.Max(0, teams - 1);
        }
        q.TotalMatches = q.GroupMatches + q.KnockoutMatches;
        q.PathText = PathText(format, teams);

        var days = (lastDay.Date - start.Date).Days + 1;
        var perDay = matchMinutes <= 0 ? 0 : windowMinutes / matchMinutes;
        var rawSlots = days * perDay * courtCount;
        // الأدوار متتابعة فلا تُستغل كل الخانات: يُحاكى التوزيع الفعلي. إن لم
        // تتّسع كل المباريات فالسعة المعروضة هي ما يتّسع منها فعلاً.
        var schedulable = rawSlots < q.TotalMatches ? rawSlots
            : TournamentEngine.SchedulableMatches(format, teams, start.Date, lastDay.Date,
                start.TimeOfDay, windowMinutes, matchMinutes, courtCount);
        q.SlotCapacity = schedulable >= q.TotalMatches ? rawSlots : schedulable;
        return q;
    }

    private static string PathText(TournamentFormat format, int teams)
    {
        if (format == TournamentFormat.Knockout)
        {
            var size = TournamentEngine.NextPowerOfTwo(teams);
            var byes = size - teams;
            var text = $"خروج المغلوب مباشرة، يبدأ من {TournamentEngine.RoundName(size)} حتى النهائي";
            return byes > 0 ? $"{text} (مع {CountWord(byes, "إعفاء واحد", "إعفاءين", "إعفاءات", "إعفاءً")} في الدور الأول)." : text + ".";
        }

        var plan = TournamentEngine.PlanGroups(teams);
        var groups = CountWord(plan.GroupCount, "مجموعة واحدة", "مجموعتان", "مجموعات", "مجموعة");
        var thirds = plan.BestThirds > 0
            ? $" مع {CountWord(plan.BestThirds, "أفضل ثالث", "أفضل ثالثَين", "من أفضل الثوالث")}"
            : "";
        return $"{groups} بنظام الدوري، يتأهل الأول والثاني من كل مجموعة{thirds}، " +
               $"ثم يبدأ خروج المغلوب من {TournamentEngine.RoundName(plan.KnockoutSize)} حتى النهائي.";
    }

    /// <summary>«واحد» / «اثنان» / «N كلمات» — مفرد ومثنى وجمع بالعربية، ومن
    /// 11 فأكثر يُميَّز العدد بمفرد (<paramref name="elevenPlus"/>): «12 مجموعة».</summary>
    private static string CountWord(int n, string one, string two, string many, string? elevenPlus = null) => n switch
    {
        1 => one,
        2 => two,
        >= 11 when elevenPlus != null => $"{n} {elevenPlus}",
        _ => $"{n} {many}",
    };

    // ── Create ────────────────────────────────────────────────────────────────

    public async Task<TournamentDto> CreateAsync(int creatorId, CreateTournamentRequest req)
    {
        var format = ParseFormat(req.Format);
        var name = req.Name.Trim();
        if (name.Length == 0)
            throw new AuthException("Name is required", "اكتب اسم البطولة", "TOURNAMENT_NAME_REQUIRED");

        if (req.TeamCount < TournamentEngine.MinTeams)
            throw new AuthException(
                $"A tournament needs at least {TournamentEngine.MinTeams} teams",
                $"عدد الفرق لا يقل عن {TournamentEngine.MinTeams}", "TOURNAMENT_TEAM_COUNT");

        if (req.ScheduledAt <= AppClock.Now)
            throw new AuthException(
                "Selected time has already passed",
                "الوقت المختار مضى — اختر موعداً قادماً", "SLOT_IN_PAST");

        if (req.MatchMinutes > req.DurationMinutes)
            throw new AuthException(
                "Match length exceeds the daily window",
                "مدة المباراة أطول من النافذة اليومية", "TOURNAMENT_MATCH_TOO_LONG");

        var firstDay = req.ScheduledAt.Date;
        var lastDay = firstDay;
        if (req.EndDate is DateTime end)
        {
            if (end.Date < firstDay)
                throw new AuthException(
                    "Tournament end date cannot be before its start date",
                    "تاريخ نهاية البطولة لا يمكن أن يسبق تاريخ بدايتها", "TOURNAMENT_BAD_END_DATE");
            if ((end.Date - firstDay).TotalDays > CourtSchedule.MaxMultiDayRangeDays)
                throw new AuthException(
                    $"A tournament cannot span more than {CourtSchedule.MaxMultiDayRangeDays} days",
                    $"مدة البطولة لا تتجاوز {CourtSchedule.MaxMultiDayRangeDays} يوماً", "TOURNAMENT_TOO_LONG");
            lastDay = end.Date;
        }

        // أقفال الملاعب نفسها التي يأخذها الحجز العادي، بترتيب المعرّف حتى لا
        // يتشابك طلبان على ملاعب متداخلة: فحص المواعيد ثم الإنشاء لا يتقاطعان
        // مع حجز أو مباراة متزامنة. تُحرَّر عند انتهاء الإنشاء.
        await using var courtGates = await DbLocks.AcquireManyAsync(
            _db, req.CourtIds.Distinct().Order().Select(id => $"court:{id}"));

        var courts = await LoadCourtsAsync(req.CourtIds);
        var primary = courts[0];
        // استضافة من حساب الملعب بطلب صريح؛ من حساب اللاعب يُعامل صاحب
        // الملعب كأي لاعب حتى على ملاعبه.
        var hostedByOwner = req.HostedByVenue;
        if (hostedByOwner && primary.Venue.OwnerId != creatorId)
            throw new AuthException(
                "Hosting is only allowed on your own courts",
                "الاستضافة متاحة على ملاعبك فقط", "NOT_OWNER");

        // ملاعب أخفاها البحث (نادٍ غير نشط أو اشتراكه منتهٍ) لا تُحجز بالمعرّف.
        if (!hostedByOwner)
            foreach (var c in courts)
                if (!await VenueBookability.IsBookableAsync(_db, c.Id))
                    throw new AuthException(
                        "Court is not available", "الملعب غير متاح للحجز", "COURT_UNAVAILABLE");
        var capacity = req.TeamCount * TournamentEngine.PlayersPerTeam;

        // الجدول يجب أن يتّسع لكل مباريات البطولة قبل حجز أي شيء.
        var quote = BuildQuote(format, req.TeamCount, req.ScheduledAt, lastDay,
            req.DurationMinutes, req.MatchMinutes, courts.Count);
        if (!quote.Fits)
            throw new AuthException(
                $"Schedule fits {quote.SlotCapacity} matches but the tournament needs {quote.TotalMatches}",
                $"الجدول يتّسع لـ {quote.SlotCapacity} مباراة والبطولة تحتاج {quote.TotalMatches} — " +
                "زد الأيام أو الملاعب أو النافذة اليومية", "TOURNAMENT_SCHEDULE_TOO_SMALL");

        var total = await ValidateAndPriceAsync(
            courts, firstDay, lastDay, req.ScheduledAt.TimeOfDay, req.DurationMinutes, null);

        var match = new Match
        {
            CreatorId = creatorId,
            CourtId = primary.Id,
            MatchType = MatchType.AmericanTeam,
            ScheduledAt = req.ScheduledAt,
            DurationMinutes = req.DurationMinutes,
            MaxPlayers = capacity,
            MinLevel = req.MinLevel,
            MaxLevel = req.MaxLevel,
            PricePerPlayer = Math.Round(total / capacity, 2),
            SportaCommissionPercent = primary.SportaCommissionPercent,
            PaymentMode = MatchPaymentMode.SharePerPlayer,
            Status = hostedByOwner ? MatchStatus.Open : MatchStatus.PendingApproval,
        };

        int? invitedPartnerId = null;
        if (!hostedByOwner)
        {
            // المنشئ لاعب: يقود الفريق الأول ويدفع حصته وحدها.
            match.MatchPlayers.Add(new MatchPlayer
            {
                UserId = creatorId,
                Status = MatchPlayerStatus.Approved,
                Team = 1,
                // تُعلَّم مدفوعة بعد نجاح الخصم فقط (أدناه).
                HasPaid = false,
            });
            if (req.PartnerId is int pid && pid != creatorId)
            {
                await ValidatePartnerAsync(creatorId, pid);
                match.MatchPlayers.Add(new MatchPlayer
                {
                    UserId = pid,
                    Status = MatchPlayerStatus.Invited,
                    InvitedById = creatorId,
                    Team = 1,
                });
                invitedPartnerId = pid;
            }

            // عضو النادي (الملعب الأساسي) يدفع حصته بعد خصم عضويته.
            var charge = (await _memberships.QuoteShareAsync(creatorId, primary.VenueId,
                match.PricePerPlayer,
                req.DurationMinutes * ((lastDay - firstDay).Days + 1), req.ScheduledAt)).Amount;
            var wallet = await _db.Wallets.FirstOrDefaultAsync(w => w.UserId == creatorId);
            if (charge > 0 && (wallet == null || wallet.Balance < charge))
                throw new AuthException(
                    "Insufficient wallet balance",
                    "رصيد المحفظة غير كافٍ، يرجى شحن المحفظة والمحاولة مجدداً",
                    "INSUFFICIENT_BALANCE");
        }

        // الإنشاء وخصم حصة المنشئ معاً: فشل الخصم (رصيد نقص بعد الفحص المبدئي
        // أو طلب متزامن) يُلغي البطولة كلها بدل بقاء منشئ «مدفوع» لم يُخصم منه شيء.
        await using var tx = await _db.Database.BeginTransactionAsync();

        _db.Matches.Add(match);
        await _db.SaveChangesAsync();

        var americano = new AmericanoMatch
        {
            MatchId = match.Id,
            AmericanoType = MatchType.AmericanTeam,
            IsTournament = true,
            EndDate = lastDay > firstDay ? lastDay : null,
            MinAllowedLevel = req.MinLevel,
            MaxAllowedLevel = req.MaxLevel,
            TotalRounds = quote.TotalMatches,
            Name = name,
            Format = format,
            MatchMinutes = req.MatchMinutes,
        };
        foreach (var court in courts.Skip(1))
            americano.Courts.Add(new TournamentCourt { CourtId = court.Id });
        _db.AmericanoMatches.Add(americano);
        await _db.SaveChangesAsync();

        if (!hostedByOwner)
        {
            var share = await _memberships.QuoteEventShareAsync(creatorId, match);
            var charged = await _wallet.TryChargeAsync(
                creatorId, share.Amount, WalletTransactionType.MatchPayment,
                "حصة بطولة", match.Id);
            if (!charged)
                throw new AuthException(
                    "Insufficient wallet balance",
                    "رصيد المحفظة غير كافٍ، يرجى شحن المحفظة والمحاولة مجدداً",
                    "INSUFFICIENT_BALANCE");
            if (match.MatchPlayers.FirstOrDefault(p => p.UserId == creatorId) is { } creator)
            {
                creator.HasPaid = true;
                share.ApplyTo(creator);
                await _db.SaveChangesAsync();
            }
        }
        await tx.CommitAsync();

        if (!hostedByOwner)
        {
            await _notifications.PushAsync(primary.Venue.OwnerId,
                "طلب بطولة جديد على ملعبك",
                $"طلب استضافة بطولة «{name}» على {primary.Venue.Name} بانتظار موافقتك",
                "match_request", match.Id);
        }

        if (invitedPartnerId is int partner)
            await _notifications.PushAsync(partner, "دعوة للانضمام لفريق في بطولة",
                $"دعاك صديقك للانضمام إلى فريقه في بطولة «{name}» — راجع التفاصيل وردّ بالقبول أو الرفض",
                "americano_invite", americano.Id);

        await _points.EarnActivityAsync(
            creatorId, PointsTransactionType.TournamentOrganized, match.Id, null);

        return await GetByIdAsync(americano.Id);
    }

    /// <summary>
    /// يتحقق لكل ملعب وكل يوم من دوامه وخلوّه وعدم إغلاقه، ويعيد مجموع سعر
    /// النافذة اليومية على كل الملاعب والأيام.
    /// </summary>
    private async Task<decimal> ValidateAndPriceAsync(
        IReadOnlyList<Court> courts, DateTime firstDay, DateTime lastDay,
        TimeSpan timeOfDay, int windowMinutes, int? excludeMatchId)
    {
        var total = 0m;
        foreach (var court in courts)
        {
            var occupied = await CourtOccupancy.ForCourtAsync(
                _db, court.Id, firstDay.Add(timeOfDay),
                lastDay.Add(timeOfDay).AddMinutes(windowMinutes), excludeMatchId);
            var blocked = await _db.CourtBlockedSlots
                .Where(s => s.CourtId == court.Id && s.Date >= firstDay && s.Date <= lastDay)
                .Select(s => new { s.Date, s.Hour })
                .ToListAsync();

            for (var day = firstDay; day <= lastDay; day = day.AddDays(1))
            {
                var dayStart = day.Add(timeOfDay);
                var dayEnd = dayStart.AddMinutes(windowMinutes);
                total += CourtSchedule.BookingPrice(court, dayStart, windowMinutes);

                if (!CourtSchedule.IsWithinOpeningHours(court, dayStart, windowMinutes))
                    throw new AuthException(
                        "Selected time is outside opening hours",
                        $"الوقت المختار خارج ساعات عمل {court.Name} يوم {day:yyyy-MM-dd}",
                        "OUTSIDE_OPENING_HOURS");
                if (CourtOccupancy.Overlaps(occupied, dayStart, dayEnd))
                    throw new AuthException(
                        "This slot is already booked",
                        $"{court.Name} محجوز في هذا الوقت يوم {day:yyyy-MM-dd}", "SLOT_TAKEN");
                var hours = Enumerable.Range(dayStart.Hour,
                    Math.Max(1, (int)Math.Ceiling((dayEnd - dayStart).TotalHours)));
                if (blocked.Any(s => s.Date == day && hours.Contains(s.Hour)))
                    throw new AuthException(
                        "Slot is unavailable",
                        $"{court.Name} غير متاح في هذا الوقت يوم {day:yyyy-MM-dd}", "SLOT_UNAVAILABLE");
            }
        }
        return total;
    }

    // ── Draw ──────────────────────────────────────────────────────────────────

    public async Task<bool> TryDrawAsync(int americanoId)
    {
        var a = await LoadAsync(americanoId, track: true);
        if (a.Format == null || a.DrawnAt != null || a.Fixtures.Count > 0) return false;

        var m = a.Match;
        if (m.Status is not (MatchStatus.Open or MatchStatus.Full)) return false;

        var teamCount = TeamCountOf(m);
        var complete = CompleteTeams(m);
        if (complete.Count < teamCount) return false;

        // طلبان متزامنان (آخر انضمامين، أو قراءتان للصفحة) قد يصلان هنا معاً:
        // واحد فقط يحجز القرعة، والآخر يتراجع.
        if (!await ClaimDrawAsync(a.Id)) return false;
        try
        {
            await DrawAsync(a, complete);
        }
        catch (AuthException ex) when (ex.Code == ScheduleTooSmallCode)
        {
            // القرعة التلقائية تجري داخل الانضمام والقراءة: لا تُفشلهما، تبقى
            // البطولة بلا قرعة ويظهر الخطأ للمنظّم حين يبدأ يدوياً.
            await ReleaseDrawAsync(a.Id);
            return false;
        }
        catch
        {
            await ReleaseDrawAsync(a.Id);
            throw;
        }
        return true;
    }

    private const string ScheduleTooSmallCode = "TOURNAMENT_SCHEDULE_TOO_SMALL";

    private static void EnsureAllScheduled(int unscheduled)
    {
        if (unscheduled > 0)
            throw new AuthException(
                $"{unscheduled} match(es) did not fit the tournament schedule",
                $"تعذّرت القرعة: {unscheduled} مباراة لا تتّسع في جدول البطولة — " +
                "أجّل البطولة أو تواصل مع الدعم", ScheduleTooSmallCode);
    }

    /// <summary>كم مباراة من قرعة بـ<paramref name="teams"/> فريقاً لن تجد خانة
    /// (محاكاة التوزيع نفسه قبل أي استرداد أو حذف).</summary>
    private static int UnscheduledCount(AmericanoMatch a, int teams)
    {
        var m = a.Match;
        var format = a.Format ?? TournamentFormat.GroupsKnockout;
        if (teams < TournamentEngine.MinTeams) format = TournamentFormat.Knockout;
        var fits = TournamentEngine.SchedulableMatches(format, teams,
            m.ScheduledAt.Date, (a.EndDate ?? m.ScheduledAt).Date, m.ScheduledAt.TimeOfDay,
            m.DurationMinutes, a.MatchMinutes, AllCourtIds(a).Count);
        return Math.Max(0, TournamentEngine.TotalMatches(format, teams) - fits);
    }

    /// <summary>حجز ذرّي للقرعة في القاعدة: يضع DrawnAt إن كان فارغاً، ويعيد
    /// false إن سبقه طلب آخر.</summary>
    private async Task<bool> ClaimDrawAsync(int americanoId) =>
        await _db.AmericanoMatches
            .Where(x => x.Id == americanoId && x.DrawnAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.DrawnAt, DateTime.UtcNow)) == 1;

    /// <summary>فشلت القرعة بعد حجزها: تُفكّ ليعيدها الطلب التالي.</summary>
    private Task ReleaseDrawAsync(int americanoId) =>
        _db.AmericanoMatches
            .Where(x => x.Id == americanoId && !x.Fixtures.Any())
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.DrawnAt, (DateTime?)null));

    /// <summary>القرعة الفعلية: خلط الفرق، بناء المجموعات والشجرة، وتوزيع
    /// المباريات على الملاعب والمواعيد.</summary>
    private async Task DrawAsync(AmericanoMatch a, List<int> teams)
    {
        var m = a.Match;
        var shuffled = teams.OrderBy(_ => Random.Shared.Next()).ToList();
        var draw = TournamentEngine.BuildDraw(a.Id, a.Format ?? TournamentFormat.GroupsKnockout, shuffled);

        var slots = TournamentEngine.Slots(
            m.ScheduledAt.Date, (a.EndDate ?? m.ScheduledAt).Date, m.ScheduledAt.TimeOfDay,
            m.DurationMinutes, a.MatchMinutes, AllCourtIds(a));
        TournamentEngine.AssignSlots(draw.Phases, slots, a.MatchMinutes);
        // كل مباراة يجب أن تجد ملعباً وموعداً؛ وإلا تفشل القرعة صراحةً بدل
        // مباريات بلا موعد لا يراها أحد.
        EnsureAllScheduled(draw.Fixtures.Count(f => !f.IsBye && f.ScheduledAt == null));
        a.Format = draw.Format;

        _db.TournamentFixtures.AddRange(draw.Fixtures);
        a.DrawnAt = DateTime.UtcNow;
        a.TotalRounds = draw.Fixtures.Count(f => !f.IsBye);
        m.Status = MatchStatus.Full;
        m.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        foreach (var userId in Recipients(m))
            await _notifications.PushAsync(userId, "أُجريت قرعة البطولة",
                $"اكتمل عدد الفرق في «{a.Name}» وتشكّلت المجموعات والمباريات — راجع جدولك",
                "tournament_draw", a.Id);
    }

    // ── Scores ────────────────────────────────────────────────────────────────

    /// <summary>
    /// أحد لاعبي الفريقين يُدخل نتيجة المباراة فتُحفظ مقترحةً، ولا تُعتمد (تأهّل،
    /// ترتيب، نقاط مستوى) حتى يؤكدها لاعب من الفريق الآخر. إدخال الفريق الآخر
    /// للنتيجة نفسها تأكيد.
    /// </summary>
    public async Task<TournamentDto> SubmitFixtureScoreAsync(
        int userId, int fixtureId, SubmitFixtureScoreRequest req)
    {
        var fixture = await LoadFixtureAsync(fixtureId);
        var a = fixture.AmericanoMatch;
        var m = a.Match;
        var side = FixtureSide(fixture, m, userId) ?? throw ScoreProposals.NotAPlayer();
        // لا نتيجة لمباراة لم يحن موعدها (كالمباريات العادية والأمريكانو).
        if ((fixture.ScheduledAt ?? m.ScheduledAt) > AppClock.Now)
            throw new AuthException(
                "This match hasn't started yet",
                "لا يمكن إدخال نتيجة مباراة لم يبدأ موعدها", "MATCH_NOT_STARTED");
        if (req.Team1Score == req.Team2Score)
            throw new AuthException(
                "A tournament match needs a winner", "لا تعادل في البطولة — حدّد فائزاً", "TOURNAMENT_NO_DRAW");

        if (fixture.IsSameAsProposal(req.Team1Score, req.Team2Score)
            && FixtureSide(fixture, m, fixture.ProposedById) != side)
            return await ConfirmFixtureAsync(fixture, userId);

        fixture.Propose(userId, req.Team1Score, req.Team2Score);
        fixture.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        var name = PlayerName(m, userId);
        var other = side == 1 ? fixture.Team2!.Value : fixture.Team1!.Value;
        foreach (var uid in TeamRosters(m).GetValueOrDefault(other, []))
            await _notifications.PushAsync(uid, "أكّد نتيجة المباراة",
                $"أدخل {name} نتيجة مباراتكم في «{a.Name}»: {req.Team1Score} - {req.Team2Score} — أكّدها أو ارفضها",
                "tournament_result_proposed", a.Id);

        return await GetByIdAsync(a.Id);
    }

    /// <summary>لاعب من الفريق الآخر يؤكد النتيجة المقترحة (فتُعتمد) أو يرفضها.</summary>
    public async Task<TournamentDto> RespondFixtureScoreAsync(int userId, int fixtureId, RespondResultRequest req)
    {
        var fixture = await LoadFixtureAsync(fixtureId, requireOpen: req.Accept);
        var a = fixture.AmericanoMatch;
        var m = a.Match;
        ScoreProposals.EnsureCanRespond(
            fixture, FixtureSide(fixture, m, userId), FixtureSide(fixture, m, fixture.ProposedById), req);

        if (req.Accept) return await ConfirmFixtureAsync(fixture, userId);

        var proposerId = fixture.ProposedById!.Value;
        fixture.Reject();
        fixture.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        await _notifications.PushAsync(proposerId, "رُفضت نتيجة المباراة",
            $"رفض {PlayerName(m, userId)} النتيجة التي أدخلتها في «{a.Name}» — أدخلوا النتيجة الصحيحة أو يحسمها المنظّم",
            "tournament_result_rejected", a.Id);
        if (m.CreatorId != userId && m.CreatorId != proposerId)
            await _notifications.PushAsync(m.CreatorId, "خلاف على نتيجة مباراة",
                $"رفض {PlayerName(m, userId)} نتيجة مباراة في «{a.Name}» — يمكنك حسمها كمنظّم",
                "tournament_result_disputed", a.Id);
        return await GetByIdAsync(a.Id);
    }

    /// <summary>المنظّم يحسم خلافاً على نتيجة مباراة بإدخالها نهائيةً بلا تأكيد.</summary>
    public async Task<TournamentDto> ResolveFixtureScoreAsync(
        int userId, int fixtureId, SubmitFixtureScoreRequest req)
    {
        var fixture = await LoadFixtureAsync(fixtureId);
        var a = fixture.AmericanoMatch;
        var m = a.Match;
        ScoreProposals.EnsureCanResolve(fixture, userId, m.CreatorId);
        if (req.Team1Score == req.Team2Score)
            throw new AuthException(
                "A tournament match needs a winner", "لا تعادل في البطولة — حدّد فائزاً", "TOURNAMENT_NO_DRAW");

        var players = new[] { fixture.Team1!.Value, fixture.Team2!.Value }
            .SelectMany(t => TeamRosters(m).GetValueOrDefault(t, []))
            .Where(u => u != userId).ToList();
        fixture.Propose(userId, req.Team1Score, req.Team2Score);
        var dto = await ConfirmFixtureAsync(fixture, userId);

        foreach (var uid in players)
            await _notifications.PushAsync(uid, "حسم المنظّم نتيجة المباراة",
                $"اعتمد المنظّم نتيجة مباراتكم في «{a.Name}»: {req.Team1Score} - {req.Team2Score}",
                "tournament_result_resolved", a.Id);
        return dto;
    }

    /// <summary>
    /// المنظّم يسجّل نتيجة مباراة لم تُعتمد بعد مرور موعدها — لم يُدخلها أحد،
    /// أو بقي اقتراحها بلا ردّ، أو غاب فريق (انسحاب بعد القرعة) فيُحسب
    /// للآخر فوز إداري. تُعتمد نهائيةً ويتقدّم الفائز بالمسار نفسه؛ الفوز
    /// الإداري لا يمنح نقاط مستوى لأن المباراة لم تُلعب.
    /// </summary>
    public async Task<TournamentDto> RecordFixtureResultAsync(
        int userId, int fixtureId, OrganizerFixtureResultRequest req)
    {
        var fixture = await LoadFixtureAsync(fixtureId);
        var a = fixture.AmericanoMatch;
        var m = a.Match;
        EnsureOrganizer(a, userId);
        if (fixture.IsCompleted)
            throw new AuthException(
                "This result is already confirmed",
                "نتيجة هذه المباراة معتمدة بالفعل", "FIXTURE_ALREADY_COMPLETED");
        if ((fixture.ScheduledAt ?? m.ScheduledAt) > AppClock.Now)
            throw new AuthException(
                "The match time has not passed yet",
                "لم يحن موعد المباراة بعد — يسجّل المنظّم النتيجة بعد موعدها", "FIXTURE_NOT_STARTED");
        if (req.Team1Score == req.Team2Score)
            throw new AuthException(
                "A tournament match needs a winner", "لا تعادل في البطولة — حدّد فائزاً", "TOURNAMENT_NO_DRAW");

        var players = new[] { fixture.Team1!.Value, fixture.Team2!.Value }
            .SelectMany(t => TeamRosters(m).GetValueOrDefault(t, []))
            .Where(u => u != userId).ToList();
        fixture.Propose(userId, req.Team1Score, req.Team2Score);
        var dto = await ConfirmFixtureAsync(fixture, userId, applyLevelPoints: !req.Walkover);

        var text = req.Walkover
            ? $"سجّل المنظّم فوزاً إدارياً لفريق {TeamName(a, fixture.WinnerTeam!.Value)} في مباراتكم في «{a.Name}»"
            : $"سجّل المنظّم نتيجة مباراتكم في «{a.Name}»: {req.Team1Score} - {req.Team2Score}";
        foreach (var uid in players)
            await _notifications.PushAsync(uid, "سجّل المنظّم نتيجة المباراة", text,
                "tournament_result_resolved", a.Id);
        return dto;
    }

    /// <summary>اعتماد النتيجة المقترحة: الفائز يتقدّم وتُحتسب نقاط المستوى.</summary>
    private async Task<TournamentDto> ConfirmFixtureAsync(
        TournamentFixture fixture, int confirmerId, bool applyLevelPoints = true)
    {
        var a = fixture.AmericanoMatch;
        var m = a.Match;
        var s1 = fixture.ProposedTeam1Score!.Value;
        var s2 = fixture.ProposedTeam2Score!.Value;
        var proposerId = fixture.ProposedById!.Value;

        var isCorrection = fixture.IsCompleted;
        fixture.Team1Score = s1;
        fixture.Team2Score = s2;
        fixture.IsCompleted = true;
        fixture.WinnerTeam = s1 > s2 ? fixture.Team1 : fixture.Team2;
        fixture.ClearProposal();
        fixture.IsDisputed = false;
        fixture.UpdatedAt = DateTime.UtcNow;
        if (m.Status == MatchStatus.Full) m.Status = MatchStatus.InProgress;

        if (fixture.Stage == TournamentStage.Knockout)
        {
            var (r, i, first) = TournamentEngine.NextSlot(fixture.Round, fixture.Index);
            var next = a.Fixtures.FirstOrDefault(
                f => f.Stage == TournamentStage.Knockout && f.Round == r && f.Index == i);
            if (next != null)
            {
                if (first) next.Team1 = fixture.WinnerTeam; else next.Team2 = fixture.WinnerTeam;
                // تغيّر طرف المباراة التالية فلا يبقى اقتراح نتيجة لطرفها القديم.
                next.ClearProposal();
            }
            else
            {
                // لا مباراة بعد النهائي: البطل معروف.
                a.IsCompleted = true;
                m.Status = MatchStatus.Completed;
            }
        }
        else if (a.Fixtures.Where(f => f.Stage == TournamentStage.Group).All(f => f.IsCompleted))
        {
            FillKnockoutFromGroups(a);
            // نتائج المجموعات أُقفلت: لا معنى لتصحيح معلّق عليها.
            foreach (var f in a.Fixtures.Where(f => f.Stage == TournamentStage.Group))
                f.ClearProposal();
        }

        await _db.SaveChangesAsync();

        var rosters = TeamRosters(m);
        // تصحيح نتيجة: تُلغى نقاط المستوى السابقة ثم تُحسب من النتيجة الجديدة.
        if (isCorrection)
            await _points.ReverseLevelPointsAsync(PointsTransactionType.LevelTournamentFixture, fixture.Id);
        if (applyLevelPoints)
            await _points.ApplyLevelPointsAsync(
                rosters.GetValueOrDefault(fixture.Team1!.Value, []),
                rosters.GetValueOrDefault(fixture.Team2!.Value, []),
                s1, s2,
                PointsTransactionType.LevelTournamentFixture, fixture.Id,
                $"نقاط مستوى — بطولة «{a.Name}»");

        if (proposerId != confirmerId)
            await _notifications.PushAsync(proposerId, "اعتُمدت نتيجة المباراة",
                $"أكّد {PlayerName(m, confirmerId)} نتيجة مباراتكم في «{a.Name}»: {s1} - {s2}",
                "tournament_result_confirmed", a.Id);

        if (a.IsCompleted)
        {
            var champion = fixture.WinnerTeam!.Value;
            foreach (var uid in Recipients(m))
                await _notifications.PushAsync(uid, "انتهت البطولة",
                    $"تُوِّج فريق {TeamName(a, champion)} ({PlayerNames(m, champion)}) بلقب «{a.Name}» — راجع الترتيب النهائي",
                    "tournament_completed", a.Id);
        }

        return await GetByIdAsync(a.Id);
    }

    /// <summary>
    /// تحميل مباراة البطولة مع التحقق أنها قابلة للتسجيل: طرفاها معروفان، والبطولة
    /// غير ملغاة، ونتيجتها لم تُقفل بما بعدها. يكفي للرفض وجود المباراة.
    /// </summary>
    private async Task<TournamentFixture> LoadFixtureAsync(int fixtureId, bool requireOpen = true)
    {
        var fixture = await _db.TournamentFixtures
            .Include(f => f.AmericanoMatch).ThenInclude(a => a.Match).ThenInclude(m => m.MatchPlayers)
                .ThenInclude(p => p.User)
            .Include(f => f.AmericanoMatch).ThenInclude(a => a.Fixtures)
            .Include(f => f.AmericanoMatch).ThenInclude(a => a.TeamNames)
            .FirstOrDefaultAsync(f => f.Id == fixtureId)
            ?? throw new AuthException("Match not found", "المباراة غير موجودة", "FIXTURE_NOT_FOUND");
        if (!requireOpen) return fixture;

        var a = fixture.AmericanoMatch;
        if (a.Match.Status is MatchStatus.Cancelled)
            throw new AuthException("Tournament is cancelled", "البطولة ملغاة", "MATCH_CLOSED");
        if (fixture.IsBye || fixture.Team1 is null || fixture.Team2 is null)
            throw new AuthException(
                "Both teams are not known yet", "لم يُعرف طرفا المباراة بعد", "FIXTURE_NOT_READY");
        if (IsLocked(fixture, a.Fixtures))
            throw new AuthException(
                "This result can no longer be changed",
                "لا يمكن تعديل هذه النتيجة بعد اعتماد ما بعدها", "FIXTURE_LOCKED");
        return fixture;
    }

    /// <summary>طرف اللاعب في المباراة (1 أو 2) حسب فريقه في البطولة، أو null.</summary>
    private static int? FixtureSide(TournamentFixture f, Match m, int? userId)
    {
        var team = m.MatchPlayers.FirstOrDefault(
            p => p.UserId == userId && p.Status == MatchPlayerStatus.Approved)?.Team;
        return team is null ? null
            : team == f.Team1 ? 1
            : team == f.Team2 ? 2
            : null;
    }

    private static string PlayerName(Match m, int? userId) =>
        m.MatchPlayers.FirstOrDefault(p => p.UserId == userId)?.User is { } u
            ? $"{u.FirstName} {u.LastName}".Trim()
            : "لاعب";

    /// <summary>نتيجة مجموعات تُقفل حين تُملأ الإقصائيات؛ ونتيجة إقصائية تُقفل
    /// حين تُعتمد المباراة التالية.</summary>
    private static bool IsLocked(TournamentFixture f, IEnumerable<TournamentFixture> all)
    {
        if (f.Stage == TournamentStage.Group)
            return all.Any(x => x.Stage == TournamentStage.Knockout && x.Round == 1
                                && (x.Team1 != null || x.Team2 != null));
        var (r, i, _) = TournamentEngine.NextSlot(f.Round, f.Index);
        return all.Any(x => x.Stage == TournamentStage.Knockout && x.Round == r && x.Index == i
                            && x.IsCompleted);
    }

    /// <summary>اكتملت المجموعات: المتأهلون يملؤون الدور الإقصائي الأول.</summary>
    private static void FillKnockoutFromGroups(AmericanoMatch a)
    {
        var plan = TournamentEngine.PlanGroups(TeamCountOf(a.Match));
        var groupOf = GroupOf(a.Fixtures);
        var tables = Enumerable.Range(0, plan.GroupCount)
            .Select(g => TournamentEngine.GroupTable(
                groupOf.Where(kv => kv.Value == g).Select(kv => kv.Key),
                a.Fixtures.Where(f => f.Stage == TournamentStage.Group && f.GroupIndex == g)))
            .ToList();
        var seeds = TournamentEngine.Qualifiers(tables, plan);
        var pairs = TournamentEngine.FirstRoundPairs(
            seeds, plan.KnockoutSize, t => groupOf.TryGetValue(t, out var g) ? g : null);

        var first = a.Fixtures
            .Where(f => f.Stage == TournamentStage.Knockout && f.Round == 1)
            .OrderBy(f => f.Index).ToList();
        for (var i = 0; i < first.Count && i < pairs.Count; i++)
        {
            first[i].Team1 = pairs[i].A;
            first[i].Team2 = pairs[i].B;
        }
    }

    // ── Organizer actions ─────────────────────────────────────────────────────

    public async Task<TournamentDto> StartWithCurrentAsync(int userId, int id)
    {
        var a = await LoadAsync(id, track: true);
        var m = a.Match;
        EnsureOrganizer(a, userId);
        if (a.DrawnAt != null)
            throw new AuthException("Draw already done", "أُجريت القرعة بالفعل", "TOURNAMENT_DRAWN");
        if (m.Status is not (MatchStatus.Open or MatchStatus.Full))
            throw new AuthException(
                "Tournament is not open", "البطولة ليست مفتوحة للتسجيل", "MATCH_CLOSED");

        var complete = CompleteTeams(m);
        if (complete.Count < TournamentEngine.MinStartTeams)
            throw new AuthException(
                $"At least {TournamentEngine.MinStartTeams} complete teams are needed",
                $"تحتاج فريقين مكتملين على الأقل للبدء (المكتمل الآن {complete.Count})",
                "TOURNAMENT_TOO_FEW_TEAMS");

        // يُحجز قبل أي استرداد أو حذف: ضغطتان متزامنتان على «ابدأ» كانتا تردّان
        // للفرق الناقصة مرتين.
        if (!await ClaimDrawAsync(a.Id))
            throw new AuthException("Draw already done", "أُجريت القرعة بالفعل", "TOURNAMENT_DRAWN");
        try
        {
            await StartAndDrawAsync(a, complete);
        }
        catch
        {
            await ReleaseDrawAsync(a.Id);
            throw;
        }
        return await GetByIdAsync(a.Id);
    }

    private async Task StartAndDrawAsync(AmericanoMatch a, List<int> complete)
    {
        var m = a.Match;
        // الجدول يتّسع للقرعة قبل ردّ أي حصة أو حذف أي فريق.
        EnsureAllScheduled(UnscheduledCount(a, complete.Count));

        // الفرق الناقصة تُحذف ويُردّ لمن دفع فيها.
        var dropped = m.MatchPlayers.Where(p => p.Team is int t && !complete.Contains(t)).ToList();
        foreach (var p in dropped)
        {
            if (p.HasPaid) await RefundShareAsync(m, p, "استرداد حصة بطولة — لم يكتمل فريقك");
            _db.MatchPlayers.Remove(p);
        }

        // إعادة ترقيم الفرق المكتملة 1..k حتى تبقى الأرقام متتابعة.
        var renumber = complete.OrderBy(t => t).Select((t, i) => (Old: t, New: i + 1))
            .ToDictionary(x => x.Old, x => x.New);
        foreach (var p in m.MatchPlayers.Except(dropped))
            if (p.Team is int t && renumber.TryGetValue(t, out var n)) p.Team = n;
        // الأسماء المخصّصة تتبع فرقها إلى أرقامها الجديدة، وأسماء المحذوفة تُحذف.
        foreach (var tn in a.TeamNames.ToList())
        {
            if (renumber.TryGetValue(tn.Team, out var n)) tn.Team = n;
            else _db.TournamentTeamNames.Remove(tn);
        }
        m.MaxPlayers = complete.Count * TournamentEngine.PlayersPerTeam;
        await _db.SaveChangesAsync();

        foreach (var p in dropped)
            await _notifications.PushAsync(p.UserId, "بدأت البطولة بدونك",
                $"بدأ منظّم «{a.Name}» بالفرق المكتملة ولم يكتمل فريقك — أُعيد ما دفعته إلى محفظتك",
                "tournament_dropped", a.Id);

        await DrawAsync(a, renumber.Values.ToList());
    }

    public async Task<TournamentDto> PostponeAsync(int userId, int id, DateTime newStart)
    {
        // لا انضمام يتسلل بين فحص الحالة وتغيير الموعد.
        await using var gate = await MatchLock.AcquireAsync(_db, await MatchIdOfAsync(id));
        var a = await LoadAsync(id, track: true);
        var m = a.Match;
        EnsureOrganizer(a, userId);
        if (m.Status is MatchStatus.Cancelled or MatchStatus.Completed || a.IsCompleted)
            throw new AuthException("Tournament is closed", "البطولة منتهية أو ملغاة", "MATCH_CLOSED");
        if (newStart <= AppClock.Now)
            throw new AuthException(
                "Selected time has already passed",
                "الوقت المختار مضى — اختر موعداً قادماً", "SLOT_IN_PAST");

        var delta = newStart - m.ScheduledAt;
        var firstDay = newStart.Date;
        // عدد الأيام يبقى كما هو: النهاية تنزاح بفرق الأيام لا بفرق الساعات
        // (موعد أبكر في اليوم كان يقصّ آخر يوم من البطولة).
        var lastDay = (a.EndDate ?? m.ScheduledAt).Date + (firstDay - m.ScheduledAt.Date);

        var courts = await LoadCourtsAsync(AllCourtIds(a));
        await ValidateAndPriceAsync(courts, firstDay, lastDay, newStart.TimeOfDay,
            m.DurationMinutes, m.Id);

        m.ScheduledAt = newStart;
        m.UpdatedAt = DateTime.UtcNow;
        a.EndDate = lastDay > firstDay ? lastDay : null;
        a.IncompleteNoticeSentAt = null;
        // الموعد تغيّر: تذكير «تبدأ خلال 30 دقيقة» يُرسل من جديد للموعد الجديد.
        m.ReminderSentAt = null;
        // ما لُعب (أو أُعفي) يبقى بموعده الفعلي؛ تنزاح المباريات المتبقية فقط.
        foreach (var f in a.Fixtures.Where(f => f.ScheduledAt != null && !f.IsCompleted))
            f.ScheduledAt = f.ScheduledAt!.Value.Add(delta);
        await _db.SaveChangesAsync();

        foreach (var uid in Recipients(m).Where(u => u != userId))
            await _notifications.PushAsync(uid, "تأجّلت البطولة",
                $"أجّل المنظّم «{a.Name}» إلى {newStart:yyyy-MM-dd} الساعة {newStart:HH:mm}",
                "tournament_postponed", a.Id);
        var ownerId = m.Court?.Venue.OwnerId;
        if (ownerId is int owner && owner != userId && !Recipients(m).Contains(owner))
            await _notifications.PushAsync(owner, "تأجّلت بطولة على ملعبك",
                $"انتقلت «{a.Name}» إلى {newStart:yyyy-MM-dd} الساعة {newStart:HH:mm}",
                "tournament_postponed", a.Id);

        return await GetByIdAsync(a.Id);
    }

    public async Task<TournamentDto> CancelAsync(int userId, int id)
    {
        // لا انضمام أو قبول يتسلل بين ردّ الحصص وتعليم البطولة ملغاة.
        await using var gate = await MatchLock.AcquireAsync(_db, await MatchIdOfAsync(id));
        var a = await LoadAsync(id, track: true);
        var m = a.Match;
        EnsureOrganizer(a, userId);
        if (m.Status is MatchStatus.Cancelled or MatchStatus.Completed || a.IsCompleted)
            throw new AuthException(
                "Tournament cannot be cancelled", "لا يمكن إلغاء بطولة منتهية أو ملغاة",
                "MATCH_NOT_CANCELLABLE");

        await _matches.RefundAllPaidAsync(m, $"استرداد حصة بطولة «{a.Name}» — أُلغيت");
        m.Status = MatchStatus.Cancelled;
        m.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        foreach (var uid in Recipients(m).Where(u => u != userId))
            await _notifications.PushAsync(uid, "أُلغيت البطولة",
                $"ألغى المنظّم «{a.Name}» وأُعيد ما دفعته إلى محفظتك",
                "tournament_cancelled", a.Id);
        var ownerId = m.Court?.Venue.OwnerId;
        if (ownerId is int owner && owner != userId && !Recipients(m).Contains(owner))
            await _notifications.PushAsync(owner, "أُلغيت بطولة على ملعبك",
                $"ألغى المنظّم «{a.Name}» فتحرّرت مواعيدها",
                "tournament_cancelled", a.Id);

        return await GetByIdAsync(a.Id);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static TournamentFormat ParseFormat(string? format) =>
        format?.Trim().ToLowerInvariant() switch
        {
            "knockout" => TournamentFormat.Knockout,
            "groups" or null or "" => TournamentFormat.GroupsKnockout,
            _ => throw new AuthException(
                "Unknown tournament format", "نظام البطولة غير معروف", "TOURNAMENT_BAD_FORMAT"),
        };

    private async Task<List<Court>> LoadCourtsAsync(IReadOnlyList<int> ids)
    {
        var distinct = ids.Distinct().ToList();
        if (distinct.Count == 0)
            throw new AuthException("Pick at least one court", "اختر ملعباً واحداً على الأقل", "COURT_REQUIRED");

        var courts = await _db.Courts
            .NotDeleted()
            .Include(c => c.Venue)
            .Include(c => c.PriceTiers)
            .Include(c => c.OpeningHours)
            .Include(c => c.PriceRules)
            .Where(c => distinct.Contains(c.Id) && c.Venue.IsApproved)
            .ToListAsync();
        if (courts.Count != distinct.Count)
            throw new AuthException("Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");
        if (courts.Select(c => c.VenueId).Distinct().Count() > 1)
            throw new AuthException(
                "All courts must belong to one venue",
                "ملاعب البطولة يجب أن تكون في منشأة واحدة", "TOURNAMENT_COURTS_MIXED");

        // بترتيب الطلب: الأول رئيسي.
        return distinct.Select(id => courts.First(c => c.Id == id)).ToList();
    }

    /// <summary>معرّف المباراة الأم للبطولة — لأخذ قفل الحدث قبل تحميله.</summary>
    private async Task<int> MatchIdOfAsync(int id) =>
        await _db.AmericanoMatches.Where(a => a.Id == id).Select(a => (int?)a.MatchId)
            .FirstOrDefaultAsync()
        ?? throw new AuthException("Tournament not found", "البطولة غير موجودة", "TOURNAMENT_NOT_FOUND");

    private async Task<AmericanoMatch> LoadAsync(int id, bool track)
    {
        IQueryable<AmericanoMatch> q = _db.AmericanoMatches
            .Include(a => a.Match).ThenInclude(m => m.MatchPlayers).ThenInclude(p => p.User)
                .ThenInclude(u => u.PlayerProfile)
            .Include(a => a.Match).ThenInclude(m => m.Court)
                .ThenInclude(c => c!.Venue).ThenInclude(v => v.CityRef)
            .Include(a => a.Fixtures).ThenInclude(f => f.Court)
            .Include(a => a.Courts).ThenInclude(c => c.Court)
            .Include(a => a.TeamNames);
        if (!track) q = q.AsNoTracking();
        return await q.FirstOrDefaultAsync(a => a.Id == id)
            ?? throw new AuthException("Tournament not found", "البطولة غير موجودة", "TOURNAMENT_NOT_FOUND");
    }

    private static void EnsureOrganizer(AmericanoMatch a, int userId)
    {
        if (a.Format == null)
            throw new AuthException("Not a tournament", "ليست بطولة إقصائية", "NOT_A_TOURNAMENT");
        if (a.Match.CreatorId != userId)
            throw new AuthException(
                "Only the organizer can do this", "هذا الإجراء لمنظّم البطولة فقط", "NOT_TOURNAMENT_CREATOR");
    }

    private static int TeamCountOf(Match m) =>
        Math.Max(1, m.MaxPlayers / TournamentEngine.PlayersPerTeam);

    /// <summary>أرقام الفرق التي اكتمل لاعباها المعتمدان.</summary>
    private static List<int> CompleteTeams(Match m) => m.MatchPlayers
        .Where(p => p.Status == MatchPlayerStatus.Approved && p.Team is int)
        .GroupBy(p => p.Team!.Value)
        .Where(g => g.Count() >= TournamentEngine.PlayersPerTeam)
        .Select(g => g.Key)
        .OrderBy(t => t)
        .ToList();

    private static Dictionary<int, List<int>> TeamRosters(Match m) => m.MatchPlayers
        .Where(p => p.Status == MatchPlayerStatus.Approved && p.Team is int)
        .GroupBy(p => p.Team!.Value)
        .ToDictionary(g => g.Key, g => g.Select(p => p.UserId).ToList());

    private static List<int> AllCourtIds(AmericanoMatch a)
    {
        var ids = new List<int>();
        if (a.Match.CourtId is int primary) ids.Add(primary);
        ids.AddRange(a.Courts.Select(c => c.CourtId).Where(id => !ids.Contains(id)));
        return ids;
    }

    /// <summary>فريق → رقم مجموعته، من مباريات دور المجموعات.</summary>
    private static Dictionary<int, int> GroupOf(IEnumerable<TournamentFixture> fixtures)
    {
        var map = new Dictionary<int, int>();
        foreach (var f in fixtures.Where(f => f.Stage == TournamentStage.Group && f.GroupIndex is int))
        {
            if (f.Team1 is int a) map[a] = f.GroupIndex!.Value;
            if (f.Team2 is int b) map[b] = f.GroupIndex!.Value;
        }
        return map;
    }

    /// <summary>اسم الفريق المعروض: ما سمّاه به لاعبوه/المنظّم، وإلا حرفه (A، B…).</summary>
    private static string TeamName(AmericanoMatch a, int team) =>
        a.TeamNames.FirstOrDefault(t => t.Team == team)?.Name
        ?? TournamentEngine.TeamLetter(team);

    /// <summary>«فلان و فلان» — لاعبا الفريق المعتمدان.</summary>
    private static string PlayerNames(Match m, int team) => string.Join(" و ", m.MatchPlayers
        .Where(p => p.Team == team && p.Status == MatchPlayerStatus.Approved)
        .OrderBy(p => p.JoinedAt)
        .Select(p => $"{p.User.FirstName} {p.User.LastName}".Trim())
        .Where(n => n.Length > 0));

    public async Task<TournamentDto> RenameTeamAsync(int userId, int id, int team, string? name)
    {
        var a = await LoadAsync(id, track: true);
        var m = a.Match;
        if (a.Format == null)
            throw new AuthException("Not a tournament", "ليست بطولة إقصائية", "NOT_A_TOURNAMENT");
        if (team < 1 || team > TeamCountOf(m))
            throw new AuthException("Team not found", "الفريق غير موجود", "TEAM_NOT_FOUND");
        if (m.Status == MatchStatus.Cancelled)
            throw new AuthException("Tournament is cancelled", "البطولة ملغاة", "MATCH_CLOSED");

        // يسمّي الفريقَ لاعبوه أو منظّم البطولة.
        var isMember = m.MatchPlayers.Any(p =>
            p.UserId == userId && p.Team == team && p.Status == MatchPlayerStatus.Approved);
        if (!isMember && m.CreatorId != userId)
            throw new AuthException(
                "Only the team's players or the organizer can rename it",
                "يسمّي الفريقَ لاعبوه أو منظّم البطولة فقط", "NOT_TEAM_MEMBER");

        var clean = string.Join(' ', (name ?? "").Split(' ', StringSplitOptions.RemoveEmptyEntries));
        if (clean.Length > TournamentEngine.MaxTeamNameLength)
            throw new AuthException(
                "Name is too long",
                $"اسم الفريق لا يتجاوز {TournamentEngine.MaxTeamNameLength} حرفاً", "TEAM_NAME_TOO_LONG");

        var existing = a.TeamNames.FirstOrDefault(t => t.Team == team);
        if (clean.Length == 0 || clean == TournamentEngine.TeamLetter(team))
        {
            // فارغ أو حرفه نفسه: يعود إلى الحرف.
            if (existing != null) _db.TournamentTeamNames.Remove(existing);
        }
        else
        {
            // لا يتكرر اسم فريقين في البطولة الواحدة (ولا حرف فريق آخر).
            var taken = Enumerable.Range(1, TeamCountOf(m))
                .Where(t => t != team)
                .Any(t => string.Equals(TeamName(a, t), clean, StringComparison.OrdinalIgnoreCase));
            if (taken)
                throw new AuthException(
                    "Another team already has this name",
                    "هذا الاسم مستخدم لفريق آخر في البطولة", "TEAM_NAME_TAKEN");

            if (existing != null) { existing.Name = clean; existing.UpdatedAt = DateTime.UtcNow; }
            else _db.TournamentTeamNames.Add(new TournamentTeamName
            {
                AmericanoMatchId = a.Id, Team = team, Name = clean,
            });
        }
        await _db.SaveChangesAsync();
        return await GetByIdAsync(a.Id);
    }

    private static List<int> Recipients(Match m) => m.MatchPlayers
        .Select(p => p.UserId).Append(m.CreatorId).Distinct().ToList();

    /// <summary>ردّ حصة لاعب واحد (الدفع فرديّ دائماً في البطولة) واسترداد ما
    /// وصل صاحب الملعب منها إن كان قد وصله.</summary>
    private async Task RefundShareAsync(Match m, MatchPlayer p, string reason)
    {
        if (m.PricePerPlayer <= 0) return;
        await _wallet.RefundAsync(p.UserId, m.ShareOf(p), reason, m.Id);
        var ownerCredited = m.CourtId != null && m.Status != MatchStatus.PendingApproval
                            && p.Status == MatchPlayerStatus.Approved;
        // عكس أرباح لا خصم مشروط بالرصيد: يُستردّ دائماً ولو صار رصيد المالك
        // سالباً، وإلا دفعت سبورتا الفرق من حصتها.
        if (ownerCredited && m.Court?.Venue.OwnerId is int owner)
            await _wallet.ReverseEarningAsync(
                owner, m.NetOfCommission(m.ShareOf(p)),
                WalletTransactionType.VenueEarning, reason, m.Id);
    }

    private async Task ValidatePartnerAsync(int inviterId, int targetId)
    {
        if (!await _db.Users.AnyAsync(u => u.Id == targetId))
            throw new AuthException("Player not found", "اللاعب غير موجود", "PLAYER_NOT_FOUND");
        var friends = await _db.Friendships.AnyAsync(f =>
            f.Status == FriendshipStatus.Accepted &&
            ((f.SenderId == inviterId && f.ReceiverId == targetId) ||
             (f.SenderId == targetId && f.ReceiverId == inviterId)));
        if (!friends)
            throw new AuthException(
                "You can only invite your friends", "يمكنك دعوة أصدقائك فقط", "NOT_FRIENDS");
    }
}
