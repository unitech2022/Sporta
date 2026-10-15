using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

public class EventInviteService : IEventInviteService
{
    /// <summary>صلاحية الدعوة حين لا يحدّدها المرسل.</summary>
    private static readonly TimeSpan DefaultLifetime = TimeSpan.FromHours(24);

    private readonly AppDbContext _db;
    private readonly INotificationService _notifications;

    public EventInviteService(AppDbContext db, INotificationService notifications)
    {
        _db = db;
        _notifications = notifications;
    }

    /// <summary>ما يلزم عن الحدث المدعو إليه، أياً كان نوعه.</summary>
    private sealed record Target(
        EventInviteKind Kind, int TargetId, Match Match, string Title, string Label);

    // ── Send ──────────────────────────────────────────────────────────────────

    public async Task<SendEventInviteResultDto> SendAsync(int senderId, SendEventInviteRequest req)
    {
        var kind = ParseKind(req.Kind);
        var target = await LoadTargetAsync(kind, req.TargetId);
        var m = target.Match;

        if (m.Status is MatchStatus.Cancelled or MatchStatus.Completed or MatchStatus.InProgress)
            throw new AuthException("Event is closed", $"{target.Label} غير متاح للدعوة", "EVENT_CLOSED");

        // يدعو المنظّم ولاعبو الحدث المعتمدون فقط — كان أي مستخدم يرسل دعوات
        // (وإشعارات) لأصدقائه إلى أي حدث. والخاصة يدعو إليها منظّمها وحده.
        var isOrganizer = m.CreatorId == senderId;
        if (!isOrganizer && !m.MatchPlayers.Any(
                p => p.UserId == senderId && p.Status == MatchPlayerStatus.Approved))
            throw new AuthException(
                "Only participants can invite", $"الدعوة لمنظّم {target.Label} ولاعبيه فقط",
                "NOT_A_PARTICIPANT");
        if (m.IsPrivate && !isOrganizer)
            throw new AuthException(
                "Only the organizer can invite to a private match",
                "المباراة خاصة — الدعوة للمنظّم وحده", "MATCH_PRIVATE");

        if (m.ScheduledAt <= AppClock.Now)
            throw new AuthException("Event already started", $"بدأ موعد {target.Label}", "EVENT_STARTED");
        if (m.MatchPlayers.Count(p => p.Status == MatchPlayerStatus.Approved) >= m.MaxPlayers)
            throw new AuthException("Event is full", $"{target.Label} مكتمل العدد", "EVENT_FULL");

        // الصلاحية لا تتجاوز موعد الحدث — دعوة لحدث بدأ لا معنى لها.
        var now = AppClock.Now;
        // صلاحية صفر أو سالبة تُنتج دعوة منتهية قبل إرسالها (الـ DTO يرفضها أيضاً).
        if (req.ExpiresInMinutes is <= 0)
            throw new AuthException(
                "Invalid invite expiry", "مدة صلاحية الدعوة غير صالحة", "INVALID_EXPIRY");
        var lifetime = req.ExpiresInMinutes is int mins ? TimeSpan.FromMinutes(mins) : DefaultLifetime;
        var expiresAt = now.Add(lifetime);
        if (req.ExpiresInMinutes is null || expiresAt > m.ScheduledAt) expiresAt = m.ScheduledAt;
        // وقت محلي ساذج كبقية مواعيد الـ API (AppClock.Now يحمل Kind=Utc فيُسلسَل بـ Z).
        expiresAt = DateTime.SpecifyKind(expiresAt, DateTimeKind.Unspecified);

        var ids = req.UserIds.Distinct().Where(id => id != senderId).ToList();
        var users = await _db.Users.Where(u => ids.Contains(u.Id))
            .Select(u => new { u.Id, Name = (u.FirstName + " " + u.LastName).Trim() })
            .ToDictionaryAsync(u => u.Id, u => u.Name);
        var friends = await _db.Friendships
            .Where(f => f.Status == FriendshipStatus.Accepted &&
                        ((f.SenderId == senderId && ids.Contains(f.ReceiverId)) ||
                         (f.ReceiverId == senderId && ids.Contains(f.SenderId))))
            .Select(f => f.SenderId == senderId ? f.ReceiverId : f.SenderId)
            .ToListAsync();
        var alreadyInvited = await _db.EventInvites
            .Where(i => i.Kind == kind && i.TargetId == target.TargetId
                        && ids.Contains(i.ReceiverId)
                        && i.Status == EventInviteStatus.Pending && i.ExpiresAt > now)
            .Select(i => i.ReceiverId)
            .ToListAsync();

        var result = new SendEventInviteResultDto { ExpiresAt = expiresAt };
        var toNotify = new List<(int UserId, EventInvite Invite)>();
        foreach (var id in ids)
        {
            var name = users.GetValueOrDefault(id, "");
            string? skip = !users.ContainsKey(id) ? "المستخدم غير موجود"
                : !friends.Contains(id) ? "ليس من أصدقائك"
                : m.MatchPlayers.Any(p => p.UserId == id) ? "مشارك بالفعل"
                : alreadyInvited.Contains(id) ? "مدعو بالفعل ودعوته سارية"
                : null;
            if (skip != null)
            {
                result.Skipped.Add(new SkippedInviteDto { UserId = id, Name = name, ReasonAr = skip });
                continue;
            }

            var invite = new EventInvite
            {
                SenderId = senderId,
                ReceiverId = id,
                Kind = kind,
                TargetId = target.TargetId,
                ExpiresAt = expiresAt,
            };
            _db.EventInvites.Add(invite);
            toNotify.Add((id, invite));
        }
        await _db.SaveChangesAsync();
        result.Sent = toNotify.Count;

        var senderName = await _db.Users.Where(u => u.Id == senderId)
            .Select(u => (u.FirstName + " " + u.LastName).Trim()).FirstOrDefaultAsync() ?? "صديقك";
        var (type, reference) = NotificationRoute(kind, target);
        foreach (var (userId, _) in toNotify)
            await _notifications.PushAsync(userId,
                $"دعوة إلى {target.Label}",
                $"دعاك {senderName} إلى {target.Title} — الدعوة سارية حتى {ExpiryText(expiresAt)}",
                type, reference);

        return result;
    }

