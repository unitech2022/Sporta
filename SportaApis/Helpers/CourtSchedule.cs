using SportaApis.Enums;
using SportaApis.Models;

namespace SportaApis.Helpers;

/// <summary>
/// Shared opening-hours and pricing rules for courts, so that the courts list,
/// availability and booking flows all agree on slots and prices.
///
/// كل ملعب يستطيع تحديد دوامه لكل يوم من أيام الأسبوع
/// (<see cref="CourtOpeningHour"/>) وقواعد تسعير حسب اليوم والوقت
/// (<see cref="CourtPriceRule"/>). الملاعب التي لم تحدد شيئاً تعمل بالسلوك
/// القديم: دوام ثابت 6 صباحاً–12 ليلاً، وسعر ذروة ×1.5 بعد الرابعة عصراً.
/// </summary>
public static class CourtSchedule
{
    /// <summary>First bookable hour of the day (inclusive) when the owner set no schedule.</summary>
    public const int DefaultOpenHour = 6;

    /// <summary>Closing hour (exclusive) when the owner set no schedule — last slot ends at 24:00.</summary>
    public const int DefaultCloseHour = 24;

    /// <summary>Legacy peak pricing applies from this hour onwards.</summary>
    public const int PeakStartHour = 16;

    /// <summary>Legacy peak hours cost 1.5× the base rate.</summary>
    public const decimal PeakMultiplier = 1.5m;

    /// <summary>
    /// أقصى طول لمدى يشغل الملعب في نفس الموعد من كل يوم (البطولة): الفحص
    /// والتسعير وقائمة المواعيد المتاحة تتبعه كلها، ولا تُنشأ بطولة أطول منه
    /// حتى لا يُسعَّر أو يُفحص مدىً مبتوراً.
    /// </summary>
    public const int MaxMultiDayRangeDays = 30;

    // ── دوام الأسبوع ─────────────────────────────────────────────────────────

    /// <summary>True when the owner defined a weekly schedule for this court.</summary>
    public static bool HasWeeklySchedule(Court court) => court.OpeningHours.Count > 0;

    /// <summary>دوام يوم بعينه: الفتح والإغلاق وهل هو مغلق كلياً.</summary>
    public static (int Open, int Close, bool Closed) HoursFor(Court court, DayOfWeek day)
    {
        var row = court.OpeningHours.FirstOrDefault(h => h.Day == day);
        if (row is null) return (DefaultOpenHour, DefaultCloseHour, false);
        if (row.IsClosed || row.CloseHour <= row.OpenHour) return (0, 0, true);
        return (row.OpenHour, row.CloseHour, false);
    }

    /// <summary>دوام تاريخ بعينه.</summary>
    public static (int Open, int Close, bool Closed) HoursOn(Court court, DateTime date) =>
        HoursFor(court, date.DayOfWeek);

    /// <summary>هل النادي مغلق في هذا اليوم؟</summary>
    public static bool IsClosedOn(Court court, DateTime date) => HoursOn(court, date).Closed;

    /// <summary>
    /// هل يقع الحجز كاملاً داخل دوام يومه؟ الحجوزات التي تتخطى ساعة الإغلاق
    /// مرفوضة، وكذلك أي حجز في يوم مغلق.
    /// </summary>
    public static bool IsWithinOpeningHours(Court court, DateTime start, int durationMinutes)
    {
        var (open, close, closed) = HoursOn(court, start);
        if (closed) return false;

        var startMinute = start.Hour * 60 + start.Minute;
        return startMinute >= open * 60 && startMinute + durationMinutes <= close * 60;
    }

    /// <summary>
    /// ساعات اليوم التي يلمسها حجز يبدأ في <paramref name="start"/> — 60 دقيقة
    /// من 10:30 تلمس 10 و11. مصدر واحد لقائمة المواعيد ورفض الساعات المحجوبة.
    /// </summary>
    public static List<int> CoveredHours(DateTime start, int durationMinutes)
    {
        var startMinute = start.Hour * 60 + start.Minute;
        var first = startMinute / 60;
        var last = (startMinute + Math.Max(1, durationMinutes) - 1) / 60;
        return Enumerable.Range(first, last - first + 1).ToList();
    }

