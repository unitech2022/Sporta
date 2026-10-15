using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

// ── Responses ─────────────────────────────────────────────────────────────────

public class AssessmentOptionDto
{
    public int Id { get; set; }
    public string TextAr { get; set; } = string.Empty;
    public string TextEn { get; set; } = string.Empty;
    public int Score { get; set; }
}

public class AssessmentQuestionDto
{
    public int Id { get; set; }
    public string Sport { get; set; } = "padel";
    public string TextAr { get; set; } = string.Empty;
    public string TextEn { get; set; } = string.Empty;
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public List<AssessmentOptionDto> Options { get; set; } = [];
}

public class AssessmentLevelDto
{
    public int Id { get; set; }
    public string Sport { get; set; } = "padel";
    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string? DescriptionAr { get; set; }
    public string? DescriptionEn { get; set; }
    public int MinScore { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
}

// ── Admin requests ──────────────────────────────────────────────────────────────

public class SaveAssessmentLevelRequest
{
    [Required] public string Sport { get; set; } = "padel";
    [Required] public string NameAr { get; set; } = string.Empty;
    [Required] public string NameEn { get; set; } = string.Empty;
    public string? DescriptionAr { get; set; }
    public string? DescriptionEn { get; set; }
    [Range(0, 100000)] public int MinScore { get; set; }
    [Range(1, 1000)] public int SortOrder { get; set; } = 1;
    public bool IsActive { get; set; } = true;
}

public class AssessmentOptionInput
{
    [Required] public string TextAr { get; set; } = string.Empty;
    [Required] public string TextEn { get; set; } = string.Empty;
    [Range(0, 100000)] public int Score { get; set; }
    public int SortOrder { get; set; }
}

public class SaveAssessmentQuestionRequest
{
    [Required] public string Sport { get; set; } = "padel";
    [Required] public string TextAr { get; set; } = string.Empty;
    [Required] public string TextEn { get; set; } = string.Empty;
    public int SortOrder { get; set; } = 1;
    public bool IsActive { get; set; } = true;
    [MinLength(2)] public List<AssessmentOptionInput> Options { get; set; } = [];
}
