using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

// ── Requests ──────────────────────────────────────────────────────────────────

public class CreateBookingRequest
{
    [Required] public int CourtId { get; set; }

    /// <summary>Slot start time. Sent by the app as a local date+time.</summary>
    [Required] public DateTime StartTime { get; set; }

    [Range(30, 240)] public int DurationMinutes { get; set; } = 60;

    /// <summary>Whether the user paid the full amount up-front (vs. their share only).</summary>
    public bool PaidFullAmount { get; set; } = true;
}

// ── Responses ─────────────────────────────────────────────────────────────────

public class BookingDto
{
    public int Id { get; set; }

    public int CourtId { get; set; }
    public string CourtName { get; set; } = string.Empty;
    public string VenueName { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;

    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public int DurationMinutes { get; set; }

    public decimal TotalPrice { get; set; }

    /// <summary>"Pending" | "Confirmed" | "Cancelled" | "Completed".</summary>
    public string Status { get; set; } = string.Empty;
    public bool PaidFullAmount { get; set; }
}
