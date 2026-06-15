namespace SportaApis.Models;

/// <summary>
/// الملف الشخصي للمدرب المعتمد على المنصة
/// </summary>
public class CoachProfile : BaseEntity
{
    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public string? Bio { get; set; }
    public string? Specialization { get; set; }
    public decimal HourlyRate { get; set; }
    public bool IsVerifiedOnPlatform { get; set; } = false;

    // إحصائيات
    public float Rating { get; set; } = 0f;
    public int TotalSessions { get; set; } = 0;
    public int TotalRatings { get; set; } = 0;

    // Navigation
    public ICollection<CoachSession> Sessions { get; set; } = [];
}
