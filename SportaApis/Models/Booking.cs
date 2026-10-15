using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// حجز الملعب - مع سياسة الإلغاء (2.8)
/// </summary>
public class Booking : BaseEntity
{
    public int CourtId { get; set; }
    public Court Court { get; set; } = null!;

    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }

    /// <summary>الإجمالي المدفوع من اللاعب (شامل نسبة سبورتا).</summary>
    public decimal TotalPrice { get; set; }

    /// <summary>
    /// نسبة سبورتا المقتطعة من هذا الحجز (بالريال)، محفوظة وقت الدفع حتى لا
    /// تتأثر بتغيير نسبة الملعب لاحقاً. المالك يستلم <see cref="OwnerAmount"/>.
    /// </summary>
    public decimal SportaCommission { get; set; }

    /// <summary>صافي ما يُقيَّد لمالك الملعب عند الموافقة.</summary>
    public decimal OwnerAmount => TotalPrice - SportaCommission;

    public BookingStatus Status { get; set; } = BookingStatus.Pending;

    // دفع كامل أو حصة فقط
    public bool PaidFullAmount { get; set; } = false;

    public DateTime? CancelledAt { get; set; }

    /// <summary>عضوية النادي التي طُبّق خصمها على هذا الحجز (إن وُجدت).</summary>
    public int? MembershipId { get; set; }

    /// <summary>مبلغ خصم العضوية من سعر المالك.</summary>
    public decimal MemberDiscountAmount { get; set; }

    /// <summary>الدقائق المحسوبة من سقف ساعات خصم العضوية الشهري.</summary>
    public int MemberDiscountMinutes { get; set; }

    /// <summary>متى أُرسل إشعار «قيّم تجربتك» بعد انتهاء الحجز (مرة واحدة).</summary>
    public DateTime? ReviewPromptSentAt { get; set; }
    public string? CancellationReason { get; set; }
}
