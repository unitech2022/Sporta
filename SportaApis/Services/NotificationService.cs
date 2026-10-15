using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Models;

namespace SportaApis.Services;

public class NotificationService : INotificationService
{
    private readonly AppDbContext _db;
    private readonly IPushSender _push;

    public NotificationService(AppDbContext db, IPushSender push)
    {
        _db = db;
        _push = push;
    }

    public async Task PushAsync(
        int userId, string title, string body, string type, int? referenceId)
    {
        _db.Notifications.Add(new Notification
        {
            UserId = userId,
            Title = title,
            Body = body,
            ReferenceType = type,
            ReferenceId = referenceId,
        });
        await _db.SaveChangesAsync();

        // Also deliver as a push (no-op if OneSignal isn't configured).
        // الإشعار داخل التطبيق محفوظ أعلاه؛ الدفع الخارجي يُطلق دون انتظار حتى
        // لا يتراكم زمن OneSignal (حتى 4 ث لكل مستلم) على الطلب في حلقات
        // القرعة/الانتهاء. المرسل لا يستخدم DbContext (HttpClientFactory فقط)
        // فلا خطر من عمله بعد انتهاء نطاق الطلب.
        FireAndForget(_push.SendAsync(userId, title, body, type, referenceId));
    }

    private static void FireAndForget(Task push) =>
        // المرسل يلتقط أخطاءه ويسجّلها؛ هذا احتياط حتى لا يبقى استثناء غير مرصود.
        _ = push.ContinueWith(t => _ = t.Exception, TaskContinuationOptions.OnlyOnFaulted);

    public async Task PushToAllAsync(
        string title, string body, string type, int? referenceId)
    {
        var userIds = await _db.Users
            .Where(u => u.IsActive)
            .Select(u => u.Id)
            .ToListAsync();

        _db.Notifications.AddRange(userIds.Select(id => new Notification
        {
            UserId = id,
            Title = title,
            Body = body,
            ReferenceType = type,
            ReferenceId = referenceId,
        }));
        await _db.SaveChangesAsync();

        // One broadcast push to all subscribed devices.
        FireAndForget(_push.BroadcastAsync(title, body, type, referenceId));
    }

    public async Task<PagedResult<NotificationDto>> GetAsync(
        int userId, int page = 1, int pageSize = 20)
    {
        (page, pageSize) = Paging.Clamp(page, pageSize);

        var query = _db.Notifications.Where(n => n.UserId == userId);
        var total = await query.CountAsync();
        var notifications = await query
            .OrderByDescending(n => n.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<NotificationDto>
        {
            Items = notifications.Select(ToDto).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    public Task<int> GetUnreadCountAsync(int userId) =>
        _db.Notifications.CountAsync(n => n.UserId == userId && !n.IsRead);

    public async Task MarkReadAsync(int userId, int id)
    {
        var n = await _db.Notifications
            .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);
        if (n == null || n.IsRead) return;
        n.IsRead = true;
        await _db.SaveChangesAsync();
    }

    public async Task MarkAllReadAsync(int userId)
    {
        var unread = await _db.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .ToListAsync();
        foreach (var n in unread) n.IsRead = true;
        await _db.SaveChangesAsync();
    }

    private static NotificationDto ToDto(Notification n) => new()
    {
        Id = n.Id,
        Title = n.Title,
        Body = n.Body,
        Type = n.ReferenceType,
        ReferenceId = n.ReferenceId,
        IsRead = n.IsRead,
        CreatedAt = n.CreatedAt,
    };
}
