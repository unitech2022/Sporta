using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IFeedService
{
    /// <summary>Recent activity of the players the current user follows.</summary>
    Task<List<FeedItemDto>> GetFeedAsync(int currentUserId);
}
