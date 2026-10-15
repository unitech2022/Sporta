using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

// ── Requests ──────────────────────────────────────────────────────────────────

/// <summary>إنشاء بطولة إقصائية (فرق من لاعبَين، مباراة 2 ضد 2).</summary>
public class CreateTournamentRequest
{
    /// <summary>استضافة من حساب الملعب (ملاعبه فقط): منظّم لا لاعب ولا يدفع.</summary>
    public bool HostedByVenue { get; set; }

    [Required, MaxLength(80)] public string Name { get; set; } = string.Empty;

    /// <summary>"groups" (مجموعات + خروج المغلوب) | "knockout" (خروج المغلوب مباشرة).</summary>
    public string Format { get; set; } = "groups";

    /// <summary>عدد الفرق (4 فأكثر — 36 أو أكثر أو أقل).</summary>
    [Range(2, 512)] public int TeamCount { get; set; } = 8;

    /// <summary>الملاعب التي تُوزَّع عليها المباريات (من منشأة واحدة). الأول رئيسي.</summary>
    [Required, MinLength(1)] public List<int> CourtIds { get; set; } = [];

    /// <summary>بداية النافذة اليومية في اليوم الأول (وقت محلي).</summary>
    [Required] public DateTime ScheduledAt { get; set; }

    /// <summary>آخر يوم (تاريخ فقط). null = يوم واحد.</summary>
    public DateTime? EndDate { get; set; }

    /// <summary>طول النافذة اليومية على كل ملعب بالدقائق.</summary>
    [Range(60, 1080)] public int DurationMinutes { get; set; } = 240;

    /// <summary>مدة المباراة الواحدة بالدقائق (لتوزيع المباريات على الخانات).</summary>
    [Range(30, 180)] public int MatchMinutes { get; set; } = 60;

    [Range(1, 7)] public float MinLevel { get; set; } = 1;
    [Range(1, 7)] public float MaxLevel { get; set; } = 7;

    /// <summary>صديق يُدعى شريكاً في فريق المنشئ (المنشئ لاعب لا مستضيف).</summary>
    public int? PartnerId { get; set; }
}

public class SubmitFixtureScoreRequest
{
    [Range(0, 99)] public int Team1Score { get; set; }
    [Range(0, 99)] public int Team2Score { get; set; }
}

/// <summary>اسم جديد للفريق؛ فارغ يعيده إلى حرفه (A، B…).</summary>
public class RenameTeamRequest
{
    [MaxLength(30)] public string? Name { get; set; }
}

public class PostponeTournamentRequest
{
    /// <summary>الموعد الجديد لبداية النافذة في اليوم الأول (وقت محلي).</summary>
    [Required] public DateTime ScheduledAt { get; set; }
}

/// <summary>تقدير قبل الإنشاء: عدد المباريات وسعة الجدول والسعر.</summary>
public class TournamentQuoteRequest
{
    public string Format { get; set; } = "groups";
    [Range(2, 512)] public int TeamCount { get; set; } = 8;
    [Required, MinLength(1)] public List<int> CourtIds { get; set; } = [];
    [Required] public DateTime ScheduledAt { get; set; }
    public DateTime? EndDate { get; set; }
    [Range(60, 1080)] public int DurationMinutes { get; set; } = 240;
    [Range(30, 180)] public int MatchMinutes { get; set; } = 60;
}

// ── Responses ─────────────────────────────────────────────────────────────────

public class TournamentQuoteDto
{
    public int TeamCount { get; set; }
    public int GroupCount { get; set; }
    public List<int> GroupSizes { get; set; } = [];
    public int KnockoutSize { get; set; }
    public int BestThirds { get; set; }
    public int GroupMatches { get; set; }
    public int KnockoutMatches { get; set; }
    public int TotalMatches { get; set; }

    /// <summary>
    /// كم مباراة يتّسع لها الجدول: أيام × خانات × ملاعب إن اتّسع لكل المباريات،
    /// وإلا عدد ما يجد منها خانة فعلاً (الأدوار متتابعة فلا تُستغل كل الخانات).
    /// </summary>
    public int SlotCapacity { get; set; }
    public bool Fits => SlotCapacity >= TotalMatches;

    /// <summary>وصف المسار: «٤ مجموعات بنظام الدوري، ثم ربع النهائي حتى النهائي».</summary>
    public string PathText { get; set; } = string.Empty;

    public decimal TotalCourtPrice { get; set; }
    public decimal PricePerPlayer { get; set; }
}

public class TournamentTeamDto
{
    public int Number { get; set; }

    /// <summary>حرف الفريق الثابت: A، B، C…</summary>
    public string Letter { get; set; } = string.Empty;

    /// <summary>الاسم المعروض: المخصّص إن وُجد وإلا الحرف.</summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>الاسم الذي كتبه الفريق أو المنظّم؛ null = الحرف.</summary>
    public string? CustomName { get; set; }

    /// <summary>«فلان و فلان» — لاعبا الفريق المعتمدان.</summary>
    public string PlayerNames { get; set; } = string.Empty;
    public List<AmericanoPlayerDto> Players { get; set; } = [];

    /// <summary>لاعبان معتمدان.</summary>
    public bool IsComplete { get; set; }

    public int? GroupIndex { get; set; }
    public string? GroupLetter { get; set; }
}

public class TournamentGroupRowDto
{
    public int Position { get; set; }
    public int Team { get; set; }
    public string Name { get; set; } = string.Empty;
    public string PlayerNames { get; set; } = string.Empty;
    public int Played { get; set; }
    public int Wins { get; set; }
    public int Points { get; set; }
    public int Diff { get; set; }
    public int Scored { get; set; }

