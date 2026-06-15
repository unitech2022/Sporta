namespace SportaApis.Models;

/// <summary>
/// تقييم الأقران بعد المباراة (1.9) - يؤثر على حساب ELO الكلي
/// </summary>
public class MatchRating : BaseEntity
{
    public int MatchId { get; set; }
    public Match Match { get; set; } = null!;

    public int RaterId { get; set; }
    public User Rater { get; set; } = null!;

    public int RatedUserId { get; set; }
    public User RatedUser { get; set; } = null!;

    public int Score { get; set; } // 1-5 مقياس رقمي
}
