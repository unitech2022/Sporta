using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IAmericanoService
{
    /// <summary>Creates an americano: singles (1-4 players, 3 rotation rounds) or
    /// teams (2-12 fixed teams of 2, a full round robin). Rounds are generated
    /// once the roster is full.</summary>
    Task<AmericanoDto> CreateAsync(int creatorId, CreateAmericanoRequest req);

    /// <summary>
    /// Adds the user to an open americano; generates rounds once full. For a
    /// teams americano <paramref name="req"/> carries the chosen team and an
    /// optional partner invite; for singles it is ignored.
    /// </summary>
    Task<AmericanoDto> JoinAsync(int userId, int americanoId, JoinAmericanoRequest? req);

    /// <summary>A captain invites a friend to their team in a teams americano.</summary>
    Task<AmericanoDto> InvitePartnerAsync(int inviterId, int americanoId, int targetId);

    /// <summary>The invited partner accepts or declines their team invitation.</summary>
    Task<AmericanoDto> RespondToPartnerInviteAsync(int userId, int americanoId, bool accept);

    /// <summary>Lists americano events (paged, newest first). <paramref name="kind"/>
    /// filters to "americano" or "tournament"; null returns both.</summary>
    Task<PagedResult<AmericanoDto>> GetAllAsync(
        int page = 1, int pageSize = 20, string? kind = null, int viewerId = 0);

    /// <summary>Events the user created or takes part in (newest first); kind as in
    /// <see cref="GetAllAsync"/>, <paramref name="activeOnly"/> drops completed/cancelled.</summary>
    Task<PagedResult<AmericanoDto>> GetMineAsync(
        int userId, int page = 1, int pageSize = 20, string? kind = null, bool activeOnly = false,
        bool finishedOnly = false);

    /// <summary>Returns a single americano with rounds + standings.</summary>
    Task<AmericanoDto> GetByIdAsync(int id);

    /// <summary>Records a round's score (creator only); completes the americano when all rounds are done.</summary>
    Task<AmericanoDto> SubmitRoundScoreAsync(int roundId, SubmitRoundScoreRequest req, int userId);
    Task<AmericanoDto> RespondRoundScoreAsync(int roundId, RespondResultRequest req, int userId);
    Task<AmericanoDto> ResolveRoundScoreAsync(int roundId, ResolveResultRequest req, int userId);
    Task<AmericanoDto> RespondToJoinRequestAsync(int creatorId, int americanoId, int targetUserId, bool approve);
}
