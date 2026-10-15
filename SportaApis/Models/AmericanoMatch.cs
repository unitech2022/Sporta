using SportaApis.Enums;
using MatchType = SportaApis.Enums.MatchType;

namespace SportaApis.Models;

/// <summary>
/// نظام الأمريكانو - فردي أو تيم (الفصل الخامس من التصميم)
/// </summary>
public class AmericanoMatch : BaseEntity
{
    public int MatchId { get; set; }
    public Match Match { get; set; } = null!;

    public MatchType AmericanoType { get; set; } // American أو AmericanTeam

    /// <summary>
    /// بطولة — نفس نظام الأمريكانو لكنها قد تمتد يوماً واحداً أو أكثر.
    /// </summary>
    public bool IsTournament { get; set; }

    /// <summary>
    /// آخر يوم للبطولة (naive KSA local مثل ScheduledAt). null للأمريكانو
    /// والبطولات ذات اليوم الواحد.
    /// </summary>
    public DateTime? EndDate { get; set; }

    // نطاق المستوى المسموح (5.1)
    public float MinAllowedLevel { get; set; }
    public float MaxAllowedLevel { get; set; }

    public int TotalRounds { get; set; }
    public bool IsCompleted { get; set; } = false;

    // ── بطولة إقصائية (Format != null) ────────────────────────────────────
    /// <summary>اسم البطولة كما كتبه المنظّم.</summary>
    public string? Name { get; set; }

    /// <summary>
    /// نظام البطولة الإقصائية. null = أمريكانو عادي (أو بطولة قديمة بنظام
    /// الأمريكانو) — الجولات في <see cref="Rounds"/>؛ وإلا فالمباريات في
    /// <see cref="Fixtures"/>.
    /// </summary>
    public TournamentFormat? Format { get; set; }

    /// <summary>مدة المباراة الواحدة بالدقائق لجدولة المباريات على الملاعب.</summary>
    public int MatchMinutes { get; set; } = 60;

    /// <summary>متى أُجريت القرعة وتشكّلت المجموعات والمباريات.</summary>
    public DateTime? DrawnAt { get; set; }

    /// <summary>
    /// متى أُبلغ المنظّم بأن العدد لم يكتمل قبل الموعد (إكمال/تأجيل/إلغاء) —
    /// يُرسل مرة واحدة.
    /// </summary>
    public DateTime? IncompleteNoticeSentAt { get; set; }

    // Navigation
    public ICollection<AmericanoRound> Rounds { get; set; } = [];
    public ICollection<TournamentFixture> Fixtures { get; set; } = [];
    public ICollection<TournamentCourt> Courts { get; set; } = [];
    public ICollection<TournamentTeamName> TeamNames { get; set; } = [];
}