    /// <summary>Opening slot start times for a given day, e.g. "06:00".</summary>
    public static List<string> OpeningSlots(Court court, DayOfWeek day)
    {
        var (open, close, closed) = HoursFor(court, day);
        if (closed) return [];
        return Enumerable.Range(open, Math.Max(0, close - open))
            .Select(h => $"{h:D2}:00")
            .ToList();
    }

    /// <summary>
    /// كل ساعات الفتح الممكنة خلال الأسبوع مجتمعة — للعرض المختصر في بطاقة
    /// الملعب حيث لا يوجد يوم محدد بعد.
    /// </summary>
    public static List<string> OpeningSlots(Court court)
    {
        if (!HasWeeklySchedule(court)) return DefaultOpeningSlots();

        var hours = new SortedSet<int>();
        foreach (var day in AllDays)
        {
            var (open, close, closed) = HoursFor(court, day);
            if (closed) continue;
            for (var h = open; h < close; h++) hours.Add(h);
        }
        return hours.Select(h => $"{h:D2}:00").ToList();
    }

    /// <summary>The global default opening slots (6:00 … 23:00).</summary>
    public static List<string> DefaultOpeningSlots() =>
        Enumerable.Range(DefaultOpenHour, DefaultCloseHour - DefaultOpenHour)
            .Select(h => $"{h:D2}:00")
            .ToList();

    public static readonly DayOfWeek[] AllDays =
    [
        DayOfWeek.Sunday, DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Wednesday,
        DayOfWeek.Thursday, DayOfWeek.Friday, DayOfWeek.Saturday,
    ];

    // ── التسعير ──────────────────────────────────────────────────────────────

    public static bool IsPeak(int hour) => hour >= PeakStartHour;

    /// <summary>True when the owner defined day/time price rules for this court.</summary>
    public static bool HasPriceRules(Court court) => court.PriceRules.Count > 0;

    /// <summary>
    /// القاعدة التي تغطي ساعة في يوم: القاعدة الخاصة بيوم محدد تسبق القاعدة
    /// العامة لكل الأيام، ولا شيء يعني السعر الأساسي.
    /// </summary>
    public static CourtPriceRule? RuleAt(Court court, DayOfWeek day, int hour)
    {
        bool Covers(CourtPriceRule r) => hour >= r.StartHour && hour < r.EndHour;
        return court.PriceRules.FirstOrDefault(r => r.Day == day && Covers(r))
            ?? court.PriceRules.FirstOrDefault(r => r.Day is null && Covers(r));
    }

    /// <summary>سعر ساعة القاعدة: سعرها الثابت، أو الأساسي معدَّلاً بنسبتها.</summary>
    public static decimal RuleRate(Court court, CourtPriceRule rule) =>
        rule.HourlyPrice is > 0
            ? rule.HourlyPrice.Value
            : Math.Round(BasePrice(court) * (100m + rule.AdjustmentPercent) / 100m, 2);

    /// <summary>
    /// سعر ساعة المالك في لحظة بعينها بعد قواعده: سعر النطاق الثابت إن وُجد،
    /// وإلا السعر الأساسي معدَّلاً بنسبة النطاق.
    /// </summary>
    public static decimal HourlyRateAt(Court court, DateTime at)
    {
        var rule = HasPriceRules(court) ? RuleAt(court, at.DayOfWeek, at.Hour) : null;
        return rule is null ? HourlyRateBefore(court, at.Hour) : RuleRate(court, rule);
    }

    /// <summary>
    /// هل هذا الموعد أغلى من السعر الأساسي؟ (لتمييزه في واجهة اللاعب).
    /// يتبع ما يُحاسَب به فعلاً في <see cref="BaseBookingPrice"/>: الملعب المسعَّر
    /// بشرائح مدد بلا قواعد لا تُطبَّق عليه ذروة الـ16:00 القديمة، فلا يُعلَّم بها —
    /// كان يُعلَّم ذروةً بسعر عادي فيتناقض الرأس («ذروة 189») مع الموعد (126).
    /// </summary>
    public static bool IsPeakSlot(Court court, DateTime start) =>
        HasPriceRules(court)
            ? HourlyRateAt(court, start) > BasePrice(court)
            : !HasTiers(court, CourtPriceKind.Booking) && IsPeak(start.Hour);

