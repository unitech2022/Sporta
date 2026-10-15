using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// جلسة تدريبية مع مدرب - كورس تدريبي (4.3)
/// </summary>
public class CoachSession : BaseEntity
{
    /// <summary>Pending = booking request awaiting the coach's approval.</summary>
    public CoachSessionStatus Status { get; set; } = CoachSessionStatus.Confirmed;

    public int CoachProfileId { get; set; }
    public CoachProfile CoachProfile { get; set; } = null!;

    public int PlayerId { get; set; }
    public User Player { get; set; } = null!;

    public int? CourtId { get; set; }
    public Court? Court { get; set; }

    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }

    // مستوى الدرس: مبتدئ / متوسط / متقدم
    public string TargetLevel { get; set; } = string.Empty;

    public DateTime ScheduledAt { get; set; }
    public int DurationMinutes { get; set; } = 60;

    /// <summary>ما يدفعه اللاعب فعلاً — بعد خصم عرض المدرب إن وُجد.</summary>
    public decimal Price { get; set; }

    /// <summary>
    /// السعر قبل خصم العرض (سعر الساعة × المدة) — لقطة وقت الحجز حتى لا يتأثر
    /// بتغيير سعر المدرب لاحقاً. يساوي <see cref="Price"/> حين لا يوجد عرض.
    /// </summary>
    public decimal BasePrice { get; set; }

    /// <summary>نسبة خصم عرض المدرب المطبَّقة على هذه الجلسة (٠ حين لا عرض).</summary>
    public decimal OfferDiscountPercent { get; set; }

    /// <summary>
    /// نسبة سبورتا وقت تأكيد الجلسة (لقطة، فلا يغيّر تعديلها لاحقاً مستحقات
    /// جلسة سابقة). تُقتطع من مستحقات المدرب — اللاعب يدفع السعر المعروض.
    /// </summary>
    public decimal SportaCommissionPercent { get; set; }


    /// <summary>ما يدفعه اللاعب: سعر المدرب + نسبة سبورتا المضافة فوقه.</summary>
    public decimal PlayerTotal() =>
        Math.Round(Price * (1m + SportaCommissionPercent / 100m), 2);

    /// <summary>مستحقات المدرب — سعره كاملاً؛ نسبة سبورتا يدفعها اللاعب فوقه.</summary>
    public decimal CoachNetAmount() => Price;

    public bool IsCompleted { get; set; } = false;
    public bool IsPaid { get; set; } = false;

    // تقييم المدرب للاعب (1-5) — يُسمح به فقط بعد الدفع وانتهاء وقت الجلسة.
    public int? CoachRating { get; set; }
    public string? CoachReview { get; set; }

    // تقييم اللاعب للمدرب (1-5) — يغذّي تقييم المدرب المعروض وشارة "معتمد".
    public int? PlayerRating { get; set; }
    public string? PlayerReview { get; set; }

    /// <summary>متى أُرسل إشعار «قيّم تجربتك» بعد انتهاء الجلسة (مرة واحدة).</summary>
    public DateTime? ReviewPromptSentAt { get; set; }
}
