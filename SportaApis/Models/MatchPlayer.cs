using SportaApis.Enums;

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

    /// <summary>Pending = join request awaiting the creator's approval.</summary>
    public MatchPlayerStatus Status { get; set; } = MatchPlayerStatus.Approved;

    /// <summary>
    /// Fixed team for a "teams" americano (1 or 2). Null for singles americano
    /// and regular matches, where there is no fixed team assignment.
    /// </summary>
    public int? Team { get; set; }

    public bool HasPaid { get; set; } = false;

    /// <summary>
    /// ما دفعه هذا اللاعب فعلاً عن حصته (بعد خصم عضوية النادي إن وُجدت).
    /// null للسجلات القديمة = <see cref="Match.PricePerPlayer"/>. كل ردّ أو
    /// تحويل للمالك يعتمد هذا المبلغ لا السعر الموحّد — انظر <see cref="Match.ShareOf"/>.
    /// </summary>
    public decimal? PaidAmount { get; set; }

    /// <summary>عضوية النادي التي خُصمت بها الحصة (null = بلا خصم).</summary>
    public int? MembershipId { get; set; }

    /// <summary>دقائق محسوبة من سقف ساعات الخصم الشهري للعضوية.</summary>
    public int MemberDiscountMinutes { get; set; }

    /// <summary>
    /// من دعا اللاعب (دعوة مباراة أو دعوة شريك). دعوة المنشئ تكفي للانضمام؛
    /// دعوة غيره تصير عند قبولها طلب انضمام ينتظر موافقة المنشئ.
    /// null للمنضمّ بنفسه وللدعوات القديمة.
    /// </summary>
    public int? InvitedById { get; set; }
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// طلب انسحاب متأخر ينتظر موافقة المنشئ (بعد مهلة الانسحاب الحرّ:
    /// 24 ساعة قبل المباراة، 48 قبل الأمريكانو/البطولة). null = لا طلب.
    /// يبقى اللاعب عضواً كاملاً حتى يوافق المنشئ.
    /// </summary>
    public DateTime? WithdrawalRequestedAt { get; set; }
}
