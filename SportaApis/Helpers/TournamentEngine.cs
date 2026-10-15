using SportaApis.Enums;
using SportaApis.Models;

namespace SportaApis.Helpers;

/// <summary>
/// منطق البطولة الإقصائية الصرف (بلا قاعدة بيانات): تخطيط المجموعات، القرعة،
/// شجرة خروج المغلوب، أسماء الأدوار، وتوزيع المباريات على الملاعب والمواعيد.
/// كل ما هنا حتميّ لمدخل معيّن، فتسهل تجربته على حدة.
/// </summary>
public static class TournamentEngine
{
    public const int PlayersPerTeam = 2;

    /// <summary>أقل عدد فرق تُنشأ عليه بطولة.</summary>
    public const int MinTeams = 4;

    /// <summary>أقل عدد فرق مكتملة يقبل المنظّم البدء بها إن لم يكتمل العدد.</summary>
    public const int MinStartTeams = 2;

    public static readonly string[] GroupLetters =
    [
        "أ", "ب", "ج", "د", "هـ", "و", "ز", "ح", "ط", "ي", "ك", "ل",
        "م", "ن", "س", "ع", "ف", "ص", "ق", "ر", "ش", "ت", "ث", "خ",
    ];

    /// <summary>حرف الفريق الافتراضي: 1 → A … 26 → Z، 27 → AA (كأعمدة الجداول).</summary>
    public static string TeamLetter(int number)
    {
        var letters = "";
        for (var n = number; n > 0; n = (n - 1) / 26)
            letters = (char)('A' + (n - 1) % 26) + letters;
        return letters;
    }

    public const int MaxTeamNameLength = 30;

    public static string GroupLetter(int index) =>
        index < GroupLetters.Length ? GroupLetters[index] : (index + 1).ToString();

    // ── التخطيط ─────────────────────────────────────────────────────────────

    /// <summary>
    /// خطة دور المجموعات: كم مجموعة، وأحجامها، وحجم شجرة الإقصائيات (قوة
    /// للرقم 2)، وكم «أفضل ثالث» يكمل العدد. يتأهل الأول والثاني من كل مجموعة
    /// دائماً، فتُختار المجموعات بحيث 2g ≤ K ≤ 3g. الأفضلية: أكبر شجرة
    /// إقصائية، ثم مجموعات متساوية، ثم أقرب إلى أربعة فرق، ثم أقل «ثوالث».
    /// (36 فريقاً → 12 مجموعة من 3 + 8 أفضل ثوالث → دور الـ32، كما في كأس العالم.)
    /// </summary>
    public sealed record GroupPlan(int GroupCount, int[] Sizes, int KnockoutSize, int BestThirds)
    {
        public int GroupMatches => Sizes.Sum(s => s * (s - 1) / 2);
        public int KnockoutMatches => KnockoutSize - 1;
        public int TotalMatches => GroupMatches + KnockoutMatches;
    }

    public static GroupPlan PlanGroups(int teams)
    {
        if (teams < 2) throw new ArgumentOutOfRangeException(nameof(teams));

        GroupPlan? best = null;
        (int, int, double, int) bestKey = default;

        var minGroups = Math.Max(1, (int)Math.Ceiling(teams / 5.0));
        var maxGroups = Math.Max(1, teams / 3);
        for (var g = minGroups; g <= maxGroups; g++)
        {
            var k = NextPowerOfTwo(2 * g);
            if (k > 3 * g || k > teams) continue;

            var uniform = teams % g == 0 ? 0 : 1;
            var size = teams / (double)g;
            var thirds = k - 2 * g;
            var key = (-k, uniform, Math.Abs(size - 4), thirds);
            if (best == null || Compare(key, bestKey) < 0)
            {
                best = new GroupPlan(g, Sizes(teams, g), k, thirds);
                bestKey = key;
            }
        }

        // فرق قليلة جداً لأي تقسيم: مجموعة واحدة والأول والثاني يلعبان النهائي.
        return best ?? new GroupPlan(1, [teams], 2, 0);

        static int Compare((int, int, double, int) a, (int, int, double, int) b)
        {
            var c = a.Item1.CompareTo(b.Item1); if (c != 0) return c;
            c = a.Item2.CompareTo(b.Item2); if (c != 0) return c;
            c = a.Item3.CompareTo(b.Item3); if (c != 0) return c;
            return a.Item4.CompareTo(b.Item4);
        }
    }

