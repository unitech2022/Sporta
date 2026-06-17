using SportaApis.Models;

namespace SportaApis.Helpers;

/// <summary>
/// Shared opening-hours and pricing rules for courts, so that the courts list,
/// availability and booking flows all agree on slots and prices.
/// </summary>
public static class CourtSchedule
{
    /// <summary>First bookable hour of the day (inclusive).</summary>
    public const int OpenHour = 6;

    /// <summary>Last bookable hour of the day (inclusive).</summary>
    public const int LastSlotHour = 23;

    /// <summary>Peak pricing applies from this hour onwards.</summary>
    public const int PeakStartHour = 16;

    /// <summary>Peak hours cost 1.5× the base rate.</summary>
    public const decimal PeakMultiplier = 1.5m;

    /// <summary>Opening slot start times for the day, e.g. "06:00".</summary>
    public static List<string> OpeningSlots() =>
        Enumerable.Range(OpenHour, LastSlotHour - OpenHour + 1)
            .Select(h => $"{h:D2}:00")
            .ToList();

    public static bool IsPeak(int hour) => hour >= PeakStartHour;

    public static decimal BasePrice(Court court) => court.PricePerHour;

    public static decimal PeakPrice(Court court) =>
        Math.Round(court.PricePerHour * PeakMultiplier, 2);

    /// <summary>Hourly rate for a slot that starts at <paramref name="hour"/>.</summary>
    public static decimal HourlyRate(Court court, int hour) =>
        IsPeak(hour) ? PeakPrice(court) : BasePrice(court);

    /// <summary>Total price for a session that starts at <paramref name="start"/>.</summary>
    public static decimal TotalPrice(Court court, DateTime start, int durationMinutes) =>
        Math.Round(HourlyRate(court, start.Hour) * (decimal)durationMinutes / 60m, 2);
}
