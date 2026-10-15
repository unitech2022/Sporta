using SportaApis.DTOs;
using SportaApis.Models;

namespace SportaApis.Services;

/// <summary>
/// قائمة انتظار المقاعد في المباريات والأمريكانو الفردي المكتملة. حين يفرغ
/// مقعد يُعرض على أول المنتظرين ويُحجز له مدة قصيرة، فإن لم ينضم انتقل للتالي.
/// التسجيل مجاني؛ الحصة تُخصم فقط عند طلب الانضمام الفعلي.
/// </summary>
public interface IWaitlistService
{
    /// <summary>حالة القائمة للمستخدم (0 للزائر = العدد وحده).</summary>
    Task<WaitlistStatusDto> GetStatusAsync(int userId, int matchId);

    /// <summary>يسجّل المستخدم في قائمة حدث لا مقعد متاحاً فيه له.</summary>
    Task<WaitlistStatusDto> JoinAsync(int userId, int matchId);

    /// <summary>يخرج المستخدم من القائمة (ويُعرض مقعده المحجوز على التالي).</summary>
    Task<WaitlistStatusDto> LeaveAsync(int userId, int matchId);

    /// <summary>
    /// يمنع أخذ مقعد محجوز لمنتظر آخر، وأيَّ طلب مباشر حين لا مقعد شاغر وفي
    /// القائمة منتظرون (يُوجَّه إليها). يُنادى قبل الخصم في كل انضمام عادي.
    /// <paramref name="match"/> يحتاج MatchPlayers محمّلة.
    /// </summary>
    Task EnsureSeatAvailableAsync(Match match, int userId);

    /// <summary>من طلب الانضمام يخرج من القائمة — حجزه أدّى غرضه.</summary>
    Task RemoveEntryAsync(int matchId, int userId);

    /// <summary>
    /// يعيد ضبط القائمة بعد أي تغيّر: يُسقط العروض المنتهية، ويعرض المقاعد
    /// الشاغرة على التالين، ويُغلق قائمة حدث بدأ أو أُلغي. best-effort.
    /// </summary>
    Task ProcessAsync(int matchId);

    /// <summary>نبضة الخلفية: يعالج كل حدث له قائمة. يعيد عددها.</summary>
    Task<int> ProcessAllAsync(CancellationToken ct = default);
}
