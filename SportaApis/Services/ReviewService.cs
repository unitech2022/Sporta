using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

public interface IReviewService
{
    Task<ReviewSessionDto> GetSessionAsync(int userId, ReviewContextType context, int contextId);
    Task<ReviewSessionDto> SubmitAsync(
        int userId, ReviewContextType context, int contextId, SubmitReviewsRequest request);
    Task<List<PendingReviewDto>> GetPendingAsync(int userId);
    Task<CourtRatingsDto> GetCourtRatingsAsync(int courtId, int page, int pageSize);
    Task<PlayerReputationDto> GetPlayerReputationAsync(int userId);
}

/// <summary>
/// التقييم المتبادل بعد كل تجربة مشتركة — كل طرف يقيّم الأطراف الأخرى:
/// <list type="bullet">
/// <item>مباراة/أمريكانو/بطولة: اللاعب ← الملعب وبقية اللاعبين؛ صاحب الملعب ← اللاعبين.</item>
/// <item>حجز ملعب: الحاجز ← الملعب؛ صاحب الملعب ← الحاجز.</item>
/// <item>جلسة تدريب: اللاعب ← المدرب والملعب؛ المدرب ← اللاعب والملعب؛ صاحب الملعب ← اللاعب والمدرب.</item>
/// </list>
/// بعد انتهاء التجربة فقط، تقييم واحد لكل (مقيِّم، هدف، تجربة) يُعدَّل. لا أحد
/// يقيّم نفسه ولا صاحب الملعب ملعبه.
/// </summary>
public class ReviewService : IReviewService
{
    /// <summary>بطاقة «قيّم تجربتك» تعرض ما انتهى خلال هذه المدة.</summary>
    private static readonly TimeSpan PendingWindow = TimeSpan.FromDays(7);

    private readonly AppDbContext _db;
    private readonly IPointsService _points;
    private readonly INotificationService _notifications;
    private readonly ICoachService _coach;

    public ReviewService(
        AppDbContext db, IPointsService points, INotificationService notifications,
        ICoachService coach)
    {
        _db = db;
        _points = points;
        _notifications = notifications;
        _coach = coach;
    }

    // ── التجربة الموحّدة ───────────────────────────────────────────────────────

    private sealed record Party(int UserId, ReviewerRole Role, string Name, string? Avatar);

    private sealed class Experience
    {
        public ReviewContextType Context { get; init; }
        public int Id { get; init; }
        public string Kind { get; init; } = "match";
        public string Title { get; init; } = string.Empty;
        public string? TitleEn { get; init; }
        public string? Subtitle { get; init; }
        public string? SubtitleEn { get; init; }
        public string? ImageUrl { get; init; }
        public DateTime StartsAt { get; init; }
        public DateTime EndsAt { get; init; }

        /// <summary>سبب يمنع التقييم مهما كان الوقت (ملغاة، غير مدفوعة…).</summary>
        public string? Blocker { get; init; }
        public bool ForceEnded { get; init; }
        public Court? Court { get; init; }
        public int? OwnerId => Court?.Venue.OwnerId;
        public List<Party> Parties { get; init; } = [];

        public bool HasEnded(DateTime now) => ForceEnded || EndsAt <= now;
    }

    private static string KindOf(Match m) =>
        m.AmericanoMatch == null ? "match"
        : (m.AmericanoMatch.IsTournament || m.AmericanoMatch.Format != null)
            ? "tournament" : "americano";

    private static string? CourtImage(Court? c) =>
        c == null ? null : string.IsNullOrWhiteSpace(c.ImageUrl) ? c.Venue.ImageUrl : c.ImageUrl;

    private static string FullName(User? u) =>
        u == null ? string.Empty : $"{u.FirstName} {u.LastName}".Trim();

