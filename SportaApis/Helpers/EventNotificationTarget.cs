using SportaApis.Models;

namespace SportaApis.Helpers;

/// <summary>
/// نوع الإشعار ومرجعه لحدثٍ قد يكون مباراة أو أمريكانو أو بطولة: التطبيق يوجّه
/// بالبادئة (match_/americano_/tournament_)، ومرجع الأمريكانو والبطولة هو معرّف
/// AmericanoMatch لا المباراة الأساسية — وإلا فتح الإشعار صفحة المباراة الخطأ.
/// يتطلب تحميل <see cref="Match.AmericanoMatch"/>.
/// </summary>
public static class EventNotificationTarget
{
    public static (string Type, int RefId) For(Match match, string suffix) =>
        match.AmericanoMatch is { } a
            ? (a.IsTournament || a.Format != null
                ? $"tournament_{suffix}"
                : $"americano_{suffix}", a.Id)
            : ($"match_{suffix}", match.Id);
}
