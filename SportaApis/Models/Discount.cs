using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// خصم على أحد رسوم المنصة. يكون **عاماً** (يسري على كل من يخضع لذلك الرسم)
/// أو **مخصصاً** (يسري فقط على المستفيدين المضافين في <see cref="Beneficiaries"/>).
///
/// عروض مثل «خصم الصيف ٥٠٪ لأول ١٠ ملاعب مدى الحياة» تُمثَّل بالكامل كبيانات:
/// خصم عام بنسبة ٥٠ على VenueCommission، بسقف مستفيدين ١٠، وبـ
/// <see cref="GrantsLifetime"/> مفعّلاً — بلا أي كود خاص بالعرض.
/// </summary>
public class Discount : BaseEntity
{
    public string NameAr { get; set; } = string.Empty;
    public string? DescriptionAr { get; set; }

    /// <summary>الرسم المستهدَف بالخصم.</summary>
    public DiscountTarget Target { get; set; }

    /// <summary>نسبة الخصم من الرسم (١..١٠٠). ٥٠ تعني نصف الرسم.</summary>
    public decimal Percent { get; set; }

    /// <summary>
    /// عام: يسري على كل من يخضع للرسم. مخصص: على المستفيدين المحددين فقط.
    /// </summary>
    public bool IsGeneral { get; set; } = true;

    /// <summary>بداية سريان العرض (null = ساري فوراً).</summary>
    public DateTime? StartsAt { get; set; }

    /// <summary>نهاية سريان العرض (null = مفتوح بلا نهاية).</summary>
    public DateTime? EndsAt { get; set; }

    /// <summary>
    /// سقف عدد المستفيدين للعروض العامة (null = بلا سقف). عند بلوغ السقف يتوقف
    /// ضمّ مستفيدين جدد ويبقى العرض سارياً لمن لحق به.
    /// </summary>
    public int? MaxBeneficiaries { get; set; }

    /// <summary>
    /// هل يبقى الخصم مع المستفيد بعد انتهاء العرض؟ («مدى الحياة» في عروض
    /// الإطلاق.) يُشترط ضمّه كمستفيد وقت سريان العرض.
    /// </summary>
    public bool GrantsLifetime { get; set; }

    /// <summary>
    /// سقف عدد مرات تطبيق الخصم فعلياً — حجوزات/جلسات محصَّلة، لا مستفيدين
    /// (null = بلا سقف). عند بلوغه يتوقف الخصم تلقائياً ولو بقيت نافذته سارية.
    /// </summary>
    public int? MaxUses { get; set; }

    /// <summary>عدد مرات التطبيق الفعلية — يزيد لحظة تحصيل الرسم فقط، لا عند العرض.</summary>
    public int UsedCount { get; set; }

    public bool IsActive { get; set; } = true;

    // Navigation
    public ICollection<DiscountBeneficiary> Beneficiaries { get; set; } = [];

    /// <summary>هل العرض ضمن نافذته الزمنية الآن؟</summary>
    public bool IsWithinWindow(DateTime now) =>
        (StartsAt is null || StartsAt <= now) && (EndsAt is null || EndsAt > now);
}

/// <summary>
/// مستفيد من خصم — إما مضاف يدوياً (خصم مخصص) أو مضموم تلقائياً عند أول رسم
/// يخضع له ضمن سقف العرض (عروض «أول N»).
/// </summary>
public class DiscountBeneficiary : BaseEntity
{
    public int DiscountId { get; set; }
    public Discount Discount { get; set; } = null!;

    /// <summary>المستخدم المستفيد (مالك الملعب أو المدرب أو اللاعب).</summary>
    public int UserId { get; set; }
    public User User { get; set; } = null!;

    /// <summary>هل ضُمّ تلقائياً ضمن سقف «أول N» أم أضافه الأدمن يدوياً؟</summary>
    public bool AutoEnrolled { get; set; }
}
