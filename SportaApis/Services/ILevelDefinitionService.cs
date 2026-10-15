using SportaApis.DTOs;

namespace SportaApis.Services;

/// <summary>سُلَّم المستويات المعروض في التطبيق (يُدار من لوحة التحكم).</summary>
public interface ILevelDefinitionService
{
    /// <summary>المستويات النشطة بترتيب العرض — للتطبيق.</summary>
    Task<List<PlayerLevelDefinitionDto>> GetActiveAsync();

    // Admin management (includes inactive).
    Task<List<PlayerLevelDefinitionDto>> GetAllAsync();
    Task<PlayerLevelDefinitionDto> CreateAsync(SavePlayerLevelDefinitionRequest req);
    Task<PlayerLevelDefinitionDto> UpdateAsync(int id, SavePlayerLevelDefinitionRequest req);
    Task DeleteAsync(int id);
}