    private static Experience FromMatch(Match m)
    {
        var end = m.AmericanoMatch?.EndDate is { } d && d > m.ScheduledAt
            ? d : m.ScheduledAt.AddMinutes(m.DurationMinutes);
        var name = m.AmericanoMatch?.Name;
        return new Experience
        {
            Context = ReviewContextType.Match,
            Id = m.Id,
            Kind = KindOf(m),
            Title = !string.IsNullOrWhiteSpace(name) ? name! : m.Court?.Name ?? string.Empty,
            TitleEn = !string.IsNullOrWhiteSpace(name) ? null : m.Court?.NameEn,
            Subtitle = m.Court?.Venue.Name,
            SubtitleEn = m.Court?.Venue.NameEn,
            ImageUrl = CourtImage(m.Court),
            StartsAt = m.ScheduledAt,
            EndsAt = end,
            Blocker = m.Status switch
            {
                MatchStatus.Cancelled => "cancelled",
                MatchStatus.PendingApproval => "cancelled",
                _ => null,
            },
            ForceEnded = m.Status == MatchStatus.Completed,
            Court = m.Court,
            Parties = m.MatchPlayers
                .Where(p => p.Status == MatchPlayerStatus.Approved)
                .Select(p => new Party(p.UserId, ReviewerRole.Player, FullName(p.User),
                    p.User?.ProfileImageUrl))
                .ToList(),
        };
    }

    private static Experience FromBooking(Booking b) => new()
    {
        Context = ReviewContextType.Booking,
        Id = b.Id,
        Kind = "booking",
        Title = b.Court.Name,
        TitleEn = b.Court.NameEn,
        Subtitle = b.Court.Venue.Name,
        SubtitleEn = b.Court.Venue.NameEn,
        ImageUrl = CourtImage(b.Court),
        StartsAt = b.StartTime,
        EndsAt = b.EndTime,
        Blocker = b.Status switch
        {
            BookingStatus.Cancelled => "cancelled",
            BookingStatus.Pending => "not_confirmed",
            _ => null,
        },
        ForceEnded = b.Status == BookingStatus.Completed,
        Court = b.Court,
        Parties = [new Party(b.UserId, ReviewerRole.Player, FullName(b.User), b.User?.ProfileImageUrl)],
    };

    private static Experience FromSession(CoachSession s) => new()
    {
        Context = ReviewContextType.CoachSession,
        Id = s.Id,
        Kind = "session",
        Title = string.IsNullOrWhiteSpace(s.Title) ? FullName(s.CoachProfile.User) : s.Title,
        Subtitle = s.Court == null
            ? FullName(s.CoachProfile.User)
            : $"{FullName(s.CoachProfile.User)} · {s.Court.Venue.Name}",
        ImageUrl = CourtImage(s.Court) ?? s.CoachProfile.User?.ProfileImageUrl,
        StartsAt = s.ScheduledAt,
        EndsAt = s.ScheduledAt.AddMinutes(s.DurationMinutes),
        Blocker = s.Status != CoachSessionStatus.Confirmed ? "cancelled"
            : !s.IsPaid ? "not_paid" : null,
        ForceEnded = s.IsCompleted,
        Court = s.Court,
        Parties =
        [
            new Party(s.PlayerId, ReviewerRole.Player, FullName(s.Player), s.Player?.ProfileImageUrl),
            new Party(s.CoachProfile.UserId, ReviewerRole.Coach,
                FullName(s.CoachProfile.User), s.CoachProfile.User?.ProfileImageUrl),
        ],
    };

    private IQueryable<Match> MatchQuery() => _db.Matches
        .Include(m => m.Court!).ThenInclude(c => c.Venue)
        .Include(m => m.AmericanoMatch)
        .Include(m => m.MatchPlayers).ThenInclude(p => p.User);

    private IQueryable<Booking> BookingQuery() => _db.Bookings
        .Include(b => b.Court).ThenInclude(c => c.Venue)
        .Include(b => b.User);

    private IQueryable<CoachSession> SessionQuery() => _db.CoachSessions
        .Include(s => s.CoachProfile).ThenInclude(c => c.User)
        .Include(s => s.Player)
        .Include(s => s.Court!).ThenInclude(c => c.Venue);

    private async Task<Experience> LoadAsync(ReviewContextType context, int id)
    {
        Experience? exp = context switch
        {
            ReviewContextType.Match =>
                await MatchQuery().FirstOrDefaultAsync(m => m.Id == id) is { } m ? FromMatch(m) : null,
            ReviewContextType.Booking =>
                await BookingQuery().FirstOrDefaultAsync(b => b.Id == id) is { } b ? FromBooking(b) : null,
            _ =>
                await SessionQuery().FirstOrDefaultAsync(s => s.Id == id) is { } s ? FromSession(s) : null,
        };
        return exp ?? throw new AuthException("Not found", "التجربة غير موجودة", "REVIEW_CONTEXT_NOT_FOUND");
    }

