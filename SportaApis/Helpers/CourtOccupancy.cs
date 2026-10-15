using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.Enums;

namespace SportaApis.Helpers;

/// <summary>
/// انشغال الملعب في وقت معيّن. الملعب الواحد قد يُشغل بحجز عادي
/// (<see cref="Models.Booking"/>)، أو بمباراة/أمريكانو/بطولة
/// (<see cref="Models.Match"/> — لا تُنشئ حجزاً)، أو بجلسة تدريب
/// (<see cref="Models.CoachSession"/>)، وكلها جداول منفصلة. هذا هو المصدر
/// الوحيد لحساب الانشغال حتى تتفق قائمة المواعيد المتاحة مع رفض التعارض عند
/// الإنشاء، فلا يُعرض موعد كمتاح ثم يُرفض (أو أسوأ: يُقبل مرتين).
/// </summary>
public static class CourtOccupancy
{
    /// <summary>
    /// أطول مدة نتوقعها لحجز/مباراة/جلسة — تُستعمل فقط لتضييق الاستعلام على
    /// البداية، ثم تُحسب النهاية في الذاكرة (أدق من ترجمة AddMinutes للـ SQL).
    /// </summary>
    private static readonly TimeSpan MaxSlotLength = TimeSpan.FromHours(24);

    /// <summary>الفترات المشغولة على الملعب والمتقاطعة مع [<paramref name="from"/>, <paramref name="to"/>).</summary>
    public static async Task<List<(DateTime Start, DateTime End)>> ForCourtAsync(
        AppDbContext db, int courtId, DateTime from, DateTime to, int? excludeMatchId = null) =>
        (await ForCourtsAsync(db, [courtId], from, to, excludeMatchId))[courtId];

