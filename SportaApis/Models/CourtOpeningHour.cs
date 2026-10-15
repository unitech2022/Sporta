namespace SportaApis.Models;

/// <summary>
/// دوام الملعب في يوم واحد من أيام الأسبوع — يحدده صاحب الملعب من لوحته.
/// الملعب الذي لا يملك أي صفوف هنا يستخدم الدوام العام الافتراضي
/// (<see cref="Helpers.CourtSchedule.DefaultOpenHour"/> إلى
/// <see cref="Helpers.CourtSchedule.DefaultCloseHour"/>) في كل الأيام، حتى تبقى
/// الملاعب المسجّلة قبل هذه الميزة تعمل كما كانت.
/// </summary>
public class CourtOpeningHour : BaseEntity
{
    public int CourtId { get; set; }
    public Court Court { get; set; } = null!;

    /// <summary>يوم الأسبوع (0 = الأحد … 6 = السبت)، مطابق لـ <see cref="System.DayOfWeek"/>.</summary>
    public DayOfWeek Day { get; set; }

    /// <summary>مغلق طوال اليوم — لا مواعيد ولا حجوزات.</summary>
    public bool IsClosed { get; set; }

    /// <summary>ساعة الفتح (0–23)، شاملة.</summary>
    public int OpenHour { get; set; } = Helpers.CourtSchedule.DefaultOpenHour;

    /// <summary>ساعة الإغلاق (1–24)، غير شاملة: آخر موعد ينتهي عندها.</summary>
    public int CloseHour { get; set; } = Helpers.CourtSchedule.DefaultCloseHour;
}
