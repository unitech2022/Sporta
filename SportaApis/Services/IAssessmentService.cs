using SportaApis.DTOs;
using SportaApis.Models;

namespace SportaApis.Services;

public interface IAssessmentService
{
    // ── Player-facing ────────────────────────────────────────────────────────
    /// <summary>Active assessment questions (+options) for a sport, ordered.</summary>
    Task<List<AssessmentQuestionDto>> GetQuestionsAsync(string sport);

    /// <summary>Active levels for a sport, ordered by rank.</summary>
    Task<List<AssessmentLevelDto>> GetLevelsAsync(string sport);

    /// <summary>
    /// Picks the level for a sport from a total score (highest level whose
    /// MinScore is reached). Returns null when the sport has no levels defined.
    /// </summary>
    Task<AssessmentLevel?> ResolveLevelAsync(string sport, int totalScore);

    // ── Admin: levels ────────────────────────────────────────────────────────
    Task<List<AssessmentLevelDto>> AdminGetLevelsAsync(string? sport);
    Task<AssessmentLevelDto> CreateLevelAsync(SaveAssessmentLevelRequest req);
    Task<AssessmentLevelDto> UpdateLevelAsync(int id, SaveAssessmentLevelRequest req);
    Task DeleteLevelAsync(int id);

    // ── Admin: questions ───────────────────────────────────────────────────────
    Task<List<AssessmentQuestionDto>> AdminGetQuestionsAsync(string? sport);
    Task<AssessmentQuestionDto> CreateQuestionAsync(SaveAssessmentQuestionRequest req);
    Task<AssessmentQuestionDto> UpdateQuestionAsync(int id, SaveAssessmentQuestionRequest req);
    Task DeleteQuestionAsync(int id);
}