    /// <summary>صفة المستخدم في التجربة: مشارك (لاعب/مدرب) وإلا صاحب الملعب.</summary>
    private static ReviewerRole? RoleOf(Experience e, int userId)
    {
        var party = e.Parties.FirstOrDefault(p => p.UserId == userId);
        if (party != null) return party.Role;
        if (e.OwnerId == userId) return ReviewerRole.VenueOwner;
        return null;
    }

    /// <summary>من يحقّ لـ [userId] تقييمه في هذه التجربة.</summary>
    private static List<ReviewTargetDto> TargetsFor(Experience e, int userId, ReviewerRole role)
    {
        var targets = new List<ReviewTargetDto>();
        // الملعب: يقيّمه المشاركون، لا صاحبه.
        if (e.Court != null && role != ReviewerRole.VenueOwner && e.OwnerId != userId)
        {
            targets.Add(new ReviewTargetDto
            {
                Type = "court",
                Id = e.Court.Id,
                Name = e.Court.Name,
                NameEn = e.Court.NameEn,
                ImageUrl = CourtImage(e.Court),
                Role = "court",
            });
        }
        foreach (var p in e.Parties.Where(p => p.UserId != userId).DistinctBy(p => p.UserId))
        {
            targets.Add(new ReviewTargetDto
            {
                Type = p.Role == ReviewerRole.Coach ? "coach" : "player",
                Id = p.UserId,
                Name = p.Name,
                ImageUrl = p.Avatar,
                Role = p.Role == ReviewerRole.Coach ? "coach" : "player",
            });
        }
        return targets;
    }

    private static string RoleName(ReviewerRole r) => r switch
    {
        ReviewerRole.Coach => "coach",
        ReviewerRole.VenueOwner => "venue",
        _ => "player",
    };

    private static ReviewTargetType ParseTarget(string type) => type?.Trim().ToLowerInvariant() switch
    {
        "court" => ReviewTargetType.Court,
        "coach" => ReviewTargetType.Coach,
        _ => ReviewTargetType.Player,
    };

    public static string ContextName(ReviewContextType c) => c switch
    {
        ReviewContextType.Booking => "booking",
        ReviewContextType.CoachSession => "session",
        _ => "match",
    };

    // ── القراءة والإرسال ───────────────────────────────────────────────────────

    public async Task<ReviewSessionDto> GetSessionAsync(
        int userId, ReviewContextType context, int contextId)
    {
        var e = await LoadAsync(context, contextId);
        return await BuildSessionAsync(e, userId);
    }

    private async Task<ReviewSessionDto> BuildSessionAsync(Experience e, int userId)
    {
        var dto = new ReviewSessionDto
        {
            Context = ContextName(e.Context),
            ContextId = e.Id,
            Kind = e.Kind,
            Title = e.Title,
            TitleEn = e.TitleEn,
            Subtitle = e.Subtitle,
            SubtitleEn = e.SubtitleEn,
            ImageUrl = e.ImageUrl,
            StartsAt = e.StartsAt,
        };

        var role = RoleOf(e, userId);
        if (role == null)
        {
            dto.Reason = "not_member";
            return dto;
        }
        dto.MyRole = RoleName(role.Value);

        if (e.Blocker != null) dto.Reason = e.Blocker;
        else if (!e.HasEnded(AppClock.Now)) dto.Reason = "not_ended";

        var targets = TargetsFor(e, userId, role.Value);
        if (dto.Reason == null && targets.Count == 0) dto.Reason = "nothing";

        var mine = await _db.Reviews
            .Include(r => r.Rater)
            .Where(r => r.ContextType == e.Context && r.ContextId == e.Id && r.RaterId == userId)
            .ToListAsync();
        foreach (var t in targets)
        {
            var type = ParseTarget(t.Type);
            var r = mine.FirstOrDefault(x => x.TargetType == type && x.TargetId == t.Id);
            if (r != null) t.MyReview = ToItem(r);
        }

        dto.Targets = targets;
        dto.RatedCount = targets.Count(t => t.MyReview != null);
        dto.CanReview = dto.Reason == null;
        return dto;
    }

