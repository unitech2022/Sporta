using SportaApis.DTOs;

namespace SportaApis.Services;

public interface ICourtService
{
    /// <summary>Lists bookable courts (paged), optionally filtered by city / type / gender.
    /// With <paramref name="window"/>, each court carries its free slots in that
    /// window (<see cref="CourtDto.FreeSlots"/>) and courts with free slots come first.</summary>
    Task<PagedResult<CourtDto>> GetCourtsAsync(
        int currentUserId, string? city, string? type, string? gender,
        int page = 1, int pageSize = 20, CourtSlotWindow? window = null);

    /// <summary>Lists every court for the admin dashboard, including suspended ones.</summary>
    Task<List<CourtDto>> GetAllForAdminAsync();

    /// <summary>Returns a single court (flattened with its venue), with
    /// <see cref="CourtDto.IsFavorite"/> resolved for the calling user.</summary>
    Task<CourtDto> GetCourtByIdAsync(int id, int currentUserId);

    /// <summary>الملاعب التي أضافها المستخدم لمفضّلته، الأحدث إضافةً أولاً.</summary>
    Task<PagedResult<CourtDto>> GetFavoritesAsync(int currentUserId, int page = 1, int pageSize = 20);

    /// <summary>
    /// يضيف الملعب لمفضّلة المستخدم أو يزيله منها. idempotent: تكرار نفس الطلب
    /// لا يغيّر شيئاً. يُرجع الحالة بعد التنفيذ.
    /// </summary>
    Task<bool> ToggleFavoriteAsync(int currentUserId, int courtId, bool favorite);

    /// <summary>
    /// تفاصيل ملعب للوحة التحكم: <paramref name="requireApproved"/> = false تتخطى
    /// شرط اعتماد النادي (اللوحة تسرد كل الملاعب فيجب أن تفتحها كلها)، وتخضع
    /// لنطاق الموظف الجغرافي.
    /// </summary>
    Task<CourtDto> GetCourtByIdAsync(int id, bool requireApproved);

    /// <summary>
    /// Returns the per-slot availability for a court on a given date, stepped
    /// by <paramref name="durationMinutes"/> (defaults to 60 for backward
    /// compatibility).
    /// </summary>
    Task<CourtAvailabilityDto> GetAvailabilityAsync(
        int courtId, DateTime date, int durationMinutes = 60);

    /// <inheritdoc cref="GetCourtByIdAsync(int, bool)"/>
    /// <param name="endDate">
    /// آخر يوم في مدى متعدد الأيام (البطولة تشغل نفس الموعد من كل يوم): الموعد
    /// لا يُعرض متاحاً إلا إذا كان فارغاً في كل أيام المدى. null = يوم واحد.
    /// </param>
    Task<CourtAvailabilityDto> GetAvailabilityAsync(
        int courtId, DateTime date, int durationMinutes, bool requireApproved,
        DateTime? endDate = null);
}
