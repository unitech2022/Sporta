using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Hubs;
using SportaApis.Models;

namespace SportaApis.Services;

/// <inheritdoc cref="ISupportChatService"/>
public class SupportChatService : ISupportChatService
{
    /// <summary>أقصى طول للرسالة — مطابق لـ HasMaxLength في AppDbContext.</summary>
    private const int MaxBodyLength = 4000;

    /// <summary>أقصى طول لمقتطف آخر رسالة في قائمة الإدارة.</summary>
    private const int PreviewLength = 300;

    private const int DefaultMessagePageSize = 30;
    private const int MaxMessagePageSize = 60;

    private readonly AppDbContext _db;
    private readonly IHubContext<SupportChatHub> _hub;
    private readonly INotificationService _notifications;

    public SupportChatService(
        AppDbContext db,
        IHubContext<SupportChatHub> hub,
        INotificationService notifications)
    {
        _db = db;
        _hub = hub;
        _notifications = notifications;
    }

    // ══ جانب المستخدم ═════════════════════════════════════════════════════════

    public async Task<SupportMessagePageDto> GetMineAsync(int userId, int? before, int limit)
    {
        var conv = await ConversationQuery().FirstOrDefaultAsync(c => c.UserId == userId);
        if (conv == null)
            return new SupportMessagePageDto { Exists = false };

        var (messages, hasMore) = await MessagePageAsync(conv.Id, before, limit);
        return new SupportMessagePageDto
        {
            Exists = true,
            Conversation = ToDto(conv),
            Messages = messages,
            HasMore = hasMore,
        };
    }

    public async Task<SupportMessageDto> SendAsUserAsync(int userId, string body)
    {
        body = NormalizeBody(body);

        var me = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        var now = AppClock.Now;
        var conv = await ConversationQuery().FirstOrDefaultAsync(c => c.UserId == userId);
        if (conv == null)
        {
            _db.SupportConversations.Add(new SupportConversation
            {
                UserId = userId,
                CreatedAt = now,
                LastMessageAt = now,
            });
            await _db.SaveChangesAsync();

            // نعيد القراءة عبر ConversationQuery حتى يحمل الكيان صاحبه وأدواره،
            // فملخّص المحادثة المبثوث يحتاجهما.
            conv = await ConversationQuery().FirstAsync(c => c.UserId == userId);
        }
        else if (conv.Status == SupportConversationStatus.Closed)
        {
            // الكتابة من جديد تُحيي المحادثة بدل ترك السجل معلّقاً في محادثة مغلقة.
            conv.Status = SupportConversationStatus.Open;
            conv.ClosedAt = null;
        }

        var msg = NewMessage(conv.Id, userId, FullName(me), fromAdmin: false, body, now);
        _db.SupportMessages.Add(msg);

        conv.LastMessageAt = now;
        conv.LastMessageText = Preview(body);
        conv.LastMessageFromAdmin = false;
        conv.UnreadForAdmin += 1;
        conv.UpdatedAt = now;
        await _db.SaveChangesAsync();

        await BroadcastMessageAsync(conv, msg);
        return ToDto(msg);
    }

    public async Task MarkMineReadAsync(int userId)
    {
        var conv = await _db.SupportConversations.FirstOrDefaultAsync(c => c.UserId == userId);
        if (conv == null) return;

        await MarkReadAsync(conv, adminSide: false);
    }

    public async Task<int> GetMyUnreadCountAsync(int userId) =>
        await _db.SupportConversations
            .Where(c => c.UserId == userId)
            .Select(c => c.UnreadForUser)
            .FirstOrDefaultAsync();

    // ══ جانب الإدارة ══════════════════════════════════════════════════════════

    public async Task<SupportInboxDto> GetInboxAsync(
        int page, int pageSize, string? search, string? status, bool unreadOnly)
    {
        (page, pageSize) = Paging.Clamp(page, pageSize);

        var query = ConversationQuery();

        if (!string.IsNullOrWhiteSpace(status)
            && Enum.TryParse<SupportConversationStatus>(status, ignoreCase: true, out var st))
            query = query.Where(c => c.Status == st);

        if (unreadOnly)
            query = query.Where(c => c.UnreadForAdmin > 0);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim();
            query = query.Where(c =>
                c.User.FirstName.Contains(term)
                || c.User.LastName.Contains(term)
                || c.User.PhoneNumber.Contains(term)
                || c.LastMessageText.Contains(term));
        }