    public async Task<ReviewSessionDto> SubmitAsync(
        int userId, ReviewContextType context, int contextId, SubmitReviewsRequest request)
    {
        var e = await LoadAsync(context, contextId);
        var role = RoleOf(e, userId)
            ?? throw new AuthException("Not part of this experience",
                "التقييم لأطراف التجربة فقط", "REVIEW_NOT_MEMBER");
        if (e.Blocker != null)
            throw e.Blocker switch
            {
                "not_paid" => new AuthException("Session is not paid yet",
                    "لا يمكن التقييم قبل دفع الجلسة", "REVIEW_NOT_PAID"),
                "not_confirmed" => new AuthException("Booking is not confirmed",
                    "الحجز غير مؤكد", "REVIEW_NOT_CONFIRMED"),
                _ => new AuthException("Cancelled", "التجربة ملغاة", "REVIEW_CANCELLED"),
            };
        if (!e.HasEnded(AppClock.Now))
            throw new AuthException("Not ended yet",
                "يمكنك التقييم بعد انتهاء التجربة", "REVIEW_NOT_ENDED");

        var targets = TargetsFor(e, userId, role);
        if (request.Reviews.Count == 0)
            throw new AuthException("Nothing to submit", "اختر تقييماً واحداً على الأقل", "REVIEW_EMPTY");

        // التحقق من الدفعة كلها أولاً — لا يُحفظ نصفها ثم يُرفض الباقي.
        var batch = new List<(ReviewTargetType Type, ReviewTargetDto Target, ReviewInput Input)>();
        foreach (var input in request.Reviews)
        {
            if (input.Score is < 1 or > 5)
                throw new AuthException("Score must be 1-5", "التقييم من 1 إلى 5 نجوم", "INVALID_SCORE");
            var type = ParseTarget(input.Type);
            var target = targets.FirstOrDefault(t => ParseTarget(t.Type) == type && t.Id == input.Id)
                ?? throw new AuthException("Target not allowed",
                    "لا يمكنك تقييم هذا الطرف", "REVIEW_TARGET_NOT_ALLOWED");
            batch.Add((type, target, input));
        }

        foreach (var (type, target, input) in batch)
            await SaveOneAsync(e, userId, role, type, target, input);

        // إعادة التحميل: الحالة قد تغيّرت (جلسة التدريب تُعلَّم مكتملة…).
        return await GetSessionAsync(userId, context, contextId);
    }

    private async Task SaveOneAsync(
        Experience e, int userId, ReviewerRole role, ReviewTargetType type,
        ReviewTargetDto target, ReviewInput input)
    {
        // جلسة التدريب: تقييم اللاعب للمدرب والمدرب للاعب يمرّان أول مرة بمسار
        // المدرب القائم (نقاط، رفع المستوى، الإشعار، تقييم المدرب المعروض)،
        // ويُعدَّل بعدها على الجلسة مباشرة.
        if (e.Context == ReviewContextType.CoachSession && type != ReviewTargetType.Court &&
            role != ReviewerRole.VenueOwner)
        {
            var session = await _db.CoachSessions.FirstAsync(s => s.Id == e.Id);
            if (type == ReviewTargetType.Coach && role == ReviewerRole.Player)
            {
                if (session.PlayerRating == null)
                    await _coach.RateCoachAsync(userId, e.Id, input.Score, input.Comment);
                else
                {
                    session.PlayerRating = input.Score;
                    session.PlayerReview = input.Comment;
                    session.UpdatedAt = DateTime.UtcNow;
                    await _db.SaveChangesAsync();
                }
            }
            else if (type == ReviewTargetType.Player && role == ReviewerRole.Coach)
            {
                if (session.CoachRating == null)
                    await _coach.RateSessionAsync(userId, e.Id, input.Score, input.Comment);
                else
                {
                    session.CoachRating = input.Score;
                    session.CoachReview = input.Comment;
                    session.UpdatedAt = DateTime.UtcNow;
                    await _db.SaveChangesAsync();
                }
            }
        }

        var (review, isNew) = await ReviewStore.UpsertAsync(
            _db, userId, role, type, target.Id, e.Context, e.Id,
            input.Score, input.Tags, input.Comment);

        if (!isNew) return;

        if (type == ReviewTargetType.Court && e.Court != null)
        {
            // نقاط المكافآت وإشعار المالك على أول تقييم فقط.
            await _points.EarnActivityAsync(
                userId, PointsTransactionType.CourtRated, review.Id, "نقاط تقييم ملعب");
            var rater = await _db.Users.Where(u => u.Id == userId)
                .Select(u => u.FirstName).FirstOrDefaultAsync();
            await _notifications.PushAsync(
                e.Court.Venue.OwnerId,
                "تقييم جديد لملعبك",
                $"قيّم {rater ?? "لاعب"} «{e.Court.Name}» بـ {input.Score} من 5",
                "court_rated", e.Court.Id);
        }
    }

