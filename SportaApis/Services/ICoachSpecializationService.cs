using SportaApis.DTOs;

namespace SportaApis.Services;

public interface ICoachSpecializationService
{
    /// <summary>Active specializations, ordered by sort order — for the coach
    /// registration picker.</summary>
    Task<List<CoachSpecializationDto>> GetActiveAsync();

    // Admin management (includes inactive).
    Task<List<CoachSpecializationDto>> GetAllAsync();
    Task<CoachSpecializationDto> CreateAsync(SaveCoachSpecializationRequest req);
    Task<CoachSpecializationDto> UpdateAsync(int id, SaveCoachSpecializationRequest req);
    Task DeleteAsync(int id);
}
