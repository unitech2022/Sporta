using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Hubs;
using SportaApis.Models;

namespace SportaApis.Services;

public interface IEventChatService
{
    /// <summary>عضو الدردشة = المنشئ أو لاعب معتمد. المنسحب يخرج بخروج صفّه.</summary>
    Task<bool> IsMemberAsync(int userId, int matchId);

    Task<EventChatSummaryDto> GetSummaryAsync(int userId, int matchId);

    /// <summary>صفحة من السجل (الأقدم أولاً) قبل <paramref name="beforeId"/>.</summary>
    Task<List<EventChatMessageDto>> GetMessagesAsync(int userId, int matchId, int? beforeId, int limit);

    Task<EventChatMessageDto> SendAsync(int userId, int matchId, SendEventChatMessageRequest req);

    /// <summary>تفاعل المستخدم مع رسالة (رمز واحد لكل عضو؛ null يزيله).</summary>
    Task<EventChatMessageDto> ReactAsync(int userId, int matchId, int messageId, string? emoji);

    /// <summary>يحذفها كاتبها أو المنظّم (تبقى «رسالة محذوفة»).</summary>
    Task DeleteAsync(int userId, int matchId, int messageId);

    Task MarkReadAsync(int userId, int matchId);

    /// <summary>رسالة نظام («انضم فلان»…) — best-effort لا يُفشل المسار الأصلي.</summary>
    Task PostSystemAsync(int matchId, string body);

    /// <summary>«انضم/انسحب فلان من الحدث» باسم العضو. best-effort.</summary>
    Task PostMemberEventAsync(int matchId, int userId, bool joined);
}

/// <summary>
/// دردشة أعضاء المباراة/الأمريكانو/البطولة. أعضاؤها المنشئ واللاعبون المعتمدون
/// فقط — صاحب الملعب لا يدخلها إلا منشئاً أو مشاركاً. تصير للقراءة فقط بعد
/// انتهاء موعد الحدث أو إلغائه. REST مصدر الحقيقة، و<see cref="EventChatHub"/>
/// يدفع الجديد لمن فتح الشاشة، والإشعار يصل العضو عند أول رسالة لم يقرأها
/// (لا عند كل رسالة) حتى لا يُغرق.
/// </summary>
public class EventChatService : IEventChatService
{
    private const int MaxPage = 50;

    private readonly AppDbContext _db;
    private readonly IHubContext<EventChatHub> _hub;
    private readonly INotificationService _notifications;
    private readonly ILogger<EventChatService> _logger;
    private readonly IWebHostEnvironment _env;

    public EventChatService(
        AppDbContext db, IHubContext<EventChatHub> hub,
        INotificationService notifications, ILogger<EventChatService> logger,
        IWebHostEnvironment env)
    {
        _db = db;
        _hub = hub;
        _notifications = notifications;
        _logger = logger;
        _env = env;
    }

    // ── العضوية والحالة ─────────────────────────────────────────────────────────

    public async Task<bool> IsMemberAsync(int userId, int matchId) =>
        userId != 0 && await _db.Matches.AnyAsync(m => m.Id == matchId &&
            (m.CreatorId == userId || m.MatchPlayers.Any(p =>
                p.UserId == userId && p.Status == MatchPlayerStatus.Approved)));

    private async Task<Match> LoadAsync(int matchId) =>
        await _db.Matches
            .Include(m => m.MatchPlayers).ThenInclude(p => p.User)
            .Include(m => m.Creator)
            .Include(m => m.Court).ThenInclude(c => c!.Venue)
            .Include(m => m.AmericanoMatch)
            .FirstOrDefaultAsync(m => m.Id == matchId)
        ?? throw new AuthException("Event not found", "الحدث غير موجود", "MATCH_NOT_FOUND");

    private static bool IsMember(Match m, int userId) =>
        userId != 0 && (m.CreatorId == userId || m.MatchPlayers.Any(p =>
            p.UserId == userId && p.Status == MatchPlayerStatus.Approved));

