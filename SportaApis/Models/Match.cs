using SportaApis.Enums;
using MatchType = SportaApis.Enums.MatchType;

namespace SportaApis.Models;

/// <summary>
/// المباراة المفتوحة - ينشئها لاعب ويتضمن بطاقة العرض (2.2)
/// </summary>
public class Match : BaseEntity
{
    public int CreatorId { get; set; }
    public User Creator { get; set; } = null!;

    public int? CourtId { get; set; }
    public Court? Court { get; set; }

    public MatchType MatchType { get; set; }
    public MatchStatus Status { get; set; } = MatchStatus.Open;

    public DateTime ScheduledAt { get; set; }
    public int DurationMinutes { get; set; } = 90;

    public int MaxPlayers { get; set; } = 4;

    // فلتر المستوى (2.3)
    public float MinLevel { get; set; } = 1;
    public float MaxLevel { get; set; } = 7;

    // سعر حصة كل لاعب
    public decimal PricePerPlayer { get; set; }

    public string? Notes { get; set; }

    // Navigation
    public ICollection<MatchPlayer> MatchPlayers { get; set; } = [];
    public ICollection<MatchRating> Ratings { get; set; } = [];
    public AmericanoMatch? AmericanoMatch { get; set; }
}
