using SportaApis.DTOs;
using SportaApis.Models;
using SportaApis.Services;

namespace SportaApis.Helpers;

/// <summary>
/// تحويل دوام الملعب وقواعد تسعيره بين الموديل والـ DTO — في مكان واحد حتى
/// يرى تطبيق المالك واللاعب ولوحة التحكم الشكل نفسه.
/// </summary>
public static class CourtScheduleMapper
{
    /// <summary>
    /// دوام الأسبوع كاملاً: سبعة صفوف دائماً (الأحد → السبت)، تُملأ الأيام غير
    /// المحددة بالدوام الافتراضي حتى لا تتعامل الواجهات مع قوائم ناقصة.
    /// </summary>
    public static List<CourtOpeningHourInput> OpeningHourDtos(Court court) =>
        CourtSchedule.AllDays.Select(day =>
        {
            var (open, close, closed) = CourtSchedule.HoursFor(court, day);
            return new CourtOpeningHourInput
            {
                Day = (int)day,
                IsClosed = closed,
                OpenHour = closed ? CourtSchedule.DefaultOpenHour : open,
                CloseHour = closed ? CourtSchedule.DefaultCloseHour : close,
            };
        }).ToList();

    public static List<CourtPriceRuleInput> PriceRuleDtos(Court court) =>
        court.PriceRules
            .OrderBy(r => r.Day is null ? -1 : (int)r.Day.Value)
            .ThenBy(r => r.StartHour)
            .Select(r => new CourtPriceRuleInput
            {
                Day = r.Day is null ? null : (int)r.Day,
                StartHour = r.StartHour,
                EndHour = r.EndHour,
                AdjustmentPercent = r.AdjustmentPercent,
                HourlyPrice = r.HourlyPrice,
            })
            .ToList();

    /// <summary>
    /// يبني صفوف الدوام من المُدخل بعد ضبط قيمها. الصف غير المتّسق (إغلاق عند
    /// الفتح أو قبله — ومنه الدوام العابر لمنتصف الليل غير المدعوم) يُرفض بخطأ
    /// واضح بدل حفظه يوماً مغلقاً بصمت. الحذف والاستبدال مسؤولية المُستدعي حتى
    /// يبقى هذا المساعد بلا اعتماد على الـ DbContext.
    /// </summary>
    public static List<CourtOpeningHour> BuildOpeningHours(
        Court court, IEnumerable<CourtOpeningHourInput> input) =>
        input
            .Where(r => r.Day is >= 0 and <= 6)
            .DistinctBy(r => r.Day)
            .Select(row =>
            {
                var open = Math.Clamp(row.OpenHour, 0, 23);
                var close = Math.Clamp(row.CloseHour, 1, 24);
                var closed = row.IsClosed;
                if (!closed && close <= open)
                    throw new AuthException(
                        "Closing time must be after opening time",
                        "وقت الإغلاق يجب أن يكون بعد وقت الفتح", "OPENING_HOURS_INVALID");

                return new CourtOpeningHour
                {
                    CourtId = court.Id,
                    Day = (DayOfWeek)row.Day,
                    IsClosed = closed,
                    OpenHour = closed ? CourtSchedule.DefaultOpenHour : open,
                    CloseHour = closed ? CourtSchedule.DefaultCloseHour : close,
                };
            })
            .ToList();

    /// <summary>يبني قواعد التسعير من المُدخل، متجاهلاً النطاقات الفارغة.</summary>
    public static List<CourtPriceRule> BuildPriceRules(
        Court court, IEnumerable<CourtPriceRuleInput> input) =>
        input
            .Where(r => r.Day is null or (>= 0 and <= 6))
            .Select(row => new
            {
                Row = row,
                Start = Math.Clamp(row.StartHour, 0, 23),
                End = Math.Clamp(row.EndHour, 1, 24),
            })
            .Where(x => x.End > x.Start)
            .Select(x => new CourtPriceRule
            {
                CourtId = court.Id,
                Day = x.Row.Day is null ? null : (DayOfWeek)x.Row.Day.Value,
                StartHour = x.Start,
                EndHour = x.End,
                AdjustmentPercent = x.Row.HourlyPrice is > 0
                    ? 0m
                    : Math.Clamp(x.Row.AdjustmentPercent, -90m, 500m),
                HourlyPrice = x.Row.HourlyPrice is > 0 ? Math.Round(x.Row.HourlyPrice.Value, 2) : null,
            })
            .ToList();

    /// <summary>
    /// أول تداخل بين نطاقين لنفس اليوم (أو كلاهما «كل الأيام»)، أو null. نطاق
    /// يوم محدد فوق «كل الأيام» ليس تداخلاً — اليوم المحدد يسبق عن قصد.
    /// </summary>
    public static string? FindOverlap(IEnumerable<CourtPriceRule> rules)
    {
        var list = rules.ToList();
        for (var i = 0; i < list.Count; i++)
            for (var j = i + 1; j < list.Count; j++)
            {
                var a = list[i];
                var b = list[j];
                if (a.Day != b.Day) continue;
                if (a.StartHour < b.EndHour && b.StartHour < a.EndHour)
                    return $"{a.StartHour:00}:00–{a.EndHour:00}:00 / {b.StartHour:00}:00–{b.EndHour:00}:00";
            }
        return null;
    }
}
