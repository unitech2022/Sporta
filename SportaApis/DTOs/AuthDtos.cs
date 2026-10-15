using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

// ── Requests ──────────────────────────────────────────────────────────────────

public class RegisterRequest
{
    [Required] public string FirstName { get; set; } = string.Empty;
    [Required] public string LastName { get; set; } = string.Empty;
    [Required] public string Phone { get; set; } = string.Empty;

    /// <summary>
    /// التذكرة الصادرة من <c>POST /api/auth/otp/verify</c> بغرض <c>register</c>.
    /// تُثبت أن صاحب الطلب يملك الرقم فعلاً — لا حساب يُنشأ بدونها.
    /// </summary>
    [Required] public string VerificationToken { get; set; } = string.Empty;

    public string? Gender { get; set; }
    public string Country { get; set; } = "السعودية";
    public string? City { get; set; }
    public string? District { get; set; }
    public int? CityId { get; set; }
    public int? DistrictId { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    [Required, MinLength(1)] public List<string> Roles { get; set; } = [];
    public string Language { get; set; } = "ar";

    /// <summary>تفاصيل المدرب - مطلوبة عند اختيار دور "coach".</summary>
    public CoachRegistrationDto? Coach { get; set; }

    /// <summary>تفاصيل الملعب/النادي - مطلوبة عند اختيار دور "venue".</summary>
    public VenueRegistrationDto? Venue { get; set; }
}

/// <summary>Updates the current user's saved location.</summary>
public class UpdateLocationRequest
{
    [Required] public double Latitude { get; set; }
    [Required] public double Longitude { get; set; }
}

/// <summary>Adds a role to the currently authenticated user.</summary>
public class AddRoleRequest
{
    [Required] public string Role { get; set; } = string.Empty; // player | coach | venue
    public CoachRegistrationDto? Coach { get; set; }
    public VenueRegistrationDto? Venue { get; set; }
}

/// <summary>بيانات الملف الشخصي للمدرب المُرسلة عند التسجيل.</summary>
public class CoachRegistrationDto
{
    public string? Bio { get; set; }

    /// <summary>اسم المدرب بالإنجليزية.</summary>
    public string? NameEn { get; set; }
    [Required] public string Specialization { get; set; } = string.Empty;

    /// <summary>سعر الحصة الفردية (ر.س).</summary>
    [Range(0, 100000)] public decimal HourlyRate { get; set; }

    /// <summary>معرف اللعبة التي يتخصص فيها المدرب (من GET /api/sports).</summary>
    public int? SportId { get; set; }

    /// <summary>الشهادات والمؤهلات — اختياري.</summary>
    public string? Certifications { get; set; }

    /// <summary>سنوات الخبرة — "lessThanYear" | "oneToThree" | "threeToFive" | "moreThanFive".</summary>
    [Required] public string ExperienceLevel { get; set; } = string.Empty;

    /// <summary>معرّفات التخصصات التدريبية المختارة (من GET /api/coach-specializations) — واحد على الأقل.</summary>
    [Required, MinLength(1)] public List<int> SpecializationIds { get; set; } = [];

    /// <summary>الفئة المستهدفة بالتدريب — "male" | "female".</summary>
    [Required] public string TargetGender { get; set; } = string.Empty;

    /// <summary>سعر باقة 8 حصص (ر.س) — اختياري.</summary>
    [Range(0, 100000)] public decimal? PackagePrice { get; set; }

    /// <summary>الملعب الذي يدرب فيه (من GET /api/venues/options) — اختياري.</summary>
    public int? PreferredVenueId { get; set; }

    /// <summary>الأيام المتاحة للتدريب (مثل "sat","sun") — يوم واحد على الأقل.</summary>
    [Required, MinLength(1)] public List<string> AvailableDays { get; set; } = [];

    /// <summary>الجنسية — "saudi" | "resident".</summary>
    [Required] public string Residency { get; set; } = string.Empty;

    /// <summary>رابط صورة الهوية الوطنية/الإقامة (الوجه الأمامي، مرفوعة عبر /api/uploads/image).</summary>
    [Required] public string NationalIdFrontUrl { get; set; } = string.Empty;

    /// <summary>رابط صورة الهوية الوطنية/الإقامة (الوجه الخلفي، مرفوعة عبر /api/uploads/image).</summary>
    [Required] public string NationalIdBackUrl { get; set; } = string.Empty;

