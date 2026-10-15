using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

/// <summary>
/// انسحاب لاعب معتمد من مباراة/أمريكانو/بطولة.
///
/// <list type="bullet">
/// <item>قبل المهلة (24 ساعة للمباراة، 48 للأمريكانو والبطولة): يخرج مباشرة.</item>
/// <item>بعدها: يصير طلباً ينتظر موافقة المنشئ، ويبقى اللاعب عضواً حتى يُبتّ فيه.</item>
/// <item>كل خروج فعلي يردّ حصة اللاعب كاملة (ويستردّ من مالك الملعب ما وصله
/// منها كما في الإلغاء) ويخصم نقاط مكافآت (<c>points_withdrawal_penalty</c>).</item>
/// <item>من طلبه ما زال معلّقاً يلغيه بلا خصم ولا مهلة — لم يأخذ مقعداً بعد.</item>
/// </list>
///
/// لا انسحاب بعد بدء اللعب فعلاً: نتيجة مُدخلة في المباراة، أو جولة مسجّلة في
/// الأمريكانو، أو قرعة أُجريت في البطولة — خروج لاعب حينها يكسر الجدول.
/// </summary>
public class WithdrawalService : IWithdrawalService
{
    private readonly AppDbContext _db;
    private readonly IWalletService _wallet;
    private readonly IPointsService _points;
    private readonly INotificationService _notifications;
    private readonly IWaitlistService _waitlist;
    private readonly IEventChatService _chat;

    public WithdrawalService(
        AppDbContext db, IWalletService wallet, IPointsService points,
        INotificationService notifications, IWaitlistService waitlist, IEventChatService chat)
    {
        _chat = chat;
        _waitlist = waitlist;
        _db = db;
        _wallet = wallet;
        _points = points;
        _notifications = notifications;
    }

    public async Task<int> MatchIdOfAmericanoAsync(int americanoId) =>
        await _db.AmericanoMatches
            .Where(a => a.Id == americanoId)
            .Select(a => (int?)a.MatchId)
            .FirstOrDefaultAsync()
        ?? throw new AuthException(
            "Americano not found", "الأمريكانو غير موجود", "AMERICANO_NOT_FOUND");

    public async Task<WithdrawalOutcome> WithdrawAsync(int userId, int matchId)
    {
        // الخروج يردّ حصة: يُسلسَل مع الانضمام والقبول والرفض على نفس الحدث،
        // فلا تُردّ الحصة مرتين بنقرتين ولا يتقاطع مع قبول متزامن.
        await using var gate = await MatchLock.AcquireAsync(_db, matchId);
        var match = await LoadAsync(matchId);
        var ev = Describe(match);
        var me = match.MatchPlayers.FirstOrDefault(p => p.UserId == userId)
            ?? throw new AuthException(
                "You are not part of this event", $"لست مشاركاً في {ev.Label}", "NOT_A_MEMBER");

        if (me.Status == MatchPlayerStatus.Invited)
            throw new AuthException(
                "Respond to the invitation instead",
                "لديك دعوة لم تردّ عليها — يمكنك رفضها بدل الانسحاب", "INVITE_PENDING");

        // طلب انضمام لم يُقبل بعد: يُلغى بلا خصم ولا مهلة.
        if (me.Status == MatchPlayerStatus.Pending)
        {
            if (me.HasPaid && match.PricePerPlayer > 0)
                await _wallet.RefundAsync(userId, match.ShareOf(me),
                    $"استرداد حصة {ev.Label} — ألغيت طلب الانضمام", match.Id);
            RemoveWithOrphanInvites(match, me);
            await _db.SaveChangesAsync();
            await gate.ReleaseAsync();
            // حدث ملغى أو منتهٍ لا مقعد فيه يُعرض على أحد.
            if (match.Status is not (MatchStatus.Cancelled or MatchStatus.Completed))
                await _waitlist.ProcessAsync(match.Id);
            return WithdrawalOutcome.RequestCancelled;
        }

        if (userId == match.CreatorId)
            throw new AuthException(
                "The organizer can't withdraw",
                $"أنت منظّم {ev.Label} — لا يمكنك الانسحاب", "CREATOR_CANNOT_WITHDRAW");

        EnsureWithdrawable(match, ev);

        if (me.WithdrawalRequestedAt != null)
            throw new AuthException(
                "Withdrawal already requested",
                "طلب انسحابك بانتظار موافقة المنظّم", "WITHDRAWAL_ALREADY_REQUESTED");

        var name = await UserNameAsync(userId);

        if (WithdrawalPolicy.IsFree(match.ScheduledAt, ev.IsEvent))
        {
            // اللاعب نفسه رأى الخصم في نافذة التأكيد، فلا إشعار خصم له هنا.
            await RemoveMemberAsync(match, me, ev);
            await gate.ReleaseAsync();
            await _notifications.PushAsync(match.CreatorId, $"انسحاب من {ev.Label}",
                $"انسحب {name} من {ev.Label} — أصبح هناك مقعد شاغر",
                $"{ev.Type}_withdrawn", ev.RefId);
            return WithdrawalOutcome.Withdrawn;
        }

        // بعد المهلة: طلب ينتظر المنظّم، واللاعب عضو كامل حتى يُبتّ فيه.
        me.WithdrawalRequestedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        await gate.ReleaseAsync();
        await _notifications.PushAsync(match.CreatorId, "طلب انسحاب",
            $"يطلب {name} الانسحاب من {ev.Label} قبل موعده بأقل من {ev.Hours} ساعة — اقبل الطلب أو ارفضه",
            $"{ev.Type}_withdrawal_request", ev.RefId);
        return WithdrawalOutcome.Requested;
    }

