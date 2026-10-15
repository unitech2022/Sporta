using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// نوع اشتراك قابل للإدارة من الأدمن — شهري أو سنوي، لكلٍّ سعره ومميزاته
/// وخصمه على عمولة سبورتا.
/// </summary>
public class Package : BaseEntity
{
    /// <summary>
    /// مفتاح ثابت يُشتق من الاسم عند الإنشاء ولا يتغيّر لاحقًا — تُستخدم به
    /// الباقة الافتراضية ("sporta-plus") للتوافق مع طلبات الاشتراك القديمة
    /// التي لا ترسل PackageId صراحةً.
    /// </summary>
    public string Key { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }

    /// <summary>نوع الاشتراك (شهري/سنوي) — هو ما يشتق منه <see cref="DurationDays"/>.</summary>
    public SubscriptionPeriod Period { get; set; } = SubscriptionPeriod.Monthly;

    public int DurationDays { get; set; } = 30;

    /// <summary>قائمة المميزات، سطر لكل ميزة.</summary>
    public string? FeaturesText { get; set; }

    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; } = 0;

    // ── مزايا مهيكلة تُطبَّق فعليًا على المشتركين (لا نص تسويقي) ──────────────

    /// <summary>مضاعف كسب نقاط الولاء للمشترك (1 = بلا مضاعفة، 2 = ضِعف النقاط...).</summary>
    public decimal PointsMultiplier { get; set; } = 1m;

    /// <summary>
    /// نسبة خصم (%) على حجوزات الملاعب للمشترك. يُقتطع الخصم من عمولة سبورتا
    /// فقط (لا يمس مستحقات مالك الملعب)، لذا فعليًا يتقيّد بسقف العمولة.
    /// </summary>
    public decimal BookingDiscountPercent { get; set; } = 0m;

    /// <summary>نقاط ترحيبية تُمنح مرة عند كل عملية اشتراك مدفوعة في الباقة.</summary>
    public int WelcomePoints { get; set; } = 0;

    /// <summary>
    /// نسبة تخفيض عمولة سبورتا للمشترك طوال مدة اشتراكه (نسبة من العمولة لا
    /// نقاط مئوية: 40% تعني أن عمولة 5% تصير 3%). تُطبَّق على عمولة حجوزات
    /// ملاعب مالك الملعب وعلى عمولة جلسات المدرب.
    /// </summary>
    public decimal CommissionDiscountPercent { get; set; } = 0m;

    /// <summary>
    /// نسبة سبورتا من كل عملية لمشتركي نوع «بالنسبة»
    /// (<see cref="SubscriptionPeriod.Commission"/>) — تحلّ محل النسبة
    /// الافتراضية طوال الاشتراك. تُتجاهل في الأنواع الأخرى.
    /// </summary>
    public decimal CommissionPercent { get; set; } = 0m;

    public ICollection<Subscription> Subscriptions { get; set; } = [];
}