    /// <summary>رقم الآيبان لاستلام المستحقات (SA + 22 رقماً). يُتحقق منه في الخدمة.</summary>
    public string Iban { get; set; } = string.Empty;

    /// <summary>اسم البنك.</summary>
    public string BankName { get; set; } = string.Empty;

    /// <summary>اسم صاحب الحساب كما هو لدى البنك.</summary>
    public string AccountHolderName { get; set; } = string.Empty;

}

/// <summary>بيانات الملعب/النادي المُرسلة عند تسجيل مالك ملعب.</summary>
/// <summary>
/// Venue-owner personal documents collected at registration. No venue/court
/// data is captured here — the owner creates their courts later from the owner
/// dashboard. Validated in AuthService for a localized error envelope.
/// </summary>
public class VenueRegistrationDto
{
    /// <summary>رابط صورة السجل التجاري (مرفوعة عبر /api/uploads/image).</summary>
    public string CommercialRegistrationImageUrl { get; set; } = string.Empty;

    /// <summary>رابط صورة هوية المالك (مرفوعة عبر /api/uploads/image).</summary>
    public string OwnerIdImageUrl { get; set; } = string.Empty;

    /// <summary>رابط صورة شهادة الضريبة (مرفوعة عبر /api/uploads/image).</summary>
    public string TaxCertificateUrl { get; set; } = string.Empty;

    /// <summary>رقم الآيبان لاستلام المستحقات (SA + 22 رقماً). يُتحقق منه في الخدمة.</summary>
    public string Iban { get; set; } = string.Empty;

    /// <summary>اسم البنك.</summary>
    public string BankName { get; set; } = string.Empty;

    /// <summary>اسم صاحب الحساب كما هو لدى البنك.</summary>
    public string AccountHolderName { get; set; } = string.Empty;
}

/// <summary>دخول بكلمة سر — لوحة التحكم (أدمن/موظف) فقط.</summary>
public class LoginRequest
{
    [Required] public string Phone { get; set; } = string.Empty;
    [Required] public string Password { get; set; } = string.Empty;
}

/// <summary>
/// تسجيل هذا الهاتف جهازاً موثوقاً بعد بصمة صاحبه. يُستدعى مصادَقاً (بعد
/// التسجيل أو بعد دخولٍ برمز واتساب على هاتف جديد).
/// </summary>
public class EnrollDeviceRequest
{
    /// <summary>معرّف يولّده التطبيق مرة واحدة لكل تثبيت.</summary>
    [Required, MaxLength(64)] public string DeviceId { get; set; } = string.Empty;
    [MaxLength(100)] public string? DeviceName { get; set; }
    [MaxLength(20)] public string? Platform { get; set; }
}

/// <summary>سرّ الجهاز — يُسلَّم مرة واحدة ولا يُعاد؛ الخادم يحفظ تجزئته فقط.</summary>
public class EnrolledDeviceDto
{
    public string DeviceId { get; set; } = string.Empty;
    public string DeviceSecret { get; set; } = string.Empty;
}

/// <summary>
/// دخول من جهاز موثوق: الرقم + سرّ الجهاز الذي أفرج عنه التطبيق بعد بصمة نظام
/// التشغيل. لا رمز واتساب هنا؛ الهاتف غير الموثوق يُوجَّه إلى otp/login.
/// </summary>
public class DeviceLoginRequest
{
    [Required] public string Phone { get; set; } = string.Empty;
    [Required, MaxLength(64)] public string DeviceId { get; set; } = string.Empty;
    [Required, MaxLength(128)] public string DeviceSecret { get; set; } = string.Empty;
}

/// <summary>طلب إرسال رمز تحقق على واتساب.</summary>
public class RequestOtpRequest
{
    [Required] public string Phone { get; set; } = string.Empty;

    /// <summary>login | register | reset | delete</summary>
    [Required] public string Purpose { get; set; } = string.Empty;
}

/// <summary>ردّ طلب الرمز — يغذّي عدّاد الشاشة وزر «إعادة الإرسال».</summary>
public class OtpRequestedDto
{
    /// <summary>القناة التي وصل عبرها فعلاً: whatsapp | sms.</summary>
    public string Channel { get; set; } = string.Empty;

    /// <summary>عدد خانات الرمز — يرسم بها التطبيق شاشة الإدخال.</summary>
    public int CodeLength { get; set; }

    public int ExpiresInSeconds { get; set; }
    public int ResendAfterSeconds { get; set; }

