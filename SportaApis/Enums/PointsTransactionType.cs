namespace SportaApis.Enums;

/// <summary>
/// أنواع حركات نقاط الولاء — موجبة (كسب) أو سالبة (استبدال/عكس/خصم إداري).
/// </summary>
public enum PointsTransactionType
{
    BookingConfirmed = 0,      // إتمام حجز ملعب مدفوع
    MatchCompleted = 1,        // إتمام مباراة وتسجيل نتيجتها
    CoachSessionConfirmed = 2, // إتمام جلسة مدرب مدفوعة
    SubscriptionBonus = 3,     // نقاط ترحيبية عند الاشتراك في باقة
    ProfileBonus = 4,          // مكافأة إكمال تقييم المستوى
    Redeemed = 5,              // استبدال نقاط برصيد محفظة
    AdminAdjustment = 6,       // منح/خصم يدوي من الأدمن
    Reversal = 7,              // عكس نقاط مكتسبة بعد استرداد/إلغاء

    // ── نقاط المكافآت بالنشاط (قيمها من SystemSettings: reward_points_*) ──────
    MatchCreated = 8,          // إنشاء مباراة
    AmericanoOrganized = 9,    // تنظيم أمريكانو
    TournamentOrganized = 10,  // تنظيم بطولة
    CoachRated = 11,           // تقييم مدرب بعد جلسة
    CourtRated = 12,           // تقييم ملعب
    FriendInvited = 13,        // دعوة صديق للتطبيق

    // ── نقاط المستوى (Kind = Level) ───────────────────────────────────────────
    LevelMatchResult = 14,     // نتيجة مباراة عادية (فوز/خسارة بحسب فرق المستوى)
    LevelAmericanoRound = 15,  // نتيجة جولة أمريكانو/بطولة
    LevelTournamentFixture = 16, // نتيجة مباراة في بطولة إقصائية

    // ── خصومات (Kind = Reward) ────────────────────────────────────────────────
    WithdrawalPenalty = 17,    // انسحاب من مباراة/أمريكانو/بطولة (points_withdrawal_penalty)
}
