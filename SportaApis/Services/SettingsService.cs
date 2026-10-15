using System.Globalization;
using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Models;

namespace SportaApis.Services;

public class SettingsService : ISettingsService
{
    private readonly AppDbContext _db;
    public SettingsService(AppDbContext db) => _db = db;

    public const string NearbyDistanceKey = "nearby_distance_km";
    public const double DefaultNearbyDistanceKm = 50;
    public const double MinNearbyDistanceKm = 1;

    /// <summary>
    /// كم ساعة قبل الموعد تُلغى المباراة/الأمريكانو إن لم يكتمل عدده. صفر
    /// يعطّل الإلغاء المسبق فلا يبقى إلا تنظيف ما فات موعده.
    /// </summary>
    public const string AutoCancelHoursKey = "match_autocancel_hours_before";
    public const double DefaultAutoCancelHours = 3;

    public const string SupportPhoneKey = "support_phone";
    public const string DefaultSupportPhone = "0500000000";

    public const string CommissionKey = "commission_percentage";
    public const decimal DefaultCommissionPercent = 5m;

    public const string CoachCommissionKey = "coach_commission_percentage";
    public const decimal DefaultCoachCommissionPercent = 5m;

    public const string TopUpMinKey = "wallet_topup_min";
    public const decimal DefaultTopUpMin = 10m;

    public const string TopUpMaxKey = "wallet_topup_max";
    public const decimal DefaultTopUpMax = 5000m;

    public const string TopUpFeePercentKey = "wallet_topup_fee_percent";
    public const string TopUpFeeFixedKey = "wallet_topup_fee_fixed";
    public const string TopUpFeeVatKey = "wallet_topup_fee_vat_percent";
    public const decimal DefaultVatPercent = 15m;

    /// <summary>
    /// رسوم بوابة الدفع كما يضبطها المدير. الافتراضي صفر: لا رسوم حتى تُدخل
    /// أرقام العقد الفعلية، حتى لا يُحصَّل من المستخدمين رقم مُخمَّن.
    /// </summary>
    public async Task<(decimal Percent, decimal Fixed, decimal VatPercent)> GetTopUpFeeAsync()
    {
        var percent = await ReadDecimalAsync(TopUpFeePercentKey) ?? 0m;
        var fixedFee = await ReadDecimalAsync(TopUpFeeFixedKey) ?? 0m;
        var vat = await ReadDecimalAsync(TopUpFeeVatKey) ?? DefaultVatPercent;

        // قيم سالبة أو نِسب عبثية تُهمَل بدل أن تُنتج رسوماً غريبة.
        if (percent < 0 || percent > 100) percent = 0m;
        if (fixedFee < 0) fixedFee = 0m;
        if (vat < 0 || vat > 100) vat = DefaultVatPercent;
        return (percent, fixedFee, vat);
    }

    /// <summary>
    /// حدّا شحن المحفظة كما يضبطهما المدير من لوحة التحكم. يُستخدمان للتحقق في
    /// الخادم ولعرض "معلومات هامة" في التطبيق، فيبقى المصدر واحداً.
    /// </summary>
    public async Task<(decimal Min, decimal Max)> GetTopUpLimitsAsync()
    {
        var min = await ReadDecimalAsync(TopUpMinKey) ?? DefaultTopUpMin;
        var max = await ReadDecimalAsync(TopUpMaxKey) ?? DefaultTopUpMax;

        // A misconfigured pair would reject every top-up; fall back rather than
        // lock the wallet.
        if (min < 0 || max <= 0 || min > max) return (DefaultTopUpMin, DefaultTopUpMax);
        return (min, max);
    }

    private async Task<decimal?> ReadDecimalAsync(string key)
    {
        var raw = await _db.SystemSettings
            .Where(s => s.Key == key)
            .Select(s => s.ValueAr)
            .FirstOrDefaultAsync();
        return raw != null &&
               decimal.TryParse(raw, NumberStyles.Any, CultureInfo.InvariantCulture, out var v)
            ? v
            : null;
    }

