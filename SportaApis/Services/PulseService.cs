using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;

namespace SportaApis.Services;

/// <summary>
/// يبني "نبض المجتمع الرياضي" باشتقاق الأحداث من الجداول الموجودة (بلا جدول سجلّ)،
/// على غرار <see cref="FeedService"/> — الفرق أن هذا على مستوى المجتمع كله بينما
/// الـ feed مقصور على من يتابعهم المستخدم.
/// </summary>
public class PulseService : IPulseService
{
    /// <summary>الحد الأقصى للبنود المعادة، والحد الأقصى لكل مصدر قبل الدمج.</summary>
    private const int MaxItems = 12;
    private const int PerSource = 5;

    /// <summary>أقصى بُعد لموعد مباراة تظهر في النبض كباحثة عن لاعبين.</summary>
    private const int SeekingHorizonDays = 14;

    private readonly AppDbContext _db;

    public PulseService(AppDbContext db) => _db = db;

    public async Task<List<PulseItemDto>> GetPulseAsync(int currentUserId)
    {
        var now = AppClock.Now;

        // CreatedAt يُخزَّن UTC بينما ScheduledAt وقت محلي ساذج، فبداية "اليوم"
        // المحلي تُحوَّل إلى UTC قبل مقارنتها بـ CreatedAt.
        var todayStartUtc = now.Date.AddHours(-AppClock.OffsetHours);

        // أحداث "ماضية" تُرتَّب بالأحدث، بينما المباريات الباحثة عن لاعبين تُقدَّم
        // عليها لأنها الوحيدة القابلة للتنفيذ ووقتها يمضي.
        var activity = new List<PulseItemDto>();
        var seekingItems = new List<PulseItemDto>();

        // ── لاعبون حدّدوا مستواهم ─────────────────────────────────────────────
        var assessments = await _db.LevelAssessments
            .Include(a => a.PlayerProfile).ThenInclude(p => p.User)
            .Where(a => a.IsCompleted &&
                        a.AssignedLevel != null &&
                        a.PlayerProfile.UserId != currentUserId &&
                        !a.PlayerProfile.User.IsDeleted)
            .OrderByDescending(a => a.CreatedAt)
            .Take(PerSource)
            .ToListAsync();

        foreach (var a in assessments)
        {
            var level = (int)a.AssignedLevel!.Value;
            var name = FullName(a.PlayerProfile.User);
            activity.Add(new PulseItemDto
            {
                ActorId = a.PlayerProfile.UserId,
                ActorName = name,
                Type = "level",
                Text = $"{name} وصل لمستوى {level}",
                Level = level,
                Highlight = level.ToString(),
                CreatedAt = AsUtc(a.CreatedAt),
            });
        }

        // ── نقاط مكتسبة اليوم ─────────────────────────────────────────────────
        // Amount > 0 يستبعد الاستبدال والعكس والخصومات الإدارية.
        var earners = await _db.PointsTransactions
            .Where(t => t.CreatedAt >= todayStartUtc &&
                        t.Amount > 0 &&
                        t.UserId != currentUserId &&
                        !t.User.IsDeleted)
            .GroupBy(t => t.UserId)
            .Select(g => new
            {
                UserId = g.Key,
                Total = g.Sum(x => x.Amount),
                LastAt = g.Max(x => x.CreatedAt),
            })
            .OrderByDescending(x => x.LastAt)
            .Take(PerSource)
            .ToListAsync();

        if (earners.Count > 0)
        {
            var earnerIds = earners.Select(e => e.UserId).ToList();
            var earnerNames = await _db.Users
                .Where(u => earnerIds.Contains(u.Id))
                .ToDictionaryAsync(u => u.Id, FullName);

            foreach (var e in earners)
            {
                var name = earnerNames.GetValueOrDefault(e.UserId, "لاعب");
                activity.Add(new PulseItemDto
                {
                    ActorId = e.UserId,
                    ActorName = name,
                    Type = "points",
                    Text = $"{name} حقق {PointsPhrase(e.Total)} خلال اليوم",
                    Points = e.Total,
                    Highlight = e.Total > 2 ? e.Total.ToString() : null,
                    CreatedAt = AsUtc(e.LastAt),
                });
            }
        }

        // ── مباريات مفتوحة تبحث عن لاعبين ─────────────────────────────────────
        // لا يوجد حقل "يبحث عن شريك" — الحالة مشتقة: مباراة مفتوحة، لم يبدأ وقتها،
        // وعدد المعتمدين فيها أقل من الحد الأقصى.
        var seeking = await _db.Matches
            .Include(m => m.Creator)
            .Where(m => m.Status == MatchStatus.Open &&
                        !m.IsPrivate &&
                        m.AmericanoMatch == null &&
                        m.ScheduledAt > now &&
                        // «يبحث عن شريك» للمواعيد القريبة فقط — مباراة بعد
                        // أشهر كانت تظهر «خلال 224 يوماً».
                        m.ScheduledAt <= now.AddDays(SeekingHorizonDays) &&
                        m.CreatorId != currentUserId &&
                        !m.Creator.IsDeleted &&
                        m.MatchPlayers.Count(p => p.Status == MatchPlayerStatus.Approved)
                            < m.MaxPlayers &&
                        !m.MatchPlayers.Any(p => p.UserId == currentUserId))
            .OrderBy(m => m.ScheduledAt)
            .Take(PerSource)
            .ToListAsync();

        foreach (var m in seeking)
        {
            var name = FullName(m.Creator);
            var (unit, value) = RelativeFuture(m.ScheduledAt, now);
            seekingItems.Add(new PulseItemDto
            {
                ActorId = m.CreatorId,
                ActorName = name,
                Type = "match_seeking",
                Text = $"{name} يبحث عن شريك لمباراة {RelativeFuturePhrase(unit, value)}",
                RelativeUnit = unit,
                RelativeValue = value,
                CreatedAt = AsUtc(m.CreatedAt),
                MatchId = m.Id,
            });
        }

        // المباريات أولاً (الأقرب موعداً، وهو ترتيب الاستعلام)، ثم بقية الأحداث بالأحدث.
        var ordered = seekingItems
            .Concat(activity.OrderByDescending(i => i.CreatedAt))
            .Take(MaxItems - 1)
            .ToList();

        // ── البند المجمّع (يُذيَّل دائماً في آخر القائمة) ──────────────────────
        var levelledToday = await _db.LevelAssessments
            .Where(a => a.IsCompleted &&
                        a.AssignedLevel != null &&
                        a.CreatedAt >= todayStartUtc &&
                        !a.PlayerProfile.User.IsDeleted)
            .Select(a => a.PlayerProfileId)
            .Distinct()
            .CountAsync();

        if (levelledToday > 0)
        {
            var lastAt = await _db.LevelAssessments
                .Where(a => a.IsCompleted &&
                            a.AssignedLevel != null &&
                            a.CreatedAt >= todayStartUtc &&
                            !a.PlayerProfile.User.IsDeleted)
                .MaxAsync(a => a.CreatedAt);

            ordered.Add(new PulseItemDto
            {
                Type = "level_summary",
                Text = PlayersSetLevelPhrase(levelledToday),
                Count = levelledToday,
                Highlight = levelledToday > 2 ? levelledToday.ToString() : null,
                CreatedAt = AsUtc(lastAt),
            });
        }

        return ordered;
    }