    public async Task RespondAsync(int creatorId, int matchId, int targetUserId, bool approve)
    {
        await using var gate = await MatchLock.AcquireAsync(_db, matchId);
        var match = await LoadAsync(matchId);
        var ev = Describe(match);
        if (match.CreatorId != creatorId)
            throw new AuthException(
                "Only the organizer can respond", "فقط المنظّم يمكنه الرد على طلبات الانسحاب",
                "NOT_OWNER");

        var player = match.MatchPlayers.FirstOrDefault(p =>
                p.UserId == targetUserId
                && p.Status == MatchPlayerStatus.Approved
                && p.WithdrawalRequestedAt != null)
            ?? throw new AuthException(
                "Withdrawal request not found", "طلب الانسحاب غير موجود",
                "WITHDRAWAL_REQUEST_NOT_FOUND");

        if (!approve)
        {
            player.WithdrawalRequestedAt = null;
            await _db.SaveChangesAsync();
            await gate.ReleaseAsync();
            await _notifications.PushAsync(targetUserId, "رُفض طلب انسحابك",
                $"اعتذر المنظّم عن قبول انسحابك — ما زلت مشاركاً في {ev.Label}",
                $"{ev.Type}_withdrawal_rejected", ev.RefId);
            return;
        }

        EnsureWithdrawable(match, ev);
        var deducted = await RemoveMemberAsync(match, player, ev);
        await gate.ReleaseAsync();
        await _notifications.PushAsync(targetUserId, "قُبل طلب انسحابك",
            $"وافق المنظّم على انسحابك من {ev.Label}، وأُعيدت حصتك إلى محفظتك",
            $"{ev.Type}_withdrawal_approved", ev.RefId);
        await NotifyPenaltyAsync(targetUserId, deducted, ev);
    }

    // ── internals ───────────────────────────────────────────────────────────────

    private async Task<Match> LoadAsync(int matchId) =>
        await _db.Matches
            .Include(m => m.MatchPlayers)
            .Include(m => m.Court).ThenInclude(c => c!.Venue)
            .Include(m => m.AmericanoMatch).ThenInclude(a => a!.Rounds)
            .Include(m => m.AmericanoMatch).ThenInclude(a => a!.Fixtures)
            .FirstOrDefaultAsync(m => m.Id == matchId)
        ?? throw new AuthException("Match not found", "المباراة غير موجودة", "MATCH_NOT_FOUND");

    /// <summary>كيف يُسمّى الحدث في الرسائل، ونوع إشعاره ومرجعه في التطبيق.</summary>
    private sealed record EventInfo(
        string Label, string Type, int RefId, bool IsEvent, int Hours);

    private static EventInfo Describe(Match match)
    {
        var a = match.AmericanoMatch;
        if (a == null)
            return new("المباراة", "match", match.Id, false, WithdrawalPolicy.MatchHours);
        var isTournament = a.IsTournament || a.Format != null;
        return isTournament
            ? new("البطولة", "tournament", a.Id, true, WithdrawalPolicy.EventHours)
            : new("الأمريكانو", "americano", a.Id, true, WithdrawalPolicy.EventHours);
    }

    /// <summary>لا انسحاب من حدث ملغى/منتهٍ/بدأ، أو بدأ لعبه فعلاً.</summary>
    private static void EnsureWithdrawable(Match match, EventInfo ev)
    {
        if (match.Status is MatchStatus.Cancelled or MatchStatus.Completed
                or MatchStatus.InProgress
            || match.ScheduledAt <= AppClock.Now)
            throw new AuthException(
                "This event can no longer be left",
                $"لا يمكن الانسحاب من {ev.Label} الآن", "WITHDRAWAL_CLOSED");

        var a = match.AmericanoMatch;
        if (a == null)
        {
            if (match.Team1Score != null || match.ProposedById != null)
                throw new AuthException(
                    "A result was already entered",
                    "أُدخلت نتيجة المباراة — لا يمكن الانسحاب", "WITHDRAWAL_CLOSED");
        }
        else if (a.Format != null)
        {
            if (a.DrawnAt != null || a.Fixtures.Count > 0)
                throw new AuthException(
                    "The draw was already made",
                    "أُجريت قرعة البطولة — لا يمكن الانسحاب الآن", "WITHDRAWAL_CLOSED");
        }
        else if (a.Rounds.Any(r => r.IsCompleted || r.ProposedById != null))
            throw new AuthException(
                "Rounds have started",
                "بدأ تسجيل نتائج الجولات — لا يمكن الانسحاب الآن", "WITHDRAWAL_CLOSED");
    }

