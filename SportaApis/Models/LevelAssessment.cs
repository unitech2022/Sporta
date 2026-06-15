using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// تقييم المستوى الأولي عبر 3 مسارات (1.4)
/// </summary>
public class LevelAssessment : BaseEntity
{
    public int PlayerProfileId { get; set; }
    public PlayerProfile PlayerProfile { get; set; } = null!;

    public LevelAssessmentType Type { get; set; }

    // مسار 2 - رفع فيديو
    public string? VideoUrl { get; set; }

    // مسار 3 - جلسة مدرب معتمد
    public int? CoachId { get; set; }
    public User? Coach { get; set; }

    public PlayerLevel? AssignedLevel { get; set; }
    public bool IsCompleted { get; set; } = false;
    public string? Notes { get; set; }
}
