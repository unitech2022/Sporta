namespace SportaApis.Models;

/// <summary>
/// رسالة واحدة داخل <see cref="SupportConversation"/>.
/// وقت الإرسال هو <see cref="BaseEntity.CreatedAt"/> ويُضبط من
/// <see cref="Helpers.AppClock"/> (ساعة التطبيق) لا من UTC.
/// </summary>
public class SupportMessage : BaseEntity
{
    public int ConversationId { get; set; }
    public SupportConversation Conversation { get; set; } = null!;

    /// <summary>كاتب الرسالة — معرّف حساب إداري في ردود الدعم.</summary>
    public int SenderUserId { get; set; }

    /// <summary>
    /// نسخة من اسم المُرسِل وقت الإرسال، حتى يبقى الاسم صحيحاً في السجل ولو
    /// تغيّر اسم الحساب أو حُذف الموظف لاحقاً.
    /// </summary>
    public string SenderName { get; set; } = string.Empty;

    /// <summary>true لردود الإدارة، false لرسائل صاحب المحادثة.</summary>
    public bool FromAdmin { get; set; }

    public string Body { get; set; } = string.Empty;

    /// <summary>وقت فتح الطرف الآخر للرسالة (null = لم تُقرأ بعد).</summary>
    public DateTime? ReadAt { get; set; }
}
