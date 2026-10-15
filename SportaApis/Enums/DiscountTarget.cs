namespace SportaApis.Enums;

/// <summary>
/// نوع الرسم الذي يخفّضه الخصم. كل خصم يستهدف رسماً واحداً حتى يبقى الحساب
/// صريحاً ولا يتسرّب خصم مصمَّم للاشتراك إلى العمولة مثلاً.
/// </summary>
public enum DiscountTarget
{
    /// <summary>نسبة سبورتا على حجوزات الملاعب (تُقتطع من مستحقات المالك).</summary>
    VenueCommission = 0,

    /// <summary>نسبة سبورتا على جلسات المدربين (تُقتطع من مستحقات المدرب).</summary>
    CoachCommission = 1,

    /// <summary>اشتراك مالك الملعب الشهري/السنوي.</summary>
    VenueSubscription = 2,

    /// <summary>الخدمات المدفوعة للاعب (اشتراك سبورتا بلس).</summary>
    PlayerSubscription = 3,

    /// <summary>خصم للاعب على حجوزات الملاعب — يخفّض ما يدفعه اللاعب ويُموَّل
    /// من عمولة سبورتا فقط، فلا يمس مستحقات مالك الملعب (سقفه قيمة العمولة).</summary>
    PlayerBooking = 4,
}
