using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IMatchService
{
    /// <summary>Lists open/full matches (paged; nearest/soonest first).
    /// Optional filters: city, gender ("male" | "female").</summary>
    Task<PagedResult<MatchDto>> GetMatchesAsync(
        int currentUserId, string? city, string? gender, int page = 1, int pageSize = 20);

    /// <summary>Returns a single match with its players.</summary>
    Task<MatchDto> GetByIdAsync(int currentUserId, int id);

    /// <summary>Creates a match and adds the creator as the first player.</summary>
    Task<MatchDto> CreateAsync(int userId, CreateMatchRequest req);

    /// <summary>Adds the current user to a match.</summary>
    Task<MatchDto> JoinAsync(int userId, int matchId);

    /// <summary>يلغي حدثاً يستضيفه صاحب الملعب ويردّ حصص المسجّلين.</summary>
    Task<MatchDto> CancelHostedAsync(int userId, int matchId);

    /// <summary>المنشئ يحوّل مباراته الخاصة إلى عامة تظهر في البحث ويصح الانضمام إليها.</summary>
    Task<MatchDto> MakePublicAsync(int userId, int matchId);

    /// <summary>Invites a friend to a match the inviter is part of (pending their acceptance).</summary>
    Task<MatchDto> InviteAsync(int inviterId, int matchId, int targetId);

    /// <summary>The invited player accepts or declines a match invitation.</summary>
    Task<MatchDto> RespondToInviteAsync(int userId, int matchId, bool accept);

    /// <summary>Pending join requests for a match (creator only).</summary>
    Task<List<MatchPlayerDto>> GetJoinRequestsAsync(int userId, int matchId);

    /// <summary>Creator approves/rejects a pending join request.</summary>
    Task<MatchDto> RespondToJoinRequestAsync(
        int userId, int matchId, int targetUserId, bool approve);

    /// <summary>Lists matches the current user created or joined (latest kick-off
    /// first). <paramref name="activeOnly"/> drops completed and cancelled ones,
    /// <paramref name="matchesOnly"/> drops americano/tournament events, and
    /// <paramref name="newestFirst"/> orders by creation instead.</summary>
    Task<PagedResult<MatchDto>> GetMyMatchesAsync(
        int userId, int page, int pageSize, string? status, bool activeOnly = false,
        bool matchesOnly = false, bool newestFirst = false, bool finishedOnly = false);

    /// <summary>
    /// The current user's approved matches that are about to start — from 30
    /// minutes before kick-off until the match ends. Drives the "upcoming
    /// match" card on the home page.
    /// </summary>
    Task<List<MatchDto>> GetUpcomingAsync(int userId);

    /// <summary>Records a match's final score + peer ratings and completes it.</summary>
    Task<MatchDto> SubmitResultAsync(int userId, int matchId, SubmitMatchResultRequest req);
    Task<MatchDto> RespondResultAsync(int userId, int matchId, RespondResultRequest req);
    Task<MatchDto> ResolveResultAsync(int userId, int matchId, ResolveResultRequest req);

    /// <summary>
    /// حذف نهائي من لوحة التحكم: تُعاد الحصص المحجوزة إلى محافظ أصحابها،
    /// ويُخطر اللاعبون، ثم يُمحى صفّ المباراة بلاعبيه وتقييماته.
    /// </summary>
    Task DeleteAsync(int matchId, string reasonAr);

    /// <summary>
    /// يلغي المباريات التي حلّ موعدها وهي غير مكتملة (مفتوحة أو تنتظر موافقة
    /// صاحب الملعب) ويعيد ما هو محجوز من حصص. يُرجِع عدد ما أُلغي.
    /// </summary>
    /// <summary>
    /// يلغي الأحداث غير المكتملة التي بقي على موعدها أقل من المهلة، ويردّ ما
    /// دُفع. مهلة صفر = تنظيف ما فات موعده فقط.
    /// </summary>
    /// <summary>يعيد لكل من دفع ما خرج من محفظته ويسترد من صاحب الملعب ما وصله
    /// (تستعمله خدمات أخرى عند إلغاء حدث يقوم على Match).</summary>
    Task RefundAllPaidAsync(Models.Match match, string reason);

    Task<int> CancelIncompleteBeforeStartAsync(
        TimeSpan lead, CancellationToken ct = default);
}
