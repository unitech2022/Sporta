using System.ComponentModel.DataAnnotations;

namespace SportaApis.Models;

/// <summary>
/// إعلان/بانر يُعرض في سلايدر الصفحة الرئيسية للاعب.
/// </summary>
public class Ad : BaseEntity
{
    public string Title { get; set; } = string.Empty;
    public string Subtitle { get; set; } = string.Empty;

    /// <summary>العنوان بالإنجليزية — يُعرض عندما تكون لغة التطبيق إنجليزية.</summary>
    public string? TitleEn { get; set; }

    /// <summary>الوصف بالإنجليزية — يُعرض عندما تكون لغة التطبيق إنجليزية.</summary>
    public string? SubtitleEn { get; set; }

    /// <summary>رابط صورة الإعلان (يُعرض بملء العرض مع تدرّج أسفل).</summary>
    public string ImageUrl { get; set; } = string.Empty;

    /// <summary>
    /// وجهة الإعلان عند الضغط: اسم تبويب داخلي ("courts" | "matches" | "coaches")
    /// أو رابط خارجي. اختياري.
    /// </summary>
    public string? Target { get; set; }

    /// <summary>
    /// أماكن ظهور الإعلان داخل التطبيق: أسماء صفحات مفصولة بفواصل
    /// ("home" | "courts" | "matches" | "coaches")، مثل "home,courts".
    /// فارغة = الرئيسية فقط (سلوك الإعلانات القديمة).
    /// ملاحظة: هذا غير <see cref="Target"/> وهو وجهة الضغط على الإعلان.
    /// </summary>
    [MaxLength(64)]
    public string Placements { get; set; } = "home";

    public bool IsActive { get; set; } = true;

    /// <summary>ترتيب العرض (الأصغر أولًا).</summary>
    public int SortOrder { get; set; } = 0;
}
