namespace SportaApis.Models;

/// <summary>
/// ملعب إضافي تشغله البطولة في نافذتها اليومية (الملعب الرئيسي هو
/// <see cref="Match.CourtId"/>). يُحتسب في انشغال الملعب كالرئيسي تماماً.
/// </summary>
public class TournamentCourt : BaseEntity
{
    public int AmericanoMatchId { get; set; }
    public AmericanoMatch AmericanoMatch { get; set; } = null!;

    public int CourtId { get; set; }
    public Court Court { get; set; } = null!;
}