    private async Task<Match> LoadForMemberAsync(int userId, int matchId)
    {
        var m = await LoadAsync(matchId);
        if (!IsMember(m, userId))
            throw new AuthException(
                "Only members can open this chat",
                "الدردشة لأعضاء الحدث فقط", "CHAT_NOT_MEMBER");
        return m;
    }

    /// <summary>نهاية الحدث: آخر أيامه + المدة. بعدها تصير الدردشة للقراءة فقط.</summary>
    private static DateTime EndsAt(Match m)
    {
        var lastDay = m.AmericanoMatch?.EndDate?.Date ?? m.ScheduledAt.Date;
        return lastDay + m.ScheduledAt.TimeOfDay + TimeSpan.FromMinutes(m.DurationMinutes);
    }

    private static bool IsWritable(Match m) =>
        m.Status is not (MatchStatus.Cancelled or MatchStatus.Completed)
        && m.AmericanoMatch?.IsCompleted != true
        && AppClock.Now <= EndsAt(m);

    /// <summary>الدور الظاهر بجانب الاسم.</summary>
    private static string RoleOf(Match m, int userId) =>
        userId != m.CreatorId ? "player"
        : m.IsHostedByVenueOwner ? "venue"
        : "organizer";

    private static (string Kind, int RefId, string Label) Describe(Match m) =>
        m.AmericanoMatch is { } a
            ? (a.IsTournament || a.Format != null ? "tournament" : "americano", a.Id,
               a.IsTournament || a.Format != null ? "البطولة" : "الأمريكانو")
            : ("match", m.Id, "المباراة");

    private static string TitleOf(Match m) => m.AmericanoMatch is { } a
        ? (!string.IsNullOrWhiteSpace(a.Name) ? a.Name!
            : a.IsTournament ? "بطولة"
            : a.AmericanoType == Enums.MatchType.AmericanTeam ? "أمريكانو فرق" : "أمريكانو فردي")
        : m.MatchType == Enums.MatchType.Competitive ? "تحدي فرق" : "ودية فردي";

    // ── القراءة ─────────────────────────────────────────────────────────────────

    public async Task<EventChatSummaryDto> GetSummaryAsync(int userId, int matchId)
    {
        var m = await LoadAsync(matchId);
        var (kind, refId, _) = Describe(m);
        var member = IsMember(m, userId);

        var members = new List<EventChatMemberDto>();
        if (member)
        {
            var creator = m.Creator;
            members.Add(new EventChatMemberDto
            {
                UserId = m.CreatorId,
                Name = $"{creator.FirstName} {creator.LastName}".Trim(),
                AvatarUrl = creator.ProfileImageUrl,
                Role = RoleOf(m, m.CreatorId),
            });
            members.AddRange(m.MatchPlayers
                .Where(p => p.Status == MatchPlayerStatus.Approved && p.UserId != m.CreatorId)
                .OrderBy(p => p.JoinedAt)
                .Select(p => new EventChatMemberDto
                {
                    UserId = p.UserId,
                    Name = $"{p.User.FirstName} {p.User.LastName}".Trim(),
                    AvatarUrl = p.User.ProfileImageUrl,
                    Role = "player",
                }));
        }

        return new EventChatSummaryDto
        {
            MatchId = m.Id,
            Kind = kind,
            RefId = refId,
            Title = TitleOf(m),
            VenueName = m.Court?.Venue.Name,
            ScheduledAt = m.ScheduledAt,
            IsMember = member,
            CanWrite = member && IsWritable(m),
            CanModerate = member && userId == m.CreatorId,
            UnreadCount = member ? await UnreadCountAsync(userId, matchId) : 0,
            Members = members,
        };
    }