    // ── المعلّق ────────────────────────────────────────────────────────────────

    public async Task<List<PendingReviewDto>> GetPendingAsync(int userId)
    {
        var now = AppClock.Now;
        var since = now - PendingWindow;
        var experiences = new List<Experience>();

        // مرشّح واسع بالموعد (البطولة قد تمتد أياماً) ثم نهاية دقيقة في الذاكرة.
        experiences.AddRange((await MatchQuery()
                .AsNoTracking()
                .Where(m => m.Status != MatchStatus.Cancelled && m.Status != MatchStatus.PendingApproval)
                .Where(m => m.ScheduledAt <= now && m.ScheduledAt >= since.AddDays(-30))
                .Where(m => m.MatchPlayers.Any(p => p.UserId == userId
                                                 && p.Status == MatchPlayerStatus.Approved)
                         || (m.Court != null && m.Court.Venue.OwnerId == userId))
                .OrderByDescending(m => m.ScheduledAt)
                .Take(40)
                .ToListAsync())
            .Select(FromMatch));

        experiences.AddRange((await BookingQuery()
                .AsNoTracking()
                .Where(b => b.Status == BookingStatus.Confirmed || b.Status == BookingStatus.Completed)
                .Where(b => b.EndTime <= now && b.EndTime >= since)
                .Where(b => b.UserId == userId || b.Court.Venue.OwnerId == userId)
                .OrderByDescending(b => b.StartTime)
                .Take(40)
                .ToListAsync())
            .Select(FromBooking));

        experiences.AddRange((await SessionQuery()
                .AsNoTracking()
                .Where(s => s.Status == CoachSessionStatus.Confirmed && s.IsPaid)
                .Where(s => s.ScheduledAt <= now && s.ScheduledAt >= since.AddDays(-1))
                .Where(s => s.PlayerId == userId || s.CoachProfile.UserId == userId
                         || (s.Court != null && s.Court.Venue.OwnerId == userId))
                .OrderByDescending(s => s.ScheduledAt)
                .Take(40)
                .ToListAsync())
            .Select(FromSession));

        var ended = experiences
            .Where(e => e.Blocker == null && e.HasEnded(now) && e.EndsAt >= since)
            .ToList();
        if (ended.Count == 0) return [];

        var mine = await _db.Reviews.AsNoTracking()
            .Where(r => r.RaterId == userId && r.CreatedAt >= DateTime.UtcNow.AddDays(-60))
            .Select(r => new { r.ContextType, r.ContextId, r.TargetType, r.TargetId })
            .ToListAsync();

        var result = new List<PendingReviewDto>();
        foreach (var e in ended)
        {
            var role = RoleOf(e, userId);
            if (role == null) continue;
            var pending = TargetsFor(e, userId, role.Value).Count(t => !mine.Any(r =>
                r.ContextType == e.Context && r.ContextId == e.Id &&
                r.TargetType == ParseTarget(t.Type) && r.TargetId == t.Id));
            if (pending == 0) continue;
            result.Add(new PendingReviewDto
            {
                Context = ContextName(e.Context),
                ContextId = e.Id,
                Kind = e.Kind,
                Title = e.Title,
                TitleEn = e.TitleEn,
                Subtitle = e.Subtitle,
                SubtitleEn = e.SubtitleEn,
                ImageUrl = e.ImageUrl,
                StartsAt = e.StartsAt,
                MyRole = RoleName(role.Value),
                PendingCount = pending,
            });
        }
        return result.OrderByDescending(p => p.StartsAt).Take(10).ToList();
    }