    /// <summary>
    /// نسبة سبورتا — the platform's cut of a booking. It is **added on top of
    /// the owner's price**: the owner always receives exactly the price they
    /// set, and the player pays that price plus this commission.
    /// </summary>
    public static decimal CommissionOn(Court court, decimal price) =>
        Math.Round(price * court.SportaCommissionPercent / 100m, 2);

    /// <summary>ما يدفعه اللاعب: سعر المالك + نسبة سبورتا فوقه.</summary>
    public static decimal WithCommission(Court court, decimal ownerPrice) =>
        ownerPrice + CommissionOn(court, ownerPrice);

    /// <summary>Owner-set base hourly rate — also what the player pays.</summary>
    public static decimal BasePrice(Court court) =>
        court.PricePerHour > 0 ? court.PricePerHour : HourlyFromTiers(court);

    /// <summary>
    /// سعر ساعة مشتقّ من شرائح المالك حين لا يضبط سعر ساعة أصلاً. بدونه كان أي
    /// موعد بمدة لا شريحة لها (١٨٠ أو ٢٤٠ دقيقة مثلاً) يُسعَّر بصفر على الملاعب
    /// المسعَّرة بالمدد وحدها. تُعتمد أطول شريحة لأنها أقرب تعبير عن سعر الساعة.
    /// </summary>
    private static decimal HourlyFromTiers(Court court)
    {
        var tier = court.PriceTiers
            .Where(t => t.Kind == CourtPriceKind.Booking
                        && t.DurationMinutes > 0 && t.Price > 0)
            .OrderByDescending(t => t.DurationMinutes)
            .FirstOrDefault();
        return tier is null
            ? 0m
            : Math.Round(tier.Price * 60m / tier.DurationMinutes, 2);
    }

    /// <summary>
    /// سعر ساعة الذروة القديم — يُستعمل فقط للملاعب التي لم تحدّد شرائح ولا قواعد.
    /// يُبنى على <see cref="BasePrice"/> لا على <c>PricePerHour</c> مباشرة، وإلا
    /// حُسب ملعبٌ مسعَّر بالشرائح وحدها بصفر.
    /// </summary>
    public static decimal PeakPrice(Court court) =>
        Math.Round(BasePrice(court) * PeakMultiplier, 2);

    /// <summary>
    /// أعلى سعر ساعة يدفعه اللاعب فعلاً: أعلى زيادة في قواعد المالك حين توجد
    /// قواعد، وإلا قاعدة الذروة القديمة. كان العرض يستخدم القديمة دائماً فيظهر
    /// للاعب سعر ذروة يخالف المخصوم.
    /// </summary>
    public static decimal EffectivePeakPrice(Court court)
    {
        if (!HasPriceRules(court))
            // الشرائح بلا قواعد = لا ذروة (انظر IsPeakSlot).
            return HasTiers(court, CourtPriceKind.Booking) ? BasePrice(court) : PeakPrice(court);
        // أعلى سعر ساعة بين النطاقات (الثابتة والنسبية) والسعر الأساسي.
        return court.PriceRules.Select(r => RuleRate(court, r))
            .Append(BasePrice(court)).Max();
    }

    /// <summary>
    /// أدنى سعر ساعة يدفعه اللاعب فعلاً (أكبر خصم في قواعد المالك، أو السعر
    /// الأساسي حين لا خصم).
    /// </summary>
    public static decimal EffectiveLowestPrice(Court court)
    {
        if (!HasPriceRules(court)) return BasePrice(court);
        return court.PriceRules.Select(r => RuleRate(court, r))
            .Append(BasePrice(court)).Min();
    }

