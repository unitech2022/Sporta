using System.Text;
using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Models;

namespace SportaApis.Services;

public class PackageService : IPackageService
{
    /// <summary>Key of the seeded package used when a subscribe request omits
    /// PackageId (keeps older clients that only know "Sporta Plus" working).</summary>
    public const string DefaultKey = "sporta-plus";

    private readonly AppDbContext _db;

    public PackageService(AppDbContext db) => _db = db;

    public async Task<List<PackageDto>> GetActiveAsync()
    {
        var items = await _db.Packages
            .Where(p => p.IsActive)
            .OrderBy(p => p.SortOrder)
            .ThenBy(p => p.Id)
            .ToListAsync();
        return items.Select(p => ToDto(p, subscribers: null)).ToList();
    }

    public async Task<List<PackageDto>> GetAllAsync()
    {
        var items = await _db.Packages
            .OrderBy(p => p.SortOrder)
            .ThenBy(p => p.Id)
            .ToListAsync();

        var now = DateTime.UtcNow;
        var counts = await _db.Subscriptions
            .Where(s => s.PackageId != null && s.EndDate != null && s.EndDate > now)
            .GroupBy(s => s.PackageId!.Value)
            .Select(g => new { PackageId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(g => g.PackageId, g => g.Count);

        return items.Select(p => ToDto(p, counts.GetValueOrDefault(p.Id))).ToList();
    }

    public async Task<PackageDto> CreateAsync(SavePackageRequest req)
    {
        var pkg = new Package { Key = await MakeUniqueKeyAsync(req.Name) };
        Apply(pkg, req);
        _db.Packages.Add(pkg);
        await _db.SaveChangesAsync();
        return ToDto(pkg, subscribers: 0);
    }

    public async Task<PackageDto> UpdateAsync(int id, SavePackageRequest req)
    {
        var pkg = await _db.Packages.FirstOrDefaultAsync(p => p.Id == id)
            ?? throw new AuthException("Package not found", "الباقة غير موجودة", "PACKAGE_NOT_FOUND");
        // Key is derived once at creation and never changed (subscriptions/
        // subscribe-requests may reference it).
        Apply(pkg, req);
        pkg.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        var now = DateTime.UtcNow;
        var subscribers = await _db.Subscriptions
            .CountAsync(s => s.PackageId == id && s.EndDate != null && s.EndDate > now);
        return ToDto(pkg, subscribers);
    }

    public async Task DeleteAsync(int id)
    {
        var pkg = await _db.Packages.FirstOrDefaultAsync(p => p.Id == id)
            ?? throw new AuthException("Package not found", "الباقة غير موجودة", "PACKAGE_NOT_FOUND");

        var hasSubscribers = await _db.Subscriptions.AnyAsync(s => s.PackageId == id);
        if (hasSubscribers)
            throw new AuthException(
                "Package has subscribers", "لا يمكن حذف باقة لها مشتركون — أوقفها بدلًا من ذلك",
                "PACKAGE_HAS_SUBSCRIBERS");

        _db.Packages.Remove(pkg);
        await _db.SaveChangesAsync();
    }

    public async Task<Package> ResolveForSubscribeAsync(int? packageId)
    {
        if (packageId is int id)
        {
            return await _db.Packages.FirstOrDefaultAsync(p => p.Id == id && p.IsActive)
                ?? throw new AuthException(
                    "Package not found", "الباقة غير موجودة أو غير متاحة", "PACKAGE_NOT_FOUND");
        }

        return await _db.Packages.FirstOrDefaultAsync(p => p.Key == DefaultKey)
            ?? throw new AuthException(
                "Default package missing", "الباقة الافتراضية غير موجودة", "PACKAGE_NOT_FOUND");
    }

    // ── helpers ────────────────────────────────────────────────────────────────

    private async Task<string> MakeUniqueKeyAsync(string name)
    {
        var baseKey = Slugify(name);
        if (string.IsNullOrEmpty(baseKey)) baseKey = "package";

        var key = baseKey;
        var suffix = 2;
        while (await _db.Packages.AnyAsync(p => p.Key == key))
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

    private static void Apply(Package pkg, SavePackageRequest req)
    {
        pkg.Name = req.Name.Trim();
        // النوع هو مصدر المدة — لا مدة يدوية. و«بالنسبة» مفتوح المدة (٠ يوم)
        // وبلا رسوم مقدَّمة، فمقابله هو نسبة سبورتا من كل عملية.
        pkg.Period = SubscriptionPeriodExtensions.ParsePeriod(req.Period);
        pkg.DurationDays = pkg.Period.Days() ?? 0;
        pkg.Price = pkg.Period.IsOpenEnded() ? 0m : req.Price;
        pkg.CommissionPercent =
            pkg.Period.IsOpenEnded() ? req.CommissionPercent : 0m;
        pkg.FeaturesText = req.Features.Count == 0
            ? null
            : string.Join('\n', req.Features.Select(f => f.Trim()).Where(f => f.Length > 0));
        pkg.IsActive = req.IsActive;
        pkg.SortOrder = req.SortOrder;
        pkg.PointsMultiplier = req.PointsMultiplier;
        pkg.BookingDiscountPercent = req.BookingDiscountPercent;
        pkg.WelcomePoints = req.WelcomePoints;
        pkg.CommissionDiscountPercent = req.CommissionDiscountPercent;
    }

    private static PackageDto ToDto(Package p, int? subscribers) => new()
    {
        Id = p.Id,
        Key = p.Key,
        Name = p.Name,
        Price = p.Price,
        Period = p.Period.Wire(),
        Duration = p.DurationDays,
        Features = string.IsNullOrWhiteSpace(p.FeaturesText)
            ? []
            : p.FeaturesText.Split('\n', StringSplitOptions.RemoveEmptyEntries).ToList(),
        IsActive = p.IsActive,
        SortOrder = p.SortOrder,
        Subscribers = subscribers ?? 0,
        PointsMultiplier = p.PointsMultiplier,
        BookingDiscountPercent = p.BookingDiscountPercent,
        WelcomePoints = p.WelcomePoints,
        CommissionDiscountPercent = p.CommissionDiscountPercent,
        CommissionPercent = p.CommissionPercent,
        CreatedAt = p.CreatedAt.ToString("yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture),
    };
}