    private static int[] Sizes(int teams, int groups)
    {
        var baseSize = teams / groups;
        var extra = teams % groups;
        return Enumerable.Range(0, groups).Select(i => baseSize + (i < extra ? 1 : 0)).ToArray();
    }

    public static int NextPowerOfTwo(int n)
    {
        var p = 1;
        while (p < n) p <<= 1;
        return p;
    }

    /// <summary>عدد مباريات البطولة كلها لعدد فرق ونظام.</summary>
    public static int TotalMatches(TournamentFormat format, int teams) =>
        format == TournamentFormat.Knockout
            ? Math.Max(0, teams - 1)
            : PlanGroups(teams).TotalMatches;

    /// <summary>اسم الدور الإقصائي بعدد الفرق فيه.</summary>
    public static string RoundName(int teamsInRound) => teamsInRound switch
    {
        2 => "النهائي",
        4 => "نصف النهائي",
        8 => "ربع النهائي",
        _ => $"دور الـ{teamsInRound}",
    };

    // ── الدوري داخل المجموعة ─────────────────────────────────────────────────

    /// <summary>جولات الدوري (طريقة الدائرة): كل فريق يلقى الآخرين مرة، وفي
    /// كل جولة يلعب مرة واحدة. تعيد (رقم الجولة، الفريق الأول، الفريق الثاني).</summary>
    public static List<(int Round, int A, int B)> RoundRobin(IReadOnlyList<int> teams)
    {
        var list = teams.ToList();
        if (list.Count % 2 == 1) list.Add(0); // 0 = استراحة
        var n = list.Count;
        var result = new List<(int, int, int)>();
        for (var round = 1; round < n; round++)
        {
            for (var i = 0; i < n / 2; i++)
            {
                var (a, b) = (list[i], list[n - 1 - i]);
                if (a != 0 && b != 0) result.Add((round, a, b));
            }
            var last = list[n - 1];
            list.RemoveAt(n - 1);
            list.Insert(1, last);
        }
        return result;
    }

    // ── الشجرة ───────────────────────────────────────────────────────────────

    /// <summary>
    /// ترتيب البذور في شجرة بحجم <paramref name="size"/> بحيث لا يلتقي الأول
    /// والثاني قبل النهائي: [1,8,4,5,2,7,3,6] لثمانية. المواقع المتجاورة تتقابل
    /// في الدور الأول.
    /// </summary>
    public static int[] BracketOrder(int size)
    {
        var order = new List<int> { 1 };
        while (order.Count < size)
        {
            var doubled = order.Count * 2;
            var next = new List<int>(doubled);
            foreach (var s in order)
            {
                next.Add(s);
                next.Add(doubled + 1 - s);
            }
            order = next;
        }
        return [.. order];
    }

    /// <summary>الفائز من (الدور r، الموقع i) يذهب إلى (الدور r+1، الموقع i/2)،
    /// في الخانة الأولى إن كان i زوجياً وإلا الثانية.</summary>
    public static (int Round, int Index, bool FirstSlot) NextSlot(int round, int index) =>
        (round + 1, index / 2, index % 2 == 0);

    // ── الترتيب داخل المجموعة ────────────────────────────────────────────────

    public sealed class GroupRow
    {
        public int Team { get; init; }
        public int Played { get; set; }
        public int Wins { get; set; }
        public int Points => Wins * 3;
        public int Scored { get; set; }
        public int Against { get; set; }
        public int Diff => Scored - Against;
        public int Position { get; set; }

