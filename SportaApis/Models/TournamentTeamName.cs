namespace SportaApis.Models;

/// <summary>
/// اسم مخصّص لفريق في بطولة إقصائية. بلا صفّ يُعرض الفريق بحرفه (A، B، C…)
/// المشتق من رقمه — انظر <see cref="Helpers.TournamentEngine.TeamLetter"/>.
/// </summary>
public class TournamentTeamName : BaseEntity
{
    public int AmericanoMatchId { get; set; }
    public AmericanoMatch AmericanoMatch { get; set; } = null!;

    /// <summary>رقم الفريق (1..N) كما في <see cref="MatchPlayer.Team"/>.</summary>
    public int Team { get; set; }

    public string Name { get; set; } = string.Empty;
}
