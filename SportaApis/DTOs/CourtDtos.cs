namespace SportaApis.DTOs;

// ── Responses ─────────────────────────────────────────────────────────────────

/// <summary>
/// A bookable court (flattened with its parent venue) as consumed by the app's
/// courts list and booking screens.
/// </summary>
public class CourtDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    public int VenueId { get; set; }
    public string VenueName { get; set; } = string.Empty;

    public string Country { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string Neighborhood { get; set; } = string.Empty;

    /// <summary>"indoor" | "outdoor".</summary>
    public string Type { get; set; } = "indoor";

    /// <summary>"all" | "men" | "women" | "family" (derived from the venue policy).</summary>
    public string Gender { get; set; } = "all";

    public decimal BasePrice { get; set; }
    public decimal PeakHourPrice { get; set; }

    public bool IsAvailable { get; set; } = true;
    public string? ImageUrl { get; set; }

    /// <summary>Selectable session durations (minutes).</summary>
    public List<int> AvailableDurations { get; set; } = [60, 90, 120];

    /// <summary>Daily opening slots (HH:mm), independent of date.</summary>
    public List<string> AvailableTimes { get; set; } = [];
}

/// <summary>Per-date slot availability for a single court.</summary>
public class CourtAvailabilityDto
{
    /// <summary>The requested date (yyyy-MM-dd).</summary>
    public string Date { get; set; } = string.Empty;
    public List<TimeSlotDto> Slots { get; set; } = [];
}

public class TimeSlotDto
{
    /// <summary>Slot start time (HH:mm).</summary>
    public string Time { get; set; } = string.Empty;
    public bool IsBooked { get; set; }
    public decimal Price { get; set; }
    public bool IsPeak { get; set; }
}