        var total = await query.CountAsync();
        var rows = await query
            .OrderByDescending(c => c.LastMessageAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new SupportInboxDto
        {
            Conversations = new PagedResult<SupportConversationDto>
            {
                Items = rows.Select(ToDto).ToList(),
                Page = page,
                PageSize = pageSize,
                Total = total,
            },
            UnreadTotal = await _db.SupportConversations.CountAsync(c => c.UnreadForAdmin > 0),
        };
    }

    public async Task<SupportMessagePageDto> GetConversationAsync(
        int conversationId, int? before, int limit)
    {
        var conv = await ConversationQuery().FirstOrDefaultAsync(c => c.Id == conversationId)
            ?? throw NotFound();

        var (messages, hasMore) = await MessagePageAsync(conv.Id, before, limit);
        return new SupportMessagePageDto
        {
            Exists = true,
            Conversation = ToDto(conv),
            Messages = messages,
            HasMore = hasMore,
        };
    }

    public async Task<SupportMessageDto> ReplyAsAdminAsync(
        int conversationId, int adminUserId, string body)
    {
        body = NormalizeBody(body);

        var conv = await ConversationQuery().FirstOrDefaultAsync(c => c.Id == conversationId)
            ?? throw NotFound();

        var msg = await AppendAdminMessageAsync(conv, adminUserId, body);
        return ToDto(msg);
    }

    public async Task<SupportConversationDto> StartConversationAsync(
        int targetUserId, int adminUserId, string? body)
    {
        var target = await _db.Users.FirstOrDefaultAsync(u => u.Id == targetUserId)
            ?? throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        var now = AppClock.Now;
        var conv = await ConversationQuery().FirstOrDefaultAsync(c => c.UserId == targetUserId);
        if (conv == null)
        {
            _db.SupportConversations.Add(new SupportConversation
            {
                UserId = target.Id,
                CreatedAt = now,
                LastMessageAt = now,
            });
            await _db.SaveChangesAsync();
            conv = await ConversationQuery().FirstAsync(c => c.UserId == targetUserId);
        }

        // بلا نص ⇒ فتح المحادثة فقط؛ الإدارة تكتب متى شاءت.
        if (!string.IsNullOrWhiteSpace(body))
            await AppendAdminMessageAsync(conv, adminUserId, NormalizeBody(body));

        return ToDto(conv);
    }

    public async Task MarkConversationReadAsync(int conversationId)
    {
        var conv = await _db.SupportConversations.FirstOrDefaultAsync(c => c.Id == conversationId)
            ?? throw NotFound();

        await MarkReadAsync(conv, adminSide: true);
    }

    public async Task<SupportConversationDto> SetStatusAsync(int conversationId, string status)
    {
        if (!Enum.TryParse<SupportConversationStatus>(status, ignoreCase: true, out var st))
            throw new AuthException("Invalid status", "حالة غير صحيحة", "INVALID_STATUS");

        var conv = await ConversationQuery().FirstOrDefaultAsync(c => c.Id == conversationId)
            ?? throw NotFound();

        var now = AppClock.Now;
        conv.Status = st;
        conv.ClosedAt = st == SupportConversationStatus.Closed ? now : null;
        conv.UpdatedAt = now;
        await _db.SaveChangesAsync();

        var summary = ToDto(conv);
        await SafeBroadcastAsync(conv.UserId, "ConversationUpdated", summary);
        return summary;
    }

    // ══ المشترك ═══════════════════════════════════════════════════════════════