        /// <summary>للمقارنة بين مجموعات بأحجام مختلفة (أفضل الثوالث).</summary>
        public double PointsPerMatch => Played == 0 ? 0 : Points / (double)Played;
        public double DiffPerMatch => Played == 0 ? 0 : Diff / (double)Played;
        public double ScoredPerMatch => Played == 0 ? 0 : Scored / (double)Played;
    }

    /// <summary>
    /// جدول مجموعة: النقاط ثم الفارق ثم المسجَّل؛ ومن تساووا في الثلاثة
    /// تحسمهم المواجهات المباشرة بينهم (نقاط ثم فارق ثم مسجَّل فيها)، وأخيراً
    /// رقم الفريق.
    /// </summary>
    public static List<GroupRow> GroupTable(
        IEnumerable<int> teams, IEnumerable<TournamentFixture> groupFixtures)
    {
        var rows = teams.ToDictionary(t => t, t => new GroupRow { Team = t });
        var played = groupFixtures
            .Where(f => f.IsCompleted && f.Team1 is int && f.Team2 is int
                        && rows.ContainsKey(f.Team1.Value) && rows.ContainsKey(f.Team2.Value))
            .ToList();
        foreach (var f in played)
        {
            var r1 = rows[f.Team1!.Value];
            var r2 = rows[f.Team2!.Value];
            var s1 = f.Team1Score ?? 0;
            var s2 = f.Team2Score ?? 0;
            r1.Played++; r2.Played++;
            r1.Scored += s1; r1.Against += s2;
            r2.Scored += s2; r2.Against += s1;
            if (s1 > s2) r1.Wins++; else if (s2 > s1) r2.Wins++;
        }

        var ordered = new List<GroupRow>();
        foreach (var tied in rows.Values
                     .GroupBy(r => (r.Points, r.Diff, r.Scored))
                     .OrderByDescending(g => g.Key.Points)
                     .ThenByDescending(g => g.Key.Diff)
                     .ThenByDescending(g => g.Key.Scored))
        {
            var block = tied.ToList();
            if (block.Count == 1) { ordered.Add(block[0]); continue; }

            // دوري مصغّر بين المتساوين وحدهم.
            var ids = block.Select(r => r.Team).ToHashSet();
            var h2h = ids.ToDictionary(t => t, _ => (Points: 0, Diff: 0, Scored: 0));
            foreach (var f in played.Where(f => ids.Contains(f.Team1!.Value) && ids.Contains(f.Team2!.Value)))
            {
                int t1 = f.Team1!.Value, t2 = f.Team2!.Value;
                int s1 = f.Team1Score ?? 0, s2 = f.Team2Score ?? 0;
                var a = h2h[t1]; var b = h2h[t2];
                h2h[t1] = (a.Points + (s1 > s2 ? 3 : 0), a.Diff + s1 - s2, a.Scored + s1);
                h2h[t2] = (b.Points + (s2 > s1 ? 3 : 0), b.Diff + s2 - s1, b.Scored + s2);
            }
            ordered.AddRange(block
                .OrderByDescending(r => h2h[r.Team].Points)
                .ThenByDescending(r => h2h[r.Team].Diff)
                .ThenByDescending(r => h2h[r.Team].Scored)
                .ThenBy(r => r.Team));
        }
        for (var i = 0; i < ordered.Count; i++) ordered[i].Position = i + 1;
        return ordered;
    }

    /// <summary>
    /// المتأهلون من المجموعات مرتَّبين كبذور: المتصدرون (الأفضل سجلاً أولاً)،
    /// ثم الوصفاء، ثم أفضل الثوالث بعدد ما تحتاجه الشجرة.
    /// </summary>
    public static List<int> Qualifiers(IReadOnlyList<List<GroupRow>> tables, GroupPlan plan)
    {
        var winners = AcrossGroups(tables.Select(t => t[0]));
        var runners = AcrossGroups(tables.Where(t => t.Count > 1).Select(t => t[1]));
        var thirds = AcrossGroups(tables.Where(t => t.Count > 2).Select(t => t[2]))
            .Take(plan.BestThirds);

        return winners.Concat(runners).Concat(thirds).Select(r => r.Team).Take(plan.KnockoutSize).ToList();
    }