    /// <summary>الرمز نصّاً — في بيئة التطوير فقط، وإلا <c>null</c>.</summary>
    public string? DevCode { get; set; }
}

/// <summary>تحقق من رمز لغرض غير الدخول؛ يُرجِع تذكرة للخطوة التالية.</summary>
public class VerifyOtpPurposeRequest
{
    [Required] public string Phone { get; set; } = string.Empty;
    [Required] public string Otp { get; set; } = string.Empty;

    /// <summary>register | reset | delete</summary>
    [Required] public string Purpose { get; set; } = string.Empty;
}

/// <summary>التذكرة التي تُقدَّم للخطوة التالية بدل الرمز.</summary>
public class VerificationTokenDto
{
    public string VerificationToken { get; set; } = string.Empty;
}

/// <summary>دخول برمز واتساب — يُرجِع نفس ردّ الدخول العادي.</summary>
public class OtpLoginRequest
{
    [Required] public string Phone { get; set; } = string.Empty;
    [Required] public string Otp { get; set; } = string.Empty;
}

public class RefreshTokenRequest
{
    [Required] public string RefreshToken { get; set; } = string.Empty;
}

public class ForgotPasswordRequest
{
    [Required] public string Phone { get; set; } = string.Empty;
}

public class VerifyOtpRequest
{
    [Required] public string Phone { get; set; } = string.Empty;
    [Required] public string Otp { get; set; } = string.Empty;
}

public class ResetPasswordRequest
{
    [Required] public string Phone { get; set; } = string.Empty;

    /// <summary>التذكرة الصادرة من <c>otp/verify</c> بغرض <c>reset</c>.</summary>
    [Required] public string VerificationToken { get; set; } = string.Empty;

    [Required, MinLength(8)] public string NewPassword { get; set; } = string.Empty;
}

public class UpdateLanguageRequest
{
    [Required] public string Language { get; set; } = string.Empty;
}

public class UpdateProfileRequest
{
    [Required] public string FirstName { get; set; } = string.Empty;
    [Required] public string LastName { get; set; } = string.Empty;
    public string? Gender { get; set; }
    public string? City { get; set; }
    public string? District { get; set; }
    public int? CityId { get; set; }
    public int? DistrictId { get; set; }
}

public class ChangePasswordRequest
{
    [Required] public string CurrentPassword { get; set; } = string.Empty;
    [Required, MinLength(8)] public string NewPassword { get; set; } = string.Empty;
}

/// <summary>
/// طلب حذف الحساب نهائياً. كلمة المرور خطوة تأكيد تمنع الحذف بالخطأ أو من جهاز
/// مفتوح، وهي كل ما تشترطه آبل (لا يجوز إحالة المستخدم للدعم لإتمام الحذف).
/// </summary>
public class DeleteAccountRequest
{
    /// <summary>التذكرة الصادرة من <c>otp/verify</c> بغرض <c>delete</c>.</summary>
    [Required] public string VerificationToken { get; set; } = string.Empty;

    /// <summary>سبب اختياري يكتبه المستخدم — يُسجَّل للتحسين ولا يؤثر على الحذف.</summary>
    public string? Reason { get; set; }
}

// ── Responses ─────────────────────────────────────────────────────────────────

public class AuthResponseDto
{
    public string AccessToken { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public UserProfileDto User { get; set; } = null!;
}

public class UserProfileDto
{
    public int Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    /// <summary>الأدوار الفعّالة فقط — الدور المعلّق لا يظهر هنا.</summary>
    public List<string> Roles { get; set; } = [];

    /// <summary>أدوار بانتظار موافقة الأدمن (المدرب/الملعب بعد التسجيل مباشرة).
    /// يعرضها التطبيق بحالة «قيد المراجعة» ولا يفتح أقسامها.</summary>
    public List<string> PendingRoles { get; set; } = [];

    public string Language { get; set; } = "ar";
    public string? Country { get; set; }
    public string? City { get; set; }
    public string? District { get; set; }
    public int? CityId { get; set; }
    public int? DistrictId { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    /// <summary>The user's chosen favorite sport (null if not chosen yet).</summary>
    public string? FavoriteSport { get; set; }

    /// <summary>Player level 1..7 (null when the user has no player profile).</summary>
    public int? Level { get; set; }
    /// <summary>Whether the player has completed the level self-assessment.</summary>
    public bool LevelAssessed { get; set; }
}

