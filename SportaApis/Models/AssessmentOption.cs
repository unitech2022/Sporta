namespace SportaApis.Models;

/// <summary>A selectable answer for an <see cref="AssessmentQuestion"/>.</summary>
public class AssessmentOption : BaseEntity
{
    public int QuestionId { get; set; }
    public AssessmentQuestion Question { get; set; } = null!;

    public string TextAr { get; set; } = string.Empty;
    public string TextEn { get; set; } = string.Empty;

    /// <summary>Points this option contributes to the total assessment score.</summary>
    public int Score { get; set; }

    public int SortOrder { get; set; }
}