    private async Task<int> UnreadCountAsync(int userId, int matchId)
    {
        var lastRead = await _db.EventChatReads
            .Where(r => r.MatchId == matchId && r.UserId == userId)
            .Select(r => (int?)r.LastReadMessageId)
            .FirstOrDefaultAsync() ?? 0;
        return await _db.EventChatMessages.CountAsync(x =>
            x.MatchId == matchId && x.Id > lastRead && !x.IsSystem
            && x.DeletedAt == null && x.SenderUserId != userId);
    }

    public async Task<List<EventChatMessageDto>> GetMessagesAsync(
        int userId, int matchId, int? beforeId, int limit)
    {
        var m = await LoadForMemberAsync(userId, matchId);
        limit = Math.Clamp(limit, 1, MaxPage);

        var query = _db.EventChatMessages.Include(x => x.Reactions)
            .Where(x => x.MatchId == matchId);
        if (beforeId is int b) query = query.Where(x => x.Id < b);
        var page = await query.OrderByDescending(x => x.Id).Take(limit).ToListAsync();
        page.Reverse();

        var avatars = await AvatarsAsync(page);
        var replies = await RepliesAsync(page);
        return page.Select(x => ToDto(m, x, avatars, replies)).ToList();
    }

    /// <summary>الرسائل المردود عليها في الصفحة (قد تكون أقدم منها).</summary>
    private async Task<Dictionary<int, EventChatMessage>> RepliesAsync(IEnumerable<EventChatMessage> messages)
    {
        var ids = messages.Where(x => x.ReplyToId != null)
            .Select(x => x.ReplyToId!.Value).Distinct().ToList();
        if (ids.Count == 0) return [];
        return await _db.EventChatMessages.Where(x => ids.Contains(x.Id))
            .ToDictionaryAsync(x => x.Id);
    }

    private async Task<Dictionary<int, string?>> AvatarsAsync(IEnumerable<EventChatMessage> messages)
    {
        var ids = messages.Where(x => x.SenderUserId != null)
            .Select(x => x.SenderUserId!.Value).Distinct().ToList();
        return await _db.Users.Where(u => ids.Contains(u.Id))
            .ToDictionaryAsync(u => u.Id, u => u.ProfileImageUrl);
    }

    private static EventChatMessageDto ToDto(
        Match m, EventChatMessage x, IReadOnlyDictionary<int, string?> avatars,
        IReadOnlyDictionary<int, EventChatMessage>? replies = null) => new()
    {
        Id = x.Id,
        MatchId = x.MatchId,
        SenderUserId = x.SenderUserId,
        SenderName = x.SenderName,
        SenderAvatarUrl = x.SenderUserId is int s && avatars.TryGetValue(s, out var a) ? a : null,
        SenderRole = x.SenderUserId is int sid ? RoleOf(m, sid) : null,
        IsSystem = x.IsSystem,
        IsDeleted = x.DeletedAt != null,
        Body = x.DeletedAt != null ? string.Empty : x.Body,
        CreatedAt = x.CreatedAt,
        ReplyTo = x.ReplyToId is int rid && replies != null && replies.TryGetValue(rid, out var r)
            ? new EventChatReplyDto
            {
                Id = r.Id,
                SenderName = r.SenderName,
                Body = r.DeletedAt != null ? string.Empty
                    : r.Body.Length > 120 ? r.Body[..120] + "…" : r.Body,
                AttachmentType = r.DeletedAt != null ? null : r.AttachmentType,
                IsDeleted = r.DeletedAt != null,
            }
            : null,
        // المحذوفة تفقد مرفقها وتفاعلاتها وإشاراتها مع نصها.
        AttachmentUrl = x.DeletedAt != null ? null : x.AttachmentUrl,
        AttachmentName = x.DeletedAt != null ? null : x.AttachmentName,
        AttachmentType = x.DeletedAt != null ? null : x.AttachmentType,
        AttachmentSize = x.DeletedAt != null ? null : x.AttachmentSize,
        MentionedUserIds = x.DeletedAt != null ? [] : ParseIds(x.MentionedUserIds),
        Reactions = x.DeletedAt != null ? [] : x.Reactions
            .GroupBy(rx => rx.Emoji)
            .OrderByDescending(g => g.Count())
            .Select(g => new EventChatReactionDto { Emoji = g.Key, UserIds = g.Select(rx => rx.UserId).ToList() })
            .ToList(),
    };

