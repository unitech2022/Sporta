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

    // نطاق المستوى المسموح (5.1)
    public float MinAllowedLevel { get; set; }
    public float MaxAllowedLevel { get; set; }

    public int TotalRounds { get; set; }
    public bool IsCompleted { get; set; } = false;

    // Navigation
    public ICollection<AmericanoRound> Rounds { get; set; } = [];
}
