namespace SportaApis.Models;

/// <summary>
/// بيانات الموظف: نطاق عمله الجغرافي وصلاحياته. يُنشأ مع كل مستخدم من نوع
/// <see cref="Enums.UserType.Staff"/>.
/// </summary>
public class StaffProfile : BaseEntity
{
    public int UserId { get; set; }
    public User User { get; set; } = null!;

    /// <summary>الدولة التي يعمل فيها الموظف — إلزامية.</summary>
    public int CountryId { get; set; }
    public Country Country { get; set; } = null!;

    /// <summary>
    /// المدينة التي يعمل فيها الموظف. <c>null</c> تعني «كل مدن الدولة».
    /// </summary>
    public int? CityId { get; set; }
    public City? City { get; set; }

    /// <summary>المسمى الوظيفي (اختياري، للعرض فقط).</summary>
    public string? JobTitle { get; set; }

    /// <summary>الأدمن الذي أنشأ الموظف (للتتبع).</summary>
    public int? CreatedByUserId { get; set; }

    // Navigation
    public ICollection<StaffPermission> Permissions { get; set; } = [];
}
