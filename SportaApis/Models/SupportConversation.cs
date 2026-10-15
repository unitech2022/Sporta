using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// محادثة الدعم الفني بين حساب واحد (لاعب/مدرب/مالك ملعب) وفريق الإدارة.
/// لكل مستخدم محادثة واحدة فقط تُستأنف في كل مرة، حتى يبقى السجل متصلاً بدل
/// إنشاء تذكرة جديدة مع كل رسالة.
///
/// أوقات هذا الجدول مخزّنة على ساعة التطبيق (<see cref="Helpers.AppClock"/>،
/// السعودية UTC+3) لا على UTC، لأن التطبيق يعرضها كما هي بدون تحويل — مثل
/// بقية أوقات المباريات والحجوزات.
/// </summary>
public class SupportConversation : BaseEntity
{
    /// <summary>صاحب المحادثة (الطرف غير الإداري).</summary>
    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public SupportConversationStatus Status { get; set; } = SupportConversationStatus.Open;

    /// <summary>وقت آخر رسالة — مفتاح ترتيب قائمة الإدارة.</summary>
    public DateTime LastMessageAt { get; set; }

    /// <summary>مقتطف آخر رسالة، حتى تعرض القائمة بدون join على الرسائل.</summary>
    public string LastMessageText { get; set; } = string.Empty;

    /// <summary>true إذا كانت آخر رسالة من الإدارة.</summary>
    public bool LastMessageFromAdmin { get; set; }

    /// <summary>رسائل لم تفتحها الإدارة بعد.</summary>
    public int UnreadForAdmin { get; set; }

    /// <summary>ردود لم يفتحها المستخدم بعد — تغذّي شارة العدّاد في التطبيق.</summary>
    public int UnreadForUser { get; set; }

    public DateTime? ClosedAt { get; set; }

    public ICollection<SupportMessage> Messages { get; set; } = [];
}
