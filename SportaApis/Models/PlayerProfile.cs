using SportaApis.Enums;
using MatchType = SportaApis.Enums.MatchType;

namespace SportaApis.Models;

/// <summary>
/// الملف الشخصي للاعب - يحتوي على التفضيلات ونظام ELO والمستوى
/// </summary>
public class PlayerProfile : BaseEntity
{
    public int UserId { get; set; }
    public User User { get; set; } = null!;

    // التفضيلات عند التسجيل (1.3)
    public PreferredHand PreferredHand { get; set; }
    public CourtPosition CourtPosition { get; set; }
    public MatchType PreferredMatchType { get; set; }
    public PlayTimePreference PreferredPlayTime { get; set; }
    public int? PlayStartYear { get; set; }

    // نظام المستوى (1.4 + 1.10)
    public PlayerLevel Level { get; set; } = PlayerLevel.Beginner;
    public float EloRating { get; set; } = 1000f; // نظام ELO الديناميكي (1.6)

    // نقاط الموثوقية - تُكسب بالالتزام وتُخصم بالإلغاء (2.8 / 2.9)
    public float ReliabilityScore { get; set; } = 0f;

    // إحصائيات
    public int TotalMatches { get; set; } = 0;
    public int TotalWins { get; set; } = 0;
    public float WinRate => TotalMatches == 0 ? 0 : (float)TotalWins / TotalMatches * 100;

    // تقييم الأقران المتوسط (1.9)
    public float PeerRatingAverage { get; set; } = 0f;
    public int PeerRatingCount { get; set; } = 0;

    // Navigation
    public ICollection<MatchPlayer> MatchPlayers { get; set; } = [];
    public ICollection<LevelAssessment> LevelAssessments { get; set; } = [];
}
