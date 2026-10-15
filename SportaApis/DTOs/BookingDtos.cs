using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

// ── Requests ──────────────────────────────────────────────────────────────────

public class CreateBookingRequest
{
    [Required] public int CourtId { get; set; }

    /// <summary>Slot start time. Sent by the app as a local date+time.</summary>
    [Required] public DateTime StartTime { get; set; }

    [Range(30, 240)] public int DurationMinutes { get; set; } = 60;

    /// <summary>Whether the user paid the full amount up-front (vs. their share only).</summary>
    public bool PaidFullAmount { get; set; } = true;
}

/// <summary>طلب تسعير حجز قبل تأكيده (نفس مدخلات الإنشاء بلا حجز فعلي).</summary>
public class BookingQuoteRequest
{
    [Required] public int CourtId { get; set; }
    [Required] public DateTime StartTime { get; set; }
    [Range(30, 240)] public int DurationMinutes { get; set; } = 60;

    /// <summary>
    /// آخر يوم في مدى متعدد الأيام يشغل الملعب في نفس الموعد من كل يوم
    /// (البطولة): السعر يعود مجموع أيام المدى. null = يوم واحد.
    /// </summary>
    public DateTime? EndDate { get; set; }
}

/// <summary>
/// تسعير الحجز كما سيُخصم فعلاً: السعر الأساسي، وخصم باقة اللاعب إن وُجد،
/// والإجمالي. يعرضه التطبيق قبل زر التأكيد.
/// </summary>
public class BookingQuoteDto
{
    /// <summary>سعر الملعب قبل أي خصم.</summary>
    public decimal BasePrice { get; set; }

    /// <summary>
    /// نسبة الخصم *الفعلية* على هذا الحجز بعد سقف العمولة (٠ حين لا خصم).
    /// قد تقل عن مجموع نسب الباقة والعروض لأن الخصم يُموَّل من عمولة سبورتا.
    /// </summary>
    public decimal DiscountPercent { get; set; }

    /// <summary>قيمة الخصم بالريال بعد تطبيق سقف العمولة.</summary>
    public decimal DiscountAmount { get; set; }

    /// <summary>ما سيُخصم من المحفظة.</summary>
    public decimal Total { get; set; }

    /// <summary>جزء الخصم (ضمن DiscountAmount) الآتي من عضوية النادي كما يوفّره اللاعب.</summary>
    public decimal MemberDiscountAmount { get; set; }

    /// <summary>اسم خطة العضوية المطبَّقة، أو null.</summary>
    public string? MembershipPlanName { get; set; }

    public bool HasDiscount => DiscountAmount > 0;
}

// ── Responses ─────────────────────────────────────────────────────────────────

public class BookingDto
{
    public int Id { get; set; }

    public int CourtId { get; set; }
    public string CourtName { get; set; } = string.Empty;
    public string? CourtNameEn { get; set; }
    public string VenueName { get; set; } = string.Empty;
    public string? VenueNameEn { get; set; }
    public string City { get; set; } = string.Empty;
    public string? CityEn { get; set; }

    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public int DurationMinutes { get; set; }

    public decimal TotalPrice { get; set; }

    /// <summary>"Pending" | "Confirmed" | "Cancelled" | "Completed".</summary>
    public string Status { get; set; } = string.Empty;
    public bool PaidFullAmount { get; set; }
}
