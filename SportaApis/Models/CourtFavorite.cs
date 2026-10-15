namespace SportaApis.Models;

/// <summary>
/// ملعب أضافه المستخدم إلى مفضّلته — علاقة أحادية بلا موافقة من النادي.
/// إزالة المفضّلة تحذف الصف (لا علَم منطقي)، فتبقى القائمة صغيرة والاستعلام
/// عنها مجرد `Any`.
/// </summary>
public class CourtFavorite : BaseEntity
{
    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public int CourtId { get; set; }
    public Court Court { get; set; } = null!;
}