    /// <summary>مقارنة أصحاب المركز نفسه من مجموعات قد تختلف أحجامها: بمعدّل
    /// المباراة الواحدة (نقاط، فارق، مسجَّل) لا بالمجاميع.</summary>
    public static IOrderedEnumerable<GroupRow> AcrossGroups(IEnumerable<GroupRow> rows) => rows
        .OrderByDescending(r => r.PointsPerMatch)
        .ThenByDescending(r => r.DiffPerMatch)
        .ThenByDescending(r => r.ScoredPerMatch)
        .ThenBy(r => r.Team);

    /// <summary>
    /// مواجهات الدور الإقصائي الأول من قائمة بذور: تُوزَّع بترتيب الشجرة ثم
    /// يُفكّ كل تقابل بين فريقين من مجموعة واحدة (سبق أن تقابلا) بتبديل أحد
    /// طرفيه مع طرف من أقرب مباراة يصلح معها التبديل، فيبقى ترتيب الشجرة أقرب
    /// ما يكون إلى البذور.
    /// </summary>
    public static List<(int? A, int? B)> FirstRoundPairs(
        IReadOnlyList<int> seeds, int size, Func<int, int?>? groupOf = null)
    {
        var order = BracketOrder(size);
        var slots = order.Select(seed => seed <= seeds.Count ? (int?)seeds[seed - 1] : null).ToArray();

        if (groupOf != null)
        {
            for (var i = 0; i + 1 < slots.Length; i += 2)
            {
                if (!SameGroup(slots[i], slots[i + 1])) continue;
                var candidates = Enumerable.Range(0, slots.Length / 2).Select(p => p * 2)
                    .Where(j => j != i).OrderBy(j => Math.Abs(j - i)).ThenBy(j => j);
                var fixedIt = false;
                foreach (var j in candidates)
                {
                    // الطرف الأدنى أولاً (يحفظ البذرة العليا في مكانها)، ثم الأعلى.
                    foreach (var (k, other) in new[] { (j + 1, j), (j, j + 1) })
                    {
                        if (SameGroup(slots[i], slots[k]) || SameGroup(slots[other], slots[i + 1])) continue;
                        (slots[i + 1], slots[k]) = (slots[k], slots[i + 1]);
                        fixedIt = true;
                        break;
                    }
                    if (fixedIt) break;
                }
            }
        }

        var pairs = new List<(int?, int?)>();
        for (var i = 0; i < slots.Length; i += 2) pairs.Add((slots[i], slots[i + 1]));
        return pairs;

        bool SameGroup(int? a, int? b) =>
            a is int x && b is int y && groupOf!(x) is int gx && groupOf(y) == gx;
    }

    // ── الجدولة على الملاعب ─────────────────────────────────────────────────

    public sealed record Slot(DateTime Start, int CourtId);

    /// <summary>
    /// خانات اللعب المتاحة: في كل يوم من أيام البطولة، داخل النافذة اليومية،
    /// كل مدة مباراة، على كل ملعب — مرتبة بالزمن ثم الملعب.
    /// </summary>
    public static List<Slot> Slots(
        DateTime firstDay, DateTime lastDay, TimeSpan windowStart, int windowMinutes,
        int matchMinutes, IReadOnlyList<int> courtIds)
    {
        var slots = new List<Slot>();
        for (var day = firstDay.Date; day <= lastDay.Date; day = day.AddDays(1))
            for (var offset = 0; offset + matchMinutes <= windowMinutes; offset += matchMinutes)
                foreach (var court in courtIds)
                    slots.Add(new Slot(day.Add(windowStart).AddMinutes(offset), court));
        return slots;
    }

