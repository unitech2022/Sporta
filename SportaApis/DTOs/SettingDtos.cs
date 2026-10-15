using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

public class SettingDto
{
    public int Id { get; set; }
    public string Key { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string Type { get; set; } = "text"; // text | switch | number
    public string ValueAr { get; set; } = string.Empty;
    public string ValueEn { get; set; } = string.Empty;
    public bool IsSensitive { get; set; }
}

/// <summary>تعديل نص سياسة — المفتاح والاسم والنوع ثابتة، النص فقط يتغير.</summary>
public class SavePolicyRequest
{
    public string ValueAr { get; set; } = string.Empty;
    public string ValueEn { get; set; } = string.Empty;
}

public class SaveSettingRequest
{
    [Required] public string Key { get; set; } = string.Empty;
    [Required] public string NameAr { get; set; } = string.Empty;
    [Required] public string NameEn { get; set; } = string.Empty;
    [Required] public string Type { get; set; } = "text";
    public string ValueAr { get; set; } = string.Empty;
    public string ValueEn { get; set; } = string.Empty;
    public bool IsSensitive { get; set; }
}
