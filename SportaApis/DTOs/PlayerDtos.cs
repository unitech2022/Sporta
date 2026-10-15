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

public class RequestCoachAssessmentRequest
{
    [Required] public int CoachId { get; set; }
}

public class AssignLevelRequest
{
    [Range(1, 7)] public int Level { get; set; }
    public string? Notes { get; set; }
}

/// <summary>A level assessment record (any of the 3 paths).</summary>
public class LevelAssessmentDto
{
    public int Id { get; set; }

    /// <summary>"self" | "video" | "coach".</summary>
    public string Type { get; set; } = string.Empty;

    /// <summary>"pending" | "completed".</summary>
    public string Status { get; set; } = "pending";

    public string? VideoUrl { get; set; }
    public string? PlayerName { get; set; }
    public string? CoachName { get; set; }
    public int? AssignedLevel { get; set; }
    public string? AssignedLevelName { get; set; }
    public DateTime CreatedAt { get; set; }
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