    private static List<int> ParseIds(string? csv) => string.IsNullOrWhiteSpace(csv) ? []
        : csv.Split(',', StringSplitOptions.RemoveEmptyEntries)
            .Select(v => int.TryParse(v, out var n) ? n : 0).Where(n => n > 0).ToList();

    // ── الكتابة ─────────────────────────────────────────────────────────────────

    public async Task<EventChatMessageDto> SendAsync(int userId, int matchId, SendEventChatMessageRequest req)
    {
        var m = await LoadForMemberAsync(userId, matchId);
        if (!IsWritable(m))
            throw new AuthException(
                "This chat is read-only now",
                "انتهى الحدث — الدردشة للقراءة فقط", "CHAT_READ_ONLY");

        var body = (req.Body ?? string.Empty).Trim();
        if (body.Length > 1000) body = body[..1000];

        // المرفق يجب أن يكون مرفوعاً عبر نقطة مرفقات الدردشة: الرابط اسم ملف
        // مولَّد (بلا مسارات) وموجود فعلاً تحت wwwroot/uploads/chat.
        var att = req.Attachment;
        if (att != null && !IsStoredAttachment(att.Url))
            throw new AuthException("Invalid attachment", "مرفق غير صالح", "CHAT_BAD_ATTACHMENT");
        if (body.Length == 0 && att == null)
            throw new AuthException("Empty message", "اكتب رسالة أولاً", "CHAT_EMPTY");

        int? replyToId = null;
        if (req.ReplyToId is int rid && await _db.EventChatMessages
                .AnyAsync(x => x.Id == rid && x.MatchId == matchId && !x.IsSystem))
            replyToId = rid;

        // الإشارة لأعضاء الحدث فقط، وبلا الكاتب نفسه.
        var memberIds = MemberIds(m).ToHashSet();
        var mentions = (req.MentionedUserIds ?? [])
            .Where(id => id != userId && memberIds.Contains(id)).Distinct().Take(20).ToList();

        var sender = await _db.Users.Where(u => u.Id == userId)
            .Select(u => new { Name = (u.FirstName + " " + u.LastName).Trim(), u.ProfileImageUrl })
            .FirstAsync();

        // من لم يقرأ شيئاً منذ آخر زيارة يُبلَّغ بإشعار — من لديه غير مقروء
        // وصله إشعار أصلاً. المُشار إليه يُبلَّغ دائماً. يُحسب قبل الحفظ.
        var others = memberIds.Where(id => id != userId).ToList();
        var toNotify = new List<int>();
        foreach (var id in others)
            if (mentions.Contains(id) || await UnreadCountAsync(id, matchId) == 0) toNotify.Add(id);

        var msg = new EventChatMessage
        {
            MatchId = matchId,
            SenderUserId = userId,
            SenderName = sender.Name,
            Body = body,
            ReplyToId = replyToId,
            AttachmentUrl = att?.Url,
            AttachmentName = att == null ? null : Truncate(att.Name, 200),
            AttachmentType = att == null ? null : att.Type == "image" ? "image" : "file",
            AttachmentSize = att?.Size,
            MentionedUserIds = mentions.Count == 0 ? null : string.Join(',', mentions),
            CreatedAt = AppClock.Now,
        };
        _db.EventChatMessages.Add(msg);
        await _db.SaveChangesAsync();
        await MarkReadToAsync(userId, matchId, msg.Id);

        var replies = await RepliesAsync([msg]);
        var dto = ToDto(m, msg, new Dictionary<int, string?> { [userId] = sender.ProfileImageUrl }, replies);
        await BroadcastAsync(matchId, "MessageReceived", dto);

        var (_, _, label) = Describe(m);
        var preview = body.Length == 0
            ? (msg.AttachmentType == "image" ? "📷 صورة" : $"📎 {msg.AttachmentName}")
            : body.Length > 80 ? body[..80] + "…" : body;
        foreach (var id in toNotify)
            await _notifications.PushAsync(id,
                mentions.Contains(id) ? $"{sender.Name} أشار إليك في دردشة {label}" : $"رسالة جديدة في دردشة {label}",
                // مرجع الإشعار معرّف المباراة الأساسية: يفتح الدردشة مباشرة.
                $"{sender.Name}: {preview}", "event_chat", matchId);

        return dto;
    }

