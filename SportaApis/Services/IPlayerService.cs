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

    /// <summary>Path 2: submits a video for level assessment (pending review).</summary>
    Task<LevelAssessmentDto> SubmitVideoAssessmentAsync(int userId, string videoUrl);

    /// <summary>Path 3: requests a level assessment from a certified coach.</summary>
    Task<LevelAssessmentDto> RequestCoachAssessmentAsync(int userId, int coachId);

    /// <summary>The player's level-assessment history.</summary>
    Task<List<LevelAssessmentDto>> GetMyAssessmentsAsync(int userId);
}