    // ── Reads ─────────────────────────────────────────────────────────────────

    public async Task<EventInviteDto?> GetMineForTargetAsync(int userId, string kind, int targetId)
    {
        var k = ParseKind(kind);
        var invite = await _db.EventInvites
            .Include(i => i.Sender).Include(i => i.Receiver)
            .Where(i => i.ReceiverId == userId && i.Kind == k && i.TargetId == targetId)
            .OrderByDescending(i => i.Status == EventInviteStatus.Pending && i.ExpiresAt > AppClock.Now)
            .ThenByDescending(i => i.CreatedAt)
            .FirstOrDefaultAsync();
        if (invite == null) return null;
        var target = await TryLoadTargetAsync(invite.Kind, invite.TargetId);
        return ToDto(invite, target);
    }

    public async Task<List<EventInviteDto>> GetReceivedAsync(int userId)
    {
        var now = AppClock.Now;
        var invites = await _db.EventInvites
            .Include(i => i.Sender).Include(i => i.Receiver)
            .Where(i => i.ReceiverId == userId && i.Status == EventInviteStatus.Pending && i.ExpiresAt > now)
            .OrderBy(i => i.ExpiresAt)
            .Take(50)
            .ToListAsync();
        var list = new List<EventInviteDto>();
        foreach (var i in invites)
            list.Add(ToDto(i, await TryLoadTargetAsync(i.Kind, i.TargetId)));
        return list;
    }

    // ── Respond ───────────────────────────────────────────────────────────────

    public async Task<EventInviteDto> DeclineAsync(int userId, int inviteId)
    {
        var invite = await _db.EventInvites
            .Include(i => i.Sender).Include(i => i.Receiver)
            .FirstOrDefaultAsync(i => i.Id == inviteId && i.ReceiverId == userId)
            ?? throw new AuthException("Invite not found", "الدعوة غير موجودة", "INVITE_NOT_FOUND");
        if (invite.Status != EventInviteStatus.Pending || invite.ExpiresAt <= AppClock.Now)
            throw new AuthException("Invite is no longer active", "الدعوة لم تعد سارية", "INVITE_CLOSED");

        invite.Status = EventInviteStatus.Declined;
        invite.RespondedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        var target = await TryLoadTargetAsync(invite.Kind, invite.TargetId);
        var (type, reference) = target != null
            ? NotificationRoute(invite.Kind, target)
            : ("event_invite_declined", invite.TargetId);
        await _notifications.PushAsync(invite.SenderId, "اعتذار عن دعوة",
            $"اعتذر {FullName(invite.Receiver)} عن دعوتك إلى {target?.Title ?? "الحدث"}",
            type, reference);
        return ToDto(invite, target);
    }

    public async Task MarkJoinedAsync(int userId, EventInviteKind kind, int targetId)
    {
        var invites = await _db.EventInvites
            .Include(i => i.Receiver)
            .Where(i => i.ReceiverId == userId && i.Kind == kind && i.TargetId == targetId
                        && i.Status == EventInviteStatus.Pending)
            .ToListAsync();
        if (invites.Count == 0) return;

        foreach (var i in invites)
        {
            i.Status = EventInviteStatus.Accepted;
            i.RespondedAt = DateTime.UtcNow;
        }
        await _db.SaveChangesAsync();

        var target = await TryLoadTargetAsync(kind, targetId);
        if (target == null) return;
        var (type, reference) = NotificationRoute(kind, target);
        foreach (var senderId in invites.Select(i => i.SenderId).Distinct())
            await _notifications.PushAsync(senderId, "قُبلت دعوتك",
                $"انضم {FullName(invites[0].Receiver)} إلى {target.Title} بدعوتك",
                type, reference);
    }