    public const string AttachmentsUrlPrefix = "/uploads/chat/";

    /// <summary>
    /// هل الرابط مرفقاً رفعته نقطة المرفقات؟ الاسم كما تولّده (GUID + امتداد)
    /// بلا فواصل مسار، والملف موجود على القرص — فلا يُمرَّر أي نص كمرفق.
    /// </summary>
    private bool IsStoredAttachment(string? url)
    {
        if (string.IsNullOrWhiteSpace(url)
            || !url.StartsWith(AttachmentsUrlPrefix, StringComparison.Ordinal)) return false;
        var name = url[AttachmentsUrlPrefix.Length..];
        if (name.Length == 0 || name != Path.GetFileName(name)
            || name.Contains("..", StringComparison.Ordinal)) return false;
        var root = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
        var dir = Path.GetFullPath(Path.Combine(root, "uploads", "chat"));
        var full = Path.GetFullPath(Path.Combine(dir, name));
        return full.StartsWith(dir + Path.DirectorySeparatorChar, StringComparison.Ordinal)
            && File.Exists(full);
    }

    private static string Truncate(string? v, int max) =>
        string.IsNullOrEmpty(v) ? string.Empty : v.Length > max ? v[..max] : v;

    public async Task<EventChatMessageDto> ReactAsync(int userId, int matchId, int messageId, string? emoji)
    {
        var m = await LoadForMemberAsync(userId, matchId);
        var msg = await _db.EventChatMessages.Include(x => x.Reactions)
            .FirstOrDefaultAsync(x => x.Id == messageId && x.MatchId == matchId)
            ?? throw new AuthException("Message not found", "الرسالة غير موجودة", "CHAT_MESSAGE_NOT_FOUND");
        if (msg.IsSystem || msg.DeletedAt != null)
            throw new AuthException("Can't react to this message", "لا يمكن التفاعل مع هذه الرسالة", "CHAT_REACT_FORBIDDEN");

        emoji = emoji?.Trim();
        var mine = msg.Reactions.FirstOrDefault(r => r.UserId == userId);
        if (string.IsNullOrEmpty(emoji) || mine?.Emoji == emoji)
        {
            // الضغط على تفاعلك نفسه يلغيه — كواتساب.
            if (mine != null) _db.EventChatReactions.Remove(mine);
        }
        else if (mine != null) mine.Emoji = emoji;
        else _db.EventChatReactions.Add(new EventChatReaction { MessageId = msg.Id, UserId = userId, Emoji = emoji });
        await _db.SaveChangesAsync();

        await _db.Entry(msg).Collection(x => x.Reactions).LoadAsync();
        var avatars = await AvatarsAsync([msg]);
        var dto = ToDto(m, msg, avatars, await RepliesAsync([msg]));
        await BroadcastAsync(matchId, "ReactionsUpdated", new { matchId, id = msg.Id, reactions = dto.Reactions });
        return dto;
    }

