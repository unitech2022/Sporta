using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// سجل دفتري لحركات نقاط الولاء (على غرار WalletTransaction) —
/// الرصيد الجاري مخزَّن في <see cref="User.PointsBalance"/> ويتحدّث مع كل حركة.
/// </summary>
public class PointsTransaction : BaseEntity
{
    public int UserId { get; set; }
    public User User { get; set; } = null!;

    /// <summary>عدد النقاط: موجب = كسب، سالب = استبدال/عكس/خصم.</summary>
    public int Amount { get; set; }

    public PointsTransactionType Type { get; set; }

    /// <summary>مكافآت (الرصيد في User.PointsBalance) أو مستوى (User.LevelPoints).</summary>
    public PointsKind Kind { get; set; } = PointsKind.Reward;

    public string? Description { get; set; }

    // مرجع العملية المسبِّبة (حجز/مباراة/جلسة/اشتراك) حسب النوع
    public int? ReferenceId { get; set; }
}
