using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// بطولة بادل (دولية أو محلية) تُعرض في لوحة اللاعب.
/// </summary>
public class Tournament : BaseEntity
{
    public string Name { get; set; } = string.Empty;

    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }

    /// <summary>المدينة/الدولة، مثل "دبي، الإمارات".</summary>
    public string Location { get; set; } = string.Empty;

    /// <summary>وصف الجائزة، مثل "الجائزة الكبرى".</summary>
    public string PrizeLabel { get; set; } = string.Empty;

    /// <summary>قيمة الجائزة كنص، مثل "$100,000" أو "50,000 ر.س".</summary>
    public string PrizeAmount { get; set; } = string.Empty;

    public TournamentScope Scope { get; set; }
}
