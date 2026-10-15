using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Models;

namespace SportaApis.Services;

public class AdService : IAdService
{
    private readonly AppDbContext _db;

    public AdService(AppDbContext db) => _db = db;

    public async Task<List<AdDto>> GetActiveAsync(string? page = null)
    {
        var query = _db.Ads.Where(a => a.IsActive);

        if (!string.IsNullOrWhiteSpace(page))
        {
            // مطابقة نصية بسيطة (LIKE) تكفي هنا لأن أسماء الأماكن متمايزة ولا
            // يحتوي أيٌّ منها الآخر. والإعلانات القديمة (Placements فارغة)
            // تُعامَل كإعلانات الرئيسية.
            var key = page.Trim().ToLowerInvariant();
            var isHome = key == HomePlacement;
            query = query.Where(a =>
                a.Placements.Contains(key)
                || (isHome && a.Placements == ""));
        }

        var items = await query
            .OrderBy(a => a.SortOrder)
            .ThenByDescending(a => a.Id)
            .ToListAsync();
        return items.Select(ToDto).ToList();
    }

    public async Task<List<AdDto>> GetAllAsync()
    {
        var items = await _db.Ads
            .OrderBy(a => a.SortOrder)
            .ThenByDescending(a => a.Id)
            .ToListAsync();
        return items.Select(ToDto).ToList();
    }

    public async Task<AdDto> CreateAsync(SaveAdRequest req)
    {
        var ad = new Ad();
        Apply(ad, req);
        _db.Ads.Add(ad);
        await _db.SaveChangesAsync();
        return ToDto(ad);
    }

    public async Task<AdDto> UpdateAsync(int id, SaveAdRequest req)
    {
        var ad = await _db.Ads.FirstOrDefaultAsync(a => a.Id == id)
            ?? throw new AuthException("Ad not found", "الإعلان غير موجود", "AD_NOT_FOUND");
        Apply(ad, req);
        ad.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return ToDto(ad);
    }

    public async Task DeleteAsync(int id)
    {
        var ad = await _db.Ads.FirstOrDefaultAsync(a => a.Id == id)
            ?? throw new AuthException("Ad not found", "الإعلان غير موجود", "AD_NOT_FOUND");
        _db.Ads.Remove(ad);
        await _db.SaveChangesAsync();
    }

    private const string HomePlacement = "home";

    /// <summary>أسماء الصفحات المسموح بها لظهور الإعلان.</summary>
    private static readonly string[] AllowedPlacements =
        { HomePlacement, "courts", "matches", "coaches" };

    /// <summary>
    /// يوحّد قائمة أماكن الظهور: أحرف صغيرة، بدون مسافات أو تكرار، مع تجاهل
    /// أي اسم غير معروف. الفارغ يرجع "home" حتى لا يختفي الإعلان تمامًا.
    /// </summary>
    private static string NormalizePlacements(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
            return HomePlacement;

        var parts = raw
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(p => p.ToLowerInvariant())
            .Where(p => AllowedPlacements.Contains(p))
            .Distinct()
            .ToList();

        return parts.Count == 0 ? HomePlacement : string.Join(',', parts);
    }

    private static void Apply(Ad ad, SaveAdRequest req)
    {
        ad.Title = req.Title.Trim();
        ad.Subtitle = req.Subtitle.Trim();
        ad.TitleEn = string.IsNullOrWhiteSpace(req.TitleEn) ? null : req.TitleEn.Trim();
        ad.SubtitleEn = string.IsNullOrWhiteSpace(req.SubtitleEn) ? null : req.SubtitleEn.Trim();
        ad.ImageUrl = req.ImageUrl.Trim();
        ad.Target = string.IsNullOrWhiteSpace(req.Target) ? null : req.Target.Trim();
        ad.Placements = NormalizePlacements(req.Placements);
        ad.IsActive = req.IsActive;
        ad.SortOrder = req.SortOrder;
    }

    private static AdDto ToDto(Ad a) => new()
    {
        Id = a.Id,
        Title = a.Title,
        Subtitle = a.Subtitle,
        TitleEn = a.TitleEn,
        SubtitleEn = a.SubtitleEn,
        ImageUrl = a.ImageUrl,
        Target = a.Target,
        Placements = string.IsNullOrWhiteSpace(a.Placements) ? HomePlacement : a.Placements,
        IsActive = a.IsActive,
        SortOrder = a.SortOrder,
    };
}
