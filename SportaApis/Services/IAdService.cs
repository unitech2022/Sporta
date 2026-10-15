using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IAdService
{
    /// <summary>
    /// Active ads/banners ordered by sort order. <paramref name="page"/> filters by
    /// placement ("home" | "courts" | "matches" | "coaches"); null returns all.
    /// </summary>
    Task<List<AdDto>> GetActiveAsync(string? page = null);

    // Admin management (includes inactive).
    Task<List<AdDto>> GetAllAsync();
    Task<AdDto> CreateAsync(SaveAdRequest req);
    Task<AdDto> UpdateAsync(int id, SaveAdRequest req);
    Task DeleteAsync(int id);
}
