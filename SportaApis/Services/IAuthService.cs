using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IAuthService
{
    Task<AuthResponseDto> RegisterAsync(RegisterRequest request);

    /// <summary>دخول بكلمة سر — لحسابات الأدمن والموظفين وحدها (لوحة التحكم).</summary>
    Task<AuthResponseDto> LoginAsync(LoginRequest request);

    /// <summary>
    /// دخول من جهاز موثوق: الرقم + سرّ الجهاز (المفرَج عنه بعد بصمة النظام).
    /// الطريق اليومي لمستخدمي التطبيق — بلا رمز واتساب.
    /// </summary>
    Task<AuthResponseDto> LoginWithDeviceAsync(string phone, string deviceId, string deviceSecret);

    /// <summary>
    /// دخول برمز واتساب — للهاتف غير الموثوق (تثبيت جديد، هاتف جديد) قبل أن
    /// يسجّل بصمته ويصير موثوقاً.
    /// </summary>
    Task<AuthResponseDto> LoginWithOtpAsync(string phone, string otp);

    /// <summary>
    /// يسجّل جهازاً موثوقاً للمستخدم ويُصدر سرّه (مرة واحدة). جهازٌ بنفس
    /// المعرّف — لهذا الحساب أو لغيره — يُستبدل، فلا يبقى سرّ قديم حيّاً.
    /// </summary>
    Task<EnrolledDeviceDto> EnrollDeviceAsync(int userId, EnrollDeviceRequest req);

    Task<AuthResponseDto> RefreshTokenAsync(string token);

    /// <summary>يرسل رمز استعادة كلمة سر لحساب أدمن/موظف.</summary>
    Task ForgotPasswordAsync(string phone);

    /// <summary>يتحقق من رمز الاستعادة ويُرجِع تذكرة لخطوة تعيين الكلمة الجديدة.</summary>
    Task<string> VerifyOtpAsync(string phone, string otp);

    Task ResetPasswordAsync(string phone, string verificationToken, string newPassword);
    Task UpdateLanguageAsync(int userId, string language);
    Task<UserProfileDto> UpdateProfileAsync(int userId, UpdateProfileRequest req);
    Task ChangePasswordAsync(int userId, string currentPassword, string newPassword);
    Task<UserProfileDto> UpdateAvatarAsync(int userId, string relativeUrl);
    Task<UserProfileDto> AddRoleAsync(int userId, AddRoleRequest req);

    /// <summary>
    /// حذف ناعم لدور واحد: يُنهي التزاماته القادمة ويسترد ما يلزم، ثم يُخفي
    /// الدور ويبقي بياناته. يُصدر توكينات جديدة بلا صلاحية الدور المحذوف.
    /// </summary>
    Task<AuthResponseDto> DeleteRoleAsync(int userId, string role);
    Task<UserProfileDto> UpdateLocationAsync(int userId, double latitude, double longitude);

    /// <summary>
    /// يحذف حساب المستخدم نهائياً بعد تأكيده برمز واتساب: يُلغي التزاماته
    /// القادمة ويمسح بياناته الشخصية ووثائقه ويُبطِّل الدخول (App Store 5.1.1(v)).
    /// </summary>
    Task DeleteAccountAsync(int userId, string verificationToken, string? reason);

    /// <summary>
    /// حذف حساب يبدأه الأدمن من لوحة التحكم — نفس مسار الحذف الذاتي بلا كلمة
    /// مرور. لا يقبل حسابات الإدارة (لها شاشة الموظفين).
    /// </summary>
    Task AdminDeleteAccountAsync(int userId, string? reason);
}
