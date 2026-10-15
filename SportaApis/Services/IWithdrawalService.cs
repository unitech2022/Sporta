namespace SportaApis.Services;

/// <summary>نتيجة طلب الانسحاب: انسحب فعلاً، أو أُرسل طلب ينتظر المنشئ.</summary>
public enum WithdrawalOutcome
{
    /// <summary>خرج اللاعب وأُعيدت حصته وخُصمت نقاطه.</summary>
    Withdrawn,

    /// <summary>بعد المهلة: طلب ينتظر موافقة المنشئ واللاعب ما زال عضواً.</summary>
    Requested,

    /// <summary>كان طلب انضمام معلّقاً فأُلغي وأُعيدت حصته بلا خصم.</summary>
    RequestCancelled,
}

/// <summary>
/// انسحاب لاعب من مباراة أو أمريكانو أو بطولة (كلها <c>Match</c> بلاعبيها):
/// مباشر قبل المهلة (<see cref="Helpers.WithdrawalPolicy"/>)، وبموافقة المنشئ
/// بعدها. كل انسحاب فعلي يردّ الحصة ويخصم نقاط المكافآت.
/// </summary>
public interface IWithdrawalService
{
    /// <summary>اللاعب يطلب الانسحاب من الحدث صاحب <paramref name="matchId"/>.</summary>
    Task<WithdrawalOutcome> WithdrawAsync(int userId, int matchId);

    /// <summary>المنشئ يقبل طلب انسحاب متأخراً أو يرفضه.</summary>
    Task RespondAsync(int creatorId, int matchId, int targetUserId, bool approve);

    /// <summary>معرّف المباراة الأساسية لأمريكانو/بطولة.</summary>
    Task<int> MatchIdOfAmericanoAsync(int americanoId);
}
