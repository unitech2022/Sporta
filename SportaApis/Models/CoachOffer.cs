namespace SportaApis.Models;

/// <summary>
/// عرض أو خصم يضيفه المدرب على صفحته العامة، يظهر للاعبين قبل الحجز.
/// </summary>
public class CoachOffer : BaseEntity
{
    public int CoachProfileId { get; set; }
    public CoachProfile CoachProfile { get; set; } = null!;

    public string Title { get; set; } = string.Empty;
    public int DiscountPercent { get; set; }

    /// <summary>"individual" | "group" | "all" — نوع الحصص المشمولة بالعرض.</summary>
    public string TargetLabel { get; set; } = "all";

    public DateTime ExpiresAt { get; set; }
    public bool IsActive { get; set; } = true;
}
