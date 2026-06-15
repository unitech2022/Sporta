namespace SportaApis.Models;

/// <summary>
/// جولة واحدة داخل مباراة الأمريكانو - التوزيع العادل (5.3)
/// </summary>
public class AmericanoRound : BaseEntity
{
    public int AmericanoMatchId { get; set; }
    public AmericanoMatch AmericanoMatch { get; set; } = null!;

    public int RoundNumber { get; set; }

    // الفريق الأول
    public int Team1Player1Id { get; set; }
    public User Team1Player1 { get; set; } = null!;
    public int Team1Player2Id { get; set; }
    public User Team1Player2 { get; set; } = null!;

    // الفريق الثاني
    public int Team2Player1Id { get; set; }
    public User Team2Player1 { get; set; } = null!;
    public int Team2Player2Id { get; set; }
    public User Team2Player2 { get; set; } = null!;

    // النتيجة
    public int? Team1Score { get; set; }
    public int? Team2Score { get; set; }
    public bool IsCompleted { get; set; } = false;
}
