using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

// ── Requests ──────────────────────────────────────────────────────────────────

/// <summary>
/// Self-assessment submission. [Answers] holds the chosen option score (0..3)
/// for each question, in order.
/// </summary>
public class LevelAssessmentRequest
{
    public string Sport { get; set; } = "padel";
    [Required, MinLength(1)] public List<int> Answers { get; set; } = [];
}

public class FavoriteSportRequest
{
    [Required] public string Sport { get; set; } = string.Empty;
}

// ── Responses ─────────────────────────────────────────────────────────────────

public class LevelAssessmentResultDto
{
    public int Level { get; set; }
    public string LevelNameAr { get; set; } = string.Empty;
    public string LevelNameEn { get; set; } = string.Empty;
}

public class PlayerProfileDto
{
    public int Level { get; set; }
    public string LevelNameAr { get; set; } = string.Empty;
    public string LevelNameEn { get; set; } = string.Empty;
    public bool LevelAssessed { get; set; }
    public float EloRating { get; set; }
    public int TotalMatches { get; set; }
    public int TotalWins { get; set; }
    public float WinRate { get; set; }
}
