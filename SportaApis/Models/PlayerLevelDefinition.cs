namespace SportaApis.Models;

/// <summary>
/// سُلَّم مستويات اللاعبين كما يعرضه التطبيق (3.0 مبتدئ … 7.0 محترف — نخبة).
/// يُدار من لوحة التحكم؛ القيمة الرقمية هي ما يُقارن بمستوى اللاعب، والعنوان
/// والوصف ما يُعرض له.
/// </summary>
public class PlayerLevelDefinition : BaseEntity
{
    /// <summary>القيمة الرقمية للمستوى بخطوة نصف درجة (3.0، 3.5، …، 7.0).</summary>
    public decimal Value { get; set; }

    public string TitleAr { get; set; } = string.Empty;
    public string TitleEn { get; set; } = string.Empty;
    public string? DescriptionAr { get; set; }
    public string? DescriptionEn { get; set; }

    /// <summary>ترتيب العرض (الأصغر أولاً).</summary>
    public int SortOrder { get; set; }

    public bool IsActive { get; set; } = true;
}
