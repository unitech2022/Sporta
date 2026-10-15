using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.Enums;
using SportaApis.Models;

namespace SportaApis.Services;

/// <summary>
/// كتابة التقييمات ومجاميعها — مشتركة بين <see cref="ReviewService"/> ومسارات
/// التقييم القديمة (تقييم جلسة التدريب في <c>CoachService</c>، وتقييم الزملاء
/// مع إدخال النتيجة في <c>MatchService</c>) كي يبقى جدول التقييمات مصدراً
/// واحداً حتى من نسخ التطبيق القديمة.
/// </summary>
public static class ReviewStore
{
    /// <summary>الجوانب المسموح بها لكل نوع هدف — غيرها يُتجاهل.</summary>
    public static readonly IReadOnlyDictionary<ReviewTargetType, string[]> AllowedTags =
        new Dictionary<ReviewTargetType, string[]>
        {
            [ReviewTargetType.Court] =
                ["clean", "lighting", "surface", "staff", "parking", "value", "amenities"],
            [ReviewTargetType.Player] =
                ["punctual", "sportsmanship", "level_accurate", "respectful", "facility_care"],
            [ReviewTargetType.Coach] =
                ["punctual", "clear", "professional", "motivating", "value"],
        };

    public static string? CleanTags(ReviewTargetType type, IEnumerable<string>? tags)
    {
        var allowed = AllowedTags[type];
        var list = (tags ?? [])
            .Select(t => t.Trim().ToLowerInvariant())
            .Where(t => allowed.Contains(t))
            .Distinct()
            .ToList();
        return list.Count == 0 ? null : string.Join(',', list);
    }

    public static List<string> SplitTags(string? tags) =>
        string.IsNullOrEmpty(tags)
            ? []
            : tags.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList();

    /// <summary>
    /// ينشئ التقييم أو يعدّله (يحفظ فوراً). مع <paramref name="overwrite"/>=false
    /// يُترك الموجود كما هو — سلوك المسارات القديمة «مرة واحدة».
    /// </summary>
    public static async Task<(Review Review, bool IsNew)> UpsertAsync(
        AppDbContext db, int raterId, ReviewerRole role,
        ReviewTargetType type, int targetId,
        ReviewContextType context, int contextId,
        int score, IEnumerable<string>? tags, string? comment, bool overwrite = true)
    {
        score = Math.Clamp(score, 1, 5);
        comment = string.IsNullOrWhiteSpace(comment) ? null : comment.Trim();
        if (comment is { Length: > 500 }) comment = comment[..500];

        var review = await db.Reviews.FirstOrDefaultAsync(r =>
            r.ContextType == context && r.ContextId == contextId &&
            r.RaterId == raterId && r.TargetType == type && r.TargetId == targetId);

        if (review != null && !overwrite) return (review, false);

        var isNew = review == null;
        if (review == null)
        {
            review = new Review
            {
                RaterId = raterId,
                TargetType = type,
                TargetId = targetId,
                ContextType = context,
                ContextId = contextId,
            };
            db.Reviews.Add(review);
        }
        else
        {
            review.UpdatedAt = DateTime.UtcNow;
        }

        review.RaterRole = role;
        review.Score = score;
        review.Tags = CleanTags(type, tags);
        review.Comment = comment;
        await db.SaveChangesAsync();

        if (type == ReviewTargetType.Player) await RecomputePlayerAsync(db, targetId);
        else if (type == ReviewTargetType.Court) await RecomputeCourtAsync(db, targetId);

        return (review, isNew);
    }

    /// <summary>سمعة اللاعب = متوسط كل ما قيّمه به اللاعبون والمدربون وأصحاب
    /// الملاعب — تُخزَّن على PlayerProfile.PeerRating* (العرض والفرز).</summary>
    public static async Task RecomputePlayerAsync(AppDbContext db, int userId)
    {
        var profile = await db.PlayerProfiles.FirstOrDefaultAsync(p => p.UserId == userId);
        if (profile == null) return;
        var stats = await db.Reviews
            .Where(r => r.TargetType == ReviewTargetType.Player && r.TargetId == userId)
            .GroupBy(_ => 1)
            .Select(g => new { Avg = g.Average(r => (double)r.Score), Count = g.Count() })
            .FirstOrDefaultAsync();
        profile.PeerRatingAverage = stats == null ? 0f : (float)Math.Round(stats.Avg, 2);
        profile.PeerRatingCount = stats?.Count ?? 0;
        await db.SaveChangesAsync();
    }

    public static async Task RecomputeCourtAsync(AppDbContext db, int courtId)
    {
        var court = await db.Courts.FirstOrDefaultAsync(c => c.Id == courtId);
        if (court == null) return;
        var stats = await db.Reviews
            .Where(r => r.TargetType == ReviewTargetType.Court && r.TargetId == courtId)
            .GroupBy(_ => 1)
            .Select(g => new { Avg = g.Average(r => (double)r.Score), Count = g.Count() })
            .FirstOrDefaultAsync();
        court.RatingAverage = stats == null ? 0 : Math.Round(stats.Avg, 2);
        court.RatingCount = stats?.Count ?? 0;
        await db.SaveChangesAsync();
    }
}
