namespace SportaApis.Models;

/// <summary>
/// الإشعارات الفورية للمستخدم
/// </summary>
public class Notification : BaseEntity
{
    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string? ActionUrl { get; set; }
    public bool IsRead { get; set; } = false;

    // مرجع الإشعار (مباراة أو حجز أو صداقة)
    public string? ReferenceType { get; set; }
    public int? ReferenceId { get; set; }
}
