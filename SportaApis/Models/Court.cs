using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// الملعب الفردي داخل النادي
/// </summary>
public class Court : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public int VenueId { get; set; }
    public Venue Venue { get; set; } = null!;

    public CourtType Type { get; set; }
    public decimal PricePerHour { get; set; }
    public bool IsAvailable { get; set; } = true;
    public string? ImageUrl { get; set; }

    // Navigation
    public ICollection<Booking> Bookings { get; set; } = [];
    public ICollection<Match> Matches { get; set; } = [];
}
