namespace SportaApis.DTOs;

// ── Responses ─────────────────────────────────────────────────────────────────

/// <summary>
/// A bookable court (flattened with its parent venue) as consumed by the app's
/// courts list and booking screens.
/// </summary>
public class CourtDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    /// <summary>اسم الملعب بالإنجليزية — null للملاعب القديمة.</summary>
    public string? NameEn { get; set; }

    public int VenueId { get; set; }
    public string VenueName { get; set; } = string.Empty;

    /// <summary>اسم النادي بالإنجليزية — null للأندية القديمة.</summary>
    public string? VenueNameEn { get; set; }

    public string Country { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;

    /// <summary>اسم المدينة بالإنجليزية (من جدول المدن) — null للأندية القديمة.</summary>
    public string? CityEn { get; set; }

    /// <summary>الحي — اسم الحي كما اختاره المالك من قائمة الأحياء (قد يكون فارغاً
    /// للأندية القديمة). يستخدمه التطبيق لفلترة الملاعب داخل المدينة.</summary>
    public string District { get; set; } = string.Empty;

    /// <summary>اسم الحي بالإنجليزية (من جدول الأحياء) — null للأندية القديمة.</summary>
    public string? DistrictEn { get; set; }

    public string Neighborhood { get; set; } = string.Empty;

    /// <summary>"indoor" | "outdoor".</summary>
    public string Type { get; set; } = "indoor";

    /// <summary>عدد الملاعب — number of identical physical courts; players pick a
    /// court number in 1..CourtCount when booking.</summary>
    public int CourtCount { get; set; } = 1;

    /// <summary>"men" | "women" | "family" (derived from the venue policy).</summary>
    public string Gender { get; set; } = "men";

    /// <summary>السعر الأساسي — owner-set hourly rate before the Sporta markup.</summary>
    public decimal BasePrice { get; set; }

    /// <summary>نسبة سبورتا — platform markup (%) added on top of the base price.</summary>
    public decimal SportaCommissionPercent { get; set; }

    /// <summary>الإجمالي — gross hourly rate (base + Sporta markup); what players pay.</summary>
    public decimal TotalPrice { get; set; }

    /// <summary>
    /// أعلى سعر ساعة يدفعه اللاعب فعلاً — من قواعد تسعير المالك حين توجد.
    /// </summary>
    public decimal PeakHourPrice { get; set; }

    /// <summary>أدنى سعر ساعة يدفعه اللاعب فعلاً (ساعات الخصم).</summary>
    public decimal LowestPrice { get; set; }

    /// <summary>Owner-set booking price tiers (duration → price). Matches use the
    /// same tiers, split evenly across players.</summary>
    public List<CourtPriceTierDto> BookingPrices { get; set; } = [];

    public bool IsAvailable { get; set; } = true;

    /// <summary>Admin suspension flag — suspended courts are hidden from players.</summary>
    public bool IsSuspended { get; set; }

    /// <summary>Whether the owning venue has been approved by an admin — unapproved
    /// venues' courts never reach players (admin-only visibility).</summary>
    public bool IsVenueApproved { get; set; }

    public string? ImageUrl { get; set; }

    /// <summary>هل أضاف المستخدم الحالي هذا الملعب لمفضّلته؟ تبقى false في
    /// المسارات الإدارية التي لا مستخدم لاعباً فيها.</summary>
    public bool IsFavorite { get; set; }

    /// <summary>متوسط تقييم اللاعبين بعد المباريات (0 بلا تقييمات) وعددها —
    /// يقرؤهما التطبيق باسمي rating/reviews.</summary>
    public double Rating { get; set; }
    public int Reviews { get; set; }

    /// <summary>أبعد يوم يستطيع هذا المستخدم الحجز فيه (null = بلا حد).
    /// يُملأ في تفاصيل الملعب فقط.</summary>
    public int? BookingWindowDays { get; set; }

    /// <summary>المستخدم عضو ساري في نادي هذا الملعب.</summary>
    public bool IsMember { get; set; }

    /// <summary>Venue geo-coordinates (null if the venue has none).</summary>
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    /// <summary>Distance (km) from the requesting user (null if unknown).</summary>
    public double? DistanceKm { get; set; }

    /// <summary>Selectable session durations (minutes).</summary>
    public List<int> AvailableDurations { get; set; } = [60, 90, 120];

    /// <summary>Daily opening slots (HH:mm) — union of the week's open hours.</summary>
    public List<string> AvailableTimes { get; set; } = [];

    /// <summary>بحث الملاعب بالوقت: المواعيد الفارغة (HH:mm) التي تبدأ داخل
    /// النافذة المطلوبة. null حين لا يُطلب بحث بالوقت.</summary>
    public List<string>? FreeSlots { get; set; }

    /// <summary>بحث الملاعب بالوقت: أقل سعر (شاملاً نسبة سبورتا) للمدة المطلوبة
    /// داخل النافذة — للمواعيد الفارغة إن وُجدت. null بلا نافذة أو يوم مغلق.</summary>
    public decimal? FromPrice { get; set; }

    /// <summary>دوام الملعب لكل يوم من أيام الأسبوع (سبعة صفوف دائماً).</summary>
    public List<CourtOpeningHourInput> OpeningHours { get; set; } = [];

    /// <summary>قواعد التسعير حسب اليوم والوقت — فارغة تعني سعراً موحّداً.</summary>
    public List<CourtPriceRuleInput> PriceRules { get; set; } = [];
}

