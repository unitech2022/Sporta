using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

public class EventChatMessageDto
{
    public int Id { get; set; }
    public int MatchId { get; set; }
    public int? SenderUserId { get; set; }
    public string SenderName { get; set; } = string.Empty;
    public string? SenderAvatarUrl { get; set; }

    /// <summary>"organizer" | "venue" | "player" | null (نظام).</summary>
    public string? SenderRole { get; set; }
    public bool IsSystem { get; set; }
    public bool IsDeleted { get; set; }
    public string Body { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }

    public EventChatReplyDto? ReplyTo { get; set; }

    public string? AttachmentUrl { get; set; }
    public string? AttachmentName { get; set; }

    /// <summary>"image" | "file".</summary>
    public string? AttachmentType { get; set; }
    public long? AttachmentSize { get; set; }

    public List<int> MentionedUserIds { get; set; } = [];

    /// <summary>التفاعلات مجمّعة بالرمز، ومعها من تفاعل (ليعرف العميل تفاعله).</summary>
    public List<EventChatReactionDto> Reactions { get; set; } = [];
}

/// <summary>اقتباس الرسالة المردود عليها داخل الفقاعة.</summary>
public class EventChatReplyDto
{
    public int Id { get; set; }
    public string SenderName { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string? AttachmentType { get; set; }
    public bool IsDeleted { get; set; }
}

public class EventChatReactionDto
{
    public string Emoji { get; set; } = string.Empty;
    public List<int> UserIds { get; set; } = [];
}

/// <summary>نتيجة رفع مرفق: يُمرَّر كما هو مع رسالة الإرسال.</summary>
public class EventChatAttachmentDto
{
    public string Url { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Type { get; set; } = "file";
    public long Size { get; set; }
}

public class EventChatReactRequest
{
    /// <summary>الرمز؛ فارغ أو null يزيل تفاعل المستخدم.</summary>
    [MaxLength(16)] public string? Emoji { get; set; }
}

public class EventChatMemberDto
{
    public int UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }

    /// <summary>"organizer" | "venue" | "player".</summary>
    public string Role { get; set; } = "player";
}

/// <summary>رأس الدردشة: من فيها، وهل الكتابة متاحة، وعدد غير المقروء.</summary>
public class EventChatSummaryDto
{
    public int MatchId { get; set; }

    /// <summary>"match" | "americano" | "tournament".</summary>
    public string Kind { get; set; } = "match";
    public int RefId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? VenueName { get; set; }
    public DateTime ScheduledAt { get; set; }

    /// <summary>المستخدم عضو (لاعب معتمد أو المنشئ).</summary>
    public bool IsMember { get; set; }

    /// <summary>الكتابة متاحة — تصير للقراءة فقط بعد انتهاء الحدث أو إلغائه.</summary>
    public bool CanWrite { get; set; }

    /// <summary>المستخدم هو المنظّم فيحذف أي رسالة.</summary>
    public bool CanModerate { get; set; }

    public int UnreadCount { get; set; }
    public List<EventChatMemberDto> Members { get; set; } = [];
}

public class SendEventChatMessageRequest
{
    /// <summary>نص الرسالة — اختياري حين يوجد مرفق.</summary>
    [MaxLength(1000)] public string? Body { get; set; }
    public int? ReplyToId { get; set; }
    public EventChatAttachmentDto? Attachment { get; set; }
    public List<int>? MentionedUserIds { get; set; }
}
