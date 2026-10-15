using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

public class PackageDto
{
    public int Id { get; set; }
    public string Key { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;

    /// <summary>السعر قبل أي خصم (السعر المشطوب في الواجهة).</summary>
    public decimal Price { get; set; }

    /// <summary>نسبة الخصم السارية على هذا المستخدم (٠ حين لا خصم).</summary>
    public decimal DiscountPercent { get; set; }

    /// <summary>ما سيدفعه المستخدم فعلاً بعد الخصم.</summary>
    public decimal PriceAfterDiscount { get; set; }

    /// <summary>نوع الاشتراك: "monthly" | "yearly" | "commission".</summary>
    public string Period { get; set; } = "monthly";

    /// <summary>مدة الاشتراك بالأيام — مشتقة من النوع (٣٠ / ٣٦٥ / ٠ لـ«بالنسبة»).</summary>
    public int Duration { get; set; }
    public List<string> Features { get; set; } = [];
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; }

    /// <summary>Currently-active paid subscribers on this package (admin view only).</summary>
    public int Subscribers { get; set; }

    // مزايا مهيكلة تُطبَّق فعليًا على المشتركين
    public decimal PointsMultiplier { get; set; } = 1m;
    public decimal BookingDiscountPercent { get; set; }
    public int WelcomePoints { get; set; }

    /// <summary>نسبة تخفيض عمولة سبورتا على المشترك (مدرب/مالك ملعب).</summary>
    public decimal CommissionDiscountPercent { get; set; }

    /// <summary>نسبة سبورتا من كل عملية — لنوع «بالنسبة» فقط.</summary>
    public decimal CommissionPercent { get; set; }

    public string CreatedAt { get; set; } = string.Empty;
}

public class SavePackageRequest
{
    [Required] public string Name { get; set; } = string.Empty;
    [Range(0, 100000)] public decimal Price { get; set; }

    /// <summary>"monthly" | "yearly" | "commission" — المدة تُشتق منه، فلا تُرسل
    /// Duration. و«commission» يتجاهل Price ويعتمد CommissionPercent.</summary>
    public string Period { get; set; } = "monthly";

    public List<string> Features { get; set; } = [];
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; } = 0;

    [Range(1, 100)] public decimal PointsMultiplier { get; set; } = 1m;
    [Range(0, 100)] public decimal BookingDiscountPercent { get; set; } = 0m;
    [Range(0, 1000000)] public int WelcomePoints { get; set; } = 0;
    [Range(0, 100)] public decimal CommissionDiscountPercent { get; set; } = 0m;

    /// <summary>نسبة سبورتا من كل عملية — تُقرأ فقط حين Period = "commission".</summary>
    [Range(0, 100)] public decimal CommissionPercent { get; set; } = 0m;
}
