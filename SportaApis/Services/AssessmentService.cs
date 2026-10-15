using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Models;

namespace SportaApis.Services;

public class AssessmentService : IAssessmentService
{
    private readonly AppDbContext _db;

    public AssessmentService(AppDbContext db) => _db = db;

    // ── Player-facing ────────────────────────────────────────────────────────

    public async Task<List<AssessmentQuestionDto>> GetQuestionsAsync(string sport)
    {
        var questions = await _db.AssessmentQuestions
            .Include(q => q.Options)
            .Where(q => q.Sport == sport && q.IsActive)
            .OrderBy(q => q.SortOrder).ThenBy(q => q.Id)
            .ToListAsync();
        return questions.Select(ToQuestionDto).ToList();
    }

    public async Task<List<AssessmentLevelDto>> GetLevelsAsync(string sport)
    {
        var levels = await _db.AssessmentLevels
            .Where(l => l.Sport == sport && l.IsActive)
            .OrderBy(l => l.SortOrder).ThenBy(l => l.MinScore)
            .ToListAsync();
        return levels.Select(ToLevelDto).ToList();
    }

    public async Task<AssessmentLevel?> ResolveLevelAsync(string sport, int totalScore)
    {
        var levels = await _db.AssessmentLevels
            .Where(l => l.Sport == sport && l.IsActive)
            .OrderBy(l => l.MinScore)
            .ToListAsync();
        if (levels.Count == 0) return null;

        // Highest level whose threshold is reached; fall back to the lowest.
        return levels.LastOrDefault(l => totalScore >= l.MinScore) ?? levels.First();
    }

    // ── Admin: levels ────────────────────────────────────────────────────────

    public async Task<List<AssessmentLevelDto>> AdminGetLevelsAsync(string? sport)
    {
        var query = _db.AssessmentLevels.AsQueryable();
        if (!string.IsNullOrWhiteSpace(sport))
            query = query.Where(l => l.Sport == sport);
        var levels = await query
            .OrderBy(l => l.Sport).ThenBy(l => l.SortOrder).ThenBy(l => l.MinScore)
            .ToListAsync();
        return levels.Select(ToLevelDto).ToList();
    }

    public async Task<AssessmentLevelDto> CreateLevelAsync(SaveAssessmentLevelRequest req)
    {
        var level = new AssessmentLevel();
        ApplyLevel(level, req);
        _db.AssessmentLevels.Add(level);
        await _db.SaveChangesAsync();
        return ToLevelDto(level);
    }

    public async Task<AssessmentLevelDto> UpdateLevelAsync(int id, SaveAssessmentLevelRequest req)
    {
        var level = await _db.AssessmentLevels.FirstOrDefaultAsync(l => l.Id == id)
            ?? throw new AuthException("Level not found", "المستوى غير موجود", "LEVEL_NOT_FOUND");
        ApplyLevel(level, req);
        level.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return ToLevelDto(level);
    }

    public async Task DeleteLevelAsync(int id)
    {
        var level = await _db.AssessmentLevels.FirstOrDefaultAsync(l => l.Id == id)
            ?? throw new AuthException("Level not found", "المستوى غير موجود", "LEVEL_NOT_FOUND");
        _db.AssessmentLevels.Remove(level);
        await _db.SaveChangesAsync();
    }

    // ── Admin: questions ───────────────────────────────────────────────────────

    public async Task<List<AssessmentQuestionDto>> AdminGetQuestionsAsync(string? sport)
    {
        var query = _db.AssessmentQuestions.Include(q => q.Options).AsQueryable();
        if (!string.IsNullOrWhiteSpace(sport))
            query = query.Where(q => q.Sport == sport);
        var questions = await query
            .OrderBy(q => q.Sport).ThenBy(q => q.SortOrder).ThenBy(q => q.Id)
            .ToListAsync();
        return questions.Select(ToQuestionDto).ToList();
    }

