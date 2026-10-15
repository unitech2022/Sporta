using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Models;

namespace SportaApis.Services;

public class FollowService : IFollowService
{
    private readonly AppDbContext _db;
    private readonly INotificationService _notifications;

    public FollowService(AppDbContext db, INotificationService notifications)
    {
        _db = db;
        _notifications = notifications;
    }

    public async Task FollowAsync(int currentUserId, int targetId)
    {
        if (targetId == currentUserId)
            throw new AuthException(
                "Cannot follow yourself", "لا يمكنك متابعة نفسك", "FOLLOW_SELF");

        if (!await _db.Users.AnyAsync(u => u.Id == targetId))
            throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        var exists = await _db.Follows.AnyAsync(
            f => f.FollowerId == currentUserId && f.FollowingId == targetId);
        if (exists) return; // idempotent

        _db.Follows.Add(new Follow { FollowerId = currentUserId, FollowingId = targetId });
        await _db.SaveChangesAsync();

        var name = await _db.Users
            .Where(u => u.Id == currentUserId)
            .Select(u => (u.FirstName + " " + u.LastName).Trim())
            .FirstOrDefaultAsync() ?? "لاعب";
        await _notifications.PushAsync(targetId, "متابِع جديد",
            $"بدأ {name} بمتابعتك", "follow", currentUserId);
    }

    public async Task UnfollowAsync(int currentUserId, int targetId)
    {
        var follow = await _db.Follows.FirstOrDefaultAsync(
            f => f.FollowerId == currentUserId && f.FollowingId == targetId);
        if (follow == null) return; // idempotent

        _db.Follows.Remove(follow);
        await _db.SaveChangesAsync();
    }

    public async Task<List<PlayerSummaryDto>> GetFollowingAsync(int currentUserId)
    {
        var users = await _db.Follows
            .Where(f => f.FollowerId == currentUserId)
            .Include(f => f.Following).ThenInclude(u => u.PlayerProfile)
            .Include(f => f.Following).ThenInclude(u => u.CityRef)
            .Select(f => f.Following)
            .ToListAsync();

        return users.Select(u => ToDto(u, isFollowing: true)).ToList();
    }

    public async Task<List<PlayerSummaryDto>> GetFollowersAsync(int currentUserId)
    {
        var users = await _db.Follows
            .Where(f => f.FollowingId == currentUserId)
            .Include(f => f.Follower).ThenInclude(u => u.PlayerProfile)
            .Include(f => f.Follower).ThenInclude(u => u.CityRef)
            .Select(f => f.Follower)
            .ToListAsync();

        // Mark which of my followers I follow back.
        var followingBack = await _db.Follows
            .Where(f => f.FollowerId == currentUserId)
            .Select(f => f.FollowingId)
            .ToListAsync();

        return users
            .Select(u => ToDto(u, isFollowing: followingBack.Contains(u.Id)))
            .ToList();
    }

    private static PlayerSummaryDto ToDto(User u, bool isFollowing) => new()
    {
        UserId = u.Id,
        Name = $"{u.FirstName} {u.LastName}".Trim(),
        AvatarUrl = u.ProfileImageUrl,
        Level = u.PlayerProfile != null ? (int)u.PlayerProfile.Level : null,
        City = u.City,
        CityEn = u.CityRef?.NameEn,
        IsFollowing = isFollowing,
    };
}