    public async Task DeleteAsync(int userId, int matchId, int messageId)
    {
        var m = await LoadForMemberAsync(userId, matchId);
        // بعد انتهاء الحدث السجل للقراءة فقط — حذفاً كما كتابةً.
        if (!IsWritable(m))
            throw new AuthException(
                "This chat is read-only now",
                "انتهى الحدث — الدردشة للقراءة فقط", "CHAT_READ_ONLY");
        var msg = await _db.EventChatMessages
            .FirstOrDefaultAsync(x => x.Id == messageId && x.MatchId == matchId)
            ?? throw new AuthException("Message not found", "الرسالة غير موجودة", "CHAT_MESSAGE_NOT_FOUND");
        if (msg.IsSystem || (msg.SenderUserId != userId && m.CreatorId != userId))
            throw new AuthException(
                "You can't delete this message",
                "لا يمكنك حذف هذه الرسالة", "CHAT_DELETE_FORBIDDEN");
        if (msg.DeletedAt != null) return;

        msg.DeletedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        await BroadcastAsync(matchId, "MessageDeleted", new { matchId, id = messageId });
    }

    public async Task MarkReadAsync(int userId, int matchId)
    {
        if (!await IsMemberAsync(userId, matchId)) return;
        var lastId = await _db.EventChatMessages.Where(x => x.MatchId == matchId)
            .MaxAsync(x => (int?)x.Id) ?? 0;
        await MarkReadToAsync(userId, matchId, lastId);
    }

    private async Task MarkReadToAsync(int userId, int matchId, int messageId)
    {
        var state = await _db.EventChatReads
            .FirstOrDefaultAsync(r => r.MatchId == matchId && r.UserId == userId);
        if (state == null)
            _db.EventChatReads.Add(new EventChatReadState
                { MatchId = matchId, UserId = userId, LastReadMessageId = messageId });
        else if (state.LastReadMessageId < messageId)
            state.LastReadMessageId = messageId;
        else return;
        await _db.SaveChangesAsync();
    }

    public async Task PostSystemAsync(int matchId, string body)
    {
        try
        {
            var m = await LoadAsync(matchId);
            var msg = new EventChatMessage
            {
                MatchId = matchId,
                IsSystem = true,
                Body = body,
                CreatedAt = AppClock.Now,
            };
            _db.EventChatMessages.Add(msg);
            await _db.SaveChangesAsync();
            await BroadcastAsync(matchId, "MessageReceived",
                ToDto(m, msg, new Dictionary<int, string?>()));
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Event chat system message failed for match {MatchId}", matchId);
        }
    }

    public async Task PostMemberEventAsync(int matchId, int userId, bool joined)
    {
        try
        {
            var name = await _db.Users.Where(u => u.Id == userId)
                .Select(u => (u.FirstName + " " + u.LastName).Trim())
                .FirstOrDefaultAsync() ?? "لاعب";
            var label = await _db.Matches.Where(m => m.Id == matchId)
                .Select(m => m.AmericanoMatch == null ? "المباراة"
                    : (m.AmericanoMatch.IsTournament || m.AmericanoMatch.Format != null) ? "البطولة"
                    : "الأمريكانو")
                .FirstOrDefaultAsync() ?? "الحدث";
            await PostSystemAsync(matchId, joined ? $"انضم {name} إلى {label}" : $"انسحب {name} من {label}");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Event chat member event failed for match {MatchId}", matchId);
        }
    }

    private static IEnumerable<int> MemberIds(Match m) => m.MatchPlayers
        .Where(p => p.Status == MatchPlayerStatus.Approved)
        .Select(p => p.UserId)
        .Append(m.CreatorId)
        .Distinct();

    private async Task BroadcastAsync(int matchId, string evt, object payload)
    {
        try
        {
            await _hub.Clients.Group(EventChatHub.Group(matchId)).SendAsync(evt, payload);
        }
        catch (Exception ex)
        {
            // البثّ مساعِد: الرسالة محفوظة ويجلبها العميل عبر REST.
            _logger.LogWarning(ex, "Event chat broadcast failed for match {MatchId}", matchId);
        }
    }
}
