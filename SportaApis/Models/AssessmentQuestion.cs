namespace SportaApis.Models;

/// <summary>
/// An admin-authored self-assessment question for a sport, with its options.
/// </summary>
public class AssessmentQuestion : BaseEntity
{
    /// <summary>Sport key, e.g. "padel". Each sport has its own questions.</summary>
    public string Sport { get; set; } = "padel";

    public string TextAr { get; set; } = string.Empty;
    public string TextEn { get; set; } = string.Empty;

    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;

    public ICollection<AssessmentOption> Options { get; set; } = [];
}
