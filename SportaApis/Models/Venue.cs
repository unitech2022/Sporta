using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// النادي / المجمع الرياضي - يحتوي على ملاعب متعددة
/// </summary>
public class Venue : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int OwnerId { get; set; }
    public User Owner { get; set; } = null!;

    public string Country { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    public VenueGenderPolicy GenderPolicy { get; set; } = VenueGenderPolicy.Mixed;
    public string? ImageUrl { get; set; }
    public bool IsActive { get; set; } = true;

    // Navigation
    public ICollection<Court> Courts { get; set; } = [];
}
