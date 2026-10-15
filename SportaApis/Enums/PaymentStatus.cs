namespace SportaApis.Enums;

/// <summary>
/// حالة حركة المحفظة. الافتراضي <see cref="Completed"/> لأن كل صف قبل إضافة هذا
/// الحقل كان حركة ناجحة فعلاً.
/// </summary>
public enum PaymentStatus
{
    /// <summary>تمت وحُرّك الرصيد فعلاً — الحركات المحسوبة في الأرصدة والإحصائيات.</summary>
    Completed = 0,

    /// <summary>
    /// محاولة دفع فشلت (رصيد غير كافٍ) — تُسجَّل للتدقيق فقط ولم يتحرك بها أي رصيد،
    /// لذا يجب استثناؤها من أي جمع مالي.
    /// </summary>
    Failed = 1,
}