    private static string FullName(Models.User u) =>
        $"{u.FirstName} {u.LastName}".Trim() is { Length: > 0 } n ? n : "لاعب";

    /// <summary>
    /// القيم مقروءة من MySQL بـ Kind=Unspecified رغم تخزينها UTC، وبدونها يُسلسل
    /// التاريخ بلا علامة منطقة فيقرأه التطبيق كتوقيت محلي ويزيح "منذ..." بثلاث ساعات.
    /// </summary>
    private static DateTime AsUtc(DateTime value) =>
        DateTime.SpecifyKind(value, DateTimeKind.Utc);

    private static string PointsPhrase(int n) => n switch
    {
        1 => "نقطة واحدة",
        2 => "نقطتين",
        <= 10 => $"{n} نقاط",
        _ => $"{n} نقطة",
    };

    private static string PlayersSetLevelPhrase(int n) => n switch
    {
        1 => "لاعب واحد حدّد مستواه اليوم",
        2 => "لاعبان حدّدا مستواهما اليوم",
        <= 10 => $"{n} لاعبين حدّدوا مستواهم اليوم",
        _ => $"{n} لاعباً حدّدوا مستواهم اليوم",
    };

    /// <summary>
    /// قرب الموعد كوحدة + قيمة، ليركّب التطبيق العبارة بلغته. الحساب هنا لأن
    /// <paramref name="now"/> بتوقيت السعودية بينما ساعة الجهاز قد تكون غيره.
    /// </summary>
    private static (string Unit, int? Value) RelativeFuture(DateTime scheduledAt, DateTime now)
    {
        var span = scheduledAt - now;

        if (span.TotalMinutes < 60) return ("soon", null);
        if (span.TotalHours < 24) return ("hours", (int)Math.Round(span.TotalHours));
        return ("days", (int)Math.Round(span.TotalDays));
    }

    /// <summary>صياغة عربية لـ <see cref="RelativeFuture"/> — احتياطي النسخ القديمة.</summary>
    private static string RelativeFuturePhrase(string unit, int? value) => (unit, value) switch
    {
        ("hours", 1) => "بعد ساعة",
        ("hours", 2) => "بعد ساعتين",
        ("hours", <= 10) => $"بعد {value} ساعات",
        ("hours", _) => $"بعد {value} ساعة",
        ("days", 1) => "غداً",
        ("days", 2) => "بعد يومين",
        ("days", <= 10) => $"بعد {value} أيام",
        ("days", _) => $"بعد {value} يوماً",
        _ => "خلال أقل من ساعة",
    };
}
