using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

/// <summary>
/// مناطق الخدمة الجغرافية (Geofencing). سياسة الفشل الآمن: التطبيق لا يُحجب
/// إلا حين توجد مناطق مفعّلة ويقع الموقع خارجها كلها — أي غياب إحداثيات أو
/// خطأ شبكة يُعامل عند العميل كـ «لا حجب».
/// </summary>
public class ServiceZoneService : IServiceZoneService
{
    public const string MessageKey = "outside_service_zone_message";
    public const string DefaultMessageAr = "أنت حالياً خارج نطاق خدمة التطبيق";
    public const string DefaultMessageEn = "You are currently outside the app's service area";

    private const string CacheKey = "service-zones:active";
    private static readonly TimeSpan CacheTtl = TimeSpan.FromSeconds(30);

    private readonly AppDbContext _db;
    private readonly IMemoryCache _cache;

    public ServiceZoneService(AppDbContext db, IMemoryCache cache)
    {
        _db = db;
        _cache = cache;
    }

    // ───────────────────────── إدارة من اللوحة ─────────────────────────

    public async Task<List<ServiceZoneDto>> GetAllAsync()
    {
        var zones = await _db.ServiceZones
            .AsNoTracking()
            .OrderBy(z => z.Id)
            .ToListAsync();
        return zones.Select(ToDto).ToList();
    }

    public async Task<ServiceZoneDto> CreateAsync(SaveServiceZoneRequest request)
    {
        Validate(request);
        var zone = new ServiceZone();
        Apply(zone, request);
        _db.ServiceZones.Add(zone);
        await _db.SaveChangesAsync();
        Invalidate();
        return ToDto(zone);
    }

    public async Task<ServiceZoneDto> UpdateAsync(int id, SaveServiceZoneRequest request)
    {
        var zone = await FindAsync(id);
        Validate(request);
        Apply(zone, request);
        zone.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        Invalidate();
        return ToDto(zone);
    }

    public async Task DeleteAsync(int id)
    {
        var zone = await FindAsync(id);
        _db.ServiceZones.Remove(zone);
        await _db.SaveChangesAsync();
        Invalidate();
    }

    // ───────────────────────── الفحص العام ─────────────────────────

    public async Task<ServiceZoneCheckDto> CheckAsync(double lat, double lng)
    {
        var zones = await GetActiveZonesCachedAsync();
        var result = Evaluate(zones, lat, lng);
        var message = await GetMessageAsync();
        result.MessageAr = message.ValueAr;
        result.MessageEn = message.ValueEn;
        return result;
    }

    /// <summary>
    /// منطق التقييم الخالص (بدون قاعدة بيانات): لا مناطق → داخل النطاق؛
    /// وإلا يجب أن تقع النقطة داخل إحداها.
    /// </summary>
    public static ServiceZoneCheckDto Evaluate(IReadOnlyList<ActiveZone> zones, double lat, double lng)
    {
        var result = new ServiceZoneCheckDto { HasZones = zones.Count > 0 };
        if (zones.Count == 0) return result;

        var hit = zones.FirstOrDefault(z => GeoPolygonHelper.Contains(z.Polygon, lat, lng));
        result.InsideServiceArea = hit != null;
        result.ZoneNameAr = hit?.NameAr;
        result.ZoneNameEn = hit?.NameEn;
        return result;
    }

    // ───────────────────────── رسالة خارج النطاق ─────────────────────────

    public async Task<ServiceZoneMessageDto> GetMessageAsync()
    {
        var setting = await _db.SystemSettings.AsNoTracking()
            .FirstOrDefaultAsync(s => s.Key == MessageKey);
        return new ServiceZoneMessageDto
        {
            ValueAr = string.IsNullOrWhiteSpace(setting?.ValueAr) ? DefaultMessageAr : setting.ValueAr,
            ValueEn = string.IsNullOrWhiteSpace(setting?.ValueEn) ? DefaultMessageEn : setting.ValueEn,
        };
    }

