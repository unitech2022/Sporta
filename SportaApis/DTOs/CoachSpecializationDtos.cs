using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

public class CoachSpecializationDto
{
    public int Id { get; set; }
    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; }
}

public class SaveCoachSpecializationRequest
{
    [Required] public string NameAr { get; set; } = string.Empty;
    [Required] public string NameEn { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; } = 0;
}
