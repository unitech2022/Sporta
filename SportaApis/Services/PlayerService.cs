using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

public class PlayerService : IPlayerService
{
    private readonly AppDbContext _db;
    private readonly IAssessmentService _assessment;

    public PlayerService(AppDbContext db, IAssessmentService assessment)
    {
        _db = db;
        _assessment = assessment;
    }

    public async Task<LevelAssessmentResultDto> SubmitLevelAssessmentAsync(
        int userId, LevelAssessmentRequest req)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        // Ensure the player has a profile (created at registration, but be safe).
        var profile = await _db.PlayerProfiles
            .FirstOrDefaultAsync(p => p.UserId == userId);
        if (profile == null)
        {
            profile = new PlayerProfile { UserId = userId };
            _db.PlayerProfiles.Add(profile);
            await _db.SaveChangesAsync();
        }

        // Total score from the chosen option scores.
        var totalScore = req.Answers.Sum();

        // Prefer the admin-defined levels for this sport; fall back to the
        // legacy 1..7 ratio mapping when the sport has no levels configured yet.
        var adminLevel = await _assessment.ResolveLevelAsync(req.Sport, totalScore);

        PlayerLevel level;
        int resultLevel;
        string nameAr, nameEn;

        if (adminLevel != null)
        {
            level = (PlayerLevel)Math.Clamp(adminLevel.SortOrder, 1, 7);
            resultLevel = adminLevel.SortOrder;
            nameAr = adminLevel.NameAr;
            nameEn = adminLevel.NameEn;
            profile.AssessmentLevelId = adminLevel.Id;
        }
        else
        {
            level = PlayerLevelInfo.FromAnswers(req.Answers);
            resultLevel = (int)level;
            nameAr = PlayerLevelInfo.NameAr(level);
            nameEn = PlayerLevelInfo.NameEn(level);
            profile.AssessmentLevelId = null;
        }

        _db.LevelAssessments.Add(new LevelAssessment
        {
            PlayerProfileId = profile.Id,
            Type = LevelAssessmentType.SelfAssessment,
            AssignedLevel = level,
            IsCompleted = true,
            Notes = $"sport={req.Sport}; score={totalScore}; answers=[{string.Join(",", req.Answers)}]",
        });

        profile.Level = level;
        profile.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return new LevelAssessmentResultDto
        {
            Level = resultLevel,
            LevelNameAr = nameAr,
            LevelNameEn = nameEn,
        };
    }

    public async Task<LevelAssessmentDto> SubmitVideoAssessmentAsync(int userId, string videoUrl)
    {
        var profile = await GetOrCreateProfileAsync(userId);
        var assessment = new LevelAssessment
        {
            PlayerProfileId = profile.Id,
            Type = LevelAssessmentType.VideoUpload,
            VideoUrl = videoUrl,
            IsCompleted = false,
        };
        _db.LevelAssessments.Add(assessment);
        await _db.SaveChangesAsync();
        return ToAssessmentDto(assessment, null);
    }

    public async Task<LevelAssessmentDto> RequestCoachAssessmentAsync(int userId, int coachId)
    {
        var coach = await _db.CoachProfiles
            .Include(c => c.User)
            .FirstOrDefaultAsync(c => c.Id == coachId)
            ?? throw new AuthException("Coach not found", "المدرب غير موجود", "COACH_NOT_FOUND");

        var profile = await GetOrCreateProfileAsync(userId);
        var assessment = new LevelAssessment
        {
            PlayerProfileId = profile.Id,
            Type = LevelAssessmentType.CoachSession,
            CoachId = coach.UserId,
            IsCompleted = false,
        };
        _db.LevelAssessments.Add(assessment);
        await _db.SaveChangesAsync();
        return ToAssessmentDto(assessment, coach.User);
    }

    public async Task<List<LevelAssessmentDto>> GetMyAssessmentsAsync(int userId)
    {
        var items = await _db.LevelAssessments
            .Include(a => a.Coach)
            .Where(a => a.PlayerProfile.UserId == userId)
            .OrderByDescending(a => a.CreatedAt)
            .ToListAsync();
        return items.Select(a => ToAssessmentDto(a, a.Coach)).ToList();
    }

    public async Task<PlayerProfileDto> GetMyProfileAsync(int userId)
    {
        var data = await _db.PlayerProfiles
            .Where(p => p.UserId == userId)
            .Select(p => new
            {
                p.Level,
                p.EloRating,
                p.TotalMatches,
                p.TotalWins,
                Assessed = p.LevelAssessments.Any(a => a.IsCompleted),
            })
            .FirstOrDefaultAsync()
            ?? throw new AuthException(
                "Player profile not found", "ملف اللاعب غير موجود", "PLAYER_PROFILE_NOT_FOUND");

        return new PlayerProfileDto
        {
            Level = (int)data.Level,
            LevelNameAr = PlayerLevelInfo.NameAr(data.Level),
            LevelNameEn = PlayerLevelInfo.NameEn(data.Level),
            LevelAssessed = data.Assessed,
            EloRating = data.EloRating,
            TotalMatches = data.TotalMatches,
            TotalWins = data.TotalWins,
            WinRate = data.TotalMatches == 0
                ? 0
                : (float)data.TotalWins / data.TotalMatches * 100,
        };
    }

    public async Task SetFavoriteSportAsync(int userId, string sport)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        user.FavoriteSport = sport;
        user.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
    }

    // ── helpers ────────────────────────────────────────────────────────────────

    private async Task<PlayerProfile> GetOrCreateProfileAsync(int userId)
    {
        var profile = await _db.PlayerProfiles.FirstOrDefaultAsync(p => p.UserId == userId);
        if (profile == null)
        {
            profile = new PlayerProfile { UserId = userId };
            _db.PlayerProfiles.Add(profile);
            await _db.SaveChangesAsync();
        }
        return profile;
    }

    internal static LevelAssessmentDto ToAssessmentDto(LevelAssessment a, User? coach)
    {
        return new LevelAssessmentDto
        {
            Id = a.Id,
            Type = a.Type switch
            {
                LevelAssessmentType.VideoUpload => "video",
                LevelAssessmentType.CoachSession => "coach",
                _ => "self",
            },
            Status = a.IsCompleted ? "completed" : "pending",
            VideoUrl = a.VideoUrl,
            CoachName = coach != null
                ? $"{coach.FirstName} {coach.LastName}".Trim()
                : null,
            PlayerName = a.PlayerProfile?.User != null
                ? $"{a.PlayerProfile.User.FirstName} {a.PlayerProfile.User.LastName}".Trim()
                : null,
            AssignedLevel = a.AssignedLevel != null ? (int)a.AssignedLevel : null,
            AssignedLevelName = a.AssignedLevel != null
                ? PlayerLevelInfo.NameAr(a.AssignedLevel.Value)
                : null,
            CreatedAt = a.CreatedAt,
        };
    }
}
