using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

public class FriendService : IFriendService
{
    private readonly AppDbContext _db;
    private readonly INotificationService _notifications;
    private readonly ISettingsService _settings;

    public FriendService(
        AppDbContext db, INotificationService notifications, ISettingsService settings)
    {
        _db = db;
        _notifications = notifications;
        _settings = settings;
    }

    private async Task<string> NameAsync(int userId) => await _db.Users
        .Where(u => u.Id == userId)
        .Select(u => (u.FirstName + " " + u.LastName).Trim())
        .FirstOrDefaultAsync() ?? "لاعب";

    /// <summary>
    /// قائمة اللاعبين: بحثاً بالاسم/الجوال، أو كاملةً حين لا نص بحث. الترتيب
    /// **بالأقرب** حين يكون للمستخدم موقع محفوظ — القرب هو ما يهمّ من يبحث عن
    /// شريك لعب — ويسقط إلى الترتيب الأبجدي لمن لا موقع له.
    /// </summary>
    public async Task<List<PlayerSummaryDto>> SearchPlayersAsync(int currentUserId, string? query)
    {
        var q = _db.Users
            .Include(u => u.PlayerProfile)
            .Include(u => u.CityRef)
            // اللاعبون والمدربون فقط — حسابات الإدارة وأصحاب الملاعب ليست
            // ملفات لاعبين تُضاف صداقتها.
            .Where(u => u.Id != currentUserId && u.IsActive &&
                        (u.UserType == UserType.Player || u.UserType == UserType.Coach))
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(query))
        {
            var term = query.Trim();
            // بالجوال: الرقم كاملاً فقط — مطابقة أي جزء كانت تكشف أصحاب
            // الأرقام المسجّلة لأي باحث.
            var phone = PhoneNumber.TryNormalize(term);
            q = phone is null
                ? q.Where(u => (u.FirstName + " " + u.LastName).Contains(term))
                : q.Where(u => (u.FirstName + " " + u.LastName).Contains(term) ||
                               u.PhoneNumber == phone);
        }

        // المسافة تُحسب صفاً صفاً في الذاكرة، فتُجلب دفعة أوسع ثم تُرتَّب وتُقصّ.
        var candidates = await q.OrderBy(u => u.FirstName).Take(200).ToListAsync();

        var me = await _db.Users
            .Where(u => u.Id == currentUserId)
            .Select(u => new { u.Latitude, u.Longitude })
            .FirstOrDefaultAsync();

        var users = me?.Latitude != null && me?.Longitude != null
            ? candidates
                .OrderBy(u => u.Latitude != null && u.Longitude != null
                    ? GeoHelper.DistanceKm(
                        me.Latitude.Value, me.Longitude.Value,
                        u.Latitude.Value, u.Longitude.Value)
                    // بلا إحداثيات: في آخر القائمة لا خارجها.
                    : double.MaxValue)
                .Take(50)
                .ToList()
            : candidates.Take(50).ToList();

        var ids = users.Select(u => u.Id).ToList();

        var relations = await LoadRelationsAsync(currentUserId, ids);
        var following = await _db.Follows
            .Where(f => f.FollowerId == currentUserId && ids.Contains(f.FollowingId))
            .Select(f => f.FollowingId)
            .ToListAsync();