/// <summary>A single duration→price tier exposed to players.</summary>
public class CourtPriceTierDto
{
    public int DurationMinutes { get; set; }

    /// <summary>السعر الأساسي — the owner-set tier price before the Sporta markup.</summary>
    public decimal BasePrice { get; set; }

    /// <summary>الإجمالي — gross tier price (base + Sporta markup); what players pay.</summary>
    public decimal Price { get; set; }

    /// <summary>أدنى إجمالي لهذه المدة بعد قواعد تسعير المالك (ساعات الخصم).</summary>
    public decimal MinPrice { get; set; }

    /// <summary>أعلى إجمالي لهذه المدة بعد قواعد تسعير المالك (ساعات الذروة).</summary>
    public decimal MaxPrice { get; set; }

    /// <summary>true حين يختلف السعر باختلاف الساعة — يعرضه التطبيق كنطاق.</summary>
    public bool VariesByHour => MaxPrice > MinPrice;
}

/// <summary>Per-date slot availability for a single court.</summary>
public class CourtAvailabilityDto
{
    /// <summary>The requested date (yyyy-MM-dd).</summary>
    public string Date { get; set; } = string.Empty;

    /// <summary>الملعب مغلق في هذا اليوم حسب دوام الأسبوع — القائمة تكون فارغة.</summary>
    public bool IsClosed { get; set; }

    /// <summary>دوام هذا اليوم (للعرض، مثال "06:00 - 24:00").</summary>
    public int OpenHour { get; set; }
    public int CloseHour { get; set; }

    public List<TimeSlotDto> Slots { get; set; } = [];
}

/// <summary>
/// نافذة بحث الملاعب بالوقت: يوم واحد، ومواعيد تبدأ في
/// [<see cref="FromHour"/>، <see cref="ToHour"/>) بالمدة المطلوبة.
/// </summary>
public record CourtSlotWindow(
    DateTime Date, int FromHour, int ToHour, int DurationMinutes, bool OnlyAvailable);

public class TimeSlotDto
{
    /// <summary>Slot start time (HH:mm).</summary>
    public string Time { get; set; } = string.Empty;
    public bool IsBooked { get; set; }
    public decimal Price { get; set; }
    public bool IsPeak { get; set; }
}

/// <summary>جسم طلب تبديل مفضّلة ملعب — منفصل عن نظيره في الأصدقاء ليتطور كلٌّ
/// على حدة.</summary>
public class ToggleCourtFavoriteRequest
{
    public bool Favorite { get; set; }
}
