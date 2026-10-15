namespace SportaApis.Models;

/// <summary>صورة من صور الملعب/النادي (يمكن رفع عدة صور لكل نادٍ).</summary>
public class VenueImage : BaseEntity
{
    public int VenueId { get; set; }
    public Venue Venue { get; set; } = null!;

    /// <summary>رابط الملف المرفوع (نسبي: /uploads/images/...).</summary>
    public string Url { get; set; } = string.Empty;
}
