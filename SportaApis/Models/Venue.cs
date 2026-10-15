using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// النادي / المجمع الرياضي - يحتوي على ملاعب متعددة
/// </summary>
public class Venue : BaseEntity
{
    public string Name { get; set; } = string.Empty;

    /// <summary>اسم النادي بالإنجليزية — يُدخل مع الاسم العربي عند الإنشاء.</summary>
    public string? NameEn { get; set; }

    public string? Description { get; set; }
    public int OwnerId { get; set; }
    public User Owner { get; set; } = null!;

    public string Country { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string? District { get; set; }

    // النصوص أعلاه تبقى للعرض/التوافق الخلفي، والمعرّفات أدناه تربط النادي
    // بجداول الدول/المدن حتى يمكن حصر ما يراه الموظف في نطاقه الجغرافي.

    /// <summary>معرّف الدولة (null للأندية القديمة قبل ربط الاسم النصي).</summary>
    public int? CountryId { get; set; }
    public Country? CountryRef { get; set; }

    /// <summary>معرّف المدينة (null للأندية القديمة قبل ربط الاسم النصي).</summary>
    public int? CityId { get; set; }
    public City? CityRef { get; set; }

    /// <summary>معرّف الحي (null للأندية القديمة قبل ربط الاسم النصي).</summary>
    public int? DistrictId { get; set; }
    public District? DistrictRef { get; set; }

    public string Address { get; set; } = string.Empty;
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    public VenueGenderPolicy GenderPolicy { get; set; } = VenueGenderPolicy.MenOnly;
    public string? ImageUrl { get; set; }
    public bool IsActive { get; set; } = true;

    /// <summary>Admin approval gate — players/booking never see this venue's
    /// courts until an admin approves it. Defaults to false for every newly
    /// created venue.</summary>
    public bool IsApproved { get; set; }

    /// <summary>
    /// نافذة الحجز المسبق بالأيام لغير الأعضاء (null = بلا حد). العضو يضيف
    /// إليها أيام أولوية خطته فيحجز أوقات الذروة قبل غيره.
    /// </summary>
    public int? BookingWindowDays { get; set; }

    // ── Owner onboarding / legal documents (collected at registration) ──────────

    /// <summary>صورة السجل التجاري (رابط الملف المرفوع).</summary>
    public string? CommercialRegistrationImageUrl { get; set; }

    /// <summary>صورة العنوان الوطني للمنشأة (رابط الملف المرفوع).</summary>
    public string? NationalAddressImageUrl { get; set; }

    /// <summary>صورة هوية المالك (رابط الملف المرفوع).</summary>
    public string? OwnerIdImageUrl { get; set; }

    /// <summary>شهادة الضريبة (رابط الملف المرفوع).</summary>
    public string? TaxCertificateUrl { get; set; }

    // ── الحذف الإداري ──────────────────────────────────────────────────────────

    /// <summary>
    /// حذف ناعم من لوحة التحكم: النادي وملاعبه يختفون من كل الشاشات (اللوحة
    /// والتطبيق ولوحة المالك) بينما تبقى حجوزاته وفواتيره السابقة سليمة في
    /// السجل المالي — قيد قاعدة البيانات يمنع مسحها أصلاً.
    /// </summary>
    public bool IsDeleted { get; set; }

    public DateTime? DeletedAt { get; set; }

    // Navigation
    public ICollection<Court> Courts { get; set; } = [];

    /// <summary>صور الملعب المرفوعة عند التسجيل.</summary>
    public ICollection<VenueImage> Images { get; set; } = [];
}
