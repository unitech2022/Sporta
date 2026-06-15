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
    public string? Description { get; set; }

    // مرجع العملية (حجز أو مباراة أو جلسة)
    public int? ReferenceId { get; set; }
}
