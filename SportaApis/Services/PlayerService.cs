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

    public PlayerService(AppDbContext db) => _db = db;

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

        var level = PlayerLevelInfo.FromAnswers(req.Answers);

        _db.LevelAssessments.Add(new LevelAssessment
        {
            PlayerProfileId = profile.Id,
            Type = LevelAssessmentType.SelfAssessment,
            AssignedLevel = level,
            IsCompleted = true,
            Notes = $"sport={req.Sport}; answers=[{string.Join(",", req.Answers)}]",
        });

        profile.Level = level;
        profile.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return new LevelAssessmentResultDto
        {
            Level = (int)level,
            LevelNameAr = PlayerLevelInfo.NameAr(level),
            LevelNameEn = PlayerLevelInfo.NameEn(level),
        };
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
}
