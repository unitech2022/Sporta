using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

public class SendEventInviteRequest
{
    /// <summary>"match" | "americano" | "tournament".</summary>
    [Required] public string Kind { get; set; } = "match";

    /// <summary>معرّف المباراة، أو معرّف الأمريكانو/البطولة.</summary>
    [Required] public int TargetId { get; set; }

    [Required, MinLength(1), MaxLength(20)] public List<int> UserIds { get; set; } = [];

    /// <summary>صلاحية الدعوة بالدقائق؛ null = حتى موعد الحدث. تُقصّ دائماً عند موعده.</summary>
    [Range(15, 60 * 24 * 14)] public int? ExpiresInMinutes { get; set; }
}

public class SendEventInviteResultDto
{
    public int Sent { get; set; }

    /// <summary>من تخطّاهم الإرسال ولماذا (ليس صديقاً، مشارك بالفعل، مدعو بالفعل…).</summary>
    public List<SkippedInviteDto> Skipped { get; set; } = [];

    public DateTime ExpiresAt { get; set; }
}

public class SkippedInviteDto
{
    public int UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string ReasonAr { get; set; } = string.Empty;
}

public class EventInviteDto
{
    public int Id { get; set; }
    public string Kind { get; set; } = "match";
    public int TargetId { get; set; }
    public int SenderId { get; set; }
    public string SenderName { get; set; } = string.Empty;
    public int ReceiverId { get; set; }
    public string ReceiverName { get; set; } = string.Empty;

    /// <summary>«مباراة في نادي…» / اسم البطولة — للعرض في القوائم.</summary>
    public string TargetTitle { get; set; } = string.Empty;
    public DateTime? TargetStartsAt { get; set; }

    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; }

    /// <summary>"pending" | "accepted" | "declined" | "expired".</summary>
    public string Status { get; set; } = "pending";
}