    /// <summary>يحفظ الرسالة وينشئ صفّ الإعداد عند أول حفظ — لا يعتمد على البذر.</summary>
    public async Task<ServiceZoneMessageDto> SaveMessageAsync(ServiceZoneMessageDto request)
    {
        var setting = await _db.SystemSettings.FirstOrDefaultAsync(s => s.Key == MessageKey);
        if (setting == null)
        {
            setting = new SystemSetting
            {
                Key = MessageKey,
                NameAr = "رسالة خارج نطاق الخدمة",
                NameEn = "Outside Service Area Message",
                Type = SettingType.Text,
            };
            _db.SystemSettings.Add(setting);
        }
        else
        {
            setting.UpdatedAt = DateTime.UtcNow;
        }

        setting.ValueAr = string.IsNullOrWhiteSpace(request.ValueAr) ? DefaultMessageAr : request.ValueAr.Trim();
        setting.ValueEn = string.IsNullOrWhiteSpace(request.ValueEn) ? DefaultMessageEn : request.ValueEn.Trim();
        await _db.SaveChangesAsync();
        return new ServiceZoneMessageDto { ValueAr = setting.ValueAr, ValueEn = setting.ValueEn };
    }

    // ───────────────────────── داخلي ─────────────────────────

    /// <summary>نسخة خفيفة من المنطقة المفعّلة مع المضلّع المفكوك، للتخزين المؤقت.</summary>
    public class ActiveZone
    {
        public int Id { get; set; }
        public string NameAr { get; set; } = string.Empty;
        public string NameEn { get; set; } = string.Empty;
        public List<(double Lat, double Lng)> Polygon { get; set; } = [];
    }

    private async Task<List<ActiveZone>> GetActiveZonesCachedAsync()
    {
        if (_cache.TryGetValue(CacheKey, out List<ActiveZone>? cached) && cached != null)
            return cached;

        var zones = await _db.ServiceZones
            .AsNoTracking()
            .Where(z => z.IsActive)
            .ToListAsync();

        var list = zones
            .Select(z => new ActiveZone
            {
                Id = z.Id,
                NameAr = z.NameAr,
                NameEn = z.NameEn,
                Polygon = GeoPolygonHelper.Parse(z.PolygonJson),
            })
            .Where(z => z.Polygon.Count >= 3)
            .ToList();

        _cache.Set(CacheKey, list, CacheTtl);
        return list;
    }

    private void Invalidate() => _cache.Remove(CacheKey);

    private async Task<ServiceZone> FindAsync(int id) =>
        await _db.ServiceZones.FirstOrDefaultAsync(z => z.Id == id)
        ?? throw new AuthException("Service zone not found", "منطقة الخدمة غير موجودة", "SERVICE_ZONE_NOT_FOUND");

    private static void Validate(SaveServiceZoneRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.NameAr))
            throw new AuthException("Zone name is required", "اسم المنطقة مطلوب", "SERVICE_ZONE_NAME_REQUIRED");
        if (request.Polygon == null || request.Polygon.Count < 3)
            throw new AuthException("Draw the zone on the map (at least 3 points)",
                "ارسم المنطقة على الخريطة (3 نقاط على الأقل)", "SERVICE_ZONE_POLYGON_REQUIRED");
        if (request.Polygon.Any(p => !GeoPolygonHelper.IsValidLat(p.Lat) || !GeoPolygonHelper.IsValidLng(p.Lng)))
            throw new AuthException("Invalid polygon coordinates", "إحداثيات المضلّع غير صالحة",
                "SERVICE_ZONE_POLYGON_INVALID");
    }

    private static void Apply(ServiceZone zone, SaveServiceZoneRequest request)
    {
        zone.NameAr = request.NameAr.Trim();
        zone.NameEn = string.IsNullOrWhiteSpace(request.NameEn) ? zone.NameAr : request.NameEn.Trim();
        zone.PolygonJson = GeoPolygonHelper.Serialize(request.Polygon.Select(p => (p.Lat, p.Lng)));
        zone.Color = NormalizeColor(request.Color);
        zone.IsActive = request.IsActive;
    }

    private static ServiceZoneDto ToDto(ServiceZone z) => new()
    {
        Id = z.Id,
        NameAr = z.NameAr,
        NameEn = z.NameEn,
        Polygon = GeoPolygonHelper.Parse(z.PolygonJson)
            .Select(p => new ServiceZonePointDto { Lat = p.Lat, Lng = p.Lng })
            .ToList(),
        Color = z.Color,
        IsActive = z.IsActive,
        CreatedAt = z.CreatedAt,
        UpdatedAt = z.UpdatedAt,
    };

    private static string? NormalizeColor(string? color)
    {
        if (string.IsNullOrWhiteSpace(color)) return null;
        var c = color.Trim();
        return c.Length <= 20 ? c : c[..20];
    }
}
