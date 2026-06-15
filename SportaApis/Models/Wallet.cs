namespace SportaApis.Models;

/// <summary>
/// المحفظة الداخلية - المبالغ المستردة تذهب إليها فوراً (2.7)
/// </summary>
public class Wallet : BaseEntity
{
    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public decimal Balance { get; set; } = 0m;

    // Navigation
    public ICollection<WalletTransaction> Transactions { get; set; } = [];
}