    public async Task<bool> HasActiveInviteFromAsync(
        int senderId, int userId, EventInviteKind kind, int targetId)
    {
        var now = AppClock.Now;
        return await _db.EventInvites.AnyAsync(i =>
            i.SenderId == senderId && i.ReceiverId == userId && i.Kind == kind
            && i.TargetId == targetId && i.Status == EventInviteStatus.Pending
            && i.ExpiresAt > now);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static EventInviteKind ParseKind(string? kind) => kind?.Trim().ToLowerInvariant() switch
    {
        "match" => EventInviteKind.Match,
        "americano" => EventInviteKind.Americano,
        "tournament" => EventInviteKind.Tournament,
        _ => throw new AuthException("Unknown invite kind", "نوع الدعوة غير معروف", "INVITE_BAD_KIND"),
    };

    private async Task<Target> LoadTargetAsync(EventInviteKind kind, int targetId) =>
        await TryLoadTargetAsync(kind, targetId)
        ?? throw new AuthException("Event not found", "الحدث غير موجود", "EVENT_NOT_FOUND");

    private async Task<Target?> TryLoadTargetAsync(EventInviteKind kind, int targetId)
    {
        if (kind == EventInviteKind.Match)
        {
            var match = await _db.Matches
                .Include(m => m.MatchPlayers)
                .Include(m => m.Court).ThenInclude(c => c!.Venue)
                .Include(m => m.AmericanoMatch)
                .FirstOrDefaultAsync(m => m.Id == targetId);
            // مباراة أمريكانو/بطولة تُدعى إليها بنوعها لا كمباراة عادية.
            if (match == null || match.AmericanoMatch != null) return null;
            var where = match.Court?.Venue.Name;
            return new Target(kind, match.Id, match,
                where != null ? $"مباراة في {where}" : "مباراة", "المباراة");
        }

        var a = await _db.AmericanoMatches
            .Include(x => x.Match).ThenInclude(m => m.MatchPlayers)
            .Include(x => x.Match).ThenInclude(m => m.Court).ThenInclude(c => c!.Venue)
            .FirstOrDefaultAsync(x => x.Id == targetId);
        if (a == null) return null;
        var isTournament = a.IsTournament || a.Format != null;
        if (kind == EventInviteKind.Tournament && !isTournament) return null;
        if (kind == EventInviteKind.Americano && isTournament) return null;

        var venue = a.Match.Court?.Venue.Name;
        var title = isTournament
            ? $"بطولة «{(string.IsNullOrWhiteSpace(a.Name) ? venue ?? "" : a.Name)}»"
            : venue != null ? $"أمريكانو في {venue}" : "أمريكانو";
        return new Target(kind, a.Id, a.Match, title, isTournament ? "البطولة" : "الأمريكانو");
    }

    /// <summary>نوع الإشعار ومرجعه بحيث يفتح التطبيق الحدث نفسه عند الضغط:
    /// «match_» يفتح تفاصيل المباراة، و«americano_»/«tournament_» صفحة الأمريكانو/البطولة.</summary>
    private static (string Type, int Reference) NotificationRoute(EventInviteKind kind, Target t) =>
        kind switch
        {
            EventInviteKind.Match => ("match_event_invite", t.Match.Id),
            EventInviteKind.Tournament => ("tournament_event_invite", t.TargetId),
            _ => ("americano_event_invite", t.TargetId),
        };

    private static string ExpiryText(DateTime at)
    {
        var today = AppClock.Now.Date;
        var hour = at.ToString("h:mm") + (at.Hour < 12 ? " ص" : " م");
        return at.Date == today ? $"اليوم {hour}"
            : at.Date == today.AddDays(1) ? $"غداً {hour}"
            : $"{at:yyyy-MM-dd} {hour}";
    }

    private static string FullName(User u) => $"{u.FirstName} {u.LastName}".Trim();

    private static EventInviteDto ToDto(EventInvite i, Target? t) => new()
    {
        Id = i.Id,
        Kind = i.Kind switch
        {
            EventInviteKind.Match => "match",
            EventInviteKind.Tournament => "tournament",
            _ => "americano",
        },
        TargetId = i.TargetId,
        SenderId = i.SenderId,
        SenderName = FullName(i.Sender),
        ReceiverId = i.ReceiverId,
        ReceiverName = FullName(i.Receiver),
        TargetTitle = t?.Title ?? "",
        TargetStartsAt = t?.Match.ScheduledAt,
        ExpiresAt = i.ExpiresAt,
        CreatedAt = i.CreatedAt,
        Status = i.Status switch
        {
            EventInviteStatus.Accepted => "accepted",
            EventInviteStatus.Declined => "declined",
            _ => i.ExpiresAt <= AppClock.Now ? "expired" : "pending",
        },
    };
}
