namespace SportaApis.DTOs;

/// <summary>رسالة واحدة كما يراها الطرفان.</summary>
public class SupportMessageDto
{
    public int Id { get; set; }
    public int ConversationId { get; set; }

    /// <summary>true = رسالة من الإدارة، false = من صاحب المحادثة.</summary>
    public bool FromAdmin { get; set; }

    public string SenderName { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public DateTime SentAt { get; set; }

    /// <summary>وقت قراءة الطرف الآخر لها (null = لم تُقرأ).</summary>
    public DateTime? ReadAt { get; set; }
}

/// <summary>ملخّص محادثة — عنصر قائمة صندوق الإدارة، ورأس الشاشة لدى المستخدم.</summary>
public class SupportConversationDto
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string UserPhone { get; set; } = string.Empty;
    public string? UserImageUrl { get; set; }

    /// <summary>أدوار الحساب ("player" / "coach" / "venueowner" …).</summary>
    public List<string> UserRoles { get; set; } = [];

    /// <summary>"Open" أو "Closed".</summary>
    public string Status { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
    public DateTime LastMessageAt { get; set; }
    public string LastMessageText { get; set; } = string.Empty;
    public bool LastMessageFromAdmin { get; set; }
    public int UnreadForAdmin { get; set; }
    public int UnreadForUser { get; set; }
}

/// <summary>صفحة من سجل الرسائل (ترقيم بمؤشّر تنازلي على المعرّف).</summary>
public class SupportMessagePageDto
{
    /// <summary>false لدى المستخدم إذا لم يبدأ أي محادثة بعد.</summary>
    public bool Exists { get; set; }

    public SupportConversationDto? Conversation { get; set; }
    public List<SupportMessageDto> Messages { get; set; } = [];

    /// <summary>هل توجد رسائل أقدم قبل أول عنصر في <see cref="Messages"/>؟</summary>
    public bool HasMore { get; set; }
}

/// <summary>قائمة محادثات الإدارة + إجمالي غير المقروء عبر كل المحادثات.</summary>
public class SupportInboxDto
{
    public PagedResult<SupportConversationDto> Conversations { get; set; } = new();

    /// <summary>عدد المحادثات التي فيها رسائل لم تفتحها الإدارة.</summary>
    public int UnreadTotal { get; set; }
}

public class SendSupportMessageRequest
{
    public string Body { get; set; } = string.Empty;
}

/// <summary>بدء محادثة من طرف الإدارة مع حساب محدد.</summary>
public class StartSupportConversationRequest
{
    public int UserId { get; set; }

    /// <summary>رسالة أولى اختيارية تُرسل فور إنشاء المحادثة.</summary>
    public string? Body { get; set; }
}