    /// <summary>
    /// يوزّع المباريات على الخانات مرحلةً مرحلة: كل مرحلة (دور المجموعات، ثم
    /// كل دور إقصائي) تبدأ بعد انتهاء آخر مباراة في المرحلة السابقة، ولا يلعب
    /// فريق مباراتين في وقت واحد. ما لا يجد خانة يبقى بلا موعد.
    /// </summary>
    public static void AssignSlots(
        IReadOnlyList<IReadOnlyList<TournamentFixture>> phases,
        IReadOnlyList<Slot> slots, int matchMinutes)
    {
        var used = new HashSet<int>();
        var busy = new Dictionary<DateTime, HashSet<int>>();
        DateTime? previousPhaseEnd = null;

        foreach (var phase in phases)
        {
            DateTime? phaseEnd = null;
            foreach (var fixture in phase)
            {
                fixture.ScheduledAt = null;
                fixture.CourtId = null;
                for (var i = 0; i < slots.Count; i++)
                {
                    if (used.Contains(i)) continue;
                    var slot = slots[i];
                    if (previousPhaseEnd is DateTime end && slot.Start < end) continue;
                    if (busy.TryGetValue(slot.Start, out var teams) &&
                        ((fixture.Team1 is int a && teams.Contains(a)) ||
                         (fixture.Team2 is int b && teams.Contains(b)))) continue;

                    used.Add(i);
                    fixture.ScheduledAt = slot.Start;
                    fixture.CourtId = slot.CourtId;
                    if (!busy.TryGetValue(slot.Start, out teams))
                        busy[slot.Start] = teams = [];
                    if (fixture.Team1 is int t1) teams.Add(t1);
                    if (fixture.Team2 is int t2) teams.Add(t2);

                    var fixtureEnd = slot.Start.AddMinutes(matchMinutes);
                    if (phaseEnd == null || fixtureEnd > phaseEnd) phaseEnd = fixtureEnd;
                    break;
                }
            }
            if (phaseEnd != null) previousPhaseEnd = phaseEnd;
        }
    }

    // ── القرعة ──────────────────────────────────────────────────────────────

    /// <summary>مباريات القرعة ومراحل جدولتها، والنظام الفعلي بعدها (فرق أقل
    /// من <see cref="MinTeams"/> تُلعب خروج مغلوب مهما كان النظام المطلوب).</summary>
    public sealed record Draw(
        List<TournamentFixture> Fixtures,
        List<IReadOnlyList<TournamentFixture>> Phases,
        TournamentFormat Format);

    /// <summary>
    /// يبني مباريات البطولة لفرق مرتّبة (مخلوطة مسبقاً): المجموعات بالتتابع ثم
    /// شجرة الإقصاء فارغة، أو شجرة خروج المغلوب مباشرة مع إعفاءاتها.
    /// </summary>
    public static Draw BuildDraw(int americanoId, TournamentFormat format, IReadOnlyList<int> teams)
    {
        var fixtures = new List<TournamentFixture>();
        var phases = new List<IReadOnlyList<TournamentFixture>>();

        if (format == TournamentFormat.GroupsKnockout && teams.Count >= MinTeams)
        {
            var plan = PlanGroups(teams.Count);
            var offset = 0;
            var groupFixtures = new List<TournamentFixture>();
            for (var g = 0; g < plan.GroupCount; g++)
            {
                var members = teams.Skip(offset).Take(plan.Sizes[g]).ToList();
                offset += plan.Sizes[g];
                var perRound = new Dictionary<int, int>();
                foreach (var (round, t1, t2) in RoundRobin(members))
                {
                    perRound.TryGetValue(round, out var idx);
                    perRound[round] = idx + 1;
                    groupFixtures.Add(new TournamentFixture
                    {
                        AmericanoMatchId = americanoId,
                        Stage = TournamentStage.Group,
                        GroupIndex = g,
                        Round = round,
                        Index = idx,
                        Team1 = t1,
                        Team2 = t2,
                    });
                }
            }
            // جولة 1 لكل المجموعات، ثم جولة 2… فيلعب كل فريق مرة في كل «يوم مباريات».
            var ordered = groupFixtures
                .OrderBy(f => f.Round).ThenBy(f => f.GroupIndex).ThenBy(f => f.Index).ToList();
            fixtures.AddRange(ordered);
            phases.Add(ordered);
            fixtures.AddRange(BuildKnockoutRounds(americanoId, plan.KnockoutSize, null, phases));
            return new Draw(fixtures, phases, TournamentFormat.GroupsKnockout);
        }

        var size = NextPowerOfTwo(teams.Count);
        fixtures.AddRange(BuildKnockoutRounds(americanoId, size, FirstRoundPairs(teams, size), phases));
        return new Draw(fixtures, phases, TournamentFormat.Knockout);
    }

