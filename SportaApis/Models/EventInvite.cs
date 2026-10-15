using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// دعوة صديق إلى مباراة/أمريكانو/بطولة. لا تحجز مقعداً — المدعو يفتح الحدث
/// وينضم بالطريقة العادية (ويدفع حصته). للدعوة وقت: بعد <see cref="ExpiresAt"/>
/// تُعدّ منتهية ولو بقيت Pending (الانتهاء محسوب لا مخزّن).
/// </summary>
public class EventInvite : BaseEntity
{
    public int SenderId { get; set; }
    public User Sender { get; set; } = null!;

    public int ReceiverId { get; set; }
    public User Receiver { get; set; } = null!;

    public EventInviteKind Kind { get; set; }
    public int TargetId { get; set; }

    /// <summary>وقت محلي ساذج مثل ScheduledAt (قارن بـ AppClock.Now).</summary>
    public DateTime ExpiresAt { get; set; }

    public EventInviteStatus Status { get; set; } = EventInviteStatus.Pending;
    public DateTime? RespondedAt { get; set; }
}
