namespace SportaApis.Models;

/// <summary>
/// رسالة في دردشة حدث (مباراة/أمريكانو/بطولة — كلها <see cref="Match"/>).
/// رسائل النظام («انضم فلان»، «انسحب فلان») بلا مُرسِل. الوقت
/// <see cref="BaseEntity.CreatedAt"/> بساعة التطبيق (<see cref="Helpers.AppClock"/>).
/// </summary>
public class EventChatMessage : BaseEntity
{
    public int MatchId { get; set; }
    public Match Match { get; set; } = null!;

    /// <summary>null لرسائل النظام.</summary>
    public int? SenderUserId { get; set; }

    /// <summary>اسم المُرسِل وقت الإرسال — يبقى صحيحاً ولو تغيّر اسم الحساب.</summary>
    public string SenderName { get; set; } = string.Empty;

    public bool IsSystem { get; set; }

    public string Body { get; set; } = string.Empty;

    /// <summary>حذفها كاتبها أو المنظّم: تبقى في السجل «رسالة محذوفة».</summary>
    public DateTime? DeletedAt { get; set; }

    /// <summary>الرسالة التي يُردّ عليها (في الحدث نفسه).</summary>
    public int? ReplyToId { get; set; }

    /// <summary>مرفق مرفوع عبر <c>/api/event-chat/{id}/attachments</c>.</summary>
    public string? AttachmentUrl { get; set; }
    public string? AttachmentName { get; set; }

    /// <summary>"image" | "file".</summary>
    public string? AttachmentType { get; set; }
    public long? AttachmentSize { get; set; }

    /// <summary>معرّفات الأعضاء المشار إليهم بـ @، مفصولة بفواصل.</summary>
    public string? MentionedUserIds { get; set; }

    public ICollection<EventChatReaction> Reactions { get; set; } = [];
}

/// <summary>تفاعل عضو مع رسالة — واحد لكل عضو (اختيار آخر يستبدله) كواتساب.</summary>
public class EventChatReaction
{
    public int Id { get; set; }
    public int MessageId { get; set; }
    public EventChatMessage Message { get; set; } = null!;
    public int UserId { get; set; }

    /// <summary>رمز التفاعل (إيموجي).</summary>
    public string Emoji { get; set; } = string.Empty;
}

/// <summary>آخر رسالة قرأها عضو في دردشة حدث — مصدر عدّاد غير المقروء.</summary>
public class EventChatReadState
{
    public int Id { get; set; }
    public int MatchId { get; set; }
    public int UserId { get; set; }
    public int LastReadMessageId { get; set; }
}
