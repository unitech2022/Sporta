using SportaApis.DTOs;
using SportaApis.Enums;

namespace SportaApis.Services;

public interface IPointsService
{
    /// <summary>رصيد المستخدم + قواعد الاستبدال + آخر الحركات (paged).</summary>
    Task<PointsSummaryDto> GetSummaryAsync(int userId, int page, int pageSize);

    /// <summary>
    /// يستبدل [points] برصيد محفظة وفق معدل التحويل المُعدّ. يرفض ما دون الحد
    /// الأدنى أو ما يتجاوز الرصيد. يعيد الملخّص بعد الاستبدال.
    /// </summary>
    Task<PointsSummaryDto> RedeemAsync(int userId, int points);

    /// <summary>
    /// مزايا الباقة النشطة للمستخدم (مضاعف النقاط + نسبة خصم الحجوزات)؛
    /// (1, 0) لغير المشتركين.
    /// </summary>
    Task<(decimal Multiplier, decimal BookingDiscountPercent)> GetActiveBenefitsAsync(int userId);

    /// <summary>
    /// شروط عمولة سبورتا من اشتراك المستخدم الساري:
    /// <c>DiscountPercent</c> تخفيض على العمولة (٤٠ تعني أن ٥٪ تصير ٣٪)،
    /// و<c>OverridePercent</c> نسبة تحلّ محل نسبة المنصة بالكامل (اشتراك
    /// «بالنسبة»). بلا اشتراك ساري: (٠، null).
    /// </summary>
    Task<(decimal DiscountPercent, decimal? OverridePercent)>
        GetActiveCommissionTermsAsync(int userId);

    // ── Earn hooks (best-effort: لا ترمي استثناءً حتى لا تكسر التدفق الأصلي) ──

    /// <summary>يمنح نقاطًا نسبةً لمبلغ مدفوع (لكل 10 ر.س) مع تطبيق مضاعف الاشتراك.</summary>
    Task EarnForSpendAsync(
        int userId, decimal amountSar, PointsTransactionType type,
        int? referenceId, string? description);

    /// <summary>يمنح نقاطًا ثابتة (مثل إتمام مباراة) مع تطبيق مضاعف الاشتراك.</summary>
    Task EarnFixedAsync(
        int userId, int basePoints, PointsTransactionType type,
        int? referenceId, string? description);

    /// <summary>نقاط إتمام مباراة (القيمة من الإعدادات) — مرة واحدة لكل لاعب/مباراة.</summary>
    Task EarnMatchCompletedAsync(int userId, int matchId);

    /// <summary>
    /// نقاط مكافأة ثابتة لنشاط (حجز ملعب، تنظيم أمريكانو، تقييم مدرب…) قيمتها
    /// من إعداد <c>reward_points_*</c> المقابل للنوع، مع مضاعف الاشتراك. مرة
    /// واحدة لكل (مستخدم، نوع، مرجع). best-effort.
    /// </summary>
    Task EarnActivityAsync(
        int userId, PointsTransactionType activity, int? referenceId, string? description);

    /// <summary>
    /// نقاط المستوى لنتيجة مباراة: يقارن متوسط مستوى كل فريق بالآخر ويمنح كل
    /// لاعب زيادة أو خصماً بحسب قواعد <c>level_points_*</c>. التعادل لا يغيّر
    /// شيئاً. اللاعب غير المعتمد من مدرب (حين يُشترط ذلك) يُتجاوز. مرة واحدة
    /// لكل (لاعب، نوع، مرجع). best-effort.
    /// </summary>
    Task ApplyLevelPointsAsync(
        IReadOnlyCollection<int> team1, IReadOnlyCollection<int> team2,
        int team1Score, int team2Score,
        PointsTransactionType type, int referenceId, string? description);

    /// <summary>
    /// يلغي نقاط المستوى الممنوحة لمرجع (نتيجة صُحّحت): يطرحها من أرصدة
    /// اللاعبين ويحذف حركاتها، فيُعاد احتسابها بـ <see cref="ApplyLevelPointsAsync"/>.
    /// </summary>
    Task ReverseLevelPointsAsync(PointsTransactionType type, int referenceId);

    /// <summary>أعلى الحاصلين على النقاط (مكافآت أو مستوى) لفترة، مع موقع المستخدم.</summary>
    Task<LeaderboardDto> GetLeaderboardAsync(
        int? currentUserId, string kind, string period, int limit);

    /// <summary>
    /// خصم الانسحاب من مباراة/أمريكانو/بطولة: قيمته من إعداد
    /// <c>points_withdrawal_penalty</c> (افتراضياً 10)، بسقف الرصيد الحالي فلا
    /// ينزل تحت الصفر. يعيد ما خُصم فعلاً. best-effort.
    /// </summary>
    Task<int> PenalizeWithdrawalAsync(int userId, int matchId, string? description);

    /// <summary>يمنح نقاطًا كما هي بلا مضاعف (النقاط الترحيبية للاشتراك).</summary>
    Task GrantAsync(
        int userId, int points, PointsTransactionType type,
        int? referenceId, string? description);

    /// <summary>
    /// يعكس نقاطًا سبق كسبها عن عملية أُلغيت/استُردت — يخصم ما مُنح فعلًا
    /// (مطروحًا منه أي عكس سابق لنفس المرجع) وبسقف الرصيد الحالي.
    /// </summary>
    Task ReverseAsync(
        int userId, PointsTransactionType earnedType, int referenceId,
        string? description);

    // ── Admin ─────────────────────────────────────────────────────────────────

    Task<PagedResult<PointsTransactionDto>> GetUserTransactionsAsync(
        int userId, int page, int pageSize);

    /// <summary>منح (موجب) أو خصم (سالب، بسقف الرصيد) يدوي. يعيد الرصيد الجديد.</summary>
    Task<int> AdminAdjustAsync(int userId, int amount, string? reason);

    /// <summary>إجماليات النقاط للوحة التحكم.</summary>
    Task<PointsStatsDto> GetStatsAsync();
}
