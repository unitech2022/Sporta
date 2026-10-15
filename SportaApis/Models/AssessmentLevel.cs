namespace SportaApis.Models;

/// <summary>
/// An admin-defined player level for a given sport. The self-assessment total
/// score is mapped to the highest level whose <see cref="MinScore"/> it reaches.
/// </summary>
public class AssessmentLevel : BaseEntity
{
    /// <summary>Sport key, e.g. "padel". Each sport has its own levels.</summary>
    public string Sport { get; set; } = "padel";

    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string? DescriptionAr { get; set; }
    public string? DescriptionEn { get; set; }

    /// <summary>Minimum total score required to reach this level.</summary>
    public int MinScore { get; set; }

    /// <summary>Display/rank order within the sport (1 = lowest).</summary>
    public int SortOrder { get; set; }

    public bool IsActive { get; set; } = true;
}
