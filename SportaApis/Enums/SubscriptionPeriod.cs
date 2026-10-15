namespace SportaApis.Enums;

/// <summary>
/// نوع الاشتراك: شهري أو سنوي. النوع هو ما يحدّد مدة الاشتراك بالأيام
/// (<see cref="Days"/>)، فلا يُدخل الأدمن المدة يدويًا.
/// </summary>
public enum SubscriptionPeriod
{
    Monthly = 0,
    Yearly = 1,

    /// <summary>
    /// «بالنسبة» — لا رسوم مقدَّمة ولا تاريخ انتهاء: سبورتا تأخذ نسبة من كل
    /// عملية بدل الاشتراك الثابت. النسبة في <c>Package.CommissionPercent</c>.
    /// </summary>
    Commission = 2,
}

public static class SubscriptionPeriodExtensions
{
    /// <summary>
    /// مدة النوع بالأيام — أساس تاريخ انتهاء الاشتراك. <c>null</c> لاشتراك
    /// «بالنسبة» لأنه مفتوح المدة ولا ينتهي.
    /// </summary>
    public static int? Days(this SubscriptionPeriod period) => period switch
    {
        SubscriptionPeriod.Yearly => 365,
        SubscriptionPeriod.Commission => null,
        _ => 30,
    };

    /// <summary>هل هذا النوع مفتوح المدة (بلا تاريخ انتهاء)؟</summary>
    public static bool IsOpenEnded(this SubscriptionPeriod period) =>
        period == SubscriptionPeriod.Commission;

    /// <summary>المفتاح المرسل للواجهات ("monthly" | "yearly" | "commission").</summary>
    public static string Wire(this SubscriptionPeriod period) => period switch
    {
        SubscriptionPeriod.Yearly => "yearly",
        SubscriptionPeriod.Commission => "commission",
        _ => "monthly",
    };

    /// <summary>الاسم العربي للعرض.</summary>
    public static string LabelAr(this SubscriptionPeriod period) => period switch
    {
        SubscriptionPeriod.Yearly => "سنوي",
        SubscriptionPeriod.Commission => "بالنسبة",
        _ => "شهري",
    };

    /// <summary>يقرأ النوع من الواجهات، والافتراضي شهري.</summary>
    public static SubscriptionPeriod ParsePeriod(string? value) =>
        (value ?? string.Empty).Trim().ToLowerInvariant() switch
        {
            "yearly" or "year" or "annual" or "سنوي" => SubscriptionPeriod.Yearly,
            "commission" or "percent" or "percentage" or "بالنسبة" =>
                SubscriptionPeriod.Commission,
            _ => SubscriptionPeriod.Monthly,
        };
}
