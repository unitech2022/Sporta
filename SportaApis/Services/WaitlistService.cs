using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;
using MatchType = SportaApis.Enums.MatchType;

namespace SportaApis.Services;

/// <summary>
/// قائمة انتظار المقاعد.
///
/// <para><b>المقعد الشاغر</b> = السعة − المعتمدون − طلبات الانضمام المعلّقة:
/// صاحب الطلب المعلّق ينتظر قرار المنشئ على مقعد بعينه، فلا يُعرض مقعده على
/// غيره. حين يزيد الشاغر عن العروض القائمة يُعرض على التالين بالترتيب.</para>
///
/// <para><b>العرض</b> يحجز المقعد لصاحبه <see cref="OfferWindow"/>: غيره لا
/// يستطيع طلب الانضمام عليه (<see cref="EnsureSeatAvailableAsync"/>). إن طلب
/// الانضمام خرج من القائمة وصار طلبه كأي طلب ينتظر المنشئ؛ وإن انتهت المهلة
/// سقط من القائمة وعُرض المقعد على التالي. وإن امتلأ المقعد بطريق آخر (دعوة
/// من المنشئ مثلاً) أُلغي العرض بصمت وعاد صاحبه إلى مكانه في الصف.</para>
///
/// <para>للمباريات والأمريكانو الفردي فقط: في أمريكانو الفرق والبطولة المقعد
/// داخل فريق من لاعبَين، فلا معنى لدور فردي فيه.</para>
/// </summary>
public class WaitlistService : IWaitlistService
{
    /// <summary>مدة حجز المقعد لمن جاء دوره.</summary>
    public static readonly TimeSpan OfferWindow = TimeSpan.FromMinutes(30);

    private readonly AppDbContext _db;
    private readonly INotificationService _notifications;
    private readonly ILogger<WaitlistService> _logger;

    public WaitlistService(
        AppDbContext db, INotificationService notifications, ILogger<WaitlistService> logger)
    {
        _db = db;
        _notifications = notifications;
        _logger = logger;
    }

    // ── للمستخدم ────────────────────────────────────────────────────────────────

    public async Task<WaitlistStatusDto> GetStatusAsync(int userId, int matchId)
    {
        var match = await LoadAsync(matchId);
        var entries = await EntriesAsync(matchId);
        var status = BuildStatus(match, entries, userId);
        // زر التسجيل لا يظهر لمن سيرفضه الخادم (جنس المباراة أو المستوى).
        if (status.CanJoin && await IneligibleReasonAsync(match, userId) != null)
            status.CanJoin = false;
        return status;
    }

    public async Task<WaitlistStatusDto> JoinAsync(int userId, int matchId)
    {
        var match = await LoadAsync(matchId);
        var ev = Describe(match);

        if (!IsSupported(match))
            throw new AuthException(
                "No waitlist for this event",
                "قائمة الانتظار غير متاحة لأمريكانو الفرق والبطولات", "WAITLIST_UNSUPPORTED");
        if (!IsOpen(match))
            throw new AuthException(
                "This event is closed", $"لا يمكن الانتظار على {ev.Label} الآن", "WAITLIST_CLOSED");
        if (match.IsPrivate)
            throw new AuthException(
                "This match is private", "هذه المباراة خاصة — بدعوة من المنظّم فقط",
                "MATCH_PRIVATE");
        if (match.CreatorId == userId)
            throw new AuthException(
                "You are the organizer", $"أنت منظّم {ev.Label}", "WAITLIST_ORGANIZER");
        if (match.MatchPlayers.Any(p => p.UserId == userId))
            throw new AuthException(
                "You are already part of this event",
                $"لك مكان أو طلب أو دعوة في {ev.Label} بالفعل", "ALREADY_JOINED");

        var entries = await EntriesAsync(matchId);
        if (entries.Any(e => e.UserId == userId))
            throw new AuthException(
                "Already on the waitlist", "أنت في قائمة الانتظار بالفعل", "WAITLIST_ALREADY");

        await EnsureEligibleAsync(match, userId);

        if (AvailableFor(match, entries, userId) > 0)
            throw new AuthException(
                "A seat is available — request to join instead",
                "يوجد مقعد متاح — اطلب الانضمام مباشرة", "WAITLIST_NOT_NEEDED");

        _db.MatchWaitlist.Add(new MatchWaitlistEntry { MatchId = matchId, UserId = userId });
        await _db.SaveChangesAsync();
        return BuildStatus(match, await EntriesAsync(matchId), userId);
    }

