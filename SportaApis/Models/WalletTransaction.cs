using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// سجل تحويلات المحفظة: المبلغ + التاريخ + نوع العملية (2.7)
/// </summary>
public class WalletTransaction : BaseEntity
{
    public int WalletId { get; set; }
    public Wallet Wallet { get; set; } = null!;

    public decimal Amount { get; set; }
    public WalletTransactionType Type { get; set; }

    /// <summary>
    /// نجحت الحركة أم فشلت. الصفوف الفاشلة مسجَّلة للتدقيق ولم تُحرّك الرصيد،
    /// فاستثنِها من أي جمع مالي (انظر <c>AdminService.GetFinanceStatsAsync</c>).
    /// </summary>
    public PaymentStatus Status { get; set; } = PaymentStatus.Completed;

    public string? Description { get; set; }

    // مرجع العملية (حجز أو مباراة أو جلسة)
    public int? ReferenceId { get; set; }

    /// <summary>
    /// معرّف العملية لدى بوابة الدفع الخارجية (Moyasar/HyperPay/Tap...).
    /// يبقى null للتحويلات الداخلية للمحفظة وحتى ربط بوابة دفع حقيقية.
    /// </summary>
    public string? PaymentReference { get; set; }
}
