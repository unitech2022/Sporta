namespace SportaApis.Models;

/// <summary>
/// مدينة تُدار من الأدمن وتتبع دولة. تُستخدم في التسجيل واختيار موقع المستخدم.
/// </summary>
public class City : BaseEntity
{
    /// <summary>الدولة التابعة لها المدينة.</summary>
    public int CountryId { get; set; }
    public Country Country { get; set; } = null!;

    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;

    /// <summary>المنطقة الإدارية (مثل "منطقة الرياض").</summary>
    public string? Region { get; set; }

    /// <summary>إحداثيات مركز المدينة (لتوسيط الخريطة عند اختيارها).</summary>
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; } = 0;

    // Navigation
    public ICollection<District> Districts { get; set; } = [];
}
