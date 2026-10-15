using SportaApis.Enums;

namespace SportaApis.Models;

public class UserRole : BaseEntity
{
    public int UserId { get; set; }
    public UserType Role { get; set; }

    /// <summary>
    /// دورا المدرب وصاحب الملعب لا يُفعَّلان إلا بموافقة الأدمن، فيُنشآن هنا
    /// بـ false ويبقى صاحبهما مستخدماً للتطبيق بدور اللاعب فقط حتى المراجعة.
    /// باقي الأدوار (لاعب/أدمن/موظف) معتمدة فور إنشائها.
    /// </summary>
    public bool IsApproved { get; set; } = true;

    /// <summary>تاريخ موافقة الأدمن (null لما لم يُراجَع بعد).</summary>
    public DateTime? ApprovedAt { get; set; }

    /// <summary>
    /// حذف ناعم: الدور يختفي من التطبيق ومن كل استعلام (مرشّح عام على الكيان)
    /// وتبقى بياناته — ملف المدرب وأنديته وسجلّه المالي — فإعادة الدور تُحييه
    /// بدل أن تُنشئ ملفاً ثانياً.
    /// </summary>
    public bool IsDeleted { get; set; }

    public DateTime? DeletedAt { get; set; }

    /// <summary>هل هذا الدور بحاجة إلى موافقة الأدمن أصلاً؟</summary>
    public static bool NeedsApproval(UserType role) =>
        role is UserType.Coach or UserType.VenueOwner;

    // Navigation
    public User User { get; set; } = null!;
}
