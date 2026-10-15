namespace SportaApis.Models;

public enum SettingType
{
    Text = 0,
    Switch = 1,
    Number = 2,
}

/// <summary>Key/value store for system-wide configurable settings (maintenance mode,
/// app version gate, policy text, support contact, etc.), managed from the admin dashboard.</summary>
public class SystemSetting : BaseEntity
{
    public string Key { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public SettingType Type { get; set; } = SettingType.Text;
    public string ValueAr { get; set; } = string.Empty;
    public string ValueEn { get; set; } = string.Empty;

    /// <summary>Sensitive values (e.g. API keys) are masked in the admin list.</summary>
    public bool IsSensitive { get; set; }
}
