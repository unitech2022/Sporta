using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Models;

namespace SportaApis.Services;

public class LevelDefinitionService : ILevelDefinitionService
{
    private readonly AppDbContext _db;

    public LevelDefinitionService(AppDbContext db) => _db = db;

    public async Task<List<PlayerLevelDefinitionDto>> GetActiveAsync()
    {
        var items = await _db.PlayerLevelDefinitions
            .Where(l => l.IsActive)
            .OrderBy(l => l.SortOrder)
            .ThenBy(l => l.Value)
            .ToListAsync();
        return items.Select(ToDto).ToList();
    }

    public async Task<List<PlayerLevelDefinitionDto>> GetAllAsync()
    {
        var items = await _db.PlayerLevelDefinitions
            .OrderBy(l => l.SortOrder)
            .ThenBy(l => l.Value)
            .ToListAsync();
        return items.Select(ToDto).ToList();
    }

    public async Task<PlayerLevelDefinitionDto> CreateAsync(SavePlayerLevelDefinitionRequest req)
    {
        await EnsureValueFreeAsync(req.Value, exceptId: null);
        var level = new PlayerLevelDefinition();
        Apply(level, req);
        _db.PlayerLevelDefinitions.Add(level);
        await _db.SaveChangesAsync();
        return ToDto(level);
    }

    public async Task<PlayerLevelDefinitionDto> UpdateAsync(int id, SavePlayerLevelDefinitionRequest req)
    {
        var level = await FindAsync(id);
        await EnsureValueFreeAsync(req.Value, exceptId: id);
        Apply(level, req);
        level.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return ToDto(level);
    }

    public async Task DeleteAsync(int id)
    {
        var level = await FindAsync(id);
        _db.PlayerLevelDefinitions.Remove(level);
        await _db.SaveChangesAsync();
    }

    private async Task<PlayerLevelDefinition> FindAsync(int id) =>
        await _db.PlayerLevelDefinitions.FirstOrDefaultAsync(l => l.Id == id)
        ?? throw new AuthException("Level not found", "المستوى غير موجود", "LEVEL_NOT_FOUND");

    /// <summary>القيمة الرقمية فريدة — مستويان بالقيمة نفسها يُربكان المقارنة.</summary>
    private async Task EnsureValueFreeAsync(decimal value, int? exceptId)
    {
        var taken = await _db.PlayerLevelDefinitions
            .AnyAsync(l => l.Value == value && (exceptId == null || l.Id != exceptId));
        if (taken)
            throw new AuthException(
                "A level with this value already exists",
                "يوجد مستوى بهذه القيمة مسبقاً", "LEVEL_VALUE_TAKEN");
    }

    private static void Apply(PlayerLevelDefinition level, SavePlayerLevelDefinitionRequest req)
    {
        // خطوة نصف درجة كما في الوثيقة (3.0، 3.5، …).
        level.Value = Math.Round(req.Value * 2m, MidpointRounding.AwayFromZero) / 2m;
        level.TitleAr = req.TitleAr.Trim();
        level.TitleEn = req.TitleEn.Trim();
        level.DescriptionAr = string.IsNullOrWhiteSpace(req.DescriptionAr) ? null : req.DescriptionAr.Trim();
        level.DescriptionEn = string.IsNullOrWhiteSpace(req.DescriptionEn) ? null : req.DescriptionEn.Trim();
        level.SortOrder = req.SortOrder;
        level.IsActive = req.IsActive;
    }

    private static PlayerLevelDefinitionDto ToDto(PlayerLevelDefinition l) => new()
    {
        Id = l.Id,
        Value = l.Value,
        TitleAr = l.TitleAr,
        TitleEn = l.TitleEn,
        DescriptionAr = l.DescriptionAr,
        DescriptionEn = l.DescriptionEn,
        SortOrder = l.SortOrder,
        IsActive = l.IsActive,
    };
}