    public async Task<WaitlistStatusDto> LeaveAsync(int userId, int matchId)
    {
        var entry = await _db.MatchWaitlist
            .FirstOrDefaultAsync(e => e.MatchId == matchId && e.UserId == userId)
            ?? throw new AuthException(
                "Not on the waitlist", "لست في قائمة الانتظار", "WAITLIST_NOT_FOUND");
        var hadOffer = entry.OfferExpiresAt > DateTime.UtcNow;
        _db.MatchWaitlist.Remove(entry);
        await _db.SaveChangesAsync();

        // إشعار تأكيد يبقى في سجل الإشعارات: خرج بنفسه ولن يصله دور.
        var ev = Describe(await LoadAsync(matchId));
        await _notifications.PushAsync(userId, "غادرت قائمة الانتظار",
            hadOffer
                ? $"تنازلت عن المقعد المحجوز لك في {ev.Label} وخرجت من قائمة الانتظار"
                : $"خرجت من قائمة انتظار {ev.Label} — لن يصلك إشعار حين يفرغ مقعد",
            $"{ev.Type}_waitlist_left", ev.RefId);

        // مقعد كان محجوزاً له يُعرض فوراً على التالي.
        if (hadOffer) await ProcessAsync(matchId);
        return await GetStatusAsync(userId, matchId);
    }

    // ── خطافات الانضمام ─────────────────────────────────────────────────────────

    public async Task EnsureSeatAvailableAsync(Match match, int userId)
    {
        if (!IsSupported(match)) return;
        var entries = await EntriesAsync(match.Id);
        if (entries.Count == 0) return;

        var free = FreeSeats(match);
        // لا مقعد شاغر (الطلبات المعلّقة تشغل مقاعدها) وفي القائمة منتظرون:
        // طلبٌ مباشر كان يتخطّاهم إلى الصف. يُوجَّه إلى القائمة ليصله دوره.
        if (free <= 0)
            throw new AuthException(
                "No free seat — join the waitlist",
                entries.Any(e => e.UserId == userId)
                    ? "لا مقعد شاغر الآن وأنت في قائمة الانتظار — يصلك إشعار حين يأتي دورك"
                    : "لا مقعد شاغر الآن وفي قائمة الانتظار من سبقك — سجّل في القائمة ليصلك دورك",
                "WAITLIST_RESERVED");
        if (AvailableFor(match, entries, userId) <= 0)
            throw new AuthException(
                "This seat is reserved for the waitlist",
                entries.Any(e => e.UserId == userId)
                    ? "المقعد الشاغر محجوز لمن قبلك في قائمة الانتظار — يصلك إشعار حين يأتي دورك"
                    : "المقعد الشاغر محجوز لمن ينتظر في قائمة الانتظار — سجّل في القائمة ليصلك دورك",
                "WAITLIST_RESERVED");
    }

    public async Task RemoveEntryAsync(int matchId, int userId)
    {
        var entry = await _db.MatchWaitlist
            .FirstOrDefaultAsync(e => e.MatchId == matchId && e.UserId == userId);
        if (entry == null) return;
        _db.MatchWaitlist.Remove(entry);
        await _db.SaveChangesAsync();
    }

    // ── المعالجة ────────────────────────────────────────────────────────────────

    public async Task ProcessAsync(int matchId)
    {
        try
        {
            await ProcessCoreAsync(matchId);
        }
        catch (Exception ex)
        {
            // القائمة مساعِدة: فشلها لا يُفشل انسحاباً أو رفضاً تمّ فعلاً.
            _logger.LogWarning(ex, "Waitlist processing failed for match {MatchId}", matchId);
        }
    }

    public async Task<int> ProcessAllAsync(CancellationToken ct = default)
    {
        var matchIds = await _db.MatchWaitlist
            .Select(e => e.MatchId)
            .Distinct()
            .ToListAsync(ct);
        foreach (var id in matchIds)
        {
            if (ct.IsCancellationRequested) break;
            await ProcessAsync(id);
        }
        return matchIds.Count;
    }