    /// <summary>Default نسبة سبورتا (%) applied to newly created courts. Admins
    /// edit this in the dashboard; per-court values can still be overridden.</summary>
    public async Task<decimal> GetDefaultCommissionAsync()
    {
        var raw = await _db.SystemSettings
            .Where(s => s.Key == CommissionKey)
            .Select(s => s.ValueAr)
            .FirstOrDefaultAsync();
        if (raw != null &&
            decimal.TryParse(raw, NumberStyles.Any, CultureInfo.InvariantCulture, out var v) &&
            v >= 0 && v <= 100)
            return v;
        return DefaultCommissionPercent;
    }

    public async Task SetDefaultCommissionAsync(decimal percent) =>
        await UpsertAsync(CommissionKey, "نسبة عمولة المنصة (%)", "Platform Commission (%)",
            SettingType.Number, percent.ToString(CultureInfo.InvariantCulture));

    /// <summary>نسبة سبورتا على جلسات المدربين — تُقتطع من مستحقات المدرب.</summary>
    public async Task<decimal> GetCoachCommissionAsync()
    {
        var value = await ReadDecimalAsync(CoachCommissionKey);
        return value is decimal v && v >= 0 && v <= 100 ? v : DefaultCoachCommissionPercent;
    }

    public async Task SetCoachCommissionAsync(decimal percent) =>
        await UpsertAsync(CoachCommissionKey, "نسبة عمولة المدربين (%)", "Coach Commission (%)",
            SettingType.Number, percent.ToString(CultureInfo.InvariantCulture));

    public async Task<string> GetSupportPhoneAsync()
    {
        var raw = await _db.SystemSettings
            .Where(s => s.Key == SupportPhoneKey)
            .Select(s => s.ValueAr)
            .FirstOrDefaultAsync();
        return string.IsNullOrWhiteSpace(raw) ? DefaultSupportPhone : raw;
    }

    public async Task SetSupportPhoneAsync(string phone) =>
        await UpsertAsync(SupportPhoneKey, "رقم الدعم", "Support Phone", SettingType.Text, phone);

    /// <summary>
    /// مهلة الإلغاء التلقائي بالساعات. القيم السالبة أو الشاذة تُهمَل لصالح
    /// الافتراضي: إعدادٌ مكسور يجب ألّا يُلغي مباريات قبل أوانها بأيام.
    /// </summary>
    public async Task<double> GetAutoCancelHoursAsync()
    {
        var raw = await _db.SystemSettings
            .Where(s => s.Key == AutoCancelHoursKey)
            .Select(s => s.ValueAr)
            .FirstOrDefaultAsync();
        if (raw != null &&
            double.TryParse(raw, NumberStyles.Any, CultureInfo.InvariantCulture, out var v)
            && v >= 0 && v <= 72)
            return v;
        return DefaultAutoCancelHours;
    }

    public async Task<double> GetNearbyDistanceKmAsync()
    {
        var raw = await _db.SystemSettings
            .Where(s => s.Key == NearbyDistanceKey)
            .Select(s => s.ValueAr)
            .FirstOrDefaultAsync();
        if (raw != null &&
            double.TryParse(raw, NumberStyles.Any, CultureInfo.InvariantCulture, out var v)
            && double.IsFinite(v))
            // صفر أو سالب من صفحة الإعدادات العامة يعني قوائم استكشاف فارغة —
            // نلتزم بحدٍّ أدنى كيلومتراً واحداً.
            return Math.Max(v, MinNearbyDistanceKm);
        return DefaultNearbyDistanceKm;
    }

    public async Task SetNearbyDistanceKmAsync(double km) =>
        await UpsertAsync(NearbyDistanceKey, "نطاق القرب (كم)", "Nearby Radius (km)",
            SettingType.Number, km.ToString(CultureInfo.InvariantCulture));

    private async Task UpsertAsync(
        string key, string nameAr, string nameEn, SettingType type, string valueAr)
    {
        var setting = await _db.SystemSettings.FirstOrDefaultAsync(s => s.Key == key);
        if (setting == null)
        {
            _db.SystemSettings.Add(new SystemSetting
            {
                Key = key, NameAr = nameAr, NameEn = nameEn, Type = type, ValueAr = valueAr,
            });
        }
        else
        {
            setting.ValueAr = valueAr;
            setting.UpdatedAt = DateTime.UtcNow;
        }
        await _db.SaveChangesAsync();
    }

    // ── Generic key/value settings (admin-managed) ──────────────────────────────

