namespace SportaApis.Services;

/// <summary>
/// النطاق الجغرافي لموظف: دولة واحدة، ومدينة واحدة داخلها أو كل مدنها
/// (<see cref="CityId"/> = null تعني كل المدن).
/// </summary>
public record GeoScope(int CountryId, int? CityId)
{
    public bool AllCities => CityId is null;
}

/// <summary>
/// سياق المستخدم الحالي في لوحة التحكم — صلاحياته ونطاقه الجغرافي. يُحمَّل مرة
/// واحدة لكل طلب (scoped) ويُستخدم في فلتر الصلاحيات وفي تصفية الاستعلامات.
/// </summary>
public interface IAdminContext
{
    /// <summary>معرّف المستخدم من التوكن (null لو غير مسجّل دخول).</summary>
    int? UserId { get; }

    /// <summary>أدمن كامل الصلاحيات — يتجاوز كل الفحوصات والتصفية الجغرافية.</summary>
    bool IsAdmin { get; }

    /// <summary>موظف بصلاحيات محددة.</summary>
    bool IsStaff { get; }

    /// <summary>هل يملك المستخدم هذه الصلاحية؟ (الأدمن دائماً نعم).</summary>
    Task<bool> HasPermissionAsync(string permission);

    /// <summary>كل مفاتيح الصلاحيات الممنوحة (كل الكتالوج للأدمن).</summary>
    Task<IReadOnlySet<string>> GetPermissionsAsync();

    /// <summary>
    /// نطاق الموظف الجغرافي، أو <c>null</c> لمن لا يخضع لأي حصر (الأدمن).
    /// </summary>
    Task<GeoScope?> GetScopeAsync();
}