    /// <summary>شجرة خروج المغلوب بحجم <paramref name="size"/>: الدور 1 ثم
    /// الأدوار التالية فارغة. مع <paramref name="firstRound"/> تُملأ مواجهات
    /// الدور الأول ويتقدّم المعفَون فوراً.</summary>
    private static List<TournamentFixture> BuildKnockoutRounds(
        int americanoId, int size, List<(int? A, int? B)>? firstRound,
        List<IReadOnlyList<TournamentFixture>> phases)
    {
        var all = new List<TournamentFixture>();
        var byRound = new Dictionary<(int Round, int Index), TournamentFixture>();
        var round = 1;
        for (var matches = size / 2; matches >= 1; matches /= 2, round++)
        {
            var list = new List<TournamentFixture>();
            for (var i = 0; i < matches; i++)
            {
                var f = new TournamentFixture
                {
                    AmericanoMatchId = americanoId,
                    Stage = TournamentStage.Knockout,
                    Round = round,
                    Index = i,
                };
                if (round == 1 && firstRound != null)
                {
                    f.Team1 = firstRound[i].A;
                    f.Team2 = firstRound[i].B;
                    if (f.Team1 == null || f.Team2 == null)
                    {
                        f.IsBye = true;
                        f.IsCompleted = true;
                        f.WinnerTeam = f.Team1 ?? f.Team2;
                    }
                }
                list.Add(f);
                byRound[(round, i)] = f;
            }
            all.AddRange(list);
            phases.Add(list.Where(f => !f.IsBye).ToList());
        }

        // المعفَون يشغلون خانتهم في الدور الثاني منذ الآن.
        foreach (var f in all.Where(f => f.IsBye && f.WinnerTeam is int))
        {
            var (r, i, first) = NextSlot(f.Round, f.Index);
            if (!byRound.TryGetValue((r, i), out var next)) continue;
            if (first) next.Team1 = f.WinnerTeam; else next.Team2 = f.WinnerTeam;
        }
        return all;
    }

    /// <summary>
    /// كم مباراة من بطولة بهذا الحجم تجد لها خانة فعلاً. عدد الخانات وحده لا
    /// يكفي: كل دور ينتظر انتهاء سابقه فتضيع خانات الملاعب الفارغة في آخر
    /// توقيت من كل دور، فيُحاكى التوزيع نفسه الذي تجريه القرعة (بنية المباريات
    /// لا تتوقف على هوية الفرق).
    /// </summary>
    public static int SchedulableMatches(
        TournamentFormat format, int teams, DateTime firstDay, DateTime lastDay,
        TimeSpan windowStart, int windowMinutes, int matchMinutes, int courtCount)
    {
        if (teams < 2 || matchMinutes <= 0 || courtCount <= 0) return 0;
        var draw = BuildDraw(0, format, Enumerable.Range(1, teams).ToList());
        var slots = Slots(firstDay, lastDay, windowStart, windowMinutes, matchMinutes,
            Enumerable.Range(1, courtCount).ToList());
        AssignSlots(draw.Phases, slots, matchMinutes);
        return draw.Fixtures.Count(f => !f.IsBye && f.ScheduledAt != null);
    }
}
