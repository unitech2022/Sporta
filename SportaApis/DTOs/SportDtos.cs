using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

public class SportDto
{
    public int Id { get; set; }
    public string Key { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string? Image { get; set; }
    public string? Description { get; set; }
    public int Players { get; set; }
    public int Duration { get; set; }
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; }
    public string CreatedAt { get; set; } = string.Empty;
}

/// <summary>إعداد لعبة: عنوان وتحته قائمة عناصر.</summary>
public class SportSettingDto
{
    public int Id { get; set; }
    public int SportId { get; set; }
    public string Title { get; set; } = string.Empty;
    public List<string> Items { get; set; } = [];
    public int SortOrder { get; set; }
}

public class SaveSportSettingRequest
{
    [Required] public string Title { get; set; } = string.Empty;
    public List<string> Items { get; set; } = [];
    public int SortOrder { get; set; } = 0;
}

public class SaveSportRequest
{
    [Required] public string Name { get; set; } = string.Empty;
    [Required] public string NameEn { get; set; } = string.Empty;
    public string? Image { get; set; }
    public string? Description { get; set; }
    [Range(1, 20)] public int Players { get; set; } = 2;
    [Range(15, 240)] public int Duration { get; set; } = 60;
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; } = 0;
}
