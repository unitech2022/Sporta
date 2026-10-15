using SportaApis.Enums;

namespace SportaApis.Models;

public class User : BaseEntity
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    /// <summary>
    /// البريد الإلكتروني — اختياري: حسابات التطبيق تُنشأ برقم الجوال وحده،
    /// ويبقى للأدمن/الموظفين ولمن يضيفه لاحقاً من إعدادات الحساب. القيمة
    /// null (لا سلسلة فارغة) لغياب البريد، وإلا اصطدمت الحسابات بفهرس التفرّد.
    /// </summary>
    public string? Email { get; set; }
    public string PasswordHash { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public UserType UserType { get; set; }
    public Language PreferredLanguage { get; set; } = Language.Arabic;
    public Gender? Gender { get; set; }
    public string? Country { get; set; }

    // النص الحر يبقى للعرض/التوافق الخلفي، والمعرّفات تربط بجداول المدن/الأحياء.
    public string? City { get; set; }
    public string? District { get; set; }

    /// <summary>معرّف المدينة المختارة من قائمة المدن (null لو لم تُختر من القائمة).</summary>
    public int? CityId { get; set; }
    public City? CityRef { get; set; }

    /// <summary>معرّف الحي المختار (تابع للمدينة، null لو لم يُختر).</summary>
    public int? DistrictId { get; set; }
    public District? DistrictRef { get; set; }

    public string? ProfileImageUrl { get; set; }
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// الحساب حُذف بطلب صاحبه (App Store 5.1.1(v)). الحذف نهائي: تُمسح كل
    /// البيانات الشخصية ويُبطَّل الدخول، ويبقى الصف نفسه مُبهَّم الهوية لتظل
    /// السجلات المالية (حجوزات، حركات محفظة) متماسكة محاسبياً.
    /// </summary>
    public bool IsDeleted { get; set; } = false;

    /// <summary>وقت تنفيذ الحذف (UTC)، أو null لحساب لم يُحذف.</summary>
    public DateTime? DeletedAt { get; set; }

    // ── Venue-owner personal documents (collected at registration) ──────────────
    /// <summary>صورة السجل التجاري (رابط الملف المرفوع).</summary>
    public string? CommercialRegistrationImageUrl { get; set; }

    /// <summary>صورة الهوية (رابط الملف المرفوع).</summary>
    public string? IdImageUrl { get; set; }

    /// <summary>صورة شهادة الضريبة (رابط الملف المرفوع).</summary>
    public string? TaxCertificateImageUrl { get; set; }

    /// <summary>Saved home location for nearby matches/courts (null until set).</summary>
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    /// <summary>The sport the user picked as their favorite (e.g. "padel").</summary>
    public string? FavoriteSport { get; set; }

    /// <summary>رصيد نقاط الولاء الجاري — السجل الكامل في PointsTransactions.</summary>
    public int PointsBalance { get; set; } = 0;

    /// <summary>
    /// نقاط المستوى الصافية (فوز + / خسارة −) من نتائج المباريات. لا تُستبدل
    /// ولا تُخصم بالاستبدال؛ السجل في PointsTransactions بـ Kind = Level.
    /// </summary>
    public int LevelPoints { get; set; } = 0;

    // ── الحساب البنكي (مطلوب لملّاك الملاعب والمدربين لاستلام مستحقاتهم) ────────

    /// <summary>
    /// رقم الآيبان المخزَّن بلا مسافات وبحروف كبيرة. يُطلب عند تسجيل مالك الملعب
    /// أو المدرب، ويُشترط وجوده قبل أي طلب سحب.
    /// </summary>
    public string? Iban { get; set; }

    /// <summary>اسم البنك كما أدخله المستخدم.</summary>
    public string? BankName { get; set; }

    /// <summary>اسم صاحب الحساب كما هو لدى البنك (قد يخالف اسم الحساب في التطبيق).</summary>
    public string? AccountHolderName { get; set; }

    // Navigation
    public ICollection<UserRole> Roles { get; set; } = [];
    public ICollection<RefreshToken> RefreshTokens { get; set; } = [];
    public ICollection<TrustedDevice> TrustedDevices { get; set; } = [];
    public PlayerProfile? PlayerProfile { get; set; }
    public CoachProfile? CoachProfile { get; set; }
    /// <summary>نطاق العمل والصلاحيات — للمستخدمين من نوع Staff فقط.</summary>
    public StaffProfile? StaffProfile { get; set; }
    public Wallet? Wallet { get; set; }
    public Subscription? Subscription { get; set; }
    public ICollection<Friendship> SentFriendRequests { get; set; } = [];
    public ICollection<Friendship> ReceivedFriendRequests { get; set; } = [];
    public ICollection<Notification> Notifications { get; set; } = [];
}
