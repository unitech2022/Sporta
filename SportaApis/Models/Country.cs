namespace SportaApis.Models;

/// <summary>
/// دولة تُدار من الأدمن. المدن تتبع الدولة، ونطاق عمل الموظف يُحدَّد بدولة
/// (وبمدينة واحدة داخلها أو كل مدنها).
/// </summary>
public class Country : BaseEntity
{
    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;

    /// <summary>رمز الدولة ISO alpha-2 (مثل "SA").</summary>
    public string Code { get; set; } = string.Empty;

    /// <summary>مفتاح الاتصال الدولي بدون + (مثل "966").</summary>
    public string? PhoneCode { get; set; }

    /// <summary>رمز العملة (مثل "SAR").</summary>
    public string? CurrencyCode { get; set; }

    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; } = 0;

    // Navigation
    public ICollection<City> Cities { get; set; } = [];
}