    /// <summary>
    /// أدنى وأعلى إجمالي لمدة معيّنة بعد تطبيق قواعد المالك — يعرضه التطبيق
    /// كنطاق سعري («من … إلى …») بدل رقم واحد لا يتغيّر بالساعة.
    /// </summary>
    public static (decimal Min, decimal Max) BookingPriceRange(
        Court court, int durationMinutes)
    {
        var basePrice = TierPrice(court, CourtPriceKind.Booking, durationMinutes)
            ?? Math.Round(BasePrice(court) * (decimal)durationMinutes / 60m, 2);
        if (!HasPriceRules(court)) return (basePrice, basePrice);

        // كل نطاق يغيّر سعر الساعة بنسبة سعره إلى الأساسي (شريحة المدة تُحفظ
        // نسبتها)، وأي ساعة بلا نطاق تبقى بالسعر نفسه.
        var hourly = BasePrice(court);
        var rates = court.PriceRules.Select(r => RuleRate(court, r)).Append(hourly).ToList();
        decimal PriceAt(decimal rate) => hourly > 0
            ? Math.Round(basePrice * rate / hourly, 2)
            : Math.Round(rate * durationMinutes / 60m, 2);
        return (PriceAt(rates.Min()), PriceAt(rates.Max()));
    }

    /// <summary>
    /// سعر الساعة قبل قواعد المالك — وهو **قاعدة الاحتساب الوحيدة** التي تتبعها
    /// <see cref="IsPeakSlot"/> و<see cref="EffectivePeakPrice"/> في العرض.
    /// الملاعب التي عرّفت قواعد تسعير تتخلّى عن ذروة الـ16:00 المبرمَجة حتى لا
    /// تُطبَّق زيادتان على الموعد نفسه، والمسعَّرة بشرائح مدد كذلك: شريحتها هي
    /// السعر، فلو بقيت الذروة لتناقض ما يُعرض مع ما يُخصم في المدد التي لا
    /// شريحة لها (أمريكانو ١٨٠ دقيقة مثلاً).
    /// </summary>
    private static decimal HourlyRateBefore(Court court, int hour) =>
        !HasPriceRules(court) && !HasTiers(court, CourtPriceKind.Booking) && IsPeak(hour)
            ? PeakPrice(court)
            : BasePrice(court);

    // ── Owner-defined tiers ──────────────────────────────────────────────────

    /// <summary>True when the owner defined explicit tiers of the given kind.</summary>
    public static bool HasTiers(Court court, CourtPriceKind kind) =>
        court.PriceTiers.Any(t => t.Kind == kind);

    /// <summary>The owner-set price for a duration, or null when no tier matches.</summary>
    public static decimal? TierPrice(Court court, CourtPriceKind kind, int durationMinutes) =>
        court.PriceTiers
            .Where(t => t.Kind == kind && t.DurationMinutes == durationMinutes)
            .Select(t => (decimal?)t.Price)
            .FirstOrDefault();

    /// <summary>
    /// Owner's booking price for a duration: the owner's tier when defined,
    /// otherwise the legacy hourly computation so older courts keep working —
    /// then adjusted by the day/time rule that covers the slot.
    /// This is what the OWNER receives — the player pays this plus commission.
    /// </summary>
    public static decimal BaseBookingPrice(Court court, DateTime start, int durationMinutes)
    {
        var tier = TierPrice(court, CourtPriceKind.Booking, durationMinutes);
        if (!HasPriceRules(court))
            return tier ?? Math.Round(
                HourlyRateBefore(court, start.Hour) * (decimal)durationMinutes / 60m, 2);

        // بقواعد المالك: كل نصف ساعة بسعر النطاق الذي تقع فيه — حجز 2 ظهراً
        // إلى 4 عصراً يُحسب ساعته الأولى بسعر الصباح والثانية بسعر المساء
        // (كان الموعد كله يُسعَّر بساعة بدايته).
        decimal sum = 0m;
        for (var offset = 0; offset < durationMinutes; offset += 30)
        {
            var minutes = Math.Min(30, durationMinutes - offset);
            sum += HourlyRateAt(court, start.AddMinutes(offset)) * minutes / 60m;
        }
        sum = Math.Round(sum, 2);
        if (tier is null) return sum;

        // شريحة المدة سعر مخفَّض للمدة كاملة: تُحفظ نسبتها إلى سعر الساعة.
        var baseSum = BasePrice(court) * durationMinutes / 60m;
        return baseSum <= 0 ? sum : Math.Round(tier.Value * sum / baseSum, 2);
    }

    /// <summary>Booking price the player pays: سعر المالك + نسبة سبورتا.</summary>
    public static decimal BookingPrice(Court court, DateTime start, int durationMinutes) =>
        WithCommission(court, BaseBookingPrice(court, start, durationMinutes));
}
