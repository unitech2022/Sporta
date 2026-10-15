using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IFriendService
{
    /// <summary>Searches players by name/phone (excludes self), with relation flags.</summary>
    Task<List<PlayerSummaryDto>> SearchPlayersAsync(int currentUserId, string? query);

    /// <summary>The current user's accepted friends.</summary>
    Task<List<PlayerSummaryDto>> GetFriendsAsync(int currentUserId);

    /// <summary>Suggested players to connect with (not self/friends/already-followed),
    /// preferring the same city. Capped to a small list.</summary>
    Task<List<PlayerSummaryDto>> GetSuggestionsAsync(int currentUserId);

    /// <summary>Pending friend requests received by the current user.</summary>
    Task<List<FriendRequestDto>> GetIncomingRequestsAsync(int currentUserId);

    /// <summary>Sends a friend request to [targetId].</summary>
    Task SendRequestAsync(int currentUserId, int targetId);

    /// <summary>Accepts/rejects an incoming request (receiver only).</summary>
    Task RespondAsync(int currentUserId, int requestId, bool accept);

    /// <summary>Marks/unmarks an accepted friend as a favorite partner (directional).</summary>
    Task ToggleFavoriteAsync(int currentUserId, int friendUserId, bool favorite);
}
