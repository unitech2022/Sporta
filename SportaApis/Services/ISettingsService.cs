using SportaApis.DTOs;
using SportaApis.Models;

namespace SportaApis.Services;

public interface ISettingsService
{
    /// <summary>Max radius (km) for showing nearby matches/courts. Default 50.</summary>
    /// <summary>مهلة إلغاء المباراة غير المكتملة قبل موعدها (بالساعات).</summary>
    Task<double> GetAutoCancelHoursAsync();

    Task<double> GetNearbyDistanceKmAsync();

    Task SetNearbyDistanceKmAsync(double km);

    /// <summary>Support contact phone shown on the account-suspended screen.</summary>
    Task<string> GetSupportPhoneAsync();

    Task SetSupportPhoneAsync(string phone);

    /// <summary>Default نسبة سبورتا (%) seeded into new courts. Default 10.</summary>
    Task<decimal> GetDefaultCommissionAsync();

    Task SetDefaultCommissionAsync(decimal percent);

    /// <summary>
    /// Admin-managed wallet top-up limits (SAR). Falls back to 10/5000 when a
    /// key is missing or the pair is inconsistent.
    /// </summary>
    Task<(decimal Min, decimal Max)> GetTopUpLimitsAsync();

    /// <summary>
    /// Admin-managed payment-gateway fee: percentage + fixed amount (both
    /// pre-VAT) and the VAT rate applied to the fee. Zero fee by default.
    /// </summary>
    Task<(decimal Percent, decimal Fixed, decimal VatPercent)> GetTopUpFeeAsync();

    /// <summary>نسبة سبورتا على جلسات المدربين (%) — تُقتطع من مستحقات المدرب.</summary>
    Task<decimal> GetCoachCommissionAsync();

    Task SetCoachCommissionAsync(decimal percent);

    // ── Generic key/value settings (admin-managed) ──────────────────────────────

    Task<List<SettingDto>> GetAllAsync();

    /// <summary>Non-sensitive settings only, for anonymous/app consumption.</summary>
    Task<List<SettingDto>> GetPublicAsync();

    Task<SettingDto?> GetByKeyAsync(string key);

    Task<SettingDto> CreateAsync(SaveSettingRequest request);

    Task<SettingDto> UpdateAsync(int id, SaveSettingRequest request);

    Task DeleteAsync(int id);

    // ── Policies (a fixed subset of the settings store) ────────────────────────

    /// <summary>الوثائق القانونية الثلاث بترتيب ثابت.</summary>
    Task<List<SettingDto>> GetPoliciesAsync();

    /// <summary>يعدّل نص سياسة فقط — يرفض أي إعداد آخر.</summary>
    Task<SettingDto> UpdatePolicyAsync(int id, SavePolicyRequest request);
}
