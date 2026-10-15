namespace SportaApis.Models;

/// <summary>
/// An hourly slot the venue owner has marked unavailable for a specific court
/// and date. Absence of a row means the (opening-hours) slot is available.
/// </summary>
public class CourtBlockedSlot : BaseEntity
{
    public int CourtId { get; set; }
    public Court Court { get; set; } = null!;

    /// <summary>The day (date-only) the block applies to.</summary>
    public DateTime Date { get; set; }

    /// <summary>The hour of day (e.g. 6..23) that is blocked.</summary>
    public int Hour { get; set; }
}
