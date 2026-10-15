using SportaApis.Enums;

namespace SportaApis.Models;

public class WithdrawalRequest : BaseEntity
{
    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public decimal Amount { get; set; }
    public WithdrawalStatus Status { get; set; } = WithdrawalStatus.Pending;

    /// <summary>IBAN of the bank account to transfer to.</summary>
    public string Iban { get; set; } = string.Empty;
    public string BankName { get; set; } = string.Empty;
    public string AccountHolderName { get; set; } = string.Empty;

    public string? AdminNotes { get; set; }
    public DateTime? ProcessedAt { get; set; }
}
