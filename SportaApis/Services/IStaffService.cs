using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IStaffService
{
    /// <summary>كتالوج الصلاحيات المتاحة مقسّماً على أقسام اللوحة.</summary>
    List<PermissionGroupDto> GetPermissionCatalog();

    /// <summary>صلاحيات ونطاق المستخدم الحالي (أدمن أو موظف).</summary>
    Task<MyAccessDto> GetMyAccessAsync();

    Task<PagedResult<StaffDto>> GetStaffAsync(string? search, int page, int pageSize);
    Task<StaffDto?> GetStaffMemberAsync(int userId);
    Task<StaffDto> CreateStaffAsync(CreateStaffRequest req, int? createdByUserId);
    Task<StaffDto> UpdateStaffAsync(int userId, UpdateStaffRequest req);

    /// <summary>تفعيل/إيقاف حساب موظف — الخيار الآمن، يحفظ كل السجلات.</summary>
    Task SetStaffActiveAsync(int userId, bool active);

    /// <summary>
    /// حذف موظف نهائياً مع نطاقه وصلاحياته. يرفض الحذف إذا كان الحساب مرتبطاً
    /// ببيانات تشغيلية (حجوزات/مباريات/أندية…) ويقترح التعطيل بدلاً منه.
    /// </summary>
    Task DeleteStaffAsync(int userId);
}
