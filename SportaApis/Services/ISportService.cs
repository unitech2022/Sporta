using SportaApis.DTOs;

namespace SportaApis.Services;

public interface ISportService
{
    /// <summary>Active sports, ordered by sort order — for public/app consumption.</summary>
    Task<List<SportDto>> GetActiveAsync();

    // Admin management (includes inactive).
    Task<List<SportDto>> GetAllAsync();
    Task<SportDto> CreateAsync(SaveSportRequest req);
    Task<SportDto> UpdateAsync(int id, SaveSportRequest req);
    Task DeleteAsync(int id);

    // Per-sport settings (title + items under it), managed by the admin.
    Task<List<SportSettingDto>> GetSettingsAsync(int sportId);
    Task<SportSettingDto> CreateSettingAsync(int sportId, SaveSportSettingRequest req);
    Task<SportSettingDto> UpdateSettingAsync(int settingId, SaveSportSettingRequest req);
    Task DeleteSettingAsync(int settingId);
}
