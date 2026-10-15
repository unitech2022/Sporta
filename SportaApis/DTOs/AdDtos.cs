namespace SportaApis.DTOs;

public class AdDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Subtitle { get; set; } = string.Empty;
    public string? TitleEn { get; set; }
    public string? SubtitleEn { get; set; }
    public string ImageUrl { get; set; } = string.Empty;

    /// <summary>"courts" | "matches" | "coaches" | external URL | null.</summary>
    public string? Target { get; set; }

    /// <summary>أماكن الظهور مفصولة بفواصل: "home,courts,matches,coaches".</summary>
    public string Placements { get; set; } = "home";

    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; }
}