    /// <summary>تأهّل (بعد اكتمال دور المجموعات).</summary>
    public bool Qualified { get; set; }
}

public class TournamentGroupDto
{
    public int Index { get; set; }
    public string Letter { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public List<TournamentGroupRowDto> Standings { get; set; } = [];
    public int Played { get; set; }
    public int Total { get; set; }
    public bool IsComplete => Played >= Total;
}

public class TournamentFixtureDto
{
    public int Id { get; set; }

    /// <summary>"group" | "knockout".</summary>
    public string Stage { get; set; } = "group";
    public int? GroupIndex { get; set; }
    public string? GroupLetter { get; set; }
    public int Round { get; set; }

    /// <summary>«المجموعة أ — الجولة 2» أو «ربع النهائي».</summary>
    public string RoundName { get; set; } = string.Empty;
    public int Index { get; set; }

    /// <summary>«مباراة 3» أو «المباراة النهائية».</summary>
    public string Title { get; set; } = string.Empty;

    public int? Team1 { get; set; }
    public int? Team2 { get; set; }
    public string Team1Name { get; set; } = string.Empty;
    public string Team2Name { get; set; } = string.Empty;
    public string Team1Players { get; set; } = string.Empty;
    public string Team2Players { get; set; } = string.Empty;

    /// <summary>مكان الفريق غير المعروف بعد: «الفائز من ربع النهائي 2» / «متصدر المجموعة أ».</summary>
    public string? Team1Placeholder { get; set; }
    public string? Team2Placeholder { get; set; }

    public int? Team1Score { get; set; }
    public int? Team2Score { get; set; }
    public bool IsCompleted { get; set; }
    public bool IsBye { get; set; }
    public int? WinnerTeam { get; set; }

    /// <summary>الفريقان معروفان ولم تُقفل النتيجة بما بعدها.</summary>
    public bool CanScore { get; set; }

    /// <summary>نتيجة أدخلها لاعب وتنتظر تأكيد لاعب من الفريق الآخر.</summary>
    public PendingResultDto? PendingResult { get; set; }

    /// <summary>رُفضت نتيجة مقترحة — خلاف يحسمه المنظّم.</summary>
    public bool IsDisputed { get; set; }

    public int? CourtId { get; set; }
    public string? CourtName { get; set; }
    public DateTime? ScheduledAt { get; set; }
}

public class TournamentRankingRowDto
{
    public int Rank { get; set; }
    public int Team { get; set; }
    public string Name { get; set; } = string.Empty;
    public List<int> UserIds { get; set; } = [];
    public string PlayerNames { get; set; } = string.Empty;

    /// <summary>«البطل» / «الوصيف» / «خرج من نصف النهائي» / «دور المجموعات».</summary>
    public string Note { get; set; } = string.Empty;
}

public class TournamentCourtDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? NameEn { get; set; }
}

public class TournamentDto
{
    public int Id { get; set; }
    public int MatchId { get; set; }
    public int CreatorId { get; set; }
    public string Name { get; set; } = string.Empty;

    /// <summary>"groups" | "knockout".</summary>
    public string Format { get; set; } = "groups";

    /// <summary>"pendingApproval" | "open" | "full" | "inProgress" | "completed" | "cancelled".</summary>
    public string Status { get; set; } = "open";
    public bool IsVenueHosted { get; set; }
    public bool IsCompleted { get; set; }
    public bool IsDrawn { get; set; }

    /// <summary>آخر لحظة للانسحاب بلا موافقة (وقت محلي): الموعد ناقص 48 ساعة.</summary>
    public DateTime WithdrawalFreeUntil { get; set; }

    /// <summary>هل الانسحاب الآن مباشر؟ وإلا يصير طلباً ينتظر المنظّم.</summary>
    public bool CanWithdrawDirectly { get; set; }

    public DateTime ScheduledAt { get; set; }
    public DateTime? EndDate { get; set; }
    public int DurationMinutes { get; set; }
    public int MatchMinutes { get; set; }

    public int TeamCount { get; set; }
    public int CompleteTeamCount { get; set; }
    public int MaxPlayers { get; set; }
    public float MinLevel { get; set; }
    public float MaxLevel { get; set; }
    public decimal PricePerPlayer { get; set; }

    public int? CourtId { get; set; }
    public string? VenueName { get; set; }
    public string? VenueNameEn { get; set; }
    public string? City { get; set; }
    public string? CityEn { get; set; }
    public List<TournamentCourtDto> Courts { get; set; } = [];

    public int GroupCount { get; set; }
    public int KnockoutSize { get; set; }
    public int BestThirds { get; set; }
    public int TotalMatches { get; set; }
    public int PlayedMatches { get; set; }
    public string PathText { get; set; } = string.Empty;

    public List<AmericanoPlayerDto> Players { get; set; } = [];
    public List<TournamentTeamDto> Teams { get; set; } = [];
    public List<TournamentGroupDto> Groups { get; set; } = [];
    public List<TournamentFixtureDto> Fixtures { get; set; } = [];

    /// <summary>الترتيب النهائي (الأول إلى الأخير) — يُملأ حين تكتمل البطولة.</summary>
    public List<TournamentRankingRowDto> Ranking { get; set; } = [];
    public int? ChampionTeam { get; set; }
    public string? ChampionName { get; set; }
    public string? ChampionPlayers { get; set; }
}