    /// <summary>
    /// يُخرج عضواً معتمداً: يردّ حصته (ويستردّ من المستلم ما وصله منها)،
    /// ويفتح مقعده، ويحذف جولات أمريكانو لم تُلعب لتُولَّد من جديد عند اكتمال
    /// العدد، ثم يخصم نقاط الانسحاب. يعيد عدد النقاط المخصومة.
    /// </summary>
    private async Task<int> RemoveMemberAsync(Match match, MatchPlayer player, EventInfo ev)
    {
        if (player.HasPaid && match.PricePerPlayer > 0)
        {
            await _wallet.RefundAsync(player.UserId, match.ShareOf(player),
                $"استرداد حصة {ev.Label} — انسحاب", match.Id);

            // الحصة تُصرف لحظة القبول (لمالك الملعب صافيةً من نسبة سبورتا، أو
            // للمنشئ حين دفع كاملاً) — إلا قبل موافقة الملعب فتبقى محجوزة عندنا.
            // عكس أرباح لا خصم مشروط بالرصيد: ما وصل المستلم يُستردّ دائماً
            // ولو صار رصيده سالباً، وإلا دفعت سبورتا الفرق من حصتها.
            var credited = match.CourtId != null && match.Status != MatchStatus.PendingApproval;
            if (credited)
            {
                if (match.PaymentMode == MatchPaymentMode.FullByCreator)
                    await _wallet.ReverseEarningAsync(match.CreatorId, match.ShareOf(player),
                        WalletTransactionType.CreatorEarning,
                        $"ردّ حصة لاعب انسحب من {ev.Label}", match.Id);
                else if (match.Court != null)
                    await _wallet.ReverseEarningAsync(match.Court.Venue.OwnerId,
                        match.NetOfCommission(match.ShareOf(player)),
                        WalletTransactionType.VenueEarning,
                        $"ردّ حصة لاعب انسحب من {ev.Label}", match.Id);
            }
        }

        RemoveWithOrphanInvites(match, player);

        if (match.Status == MatchStatus.Full) match.Status = MatchStatus.Open;
        match.UpdatedAt = DateTime.UtcNow;

        // جولات وُلّدت عند الاكتمال ولم يُسجَّل فيها شيء: تسقط، وتُولَّد من
        // جديد بالتشكيلة الجديدة حين يكتمل العدد مرة أخرى.
        if (match.AmericanoMatch is { Format: null } a && a.Rounds.Count > 0)
            _db.AmericanoRounds.RemoveRange(a.Rounds);

        await _db.SaveChangesAsync();

        // المنسحب يخرج من الدردشة بخروج صفّه؛ يبقى أثره رسالةَ نظام.
        await _chat.PostMemberEventAsync(match.Id, player.UserId, joined: false);

        // المقعد الذي فرغ يُعرض فوراً على أول من في قائمة الانتظار.
        await _waitlist.ProcessAsync(match.Id);

        return await _points.PenalizeWithdrawalAsync(
            player.UserId, match.Id, $"انسحاب من {ev.Label}");
    }

    /// <summary>
    /// يحذف صفّ اللاعب، ومعه دعوات الشركاء في فريقه إن لم يبقَ فيه عضو غير
    /// مدعوّ (دعوة لفريق بلا صاحب لا معنى لها) — كما عند رفض طلب الانضمام.
    /// </summary>
    private void RemoveWithOrphanInvites(Match match, MatchPlayer player)
    {
        _db.MatchPlayers.Remove(player);
        if (player.Team is not int team) return;
        var teamHasMember = match.MatchPlayers.Any(p =>
            p != player && p.Team == team && p.Status != MatchPlayerStatus.Invited);
        if (teamHasMember) return;
        foreach (var orphan in match.MatchPlayers
                     .Where(p => p != player && p.Team == team
                                 && p.Status == MatchPlayerStatus.Invited)
                     .ToList())
            _db.MatchPlayers.Remove(orphan);
    }

    private async Task NotifyPenaltyAsync(int userId, int deducted, EventInfo ev)
    {
        if (deducted <= 0) return;
        await _notifications.PushAsync(userId, "خصم نقاط",
            $"خُصمت {deducted} نقطة من نقاط مكافآتك بسبب الانسحاب من {ev.Label}",
            "points_withdrawal_penalty", null);
    }

    private async Task<string> UserNameAsync(int userId) =>
        await _db.Users.Where(u => u.Id == userId)
            .Select(u => (u.FirstName + " " + u.LastName).Trim())
            .FirstOrDefaultAsync() ?? "لاعب";
}
