using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

/// <summary>قراءة البطولة: تجميع الفرق والمجموعات والشجرة والترتيب النهائي في DTO واحد.</summary>
public partial class TournamentService
{
    public async Task<TournamentDto> GetByIdAsync(int id)
    {
        // بطولة على ملعب وافق عليها المالك وقد اكتمل عددها: قرعتها تُجرى عند
        // أول قراءة إن لم تُجرَ بعد.
        await TryDrawAsync(id);

        var a = await LoadAsync(id, track: false);
        if (a.Format == null)
            throw new AuthException("Not a tournament", "ليست بطولة إقصائية", "NOT_A_TOURNAMENT");

        var m = a.Match;
        var format = a.Format.Value;
        var teamCount = TeamCountOf(m);
        var players = m.MatchPlayers.ToDictionary(p => p.UserId, p => new AmericanoPlayerDto
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

        var groupOf = GroupOf(a.Fixtures);
        var teams = Enumerable.Range(1, teamCount).Select(t =>
        {
            var members = m.MatchPlayers.Where(p => p.Team == t).OrderBy(p => p.JoinedAt).ToList();
            var approved = members.Where(p => p.Status == MatchPlayerStatus.Approved).ToList();
            groupOf.TryGetValue(t, out var g);
            return new TournamentTeamDto
            {
                Number = t,
                Letter = TournamentEngine.TeamLetter(t),
                Name = TeamName(a, t),
                CustomName = a.TeamNames.FirstOrDefault(x => x.Team == t)?.Name,
                PlayerNames = PlayerNames(m, t),
                Players = members.Select(p => players[p.UserId]).ToList(),
                IsComplete = approved.Count >= TournamentEngine.PlayersPerTeam,
                GroupIndex = groupOf.ContainsKey(t) ? g : null,
                GroupLetter = groupOf.ContainsKey(t) ? TournamentEngine.GroupLetter(g) : null,
            };
        }).ToList();
        string NameOf(int? team) => team is int t
            ? teams.FirstOrDefault(x => x.Number == t)?.Name ?? TournamentEngine.TeamLetter(t)
            : "";
        string PlayersOf(int? team) => team is int t
            ? teams.FirstOrDefault(x => x.Number == t)?.PlayerNames ?? ""
            : "";

        // ── المجموعات ──
        var groups = new List<TournamentGroupDto>();
        TournamentEngine.GroupPlan? plan = null;
        var groupsDone = false;
        if (format == TournamentFormat.GroupsKnockout && a.DrawnAt != null)
        {
            plan = TournamentEngine.PlanGroups(teamCount);
            var groupFixtures = a.Fixtures.Where(f => f.Stage == TournamentStage.Group).ToList();
            groupsDone = groupFixtures.Count > 0 && groupFixtures.All(f => f.IsCompleted);
            var qualified = groupsDone
                ? a.Fixtures.Where(f => f.Stage == TournamentStage.Knockout && f.Round == 1)
                    .SelectMany(f => new[] { f.Team1, f.Team2 }).OfType<int>().ToHashSet()
                : [];
            for (var g = 0; g < plan.GroupCount; g++)
            {
                var members = groupOf.Where(kv => kv.Value == g).Select(kv => kv.Key).ToList();
                var mine = groupFixtures.Where(f => f.GroupIndex == g).ToList();
                var table = TournamentEngine.GroupTable(members, mine);
                groups.Add(new TournamentGroupDto
                {
                    Index = g,
                    Letter = TournamentEngine.GroupLetter(g),
                    Title = $"المجموعة {TournamentEngine.GroupLetter(g)}",
                    Played = mine.Count(f => f.IsCompleted),
                    Total = mine.Count,
                    Standings = table.Select(r => new TournamentGroupRowDto
                    {
                        Position = r.Position,
                        Team = r.Team,
                        Name = NameOf(r.Team),
                        PlayerNames = PlayersOf(r.Team),
                        Played = r.Played,
                        Wins = r.Wins,
                        Points = r.Points,
                        Diff = r.Diff,
                        Scored = r.Scored,
                        Qualified = qualified.Contains(r.Team),
                    }).ToList(),
                });
            }
        }

        // ── المباريات ──
        var knockoutSize = a.Fixtures.Count(f => f.Stage == TournamentStage.Knockout && f.Round == 1) * 2;
        var fixtures = a.Fixtures
            .OrderBy(f => f.Stage).ThenBy(f => f.Round).ThenBy(f => f.GroupIndex).ThenBy(f => f.Index)
            .Select(f =>
            {
                var isGroup = f.Stage == TournamentStage.Group;
                var teamsInRound = isGroup ? 0 : knockoutSize >> (f.Round - 1);
                var isFinal = !isGroup && teamsInRound == 2;
                var canScore = !f.IsBye && f.Team1 != null && f.Team2 != null
                               && m.Status != MatchStatus.Cancelled && !IsLocked(f, a.Fixtures);
                return new TournamentFixtureDto
                {
                    Id = f.Id,
                    Stage = isGroup ? "group" : "knockout",
                    GroupIndex = f.GroupIndex,
                    GroupLetter = f.GroupIndex is int gi ? TournamentEngine.GroupLetter(gi) : null,
                    Round = f.Round,
                    RoundName = isGroup ? $"الجولة {f.Round}" : TournamentEngine.RoundName(teamsInRound),
                    Index = f.Index,
                    Title = isFinal ? "المباراة النهائية" : $"مباراة {f.Index + 1}",
                    Team1 = f.Team1,
                    Team2 = f.Team2,
                    Team1Name = NameOf(f.Team1),
                    Team2Name = NameOf(f.Team2),
                    Team1Players = PlayersOf(f.Team1),
                    Team2Players = PlayersOf(f.Team2),
                    Team1Placeholder = f.Team1 is null ? Placeholder(f, true, format, teamsInRound) : null,
                    Team2Placeholder = f.Team2 is null ? Placeholder(f, false, format, teamsInRound) : null,
                    Team1Score = f.Team1Score,
                    Team2Score = f.Team2Score,
                    IsCompleted = f.IsCompleted,
                    IsBye = f.IsBye,
                    WinnerTeam = f.WinnerTeam,
                    CanScore = canScore,
                    // اقتراح على مباراة أُقفلت لا يمكن تأكيده فلا يُعرض.
                    IsDisputed = canScore && f.IsDisputed,
                    PendingResult = canScore
                        ? ScoreProposals.ToDto(f, FixtureSide(f, m, f.ProposedById), PlayerName(m, f.ProposedById))
                        : null,
                    CourtId = f.CourtId,
                    CourtName = f.Court?.Name,
                    ScheduledAt = f.ScheduledAt,
                };
            })
            .ToList();

        var courts = new List<TournamentCourtDto>();
        if (m.Court != null)
            courts.Add(new TournamentCourtDto { Id = m.Court.Id, Name = m.Court.Name, NameEn = m.Court.NameEn });
        courts.AddRange(a.Courts.Where(c => c.CourtId != m.CourtId)
            .Select(c => new TournamentCourtDto { Id = c.CourtId, Name = c.Court.Name, NameEn = c.Court.NameEn }));

        var champion = a.IsCompleted
            ? a.Fixtures.Where(f => f.Stage == TournamentStage.Knockout)
                .OrderByDescending(f => f.Round).FirstOrDefault()?.WinnerTeam
            : null;

        var quote = BuildQuote(format, teamCount, m.ScheduledAt,
            (a.EndDate ?? m.ScheduledAt).Date, m.DurationMinutes, a.MatchMinutes, courts.Count);

        return new TournamentDto
        {
            Id = a.Id,
            MatchId = m.Id,
            CreatorId = m.CreatorId,
            Name = a.Name ?? "",
            Format = format == TournamentFormat.Knockout ? "knockout" : "groups",
            Status = m.Status switch
            {
                MatchStatus.PendingApproval => "pendingApproval",
                MatchStatus.Open => "open",
                MatchStatus.Full => "full",
                MatchStatus.InProgress => "inProgress",
                MatchStatus.Completed => "completed",
                _ => "cancelled",
            },
            IsVenueHosted = m.IsHostedByVenueOwner,
            IsCompleted = a.IsCompleted,
            IsDrawn = a.DrawnAt != null,
            WithdrawalFreeUntil = WithdrawalPolicy.FreeUntil(m.ScheduledAt, isEvent: true),
            CanWithdrawDirectly = WithdrawalPolicy.IsFree(m.ScheduledAt, isEvent: true),
            ScheduledAt = m.ScheduledAt,
            EndDate = a.EndDate,
            DurationMinutes = m.DurationMinutes,
            MatchMinutes = a.MatchMinutes,
            TeamCount = teamCount,
            CompleteTeamCount = CompleteTeams(m).Count,
            MaxPlayers = m.MaxPlayers,
            MinLevel = a.MinAllowedLevel,
            MaxLevel = a.MaxAllowedLevel,
            PricePerPlayer = m.CourtId == null ? 0m : m.PricePerPlayer,
            CourtId = m.CourtId,
            VenueName = m.Court?.Venue.Name,
            VenueNameEn = m.Court?.Venue.NameEn,
            City = m.Court?.Venue.City,
            CityEn = m.Court?.Venue.CityRef?.NameEn,
            Courts = courts,
            GroupCount = plan?.GroupCount ?? quote.GroupCount,
            KnockoutSize = a.DrawnAt != null ? Math.Max(knockoutSize, 2) : quote.KnockoutSize,
            BestThirds = plan?.BestThirds ?? quote.BestThirds,
            TotalMatches = a.DrawnAt != null ? a.Fixtures.Count(f => !f.IsBye) : quote.TotalMatches,
            PlayedMatches = a.Fixtures.Count(f => f.IsCompleted && !f.IsBye),
            PathText = PathText(format, teamCount),
            Players = players.Values.ToList(),
            Teams = teams,
            Groups = groups,
            Fixtures = fixtures,
            Ranking = a.IsCompleted ? Ranking(a, teams, groups, knockoutSize) : [],
            ChampionTeam = champion,
            ChampionName = champion is int c ? NameOf(c) : null,
            ChampionPlayers = champion is int cp ? PlayersOf(cp) : null,
        };
    }

    /// <summary>وصف الطرف المجهول: «الفائز من ربع النهائي 2» أو «متأهل من المجموعات».</summary>
    private static string Placeholder(
        TournamentFixture f, bool firstSlot, TournamentFormat format, int teamsInRound)
    {
        if (f.Stage == TournamentStage.Group) return "—";
        if (f.Round == 1)
            return format == TournamentFormat.GroupsKnockout ? "متأهل من المجموعات" : "إعفاء";
        var prevIndex = f.Index * 2 + (firstSlot ? 0 : 1);
        return $"الفائز من {TournamentEngine.RoundName(teamsInRound * 2)} {prevIndex + 1}";
    }

    /// <summary>
    /// الترتيب النهائي: البطل، الوصيف، ثم خاسرو كل دور إقصائي من الأعلى إلى
    /// الأدنى، ثم من لم يتأهل من المجموعات (بمركزه في مجموعته أولاً). داخل
    /// الكتلة الواحدة يُرتَّب بسجل المجموعات بمعدّل المباراة (النقاط ثم الفارق،
    /// فالمجموعات قد تختلف أحجامها) وإلا برقم الفريق.
    /// </summary>
    private static List<TournamentRankingRowDto> Ranking(
        AmericanoMatch a, List<TournamentTeamDto> teams, List<TournamentGroupDto> groups, int knockoutSize)
    {
        var record = groups.SelectMany(g => g.Standings)
            .ToDictionary(r => r.Team, r => (r.Points, r.Diff, r.Position, r.Played));
        double PerMatch(int value, int played) => played == 0 ? 0 : value / (double)played;
        double Key1(int t) => record.TryGetValue(t, out var r) ? -PerMatch(r.Points, r.Played) : 0;
        double Key2(int t) => record.TryGetValue(t, out var r) ? -PerMatch(r.Diff, r.Played) : 0;

        var rows = new List<TournamentRankingRowDto>();
        var placed = new HashSet<int>();
        void Add(IEnumerable<int> block, string note, Func<int, int>? primary = null)
        {
            primary ??= _ => 0;
            foreach (var t in block.Where(placed.Add).ToList()
                         .OrderBy(primary).ThenBy(Key1).ThenBy(Key2).ThenBy(t => t))
            {
                var team = teams.FirstOrDefault(x => x.Number == t);
                rows.Add(new TournamentRankingRowDto
                {
                    Rank = rows.Count + 1,
                    Team = t,
                    Name = team?.Name ?? TournamentEngine.TeamLetter(t),
                    PlayerNames = team?.PlayerNames ?? "",
                    UserIds = team?.Players.Where(p => p.Status == "approved").Select(p => p.UserId).ToList() ?? [],
                    Note = note,
                });
            }
        }

        var ko = a.Fixtures.Where(f => f.Stage == TournamentStage.Knockout && !f.IsBye).ToList();
        var lastRound = ko.Count == 0 ? 0 : ko.Max(f => f.Round);
        var final = ko.FirstOrDefault(f => f.Round == lastRound);
        if (final?.WinnerTeam is int champion)
        {
            Add([champion], "البطل");
            var runnerUp = final.Team1 == champion ? final.Team2 : final.Team1;
            if (runnerUp is int ru) Add([ru], "الوصيف");
        }
        for (var r = lastRound - 1; r >= 1; r--)
        {
            var size = knockoutSize >> (r - 1);
            var losers = ko.Where(f => f.Round == r && f.IsCompleted && f.WinnerTeam is int)
                .Select(f => f.Team1 == f.WinnerTeam ? f.Team2 : f.Team1)
                .OfType<int>();
            Add(losers, $"خرج من {TournamentEngine.RoundName(size)}");
        }

        // من لم يتأهل: بحسب مركزه في مجموعته (الثالث قبل الرابع) ثم سجله.
        var rest = teams.Select(t => t.Number).Where(t => !placed.Contains(t));
        Add(rest, groups.Count > 0 ? "دور المجموعات" : "لم يتأهل",
            t => record.TryGetValue(t, out var r) ? r.Position : int.MaxValue);
        return rows;
    }
}
