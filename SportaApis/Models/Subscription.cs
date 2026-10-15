using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// اشتراك المستخدم الجاري. شروط الاشتراك تُنسخ هنا **لقطةً** وقت الاشتراك
/// (السعر والمزايا والنسب)، فأي تعديل يجريه الأدمن على <see cref="Package"/>
/// لاحقًا لا يمسّ من اشترك قبله — يسري على الاشتراكات الجديدة فقط.
/// </summary>
public class Subscription : BaseEntity
{
    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public SubscriptionPlan Plan { get; set; } = SubscriptionPlan.Free;
    public DateTime? StartDate { get; set; }

    /// <summary>تاريخ الانتهاء — <c>null</c> لاشتراك «بالنسبة» المفتوح المدة.</summary>
    public DateTime? EndDate { get; set; }

    /// <summary>Which admin-managed package this paid subscription is for (null while Free).</summary>
    public int? PackageId { get; set; }
    public Package? Package { get; set; }

    // ── لقطة شروط الاشتراك وقت الشراء (حماية المشتركين السابقين) ─────────────

    /// <summary>اسم الاشتراك كما كان وقت الشراء.</summary>
    public string? PackageName { get; set; }

    /// <summary>نوع الاشتراك وقت الشراء (شهري/سنوي/بالنسبة).</summary>
    public SubscriptionPeriod Period { get; set; } = SubscriptionPeriod.Monthly;

    /// <summary>ما دفعه المستخدم فعلاً (بعد أي خصم ساري وقتها).</summary>
    public decimal PricePaid { get; set; }

    /// <summary>مضاعف نقاط الولاء المتفق عليه وقت الاشتراك.</summary>
    public decimal PointsMultiplier { get; set; } = 1m;

    /// <summary>نسبة خصم حجوزات الملاعب المتفق عليها وقت الاشتراك.</summary>
    public decimal BookingDiscountPercent { get; set; }

    /// <summary>النقاط الترحيبية الممنوحة وقت الاشتراك (للسجل).</summary>
    public int WelcomePoints { get; set; }

    /// <summary>نسبة تخفيض عمولة سبورتا المتفق عليها وقت الاشتراك.</summary>
    public decimal CommissionDiscountPercent { get; set; }

    /// <summary>نسبة سبورتا لمشتركي «بالنسبة» كما كانت وقت الاشتراك.</summary>
    public decimal CommissionPercent { get; set; }

    /// <summary>
    /// اشتراك مدفوع ساري: إمّا مفتوح المدة («بالنسبة») أو لم ينتهِ بعد.
    /// الحساب المجاني يُعد "ساريًا" دائمًا كما في السابق.
    /// </summary>
    public bool IsActive =>
        Plan == SubscriptionPlan.Free ||
        EndDate == null ||
        EndDate > DateTime.UtcNow;

    /// <summary>ينسخ شروط [package] إلى هذا الاشتراك — تُستدعى عند كل شراء.</summary>
    public void SnapshotFrom(Package package, decimal pricePaid)
    {
        PackageId = package.Id;
        PackageName = package.Name;
        Period = package.Period;
        PricePaid = pricePaid;
        PointsMultiplier = package.PointsMultiplier;
        BookingDiscountPercent = package.BookingDiscountPercent;
        WelcomePoints = package.WelcomePoints;
        CommissionDiscountPercent = package.CommissionDiscountPercent;
        CommissionPercent = package.CommissionPercent;
    }
}