    /// <summary>
    /// يضيف رد إدارة إلى محادثة محمّلة (مع <c>User</c> و<c>Roles</c>)، يحدّث
    /// العدّادات، يبثّ السطر، ويُشعِر صاحب المحادثة.
    /// </summary>
    private async Task<SupportMessage> AppendAdminMessageAsync(
        SupportConversation conv, int adminUserId, string body)
    {
        var admin = await _db.Users.FirstOrDefaultAsync(u => u.Id == adminUserId);
        var now = AppClock.Now;

        var msg = NewMessage(conv.Id, adminUserId, AdminDisplayName(admin), fromAdmin: true, body, now);
        _db.SupportMessages.Add(msg);

        conv.LastMessageAt = now;
        conv.LastMessageText = Preview(body);
        conv.LastMessageFromAdmin = true;
        conv.UnreadForUser += 1;
        // الرد نفسه يعني أن الإدارة قرأت ما وصلها.
        conv.UnreadForAdmin = 0;
        if (conv.Status == SupportConversationStatus.Closed)
        {
            conv.Status = SupportConversationStatus.Open;
            conv.ClosedAt = null;
        }
        conv.UpdatedAt = now;
        await _db.SaveChangesAsync();

        await BroadcastMessageAsync(conv, msg);

        // إشعار/بوش للمستخدم — التطبيق قد يكون مغلقاً فلا يصله بث الـ hub.
        try
        {
            await _notifications.PushAsync(
                conv.UserId, "رسالة من الدعم", Preview(body), "support_chat", conv.Id);
        }
        catch
        {
            // الرسالة محفوظة أصلاً؛ فشل الإشعار لا يُبطل الرد.
        }

        return msg;
    }

    /// <summary>يمسح عدّاد طرف ويختم رسائل الطرف الآخر كمقروءة، ثم يبلّغ الطرفين.</summary>
    private async Task MarkReadAsync(SupportConversation conv, bool adminSide)
    {
        var now = AppClock.Now;
        DateTime? readAt = now;

        // رسائل الطرف الآخر فقط: الإدارة تقرأ رسائل المستخدم والعكس.
        await _db.SupportMessages
            .Where(m => m.ConversationId == conv.Id
                        && m.ReadAt == null
                        && m.FromAdmin != adminSide)
            .ExecuteUpdateAsync(s => s.SetProperty(m => m.ReadAt, readAt));

        if (adminSide) conv.UnreadForAdmin = 0;
        else conv.UnreadForUser = 0;
        conv.UpdatedAt = now;
        await _db.SaveChangesAsync();

        await SafeBroadcastAsync(conv.UserId, "ConversationRead", new
        {
            conversationId = conv.Id,
            byAdmin = adminSide,
            readAt = now,
        });
    }

    /// <summary>يدفع سطراً جديداً لصاحب المحادثة ولصندوق الإدارة معاً.</summary>
    private async Task BroadcastMessageAsync(SupportConversation conv, SupportMessage msg)
    {
        var payload = new { conversationId = conv.Id, message = ToDto(msg) };
        await SafeBroadcastAsync(conv.UserId, "MessageReceived", payload);
        await SafeBroadcastAsync(conv.UserId, "ConversationUpdated", ToDto(conv), adminsOnly: true);
    }

    /// <summary>
    /// بثّ لا يُفشل عملية كتابة نجحت بالفعل: الرسالة محفوظة، وأي عميل منقطع
    /// سيلتقطها في أول تحميل للسجل.
    /// </summary>
    private async Task SafeBroadcastAsync(
        int userId, string eventName, object payload, bool adminsOnly = false)
    {
        try
        {
            if (!adminsOnly)
                await _hub.Clients.Group(SupportChatHub.UserGroup(userId))
                    .SendAsync(eventName, payload);

            await _hub.Clients.Group(SupportChatHub.AdminsGroup)
                .SendAsync(eventName, payload);
        }
        catch
        {
            // منفذ النقل معطّل/مغلق — لا شيء نفعله هنا.
        }
    }

