using SportaApis.DTOs;

namespace SportaApis.Services;

public interface ICourtService
{
    /// <summary>Lists bookable courts, optionally filtered by city / type / gender.</summary>
    Task<List<CourtDto>> GetCourtsAsync(string? city, string? type, string? gender);

    /// <summary>Returns a single court (flattened with its venue).</summary>
    Task<CourtDto> GetCourtByIdAsync(int id);

    /// <summary>Returns the per-slot availability for a court on a given date.</summary>
    Task<CourtAvailabilityDto> GetAvailabilityAsync(int courtId, DateTime date);
}