    /// <summary>
    /// <see cref="ForCourtAsync"/> لعدة ملاعب دفعة واحدة — نفس القواعد بعدد ثابت
    /// من الاستعلامات مهما كثرت الملاعب (بحث الملاعب بالوقت يفحص مدينة كاملة).
    /// كل معرّف مطلوب له مدخل في القاموس ولو كانت قائمته فارغة.
    /// </summary>
    public static async Task<Dictionary<int, List<(DateTime Start, DateTime End)>>> ForCourtsAsync(
        AppDbContext db, IEnumerable<int> courtIds, DateTime from, DateTime to,
        int? excludeMatchId = null)
    {
        var result = courtIds.Distinct()
            .ToDictionary(id => id, _ => new List<(DateTime Start, DateTime End)>());
        if (result.Count == 0) return result;
        var ids = result.Keys.ToList();

        // كل استعلام يجلب ما يبدأ قبل نهاية النافذة وبعد بدايتها بمقدار أطول
        // مدة ممكنة، ثم نصفّي بالتقاطع الحقيقي بعد حساب النهاية.
        var earliestStart = from - MaxSlotLength;
        var fromDay = from.Date;

        // البطولة (أمريكانو بـ EndDate) تمتد أياماً وتشغل الملعب في نفس الوقت
        // من كل يوم، فتُعالَج على حدة لأن يوم بدايتها قد يسبق النافذة بكثير.
        // البطولة الإقصائية قد تشغل ملاعب إضافية (TournamentCourts) في النافذة
        // نفسها، فتُحتسب على كل ملعب منها كما على الرئيسي — ولو كانت يوماً
        // واحداً، فالملعب الإضافي ليس CourtId المباراة فلا يلتقطه استعلامها.
        var previousDay = fromDay.AddDays(-1);
        var tournaments = await db.AmericanoMatches
            .Where(a => (a.EndDate != null
                            ? (a.Match.CourtId != null && ids.Contains(a.Match.CourtId.Value))
                              || a.Courts.Any(c => ids.Contains(c.CourtId))
                            : a.Courts.Any(c => ids.Contains(c.CourtId) && c.CourtId != a.Match.CourtId))
                        && a.Match.Status != MatchStatus.Cancelled
                        && a.MatchId != excludeMatchId
                        && a.Match.ScheduledAt < to
                        && (a.EndDate ?? a.Match.ScheduledAt) >= previousDay)
            .Select(a => new
            {
                a.MatchId,
                a.Match.ScheduledAt,
                a.Match.DurationMinutes,
                a.EndDate,
                MainCourtId = a.Match.CourtId,
                ExtraCourtIds = a.Courts.Select(c => c.CourtId).ToList(),
            })
            .ToListAsync();

        // المباراة الرئيسية للبطولة متعددة الأيام تُحسب من حلقة الأيام أدناه لا
        // من استعلام المباريات. بطولة اليوم الواحد تبقى في استعلام المباريات
        // لملعبها الرئيسي، والحلقة لا تضيفها إلا لملاعبها الإضافية.
        var multiDayIds = tournaments
            .Where(t => t.EndDate != null)
            .Select(t => t.MatchId)
            .ToList();

        var bookings = await db.Bookings
            .Where(b => ids.Contains(b.CourtId)
                        && b.Status != BookingStatus.Cancelled
                        && b.StartTime < to
                        && b.EndTime > from)
            .Select(b => new { b.CourtId, b.StartTime, b.EndTime })
            .ToListAsync();

        var matches = await db.Matches
            .Where(m => m.CourtId != null && ids.Contains(m.CourtId.Value)
                        && m.Status != MatchStatus.Cancelled
                        && m.Id != excludeMatchId
                        && m.ScheduledAt < to
                        && m.ScheduledAt > earliestStart
                        && !multiDayIds.Contains(m.Id))
            .Select(m => new { CourtId = m.CourtId!.Value, m.ScheduledAt, m.DurationMinutes })
            .ToListAsync();

        // الجلسة المرفوضة وحدها هي التي تُحرّر الملعب؛ المعلّقة محجوزة فعلياً
        // بانتظار ردّ المدرب.
        var sessions = await db.CoachSessions
            .Where(s => s.CourtId != null && ids.Contains(s.CourtId.Value)
                        && s.Status != CoachSessionStatus.Rejected
                        && s.ScheduledAt < to
                        && s.ScheduledAt > earliestStart)
            .Select(s => new { CourtId = s.CourtId!.Value, s.ScheduledAt, s.DurationMinutes })
            .ToListAsync();

        foreach (var b in bookings)
            result[b.CourtId].Add((b.StartTime, b.EndTime));
        foreach (var m in matches)
            result[m.CourtId].Add((m.ScheduledAt, m.ScheduledAt.AddMinutes(m.DurationMinutes)));
        foreach (var s in sessions)
            result[s.CourtId].Add((s.ScheduledAt, s.ScheduledAt.AddMinutes(s.DurationMinutes)));

        // يوم واحد لكل يوم بطولة، بدءاً من اليوم السابق للنافذة (موعد ليلي قد
        // يمتد إليها) وحتى آخر يوم فيها.
        foreach (var t in tournaments)
        {
            // متعددة الأيام: الرئيسي والإضافية. يوم واحد: الإضافية فقط (الرئيسي
            // جاء من استعلام المباريات).
            var targets = t.ExtraCourtIds.ToHashSet();
            if (t.EndDate != null && t.MainCourtId is int main) targets.Add(main);
            else if (t.MainCourtId is int single) targets.Remove(single);
            targets.IntersectWith(ids);
            if (targets.Count == 0) continue;

            var firstDay = t.ScheduledAt.Date;
            var floor = fromDay.AddDays(-1);
            var lastDay = (t.EndDate ?? t.ScheduledAt).Date;

            for (var day = firstDay < floor ? floor : firstDay;
                 day <= lastDay && day <= to;
                 day = day.AddDays(1))
            {
                var start = day.Add(t.ScheduledAt.TimeOfDay);
                foreach (var courtId in targets)
                    result[courtId].Add((start, start.AddMinutes(t.DurationMinutes)));
            }
        }

        foreach (var id in ids)
            result[id] = [.. result[id].Where(r => r.Start < to && r.End > from)];
        return result;
    }

    /// <summary>هل الملعب مشغول في [<paramref name="start"/>, <paramref name="end"/>)؟</summary>
    public static async Task<bool> IsTakenAsync(
        AppDbContext db, int courtId, DateTime start, DateTime end) =>
        (await ForCourtAsync(db, courtId, start, end)).Count > 0;

    /// <summary>هل تتقاطع الفترة مع أي فترة مشغولة سبق جلبها؟</summary>
    public static bool Overlaps(
        IEnumerable<(DateTime Start, DateTime End)> ranges, DateTime start, DateTime end) =>
        ranges.Any(r => start < r.End && end > r.Start);
}