    /// <summary>
    /// صفحة من السجل. الترقيم يمشي للخلف من الأحدث (أو من <paramref name="before"/>
    /// عند طلب الأقدم)، ثم تُقلب الصفحة زمنياً للعرض.
    /// </summary>
    private async Task<(List<SupportMessageDto> Items, bool HasMore)> MessagePageAsync(
        int conversationId, int? before, int limit)
    {
        limit = Math.Clamp(limit <= 0 ? DefaultMessagePageSize : limit, 1, MaxMessagePageSize);

        var query = _db.SupportMessages.Where(m => m.ConversationId == conversationId);
        if (before is > 0) query = query.Where(m => m.Id < before.Value);

        var rows = await query
            .OrderByDescending(m => m.Id)
            .Take(limit + 1)          // صف زائد واحد = "يوجد أقدم"
            .ToListAsync();

        var hasMore = rows.Count > limit;
        if (hasMore) rows.RemoveAt(rows.Count - 1);
        rows.Reverse();

        return (rows.Select(ToDto).ToList(), hasMore);
    }

    /// <summary>محادثة مع صاحبها وأدواره — كل ما يحتاجه ملخّص القائمة.</summary>
    private IQueryable<SupportConversation> ConversationQuery() =>
        _db.SupportConversations
            .Include(c => c.User)
                .ThenInclude(u => u.Roles);

    private static SupportMessage NewMessage(
        int conversationId, int senderId, string senderName, bool fromAdmin, string body, DateTime now)
        => new()
        {
            ConversationId = conversationId,
            SenderUserId = senderId,
            SenderName = senderName,
            FromAdmin = fromAdmin,
            Body = body,
            CreatedAt = now,
        };

    private static string NormalizeBody(string? body)
    {
        var text = (body ?? string.Empty).Trim();
        if (text.Length == 0)
            throw new AuthException("Message is empty", "الرسالة فارغة", "EMPTY_MESSAGE");

        return text.Length > MaxBodyLength ? text[..MaxBodyLength] : text;
    }

    private static string Preview(string body) =>
        body.Length <= PreviewLength ? body : body[..PreviewLength];

    private static string FullName(User u) => $"{u.FirstName} {u.LastName}".Trim();

    /// <summary>
    /// مفردات العملاء تستخدم "venue" لدور مالك الملعب لا "venueowner" — نفس ما
    /// يرسله AuthService و AdminService، وإلا لن تعرف اللوحة والتطبيق الدور.
    /// </summary>
    private static string RoleKey(UserType type) => type switch
    {
        UserType.Coach => "coach",
        UserType.VenueOwner => "venue",
        UserType.Admin => "admin",
        UserType.Staff => "staff",
        _ => "player",
    };

    /// <summary>
    /// اسم من ردّ من الإدارة. يُخزَّن لحظة الإرسال ليبقى السجل منسوباً لصاحبه
    /// حتى لو حُذف الموظف لاحقاً، و"الدعم" احتياط لو تعذّر إيجاد الحساب.
    /// </summary>
    private static string AdminDisplayName(User? admin) =>
        admin == null ? "الدعم" : FullName(admin);

    private static AuthException NotFound() =>
        new("Conversation not found", "المحادثة غير موجودة", "CONVERSATION_NOT_FOUND");

    private static SupportMessageDto ToDto(SupportMessage m) => new()
    {
        Id = m.Id,
        ConversationId = m.ConversationId,
        FromAdmin = m.FromAdmin,
        SenderName = m.SenderName,
        Body = m.Body,
        SentAt = m.CreatedAt,
        ReadAt = m.ReadAt,
    };

    private static SupportConversationDto ToDto(SupportConversation c) => new()
    {
        Id = c.Id,
        UserId = c.UserId,
        UserName = c.User == null ? string.Empty : FullName(c.User),
        UserPhone = c.User?.PhoneNumber ?? string.Empty,
        UserImageUrl = c.User?.ProfileImageUrl,
        UserRoles = c.User?.Roles.Select(r => RoleKey(r.Role)).Distinct().ToList() ?? [],
        Status = c.Status.ToString(),
        CreatedAt = c.CreatedAt,
        LastMessageAt = c.LastMessageAt,
        LastMessageText = c.LastMessageText,
        LastMessageFromAdmin = c.LastMessageFromAdmin,
        UnreadForAdmin = c.UnreadForAdmin,
        UnreadForUser = c.UnreadForUser,
    };
}
