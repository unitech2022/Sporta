namespace SportaApis.Models;

/// <summary>
/// حي تابع لمدينة. يظهر للمستخدم بعد اختيار المدينة.
/// </summary>
public class District : BaseEntity
{
    public int CityId { get; set; }
    public City City { get; set; } = null!;

    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; } = 0;
}
