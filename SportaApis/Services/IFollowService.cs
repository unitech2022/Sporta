using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IFollowService
{
    /// <summary>Follows [targetId] (idempotent).</summary>
    Task FollowAsync(int currentUserId, int targetId);

    /// <summary>Unfollows [targetId] (idempotent).</summary>
    Task UnfollowAsync(int currentUserId, int targetId);

    /// <summary>Players the current user follows.</summary>
    Task<List<PlayerSummaryDto>> GetFollowingAsync(int currentUserId);

    /// <summary>Players who follow the current user.</summary>
    Task<List<PlayerSummaryDto>> GetFollowersAsync(int currentUserId);
}
