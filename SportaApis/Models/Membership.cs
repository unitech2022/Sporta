namespace SportaApis.Models;

/// <summary>
/// خطة عضوية يعرضها صاحب النادي: اشتراك شهري يمنح المشترك خصماً على حجز
/// ملاعب هذا النادي وأولوية في الحجز (أيام إضافية قبل غير الأعضاء).
/// </summary>
public class MembershipPlan : BaseEntity
{
    public int VenueId { get; set; }
    public Venue Venue { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string? NameEn { get; set; }
    public string? Description { get; set; }

    /// <summary>السعر الشهري الذي يدفعه اللاعب.</summary>
    public decimal MonthlyPrice { get; set; }

    /// <summary>نسبة الخصم على سعر المالك في حجز ملاعب النادي (0..100).</summary>
    public decimal DiscountPercent { get; set; }

    /// <summary>سقف ساعات الخصم في الشهر — null بلا سقف.</summary>
    public int? MonthlyDiscountHours { get; set; }

    /// <summary>أيام إضافية يحجز فيها العضو قبل غير الأعضاء (تحتاج نافذة حجز للنادي).</summary>
    public int PriorityDays { get; set; }

    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; }
    public int SortOrder { get; set; }
}

/// <summary>
/// اشتراك لاعب في خطة عضوية نادٍ. شروط الخطة تُنسخ لقطةً وقت الاشتراك فلا
/// يتأثر المشترك بتعديل المالك لاحقاً. الفترة الحالية [PeriodStart, PeriodEnd)
/// بالتوقيت العالمي، وتتجدد شهرياً من المحفظة إن فعّل اللاعب AutoRenew.
/// </summary>
public class Membership : BaseEntity
{
    public int PlanId { get; set; }
    public MembershipPlan Plan { get; set; } = null!;

    public int VenueId { get; set; }
    public Venue Venue { get; set; } = null!;

    public int UserId { get; set; }
    public User User { get; set; } = null!;

    // ── لقطة الشروط ──
    public string PlanName { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal DiscountPercent { get; set; }
    public int? MonthlyDiscountHours { get; set; }
    public int PriorityDays { get; set; }

    /// <summary>بداية ونهاية الفترة المدفوعة الحالية (UTC).</summary>
    public DateTime PeriodStart { get; set; }
    public DateTime PeriodEnd { get; set; }

    /// <summary>التجديد التلقائي الشهري من المحفظة — إلغاؤه يُبقي العضوية حتى نهاية الفترة.</summary>
    public bool AutoRenew { get; set; }

    /// <summary>انتهت ولم تُجدَّد (أُغلقت معالجتها).</summary>
    public bool IsEnded { get; set; }

    public DateTime? RenewalReminderSentAt { get; set; }

    public bool IsActiveAt(DateTime utcNow) => !IsEnded && PeriodEnd > utcNow;
}