    private async Task ProcessCoreAsync(int matchId)
    {
        var match = await _db.Matches
            .Include(m => m.MatchPlayers)
            .Include(m => m.AmericanoMatch)
            .FirstOrDefaultAsync(m => m.Id == matchId);
        var entries = await _db.MatchWaitlist
            .Where(e => e.MatchId == matchId)
            .OrderBy(e => e.CreatedAt).ThenBy(e => e.Id)
            .ToListAsync();
        if (entries.Count == 0) return;
        if (match == null)
        {
            _db.MatchWaitlist.RemoveRange(entries);
            await _db.SaveChangesAsync();
            return;
        }

        var ev = Describe(match);
        var pushes = new List<(int UserId, string Title, string Body, string Type)>();

        // حدث بدأ أو أُلغي أو انتهى: تُغلق القائمة ويُبلَّغ من بقي فيها.
        if (!IsSupported(match) || !IsOpen(match))
        {
            foreach (var e in entries)
                pushes.Add((e.UserId, "لم يتوفر مقعد",
                    $"أُغلقت قائمة انتظار {ev.Label} دون أن يفرغ مقعد لك",
                    $"{ev.Type}_waitlist_closed"));
            _db.MatchWaitlist.RemoveRange(entries);
            await _db.SaveChangesAsync();
            await PushAllAsync(pushes, ev.RefId);
            return;
        }

        var now = DateTime.UtcNow;

        // عروض انتهت مهلتها ولم يطلب أصحابها الانضمام: يسقطون من القائمة.
        foreach (var e in entries.Where(e => e.OfferExpiresAt != null && e.OfferExpiresAt <= now).ToList())
        {
            entries.Remove(e);
            _db.MatchWaitlist.Remove(e);
            pushes.Add((e.UserId, "انتهت مهلة المقعد",
                $"لم تطلب الانضمام إلى {ev.Label} خلال المهلة، فانتقل المقعد للتالي في القائمة",
                $"{ev.Type}_waitlist_expired"));
        }

        var free = FreeSeats(match);
        var active = entries.Where(e => e.OfferExpiresAt > now).ToList();

        if (active.Count > free)
        {
            // امتلأ مقعد معروض بطريق آخر: يُلغى أحدث العروض ويعود أصحابها إلى
            // أماكنهم في الصف (ترتيبهم بوقت التسجيل لا يتغيّر).
            foreach (var e in active.Skip(Math.Max(free, 0)))
            {
                e.OfferedAt = null;
                e.OfferExpiresAt = null;
            }
        }
        else
        {
            // لا يتجاوز الحجز موعد الحدث نفسه (الموعد محلي ساذج ← UTC).
            var startsUtc = match.ScheduledAt.AddHours(-AppClock.OffsetHours);
            var expires = now + OfferWindow < startsUtc ? now + OfferWindow : startsUtc;
            foreach (var e in entries.Where(e => e.OfferExpiresAt == null).Take(free - active.Count))
            {
                e.OfferedAt = now;
                e.OfferExpiresAt = expires;
                var minutes = Math.Max(1, (int)Math.Round((expires - now).TotalMinutes));
                pushes.Add((e.UserId, $"فرغ مقعد في {ev.Label}",
                    $"جاء دورك في قائمة الانتظار — المقعد محجوز لك {minutes} دقيقة، اطلب الانضمام الآن",
                    $"{ev.Type}_waitlist_offer"));
            }
        }

        await _db.SaveChangesAsync();
        await PushAllAsync(pushes, ev.RefId);
    }

    // ── مساعدات ─────────────────────────────────────────────────────────────────

    private async Task<Match> LoadAsync(int matchId) =>
        await _db.Matches
            .Include(m => m.MatchPlayers)
            .Include(m => m.AmericanoMatch)
            .FirstOrDefaultAsync(m => m.Id == matchId)
        ?? throw new AuthException("Match not found", "المباراة غير موجودة", "MATCH_NOT_FOUND");

    private Task<List<MatchWaitlistEntry>> EntriesAsync(int matchId) =>
        _db.MatchWaitlist
            .Where(e => e.MatchId == matchId)
            .OrderBy(e => e.CreatedAt).ThenBy(e => e.Id)
            .ToListAsync();

    private static bool IsSupported(Match match) =>
        match.AmericanoMatch is not { } a
        || (a.Format == null && a.AmericanoType != MatchType.AmericanTeam);

    /// <summary>الحدث يقبل لاعبين ولم يبدأ.</summary>
    private static bool IsOpen(Match match) =>
        match.Status is MatchStatus.Open or MatchStatus.Full
        && match.ScheduledAt > AppClock.Now
        && match.AmericanoMatch?.IsCompleted != true;

