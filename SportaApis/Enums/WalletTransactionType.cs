namespace SportaApis.Enums;

public enum WalletTransactionType
{
    Deposit = 0,        // إيداع
    Refund = 1,         // استرداد
    MatchPayment = 2,   // دفع حصة مباراة
    BookingPayment = 3, // دفع حجز ملعب
    CoachPayment = 4,   // دفع جلسة مدرب
    Reward = 5          // مكافأة
}
