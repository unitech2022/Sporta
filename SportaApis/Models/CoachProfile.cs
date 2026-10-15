using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// الملف الشخصي للمدرب المعتمد على المنصة
/// </summary>
public class CoachProfile : BaseEntity
{
    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public string? Bio { get; set; }

    /// <summary>اسم المدرب بالإنجليزية — يُدخل مع بيانات التسجيل.</summary>
    public string? NameEn { get; set; }

    public string? Specialization { get; set; }

    /// <summary>اللعبة التي يتخصص فيها المدرب (تُختار عند التسجيل من قائمة الألعاب).</summary>
    public int? SportId { get; set; }
    public Sport? Sport { get; set; }

    /// <summary>صورة الهوية/الإقامة المرفوعة عند إنشاء حساب المدرب (تُعرض للأدمن).
    /// أصبحت غير مُستخدمة في تدفق التسجيل الحالي — استُبدلت بصورتي الهوية
    /// (الوجه الأمامي/الخلفي)، وأُبقيت هنا فقط للتوافق مع بيانات قديمة.</summary>
    public string? IdDocumentUrl { get; set; }

    /// <summary>سعر الحصة الفردية (ر.س).</summary>
    public decimal HourlyRate { get; set; }

    /// <summary>سعر باقة 8 حصص (ر.س) — اختياري.</summary>
    public decimal? PackagePrice { get; set; }

    /// <summary>الشهادات والمؤهلات (نص حر) — اختياري.</summary>
    public string? Certifications { get; set; }

    public CoachExperienceLevel ExperienceLevel { get; set; } = CoachExperienceLevel.LessThanYear;

    /// <summary>الفئة المستهدفة بالتدريب: رجال أو نساء.</summary>
    public Gender TargetGender { get; set; } = Gender.Male;

    /// <summary>الملعب الذي يدرب فيه المدرب عادة — اختياري.</summary>
    public int? PreferredVenueId { get; set; }
    public Venue? PreferredVenue { get; set; }

    /// <summary>الأيام المتاحة للتدريب، مفصولة بفواصل (مثل "sat,sun,mon").</summary>
    public string? AvailableDays { get; set; }

    /// <summary>الجنسية (سعودي/مقيم) — تحدد نوع وثيقة الهوية المطلوبة.</summary>
    public CoachResidency Residency { get; set; } = CoachResidency.Saudi;

    /// <summary>صورة الهوية الوطنية أو الإقامة — الوجه الأمامي.</summary>
    public string? NationalIdFrontUrl { get; set; }

    /// <summary>صورة الهوية الوطنية أو الإقامة — الوجه الخلفي.</summary>
    public string? NationalIdBackUrl { get; set; }

    public bool IsVerifiedOnPlatform { get; set; } = false;

    // إحصائيات
    public float Rating { get; set; } = 0f;
    public int TotalSessions { get; set; } = 0;
    public int TotalRatings { get; set; } = 0;

    // Navigation
    public ICollection<CoachSession> Sessions { get; set; } = [];
    public ICollection<CoachProfileSpecialization> Specializations { get; set; } = [];
    public ICollection<CoachOffer> Offers { get; set; } = [];
}
