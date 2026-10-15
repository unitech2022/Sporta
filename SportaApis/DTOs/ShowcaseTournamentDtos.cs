namespace SportaApis.DTOs;

/// <summary>بطولة استعراضية (دولية/محلية) تُعرض في لوحة اللاعب — ليست بطولة قابلة للعب.</summary>
public class ShowcaseTournamentDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string Location { get; set; } = string.Empty;
    public string PrizeLabel { get; set; } = string.Empty;
    public string PrizeAmount { get; set; } = string.Empty;

    /// <summary>"international" | "local".</summary>
    public string Scope { get; set; } = "international";
}
