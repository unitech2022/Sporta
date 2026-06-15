namespace SportaApis.Models;

/// <summary>
/// ربط اللاعبين بالمباراة (جدول وسيط)
/// </summary>
public class MatchPlayer : BaseEntity
{
    public int MatchId { get; set; }
    public Match Match { get; set; } = null!;

    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public bool HasPaid { get; set; } = false;
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
}