    public async Task<AssessmentQuestionDto> CreateQuestionAsync(SaveAssessmentQuestionRequest req)
    {
        var question = new AssessmentQuestion
        {
            Sport = req.Sport.Trim(),
            TextAr = req.TextAr.Trim(),
            TextEn = req.TextEn.Trim(),
            SortOrder = req.SortOrder,
            IsActive = req.IsActive,
            Options = BuildOptions(req.Options),
        };
        _db.AssessmentQuestions.Add(question);
        await _db.SaveChangesAsync();
        return ToQuestionDto(question);
    }

    public async Task<AssessmentQuestionDto> UpdateQuestionAsync(
        int id, SaveAssessmentQuestionRequest req)
    {
        var question = await _db.AssessmentQuestions
            .Include(q => q.Options)
            .FirstOrDefaultAsync(q => q.Id == id)
            ?? throw new AuthException(
                "Question not found", "السؤال غير موجود", "QUESTION_NOT_FOUND");

        question.Sport = req.Sport.Trim();
        question.TextAr = req.TextAr.Trim();
        question.TextEn = req.TextEn.Trim();
        question.SortOrder = req.SortOrder;
        question.IsActive = req.IsActive;
        question.UpdatedAt = DateTime.UtcNow;

        // Replace options wholesale (simplest editing model for the dashboard).
        _db.AssessmentOptions.RemoveRange(question.Options);
        question.Options = BuildOptions(req.Options);

        await _db.SaveChangesAsync();
        return ToQuestionDto(question);
    }

    public async Task DeleteQuestionAsync(int id)
    {
        var question = await _db.AssessmentQuestions
            .Include(q => q.Options)
            .FirstOrDefaultAsync(q => q.Id == id)
            ?? throw new AuthException(
                "Question not found", "السؤال غير موجود", "QUESTION_NOT_FOUND");
        _db.AssessmentOptions.RemoveRange(question.Options);
        _db.AssessmentQuestions.Remove(question);
        await _db.SaveChangesAsync();
    }

    // ── helpers ────────────────────────────────────────────────────────────────

    private static List<AssessmentOption> BuildOptions(List<AssessmentOptionInput> inputs) =>
        inputs.Select((o, i) => new AssessmentOption
        {
            TextAr = o.TextAr.Trim(),
            TextEn = o.TextEn.Trim(),
            Score = o.Score,
            SortOrder = o.SortOrder == 0 ? i : o.SortOrder,
        }).ToList();

    private static void ApplyLevel(AssessmentLevel level, SaveAssessmentLevelRequest req)
    {
        level.Sport = req.Sport.Trim();
        level.NameAr = req.NameAr.Trim();
        level.NameEn = req.NameEn.Trim();
        level.DescriptionAr = req.DescriptionAr?.Trim();
        level.DescriptionEn = req.DescriptionEn?.Trim();
        level.MinScore = req.MinScore;
        level.SortOrder = req.SortOrder;
        level.IsActive = req.IsActive;
    }

    private static AssessmentLevelDto ToLevelDto(AssessmentLevel l) => new()
    {
        Id = l.Id,
        Sport = l.Sport,
        NameAr = l.NameAr,
        NameEn = l.NameEn,
        DescriptionAr = l.DescriptionAr,
        DescriptionEn = l.DescriptionEn,
        MinScore = l.MinScore,
        SortOrder = l.SortOrder,
        IsActive = l.IsActive,
    };

    private static AssessmentQuestionDto ToQuestionDto(AssessmentQuestion q) => new()
    {
        Id = q.Id,
        Sport = q.Sport,
        TextAr = q.TextAr,
        TextEn = q.TextEn,
        SortOrder = q.SortOrder,
        IsActive = q.IsActive,
        Options = q.Options
            .OrderBy(o => o.SortOrder).ThenBy(o => o.Id)
            .Select(o => new AssessmentOptionDto
            {
                Id = o.Id,
                TextAr = o.TextAr,
                TextEn = o.TextEn,
                Score = o.Score,
            }).ToList(),
    };
}
