namespace SportaApis.Models;

/// <summary>
/// قاعدة تسعير حسب اليوم والوقت — يرفع بها صاحب الملعب سعره في أوقات الذروة
/// أو يخفضه في الأوقات الهادئة. تُطبَّق كنسبة على السعر الأساسي للحجز
/// (شريحة المدة إن وُجدت، وإلا سعر الساعة)، فتعمل مع كل المدد.
/// </summary>
public class CourtPriceRule : BaseEntity
{
    public int CourtId { get; set; }
    public Court Court { get; set; } = null!;

    /// <summary>يوم الأسبوع، أو null لتطبيقها على كل الأيام.</summary>
    public DayOfWeek? Day { get; set; }

    /// <summary>بداية النطاق بالساعة (0–23)، شاملة.</summary>
    public int StartHour { get; set; }

    /// <summary>نهاية النطاق بالساعة (1–24)، غير شاملة.</summary>
    public int EndHour { get; set; }

    /// <summary>
    /// نسبة التعديل: ‎+50‎ تعني ‎×1.5‎ (زيادة 50%)، و‎-20‎ تعني ‎×0.8‎ (خصم 20%).
    /// </summary>
    public decimal AdjustmentPercent { get; set; }

    /// <summary>
    /// سعر ساعة ثابت لهذا النطاق (سعر المالك قبل نسبة سبورتا). حين يُضبط يحلّ
    /// محل السعر الأساسي في هذا الوقت وتُهمَل <see cref="AdjustmentPercent"/> —
    /// «من 6 صباحاً إلى 3 عصراً بـ 100 ر.س». null = قاعدة بالنسبة.
    /// </summary>
    public decimal? HourlyPrice { get; set; }
}
