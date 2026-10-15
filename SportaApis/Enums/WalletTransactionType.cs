namespace SportaApis.Enums;

public enum WalletTransactionType
{
    Deposit = 0,        // إيداع
    Refund = 1,         // استرداد
    MatchPayment = 2,   // دفع حصة مباراة
    BookingPayment = 3, // دفع حجز ملعب
    CoachPayment = 4,   // دفع جلسة مدرب
    Reward = 5,         // مكافأة
    Subscription = 6,   // اشتراك Sporta Plus
    Withdrawal = 7,     // سحب الرصيد
    CoachEarning = 8,   // أرباح مدرب من جلسة
    VenueEarning = 9,   // أرباح صاحب ملعب من حجز

    /// <summary>Reimbursement to a match creator who paid the full match price
    /// up-front, paid back as other players join.</summary>
    CreatorEarning = 10, // استرداد حصة من لاعب انضم لمباراة دفعها المنشئ كاملة

    PointsRedemption = 11, // استبدال نقاط ولاء برصيد محفظة

    MembershipPayment = 12, // اشتراك عضوية نادٍ (من اللاعب)
    MembershipEarning = 13, // دخل عضوية نادٍ (لصاحب الملعب بعد نسبة سبورتا)
}
