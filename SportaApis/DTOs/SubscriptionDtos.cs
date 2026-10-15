namespace SportaApis.DTOs;

public class SubscriptionDto
{
    /// <summary>"free" | "plus".</summary>
    public string Plan { get; set; } = "free";
    public bool IsActive { get; set; }
    public DateTime? EndDate { get; set; }

    /// <summary>اسم الباقة المعروضة كما ضبطها الأدمن.</summary>
    public string PackageName { get; set; } = string.Empty;

    /// <summary>معرّف الباقة المشترَك بها حالياً (null للحساب المجاني) — يستخدمه
    /// التطبيق لتمييز «باقتك الحالية» داخل قائمة الباقات.</summary>
    public int? PackageId { get; set; }

    /// <summary>نوع الاشتراك: "monthly" | "yearly" | "commission".</summary>
    public string Period { get; set; } = "monthly";

    /// <summary>مميزات الباقة كما أُدخلت في لوحة التحكم، سطر لكل ميزة.</summary>
    public List<string> Features { get; set; } = [];

    /// <summary>Monthly price of Sporta Plus before any discount (SAR).</summary>
    public decimal MonthlyPrice { get; set; }

    /// <summary>نسبة الخصم السارية على اشتراك هذا اللاعب (٠ حين لا خصم).</summary>
    public decimal DiscountPercent { get; set; }

    /// <summary>ما سيدفعه اللاعب فعلاً عند الاشتراك بعد الخصم.</summary>
    public decimal MonthlyPriceAfterDiscount { get; set; }

    // مزايا الباقة المعروضة/النشطة (تُقرأ من Package)
    public decimal PointsMultiplier { get; set; } = 1m;
    public decimal BookingDiscountPercent { get; set; }
    public int WelcomePoints { get; set; }

    /// <summary>نسبة تخفيض عمولة سبورتا على المشترك (مدرب/مالك ملعب).</summary>
    public decimal CommissionDiscountPercent { get; set; }

    /// <summary>نسبة سبورتا من كل عملية — لمشتركي نوع «بالنسبة» فقط.</summary>
    public decimal CommissionPercent { get; set; }
}

/// <summary>Optional — omit to subscribe to the default legacy package (Sporta Plus).</summary>
public class SubscribeRequest
{
    public int? PackageId { get; set; }
}