    /// <summary>السعة − المعتمدون − طلبات الانضمام المعلّقة.</summary>
    private static int FreeSeats(Match match) =>
        match.MaxPlayers - match.MatchPlayers.Count(p =>
            p.Status is MatchPlayerStatus.Approved or MatchPlayerStatus.Pending);

    /// <summary>المقاعد المتاحة لهذا المستخدم بعد طرح المحجوز لغيره.</summary>
    private static int AvailableFor(Match match, IEnumerable<MatchWaitlistEntry> entries, int userId)
    {
        var now = DateTime.UtcNow;
        var reservedForOthers = entries.Count(e => e.UserId != userId && e.OfferExpiresAt > now);
        var mine = entries.Any(e => e.UserId == userId && e.OfferExpiresAt > now);
        // من حُجز له مقعد له أن يأخذه ما دام في الحدث مقعد شاغر.
        return mine ? FreeSeats(match) : FreeSeats(match) - reservedForOthers;
    }

    private WaitlistStatusDto BuildStatus(Match match, List<MatchWaitlistEntry> entries, int userId)
    {
        var now = DateTime.UtcNow;
        var index = entries.FindIndex(e => e.UserId == userId);
        var mine = index >= 0 ? entries[index] : null;
        var supported = IsSupported(match);
        var open = supported && IsOpen(match);
        var involved = match.MatchPlayers.Any(p => p.UserId == userId) || match.CreatorId == userId;
        var free = FreeSeats(match);
        var available = AvailableFor(match, entries, userId);
        var offerActive = mine?.OfferExpiresAt > now;

        return new WaitlistStatusDto
        {
            Supported = supported,
            IsOpen = open,
            Count = entries.Count,
            Position = mine == null ? null : index + 1,
            OfferActive = offerActive,
            OfferMinutesLeft = offerActive
                ? Math.Max(1, (int)Math.Ceiling((mine!.OfferExpiresAt!.Value - now).TotalMinutes))
                : null,
            SeatReservedForOthers = !offerActive && free > 0 && available <= 0,
            CanJoin = open && userId != 0 && !involved && mine == null && available <= 0,
            OfferWindowMinutes = (int)OfferWindow.TotalMinutes,
        };
    }

    private async Task EnsureEligibleAsync(Match match, int userId)
    {
        if (await IneligibleReasonAsync(match, userId) is { } reason) throw reason;
    }

    /// <summary>نفس شروط الانضمام: الجنس (للمباراة) والمستوى. null = مؤهل.</summary>
    private async Task<AuthException?> IneligibleReasonAsync(Match match, int userId)
    {
        var user = await _db.Users
            .Where(u => u.Id == userId)
            .Select(u => new
            {
                u.Gender,
                Level = u.PlayerProfile != null ? (int?)u.PlayerProfile.Level : null,
            })
            .FirstOrDefaultAsync();
        if (user == null) return null;

        if (match.AmericanoMatch == null && user.Gender != null && user.Gender != match.Gender)
            return new AuthException(
                "Gender not allowed",
                match.Gender == Gender.Female
                    ? "هذه المباراة مخصصة للنساء فقط"
                    : "هذه المباراة مخصصة للرجال فقط",
                "GENDER_NOT_ALLOWED");

        var (min, max) = match.AmericanoMatch is { } a
            ? (a.MinAllowedLevel, a.MaxAllowedLevel)
            : (match.MinLevel, match.MaxLevel);
        if (user.Level is int lvl && (lvl < min || lvl > max))
            return new AuthException(
                "Your level is outside the allowed range",
                $"مستواك ({lvl}) خارج النطاق المسموح ({min:0.##} - {max:0.##})",
                "LEVEL_NOT_ALLOWED");
        return null;
    }

    private sealed record EventInfo(string Label, string Type, int RefId);

    private static EventInfo Describe(Match match) => match.AmericanoMatch is { } a
        ? new(a.IsTournament ? "البطولة" : "الأمريكانو",
              a.IsTournament ? "tournament" : "americano", a.Id)
        : new("المباراة", "match", match.Id);

    private async Task PushAllAsync(
        List<(int UserId, string Title, string Body, string Type)> pushes, int refId)
    {
        foreach (var p in pushes)
            await _notifications.PushAsync(p.UserId, p.Title, p.Body, p.Type, refId);
    }
}