    public async Task<List<SettingDto>> GetAllAsync()
    {
        var settings = await _db.SystemSettings.OrderBy(s => s.Key).ToListAsync();
        return settings.Select(ToDto).ToList();
    }

    public async Task<List<SettingDto>> GetPublicAsync()
    {
        var settings = await _db.SystemSettings
            .Where(s => !s.IsSensitive)
            .OrderBy(s => s.Key)
            .ToListAsync();
        return settings.Select(ToDto).ToList();
    }

    public async Task<SettingDto?> GetByKeyAsync(string key)
    {
        var setting = await _db.SystemSettings.FirstOrDefaultAsync(s => s.Key == key);
        return setting == null ? null : ToDto(setting);
    }

    public async Task<SettingDto> CreateAsync(SaveSettingRequest request)
    {
        var key = request.Key.Trim();
        if (await _db.SystemSettings.AnyAsync(s => s.Key == key))
            throw new AuthException("Setting key already exists", "المفتاح موجود مسبقًا", "DUPLICATE_KEY");

        var setting = new SystemSetting
        {
            Key = key,
            NameAr = request.NameAr.Trim(),
            NameEn = request.NameEn.Trim(),
            Type = ParseType(request.Type),
            ValueAr = request.ValueAr,
            ValueEn = request.ValueEn,
            IsSensitive = request.IsSensitive,
        };
        _db.SystemSettings.Add(setting);
        await _db.SaveChangesAsync();
        return ToDto(setting);
    }

    public async Task<SettingDto> UpdateAsync(int id, SaveSettingRequest request)
    {
        var setting = await _db.SystemSettings.FindAsync(id)
            ?? throw new AuthException("Setting not found", "الإعداد غير موجود", "SETTING_NOT_FOUND");

        setting.NameAr = request.NameAr.Trim();
        setting.NameEn = request.NameEn.Trim();
        setting.Type = ParseType(request.Type);
        setting.ValueAr = request.ValueAr;
        setting.ValueEn = request.ValueEn;
        setting.IsSensitive = request.IsSensitive;
        setting.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return ToDto(setting);
    }

    // ── Policies (a fixed subset of the settings store) ────────────────────────

    /// <summary>مفاتيح الوثائق القانونية — تُدار من صفحة السياسات بصلاحية مستقلة.</summary>
    public static readonly string[] PolicyKeys =
        ["terms_conditions", "privacy_policy", "refund_policy"];

    public async Task<List<SettingDto>> GetPoliciesAsync()
    {
        var settings = await _db.SystemSettings
            .Where(s => PolicyKeys.Contains(s.Key))
            .ToListAsync();

        // Keep the editor's tab order stable regardless of insertion order.
        return PolicyKeys
            .Select(k => settings.FirstOrDefault(s => s.Key == k))
            .Where(s => s is not null)
            .Select(s => ToDto(s!))
            .ToList();
    }

    public async Task<SettingDto> UpdatePolicyAsync(int id, SavePolicyRequest request)
    {
        var setting = await _db.SystemSettings.FindAsync(id)
            ?? throw new AuthException("Setting not found", "الإعداد غير موجود", "SETTING_NOT_FOUND");

        if (!PolicyKeys.Contains(setting.Key))
            throw new AuthException(
                "Not a policy setting", "هذا الإعداد ليس سياسة", "NOT_A_POLICY");

        setting.ValueAr = request.ValueAr;
        setting.ValueEn = request.ValueEn;
        setting.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return ToDto(setting);
    }

    public async Task DeleteAsync(int id)
    {
        var setting = await _db.SystemSettings.FindAsync(id)
            ?? throw new AuthException("Setting not found", "الإعداد غير موجود", "SETTING_NOT_FOUND");
        _db.SystemSettings.Remove(setting);
        await _db.SaveChangesAsync();
    }

    private static SettingType ParseType(string type) => type.ToLowerInvariant() switch
    {
        "switch" => SettingType.Switch,
        "number" => SettingType.Number,
        _ => SettingType.Text,
    };

    private static SettingDto ToDto(SystemSetting s) => new()
    {
        Id = s.Id,
        Key = s.Key,
        NameAr = s.NameAr,
        NameEn = s.NameEn,
        Type = s.Type.ToString().ToLower(),
        ValueAr = s.ValueAr,
        ValueEn = s.ValueEn,
        IsSensitive = s.IsSensitive,
    };
}
