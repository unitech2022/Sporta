namespace SportaApis.Helpers;

/// <summary>
/// مهلة الانسحاب الحرّ من حدث: قبلها ينسحب اللاعب مباشرة، وبعدها يصير
/// انسحابه طلباً ينتظر موافقة المنشئ. المباراة العادية 24 ساعة قبل موعدها،
/// والأمريكانو والبطولة 48 ساعة (تنظيمهما أصعب وتعويض اللاعب أبطأ).
/// الأوقات محلية ساذجة فتُقارن بـ <see cref="AppClock"/>.
/// </summary>
public static class WithdrawalPolicy
{
    public const int MatchHours = 24;
    public const int EventHours = 48;

    /// <summary>آخر لحظة للانسحاب بلا موافقة.</summary>
    public static DateTime FreeUntil(DateTime scheduledAt, bool isEvent) =>
        scheduledAt.AddHours(-(isEvent ? EventHours : MatchHours));

    /// <summary>هل ما زال الانسحاب مباشراً بلا موافقة المنشئ؟</summary>
    public static bool IsFree(DateTime scheduledAt, bool isEvent) =>
        AppClock.Now <= FreeUntil(scheduledAt, isEvent);
}