    // ── الملخّصات ─────────────────────────────────────────────────────────────

    public async Task<CourtRatingsDto> GetCourtRatingsAsync(int courtId, int page, int pageSize)
    {
        (page, pageSize) = Paging.Clamp(page, pageSize);
        var court = await _db.Courts.AsNoTracking().FirstOrDefaultAsync(c => c.Id == courtId)
            ?? throw new AuthException("Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        var all = _db.Reviews.AsNoTracking()
            .Where(r => r.TargetType == ReviewTargetType.Court && r.TargetId == courtId);

        var total = await all.CountAsync();
        var items = await all
            .Include(r => r.Rater)
            .OrderByDescending(r => r.Comment != null)
            .ThenByDescending(r => r.UpdatedAt ?? r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new CourtRatingsDto
        {
            CourtId = courtId,
            Average = court.RatingAverage,
            Count = court.RatingCount,
            Distribution = await DistributionAsync(all),
            TopPraised = await TopPraisedAsync(all),
            Reviews = new PagedResult<ReviewItemDto>
            {
                Items = items.Select(ToItem).ToList(),
                Page = page,
                PageSize = pageSize,
                Total = total,
            },
        };
    }

    public async Task<PlayerReputationDto> GetPlayerReputationAsync(int userId)
    {
        var all = _db.Reviews.AsNoTracking()
            .Where(r => r.TargetType == ReviewTargetType.Player && r.TargetId == userId);
        var stats = await all.GroupBy(_ => 1)
            .Select(g => new { Avg = g.Average(r => (double)r.Score), Count = g.Count() })
            .FirstOrDefaultAsync();
        var byRole = await all.GroupBy(r => r.RaterRole)
            .Select(g => new { g.Key, Count = g.Count() })
            .ToListAsync();
        return new PlayerReputationDto
        {
            UserId = userId,
            Average = stats == null ? 0 : Math.Round(stats.Avg, 2),
            Count = stats?.Count ?? 0,
            Distribution = await DistributionAsync(all),
            TopPraised = await TopPraisedAsync(all),
            ByRole = byRole.ToDictionary(r => RoleName(r.Key), r => r.Count),
        };
    }

    private static async Task<Dictionary<int, int>> DistributionAsync(IQueryable<Review> q)
    {
        var dist = await q.GroupBy(r => r.Score)
            .Select(g => new { Score = g.Key, Count = g.Count() })
            .ToListAsync();
        return Enumerable.Range(1, 5)
            .ToDictionary(s => s, s => dist.FirstOrDefault(d => d.Score == s)?.Count ?? 0);
    }

    /// <summary>أكثر الجوانب ذكراً في تقييمات ٤ نجوم فأكثر.</summary>
    private static async Task<List<ReviewTagCountDto>> TopPraisedAsync(IQueryable<Review> q)
    {
        var tags = await q.Where(r => r.Score >= 4 && r.Tags != null)
            .Select(r => r.Tags!).ToListAsync();
        return tags
            .SelectMany(ReviewStore.SplitTags)
            .GroupBy(t => t)
            .Select(g => new ReviewTagCountDto { Tag = g.Key, Count = g.Count() })
            .OrderByDescending(t => t.Count)
            .Take(4)
            .ToList();
    }

    private static ReviewItemDto ToItem(Review r) => new()
    {
        Id = r.Id,
        RaterId = r.RaterId,
        RaterName = FullName(r.Rater),
        RaterAvatarUrl = r.Rater?.ProfileImageUrl,
        RaterRole = RoleName(r.RaterRole),
        Score = r.Score,
        Tags = ReviewStore.SplitTags(r.Tags),
        Comment = r.Comment,
        CreatedAt = r.CreatedAt,
        UpdatedAt = r.UpdatedAt,
    };
}