        return users.Select(u => new PlayerSummaryDto
        {
            UserId = u.Id,
            Name = $"{u.FirstName} {u.LastName}".Trim(),
            AvatarUrl = u.ProfileImageUrl,
            Level = u.PlayerProfile != null ? (int)u.PlayerProfile.Level : null,
            City = u.City,
            CityEn = u.CityRef?.NameEn,
            UserType = u.UserType == UserType.Coach ? "coach" : "player",
            Relation = relations.GetValueOrDefault(u.Id, "none"),
            IsFollowing = following.Contains(u.Id),
        }).ToList();
    }

    public async Task<List<PlayerSummaryDto>> GetSuggestionsAsync(int currentUserId)
    {
        // Players already connected to (friends or pending) or already followed.
        var relatedIds = await _db.Friendships
            .Where(f => f.SenderId == currentUserId || f.ReceiverId == currentUserId)
            .Select(f => f.SenderId == currentUserId ? f.ReceiverId : f.SenderId)
            .ToListAsync();
        var followedIds = await _db.Follows
            .Where(f => f.FollowerId == currentUserId)
            .Select(f => f.FollowingId)
            .ToListAsync();
        var excluded = relatedIds.Concat(followedIds).Append(currentUserId).ToHashSet();

        var me = await _db.Users
            .Where(u => u.Id == currentUserId)
            .Select(u => new { u.City, u.Latitude, u.Longitude })
            .FirstOrDefaultAsync();

        // Candidates are players and coaches only, excluding existing connections.
        var candidates = await _db.Users
            .Include(u => u.PlayerProfile)
            .Include(u => u.CityRef)
            .Where(u => u.IsActive &&
                        (u.UserType == UserType.Player || u.UserType == UserType.Coach) &&
                        !excluded.Contains(u.Id))
            .ToListAsync();

        // Nearby only: within the configured radius when both sides have
        // coordinates, otherwise fall back to same-city. Users with no saved
        // location at all see the unfiltered list (no proximity to compare).
        var nearby = candidates;
        if (me?.Latitude != null && me?.Longitude != null)
        {
            var maxKm = await _settings.GetNearbyDistanceKmAsync();
            nearby = candidates
                .Where(u => u.Latitude != null && u.Longitude != null
                    ? GeoHelper.DistanceKm(
                        me.Latitude.Value, me.Longitude.Value,
                        u.Latitude.Value, u.Longitude.Value) <= maxKm
                    : me.City != null && u.City == me.City)
                .OrderBy(u => u.Latitude != null && u.Longitude != null
                    ? GeoHelper.DistanceKm(
                        me.Latitude.Value, me.Longitude.Value,
                        u.Latitude.Value, u.Longitude.Value)
                    : double.MaxValue)
                .ToList();
        }
        else if (me?.City != null)
        {
            nearby = candidates.Where(u => u.City == me.City).ToList();
        }

        return nearby
            .Take(6)
            .Select(u => new PlayerSummaryDto
            {
                UserId = u.Id,
                Name = $"{u.FirstName} {u.LastName}".Trim(),
                AvatarUrl = u.ProfileImageUrl,
                Level = u.PlayerProfile != null ? (int)u.PlayerProfile.Level : null,
                City = u.City,
                CityEn = u.CityRef?.NameEn,
                UserType = u.UserType == UserType.Coach ? "coach" : "player",
                Relation = "none",
                IsFollowing = false,
            }).ToList();
    }

    public async Task<List<PlayerSummaryDto>> GetFriendsAsync(int currentUserId)
    {
        var friendships = await _db.Friendships
            .Include(f => f.Sender).ThenInclude(u => u.PlayerProfile)
            .Include(f => f.Sender).ThenInclude(u => u.CityRef)
            .Include(f => f.Receiver).ThenInclude(u => u.PlayerProfile)
            .Include(f => f.Receiver).ThenInclude(u => u.CityRef)
            .Where(f => f.Status == FriendshipStatus.Accepted &&
                        (f.SenderId == currentUserId || f.ReceiverId == currentUserId))
            .ToListAsync();

        return friendships.Select(f =>
        {
            var other = f.SenderId == currentUserId ? f.Receiver : f.Sender;
            var isFavorite = f.SenderId == currentUserId ? f.SenderFavorite : f.ReceiverFavorite;
            return new PlayerSummaryDto
            {
                UserId = other.Id,
                Name = $"{other.FirstName} {other.LastName}".Trim(),
                AvatarUrl = other.ProfileImageUrl,
                Level = other.PlayerProfile != null ? (int)other.PlayerProfile.Level : null,
                City = other.City,
                CityEn = other.CityRef?.NameEn,
                UserType = other.UserType == UserType.Coach ? "coach" : "player",
                Relation = "friends",
                IsFavorite = isFavorite,
            };
        }).ToList();
    }

    public async Task ToggleFavoriteAsync(int currentUserId, int friendUserId, bool favorite)
    {
        var friendship = await _db.Friendships.FirstOrDefaultAsync(f =>
            f.Status == FriendshipStatus.Accepted &&
            ((f.SenderId == currentUserId && f.ReceiverId == friendUserId) ||
             (f.SenderId == friendUserId && f.ReceiverId == currentUserId)))
            ?? throw new AuthException(
                "Not friends with this player", "لستما صديقين", "NOT_FRIENDS");

        if (friendship.SenderId == currentUserId)
            friendship.SenderFavorite = favorite;
        else
            friendship.ReceiverFavorite = favorite;

        await _db.SaveChangesAsync();
    }

    public async Task<List<FriendRequestDto>> GetIncomingRequestsAsync(int currentUserId)
    {
        var requests = await _db.Friendships
            .Include(f => f.Sender).ThenInclude(u => u.PlayerProfile)
            .Include(f => f.Sender).ThenInclude(u => u.CityRef)
            .Where(f => f.ReceiverId == currentUserId && f.Status == FriendshipStatus.Pending)
            .OrderByDescending(f => f.CreatedAt)
            .ToListAsync();

        return requests.Select(f => new FriendRequestDto
        {
            Id = f.Id,
            FromUserId = f.SenderId,
            FromName = $"{f.Sender.FirstName} {f.Sender.LastName}".Trim(),
            AvatarUrl = f.Sender.ProfileImageUrl,
            Level = f.Sender.PlayerProfile != null ? (int)f.Sender.PlayerProfile.Level : null,
            City = f.Sender.City,
            CityEn = f.Sender.CityRef?.NameEn,
        }).ToList();
    }

    public async Task SendRequestAsync(int currentUserId, int targetId)
    {
        if (targetId == currentUserId)
            throw new AuthException(
                "Cannot add yourself", "لا يمكنك إضافة نفسك", "FRIEND_SELF");

        if (!await _db.Users.AnyAsync(u => u.Id == targetId))
            throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        var existing = await _db.Friendships.FirstOrDefaultAsync(f =>
            (f.SenderId == currentUserId && f.ReceiverId == targetId) ||
            (f.SenderId == targetId && f.ReceiverId == currentUserId));

        if (existing != null)
        {
            if (existing.Status == FriendshipStatus.Accepted)
                throw new AuthException(
                    "Already friends", "أنتما صديقان بالفعل", "ALREADY_FRIENDS");
            throw new AuthException(
                "A request already exists", "يوجد طلب صداقة بالفعل", "REQUEST_EXISTS");
        }

        _db.Friendships.Add(new Friendship
        {
            SenderId = currentUserId,
            ReceiverId = targetId,
            Status = FriendshipStatus.Pending,
        });
        await _db.SaveChangesAsync();

        await _notifications.PushAsync(targetId, "طلب صداقة جديد",
            $"أرسل لك {await NameAsync(currentUserId)} طلب صداقة",
            "friend_request", currentUserId);
    }

    public async Task RespondAsync(int currentUserId, int requestId, bool accept)
    {
        var request = await _db.Friendships.FirstOrDefaultAsync(f => f.Id == requestId)
            ?? throw new AuthException(
                "Request not found", "الطلب غير موجود", "REQUEST_NOT_FOUND");

        if (request.ReceiverId != currentUserId)
            throw new AuthException(
                "Not allowed", "غير مسموح", "NOT_REQUEST_RECEIVER");

        if (accept)
        {
            request.Status = FriendshipStatus.Accepted;
            request.RespondedAt = DateTime.UtcNow;
        }
        else
        {
            _db.Friendships.Remove(request);
        }
        await _db.SaveChangesAsync();

        if (accept)
        {
            await _notifications.PushAsync(request.SenderId, "تم قبول طلب الصداقة",
                $"قبل {await NameAsync(currentUserId)} طلب صداقتك",
                "friend_accepted", currentUserId);
        }
    }

    // ── helpers ────────────────────────────────────────────────────────────────

    private async Task<Dictionary<int, string>> LoadRelationsAsync(
        int currentUserId, List<int> otherIds)
    {
        var friendships = await _db.Friendships
            .Where(f =>
                (f.SenderId == currentUserId && otherIds.Contains(f.ReceiverId)) ||
                (f.ReceiverId == currentUserId && otherIds.Contains(f.SenderId)))
            .ToListAsync();

        var map = new Dictionary<int, string>();
        foreach (var f in friendships)
        {
            var other = f.SenderId == currentUserId ? f.ReceiverId : f.SenderId;
            map[other] = f.Status switch
            {
                FriendshipStatus.Accepted => "friends",
                FriendshipStatus.Pending => f.SenderId == currentUserId
                    ? "pending_sent"
                    : "pending_received",
                _ => "none",
            };
        }
        return map;
    }
}
