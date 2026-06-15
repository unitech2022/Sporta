using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IPlayerService
{
    /// <summary>Stores the player's self-assessment and updates their level.</summary>
    Task<LevelAssessmentResultDto> SubmitLevelAssessmentAsync(
        int userId, LevelAssessmentRequest req);

    /// <summary>Returns the current player's profile (level + stats).</summary>
    Task<PlayerProfileDto> GetMyProfileAsync(int userId);

    /// <summary>Sets the user's favorite sport.</summary>
    Task SetFavoriteSportAsync(int userId, string sport);
}
