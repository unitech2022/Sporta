namespace SportaApis.DTOs;

/// <summary>بند واحد في "نبض المجتمع الرياضي".</summary>
public class PulseItemDto
{
    /// <summary>صاحب الحدث — null للبنود المجمّعة التي لا تخص لاعباً بعينه.</summary>
    public int? ActorId { get; set; }
    public string? ActorName { get; set; }

    /// <summary>"level" | "points" | "match_seeking" | "level_summary".</summary>
    public string Type { get; set; } = string.Empty;

    /// <summary>
    /// النص جاهزاً بالعربية، على غرار <see cref="FeedItemDto.Text"/>. التطبيق يركّب
    /// الجملة بلغته من الحقول المنظّمة أدناه ولا يعرض هذا إلا كاحتياطي (نسخ قديمة).
    /// </summary>
    public string Text { get; set; } = string.Empty;

    /// <summary>المستوى الذي وصله اللاعب — بنود "level" فقط.</summary>
    public int? Level { get; set; }

    /// <summary>النقاط المكتسبة اليوم — بنود "points" فقط.</summary>
    public int? Points { get; set; }

    /// <summary>عدد اللاعبين الذين حدّدوا مستواهم اليوم — بنود "level_summary" فقط.</summary>
    public int? Count { get; set; }

    /// <summary>
    /// قرب موعد المباراة كوحدة زمنية — "soon" (أقل من ساعة) | "hours" | "days".
    /// يُحسب في الخادم بساعة السعودية فلا يتأثر بساعة الجهاز. بنود "match_seeking" فقط.
    /// </summary>
    public string? RelativeUnit { get; set; }

    /// <summary>قيمة <see cref="RelativeUnit"/> (عدد الساعات أو الأيام)، null مع "soon".</summary>
    public int? RelativeValue { get; set; }

    /// <summary>
    /// الجزء الرقمي داخل <see cref="Text"/> ليبرزه التطبيق (مثل "6" أو "15").
    /// null إذا لم يكن في النص رقم يستحق الإبراز.
    /// </summary>
    public string? Highlight { get; set; }

    /// <summary>وقت الحدث بالـ UTC (Kind=Utc دائماً حتى يصل للتطبيق بعلامة Z).</summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>معرّف المباراة — يُملأ لبنود match_seeking فقط (زر "اقتنص المباراة").</summary>
    public int? MatchId { get; set; }
}
