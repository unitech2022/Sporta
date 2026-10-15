namespace SportaApis.Models;

/// <summary>
/// إعداد خاص بلعبة: عنوان وتحته عناصر (سطر لكل عنصر في <see cref="ItemsText"/>)،
/// يُدار من الأدمن عبر لوحة التحكم.
/// </summary>
public class SportSetting : BaseEntity
{
    public int SportId { get; set; }
    public Sport Sport { get; set; } = null!;

    public string Title { get; set; } = string.Empty;

    /// <summary>العناصر تحت العنوان، مفصولة بأسطر (نفس نمط Package.FeaturesText).</summary>
    public string ItemsText { get; set; } = string.Empty;

    /// <summary>ترتيب العرض (الأصغر أولًا).</summary>
    public int SortOrder { get; set; } = 0;
}
