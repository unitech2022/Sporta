using System.Text;
using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Models;

namespace SportaApis.Services;

public class SportService : ISportService
{
    private readonly AppDbContext _db;

    public SportService(AppDbContext db) => _db = db;

    public async Task<List<SportDto>> GetActiveAsync()
    {
        var items = await _db.Sports
            .Where(s => s.IsActive)
            .OrderBy(s => s.SortOrder)
            .ThenBy(s => s.Id)
            .ToListAsync();
        return items.Select(ToDto).ToList();
    }

    public async Task<List<SportDto>> GetAllAsync()
    {
        var items = await _db.Sports
            .OrderBy(s => s.SortOrder)
            .ThenBy(s => s.Id)
            .ToListAsync();
        return items.Select(ToDto).ToList();
    }

    public async Task<SportDto> CreateAsync(SaveSportRequest req)
    {
        var sport = new Sport { Key = await MakeUniqueKeyAsync(req.NameEn) };
        Apply(sport, req);
        _db.Sports.Add(sport);
        await _db.SaveChangesAsync();
        return ToDto(sport);
    }

    public async Task<SportDto> UpdateAsync(int id, SaveSportRequest req)
    {
        var sport = await _db.Sports.FirstOrDefaultAsync(s => s.Id == id)
            ?? throw new AuthException("Sport not found", "اللعبة غير موجودة", "SPORT_NOT_FOUND");
        // Key is derived once at creation and never changed, so existing
        // references (assessment questions/levels, favorite sport) keep working.
        Apply(sport, req);
        sport.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return ToDto(sport);
    }

    public async Task DeleteAsync(int id)
    {
        var sport = await _db.Sports.FirstOrDefaultAsync(s => s.Id == id)
            ?? throw new AuthException("Sport not found", "اللعبة غير موجودة", "SPORT_NOT_FOUND");
        _db.Sports.Remove(sport);
        await _db.SaveChangesAsync();
    }

    // ── Per-sport settings ───────────────────────────────────────────────────

    public async Task<List<SportSettingDto>> GetSettingsAsync(int sportId)
    {
        var items = await _db.SportSettings
            .Where(s => s.SportId == sportId)
            .OrderBy(s => s.SortOrder)
            .ThenBy(s => s.Id)
            .ToListAsync();
        return items.Select(ToSettingDto).ToList();
    }

    public async Task<SportSettingDto> CreateSettingAsync(int sportId, SaveSportSettingRequest req)
    {
        var sportExists = await _db.Sports.AnyAsync(s => s.Id == sportId);
        if (!sportExists)
            throw new AuthException("Sport not found", "اللعبة غير موجودة", "SPORT_NOT_FOUND");

        var setting = new SportSetting { SportId = sportId };
        ApplySetting(setting, req);
        _db.SportSettings.Add(setting);
        await _db.SaveChangesAsync();
        return ToSettingDto(setting);
    }

    public async Task<SportSettingDto> UpdateSettingAsync(int settingId, SaveSportSettingRequest req)
    {
        var setting = await _db.SportSettings.FirstOrDefaultAsync(s => s.Id == settingId)
            ?? throw new AuthException("Setting not found", "الإعداد غير موجود", "SPORT_SETTING_NOT_FOUND");
        ApplySetting(setting, req);
        setting.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return ToSettingDto(setting);
    }

    public async Task DeleteSettingAsync(int settingId)
    {
        var setting = await _db.SportSettings.FirstOrDefaultAsync(s => s.Id == settingId)
            ?? throw new AuthException("Setting not found", "الإعداد غير موجود", "SPORT_SETTING_NOT_FOUND");
        _db.SportSettings.Remove(setting);
        await _db.SaveChangesAsync();
    }

    private static void ApplySetting(SportSetting setting, SaveSportSettingRequest req)
    {
        setting.Title = req.Title.Trim();
        setting.ItemsText = string.Join(
            '\n',
            req.Items.Select(i => i.Trim()).Where(i => i.Length > 0));
        setting.SortOrder = req.SortOrder;
    }

    private static SportSettingDto ToSettingDto(SportSetting s) => new()
    {
        Id = s.Id,
        SportId = s.SportId,
        Title = s.Title,
        Items = s.ItemsText
            .Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .ToList(),
        SortOrder = s.SortOrder,
    };

    private async Task<string> MakeUniqueKeyAsync(string nameEn)
    {
        var baseKey = Slugify(nameEn);
        if (string.IsNullOrEmpty(baseKey)) baseKey = "sport";

        var key = baseKey;
        var suffix = 2;
        while (await _db.Sports.AnyAsync(s => s.Key == key))
            key = $"{baseKey}{suffix++}";
        return key;
    }

    private static string Slugify(string value)
    {
        var sb = new StringBuilder();
        foreach (var ch in value.Trim().ToLowerInvariant())
        {
            if (char.IsLetterOrDigit(ch)) sb.Append(ch);
            else if (sb.Length > 0 && sb[^1] != '-') sb.Append('-');
        }
        return sb.ToString().Trim('-');
    }

    private static void Apply(Sport sport, SaveSportRequest req)
    {
        sport.NameAr = req.Name.Trim();
        sport.NameEn = req.NameEn.Trim();
        sport.ImageUrl = string.IsNullOrWhiteSpace(req.Image) ? null : req.Image.Trim();
        sport.Description = string.IsNullOrWhiteSpace(req.Description) ? null : req.Description.Trim();
        sport.PlayersPerMatch = req.Players;
        sport.DurationMinutes = req.Duration;
        sport.IsActive = req.IsActive;
        sport.SortOrder = req.SortOrder;
    }

    private static SportDto ToDto(Sport s) => new()
    {
        Id = s.Id,
        Key = s.Key,
        Name = s.NameAr,
        NameEn = s.NameEn,
        Image = s.ImageUrl,
        Description = s.Description,
        Players = s.PlayersPerMatch,
        Duration = s.DurationMinutes,
        IsActive = s.IsActive,
        SortOrder = s.SortOrder,
        CreatedAt = s.CreatedAt.ToString("yyyy-MM-dd"),
    };
}
