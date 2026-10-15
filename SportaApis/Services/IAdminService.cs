using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IAdminService
{
    /// <summary>Aggregate counts + revenue for the dashboard home.</summary>
    Task<AdminStatsDto> GetStatsAsync();

    /// <summary>Paged list of users, optionally filtered by role and search.</summary>
    Task<PagedResult<AdminUserDto>> GetUsersAsync(
        string? role, string? search, int page, int pageSize);

    /// <summary>
    /// كل بيانات حساب واحد (الملف الشخصي + المحفظة + الاشتراك + الوثائق +
    /// النشاط + أقسام الدور). null لو لم يوجد أو كان خارج نطاق الموظف.
    /// </summary>
    Task<AdminUserDetailDto?> GetUserAsync(int userId);

    /// <summary>Paged recent notifications across all users (newest first).</summary>
    Task<PagedResult<AdminNotificationDto>> GetNotificationsAsync(int page, int pageSize);

    /// <summary>Count of unread notifications across all users (for the dashboard bell).</summary>
    Task<int> GetUnreadNotificationsCountAsync();

    /// <summary>Paged court bookings across all users, optionally filtered by status.</summary>
    Task<PagedResult<AdminBookingDto>> GetBookingsAsync(string? status, int page, int pageSize);

    /// <summary>A single booking's admin detail (null if not found).</summary>
    Task<AdminBookingDto?> GetBookingAsync(int bookingId);

    /// <summary>Platform-wide financial summary (incoming/outgoing/balances/breakdown).</summary>
    Task<FinanceStatsDto> GetFinanceStatsAsync();

    /// <summary>
    /// Paged wallet transactions across all users, optionally filtered by
    /// type/search and by <c>status</c> ("completed" | "failed").
    /// </summary>
    Task<PagedResult<AdminTransactionDto>> GetTransactionsAsync(
        string? type, string? search, int page, int pageSize, string? status = null);

    /// <summary>A single wallet transaction's admin detail (null if not found).</summary>
    Task<AdminTransactionDto?> GetTransactionAsync(int transactionId);

    /// <summary>Sends an announcement to every active user (in-app + push).</summary>
    Task BroadcastAsync(string title, string body);

    /// <summary>Sends a notification to a single user (in-app + push).</summary>
    Task SendToUserAsync(int userId, string title, string body);
    Task<int> DeleteNotificationsAsync(List<int> ids, bool wholeBroadcast);

    /// <summary>Locks (deactivates) or unlocks a user account and notifies them.</summary>
    Task SetLockedAsync(int userId, bool locked);

    /// <summary>يعتمد (أو يسحب اعتماد) دور المدرب/صاحب الملعب ويُشعر صاحبه.</summary>
    Task SetRoleApprovedAsync(int userId, Enums.UserType role, bool approved);

    /// <summary>
    /// يضبط مستوى لاعب يدوياً (1..7) ويُشعره. تجاوزٌ لما قرّره التقييم الذاتي
    /// أو المدرب، ويعيد المستوى بعد الضبط.
    /// </summary>
    Task<int> SetPlayerLevelAsync(int userId, int level);

    /// <summary>Sets نسبة سبورتا — the platform markup (%) for a single court.</summary>
    Task SetCourtCommissionAsync(int courtId, decimal percent);

    /// <summary>Suspends or reinstates a court and notifies its venue owner.
    /// Suspended courts are hidden from players and cannot be booked.</summary>
    Task SetCourtSuspendedAsync(int courtId, bool suspended);

    /// <summary>Approves or revokes approval for a venue and notifies its owner.
    /// Unapproved venues' courts are never shown to players or bookable.</summary>
    Task SetVenueApprovedAsync(int venueId, bool approved);

    /// <summary>
    /// حذف نادٍ وكل ملاعبه حذفاً ناعماً: يختفي من اللوحة والتطبيق ولوحة المالك،
    /// وتُلغى الحجوزات القادمة مع ردّ ما دُفع، ويُشعَر المالك. الحجوزات السابقة
    /// تبقى في السجل المالي.
    /// </summary>
    Task DeleteVenueAsync(int venueId);

    /// <summary>حذف ملعب واحد حذفاً ناعماً — انظر <see cref="DeleteVenueAsync"/>.</summary>
    Task DeleteCourtAsync(int courtId);

    /// <summary>
    /// حذف حساب لاعب أو مدرب من اللوحة — يمرّ على نفس مسار حذف الحساب الذاتي
    /// (إلغاء الالتزامات القادمة، ردّ الأموال، مسح البيانات الشخصية، ثم التعمية)
    /// بعد التحقق من أن المستخدم داخل نطاق الموظف الجغرافي.
    /// </summary>
    Task DeleteUserAccountAsync(int userId, string? reason);
}
