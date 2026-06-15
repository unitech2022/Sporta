namespace SportaApis.Models;

/// <summary>
/// جلسة تدريبية مع مدرب - كورس تدريبي (4.3)
/// </summary>
public class CoachSession : BaseEntity
{
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
    public decimal Price { get; set; }

    public bool IsCompleted { get; set; } = false;
    public int? PlayerRating { get; set; } // 1-5
    public string? PlayerReview { get; set; }
}
