using SportaApis.DTOs;

namespace SportaApis.Services;

public interface INotificationService
{
    /// <summary>Creates a notification for [userId] (best-effort helper).</summary>
    Task PushAsync(int userId, string title, string body, string type, int? referenceId);

    /// <summary>
    /// Stores an in-app notification for every active user and broadcasts a push.
    /// Used by admin announcements ("للجميع").
    /// </summary>
    Task PushToAllAsync(string title, string body, string type, int? referenceId);

    Task<PagedResult<NotificationDto>> GetAsync(int userId, int page = 1, int pageSize = 20);
    Task<int> GetUnreadCountAsync(int userId);
    Task MarkReadAsync(int userId, int id);
    Task MarkAllReadAsync(int userId);
}
