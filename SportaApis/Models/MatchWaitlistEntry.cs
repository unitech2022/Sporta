namespace SportaApis.Models;

/// <summary>
/// لاعب ينتظر مقعداً في مباراة/أمريكانو مكتمل. الترتيب بوقت التسجيل
/// (<see cref="BaseEntity.CreatedAt"/>). حين يفرغ مقعد يُعرض على الأول
/// ويُحجز له حتى <see cref="OfferExpiresAt"/>، فإن لم ينضم انتقل للتالي.
/// يُحذف الصف حين ينضم صاحبه أو يغادر أو تنتهي مهلته أو يُغلق الحدث.
/// </summary>
public class MatchWaitlistEntry : BaseEntity
{
    public int MatchId { get; set; }
    public Match Match { get; set; } = null!;

    public int UserId { get; set; }
    public User User { get; set; } = null!;

    /// <summary>متى عُرض عليه المقعد (UTC)؛ null = ما زال ينتظر دوره.</summary>
    public DateTime? OfferedAt { get; set; }

    /// <summary>نهاية حجز المقعد له (UTC)؛ null = لا عرض قائم.</summary>
    public DateTime? OfferExpiresAt { get; set; }
}
