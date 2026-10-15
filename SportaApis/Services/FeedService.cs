using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Helpers;

namespace SportaApis.Services;

/// <summary>
/// Builds the followed-players activity feed by deriving recent events from the
/// existing tables (no separate activity log).
/// </summary>
public class FeedService : IFeedService
{
    private readonly AppDbContext _db;

    public FeedService(AppDbContext db) => _db = db;

    /// <summary>
    /// القيم مقروءة من MySQL بـ Kind=Unspecified رغم تخزينها UTC، وبدونها يُسلسل
    /// التاريخ بلا علامة منطقة فيقرأه التطبيق كتوقيت محلي ويزيح "منذ..." بثلاث ساعات.
    /// </summary>
    private static DateTime AsUtc(DateTime value) =>
        DateTime.SpecifyKind(value, DateTimeKind.Utc);

    public async Task<List<FeedItemDto>> GetFeedAsync(int currentUserId)
    {
        // الحسابات المحذوفة تبقى في جدول المتابعة لكنها مُبهَّمة الاسم،
        // فتُستبعد كي لا يظهر "حساب محذوف" في النشاط.
        var followedIds = await _db.Follows
            .Where(f => f.FollowerId == currentUserId && !f.Following.IsDeleted)
            .Select(f => f.FollowingId)
            .ToListAsync();

        if (followedIds.Count == 0) return [];

        var names = await _db.Users
            .Where(u => followedIds.Contains(u.Id))
            .ToDictionaryAsync(
                u => u.Id, u => $"{u.FirstName} {u.LastName}".Trim());

        string Name(int id) => names.GetValueOrDefault(id, "لاعب");

        var items = new List<FeedItemDto>();

        // Joined matches.
        var joins = await _db.MatchPlayers
            .Include(p => p.Match).ThenInclude(m => m.Court).ThenInclude(c => c!.Venue)
            .Where(p => followedIds.Contains(p.UserId) && p.Match.AmericanoMatch == null)
            .OrderByDescending(p => p.JoinedAt)
            .Take(20)
            .ToListAsync();
        foreach (var j in joins)
        {
            var venue = j.Match.Court?.Venue;
            items.Add(new FeedItemDto
            {
                ActorId = j.UserId,
                ActorName = Name(j.UserId),
                Type = "match_joined",
                Text = venue == null
                    ? "انضم إلى مباراة"
                    : $"انضم إلى مباراة في {venue.Name}",
                VenueName = venue?.Name,
                VenueNameEn = venue?.NameEn,
                CreatedAt = AsUtc(j.JoinedAt),
            });
        }

        // Booked coach sessions.
        var sessions = await _db.CoachSessions
            .Include(s => s.CoachProfile).ThenInclude(c => c.User)
            .Where(s => followedIds.Contains(s.PlayerId))
            .OrderByDescending(s => s.CreatedAt)
            .Take(20)
            .ToListAsync();
        foreach (var s in sessions)
        {
            var coach = $"{s.CoachProfile.User.FirstName} {s.CoachProfile.User.LastName}".Trim();
            items.Add(new FeedItemDto
            {
                ActorId = s.PlayerId,
                ActorName = Name(s.PlayerId),
                Type = "coach_session",
                Text = $"حجز جلسة تدريب مع المدرب {coach}",
                CoachName = coach,
                CreatedAt = AsUtc(s.CreatedAt),
            });
        }

        // Completed level assessments.
        var assessments = await _db.LevelAssessments
            .Include(a => a.PlayerProfile)
            .Where(a => a.IsCompleted &&
                        a.AssignedLevel != null &&
                        followedIds.Contains(a.PlayerProfile.UserId))
            .OrderByDescending(a => a.CreatedAt)
            .Take(20)
            .ToListAsync();
        foreach (var a in assessments)
        {
            var level = a.AssignedLevel!.Value;
            items.Add(new FeedItemDto
            {
                ActorId = a.PlayerProfile.UserId,
                ActorName = Name(a.PlayerProfile.UserId),
                Type = "level",
                Text = $"حدّد مستواه: {(int)level} - {PlayerLevelInfo.NameAr(level)}",
                Level = (int)level,
                CreatedAt = AsUtc(a.CreatedAt),
            });
        }

        return items
            .OrderByDescending(i => i.CreatedAt)
            .Take(30)
            .ToList();
    }
}
