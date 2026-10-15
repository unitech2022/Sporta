using System.ComponentModel.DataAnnotations;
using SportaApis.Helpers;

namespace SportaApis.DTOs;

// ── Owner management ────────────────────────────────────────────────────────────

public class OwnerCourtDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? NameEn { get; set; }

    /// <summary>"indoor" | "outdoor".</summary>
    public string Type { get; set; } = "indoor";

    /// <summary>عدد الملاعب — number of identical physical courts.</summary>
    public int CourtCount { get; set; } = 1;
    public decimal PricePerHour { get; set; }
    public bool IsAvailable { get; set; }
    public string? ImageUrl { get; set; }

    /// <summary>Court geo-location (null when not set).</summary>
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    /// <summary>Owner-set booking price tiers (duration → price). Matches use the
    /// same tiers, split evenly across players.</summary>
    public List<CourtPriceTierInput> BookingTiers { get; set; } = [];

    /// <summary>دوام الأسبوع — فارغة تعني الدوام الافتراضي (6 ص – 12 م كل يوم).</summary>
    public List<CourtOpeningHourInput> OpeningHours { get; set; } = [];

    /// <summary>قواعد التسعير حسب اليوم والوقت — فارغة تعني سعراً موحّداً.</summary>
    public List<CourtPriceRuleInput> PriceRules { get; set; } = [];
}

/// <summary>A single duration→price tier as sent/returned for an owner's court.</summary>
public class CourtPriceTierInput
{
    [Range(15, 480)] public int DurationMinutes { get; set; }
    [Range(0, 100000)] public decimal Price { get; set; }
}

/// <summary>دوام الملعب في يوم واحد — يُرسَل ويُعاد كما هو.</summary>
public class CourtOpeningHourInput
{
    /// <summary>0 = الأحد … 6 = السبت.</summary>
    [Range(0, 6)] public int Day { get; set; }

    /// <summary>مغلق طوال اليوم.</summary>
    public bool IsClosed { get; set; }

    /// <summary>ساعة الفتح (0–23)، شاملة.</summary>
    [Range(0, 23)] public int OpenHour { get; set; } = CourtSchedule.DefaultOpenHour;

    /// <summary>ساعة الإغلاق (1–24)، غير شاملة.</summary>
    [Range(1, 24)] public int CloseHour { get; set; } = CourtSchedule.DefaultCloseHour;
}

/// <summary>قاعدة تسعير حسب اليوم والوقت — تُرسَل وتُعاد كما هي.</summary>
public class CourtPriceRuleInput
{
    /// <summary>0 = الأحد … 6 = السبت، أو null لكل الأيام.</summary>
    [Range(0, 6)] public int? Day { get; set; }

    /// <summary>بداية النطاق بالساعة (0–23)، شاملة.</summary>
    [Range(0, 23)] public int StartHour { get; set; }

    /// <summary>نهاية النطاق بالساعة (1–24)، غير شاملة.</summary>
    [Range(1, 24)] public int EndHour { get; set; }

    /// <summary>‎+50‎ تعني زيادة 50%، و‎-20‎ تعني خصم 20%.</summary>
    [Range(-90, 500)] public decimal AdjustmentPercent { get; set; }

    /// <summary>سعر ساعة ثابت لهذا النطاق (سعر المالك) — يُقدَّم على النسبة حين يُرسل.</summary>
    [Range(0, 100000)] public decimal? HourlyPrice { get; set; }
}

/// <summary>أسعار النادي حسب الوقت — تُطبَّق على كل ملاعبه أو على المختار منها.</summary>
public class UpdateVenuePriceRulesRequest
{
    /// <summary>الملاعب المستهدفة؛ فارغة = كل ملاعب النادي.</summary>
    public List<int> CourtIds { get; set; } = [];

    /// <summary>النطاقات (تستبدل قواعد كل ملعب مستهدف؛ فارغة = سعر موحّد).</summary>
    public List<CourtPriceRuleInput> PriceRules { get; set; } = [];
}

public class VenuePricingDto
{
    public int VenueId { get; set; }
    public string VenueName { get; set; } = string.Empty;
    public List<VenuePricingCourtDto> Courts { get; set; } = [];
}

public class VenuePricingCourtDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? NameEn { get; set; }

    /// <summary>سعر الساعة الأساسي (سعر المالك).</summary>
    public decimal BasePrice { get; set; }
    public decimal SportaCommissionPercent { get; set; }
    public List<CourtOpeningHourInput> OpeningHours { get; set; } = [];
    public List<CourtPriceRuleInput> PriceRules { get; set; } = [];
}

/// <summary>دوام الأسبوع وقواعد التسعير معاً — جسم طلب حفظ جدول الملعب.</summary>
public class UpdateCourtScheduleRequest
{
    /// <summary>دوام الأيام السبعة (أرسل ما تريد تغييره؛ القائمة تستبدل الموجود).</summary>
    public List<CourtOpeningHourInput> OpeningHours { get; set; } = [];

    /// <summary>قواعد التسعير (القائمة تستبدل الموجود؛ فارغة تعني سعراً موحّداً).</summary>
    public List<CourtPriceRuleInput> PriceRules { get; set; } = [];
}

public class OwnerVenueDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? NameEn { get; set; }
    public string? Description { get; set; }
    public string City { get; set; } = string.Empty;

    /// <summary>معرّفات الموقع — مطلوبة لكل نادٍ جديد، وقد تكون null للأندية
    /// القديمة التي تعذّر ربط أسمائها النصية بالقوائم.</summary>
    public int? CityId { get; set; }
    public int? DistrictId { get; set; }
    public int? CountryId { get; set; }

    public string? District { get; set; }
    public string Address { get; set; } = string.Empty;
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    /// <summary>"men" | "womenOnly" | "familyOnly".</summary>
    public string GenderPolicy { get; set; } = "men";

    /// <summary>صورة الملعب التمثيلية (أول صورة من <see cref="ImageUrls"/>).</summary>
    public string? ImageUrl { get; set; }

    /// <summary>كل صور الملعب.</summary>
    public List<string> ImageUrls { get; set; } = [];

    /// <summary>لا يظهر الملعب للاعبين حتى توافق عليه الإدارة.</summary>
    public bool IsApproved { get; set; }

    public List<OwnerCourtDto> Courts { get; set; } = [];
}

/// <summary>A venue with its owner's contact info and onboarding documents,
/// as reviewed by the admin in the web dashboard.</summary>
public class AdminVenueDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? NameEn { get; set; }
    public string? Description { get; set; }
    public string Country { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;

    /// <summary>الحي.</summary>
    public string? District { get; set; }

    /// <summary>معرّفات الموقع — null فقط للأندية القديمة غير المربوطة.</summary>
    public int? CountryId { get; set; }
    public int? CityId { get; set; }
    public int? DistrictId { get; set; }
    public string Address { get; set; } = string.Empty;
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    /// <summary>"men" | "womenOnly" | "familyOnly".</summary>
    public string GenderPolicy { get; set; } = "men";
    public bool IsActive { get; set; } = true;

    /// <summary>لا يظهر الملعب للاعبين حتى توافق عليه الإدارة.</summary>
    public bool IsApproved { get; set; }
    public int CourtsCount { get; set; }
    public DateTime CreatedAt { get; set; }

    // ── Owner ─────────────────────────────────────────────────────────────────
    public int OwnerId { get; set; }
    public string OwnerName { get; set; } = string.Empty;
    public string? OwnerPhone { get; set; }

    // ── Onboarding documents ─────────────────────────────────────────────────
    public string? CommercialRegistrationImageUrl { get; set; }
    public string? NationalAddressImageUrl { get; set; }
    public string? OwnerIdImageUrl { get; set; }
    public string? TaxCertificateUrl { get; set; }
    public List<string> ImageUrls { get; set; } = [];

    /// <summary>ملاعب النادي — تُعبّأ في تفاصيل النادي فقط، وتبقى فارغة في القائمة.</summary>
    public List<AdminVenueCourtDto> Courts { get; set; } = [];
}

/// <summary>ملعب واحد داخل النادي كما يظهر في صفحة تفاصيل النادي باللوحة.</summary>
public class AdminVenueCourtDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    /// <summary>"indoor" | "outdoor".</summary>
    public string Type { get; set; } = "indoor";

    /// <summary>عدد الملاعب المتطابقة تحت هذا الاسم.</summary>
    public int CourtCount { get; set; } = 1;

    /// <summary>السعر الذي حدّده المالك وهو ما يدفعه اللاعب.</summary>
    public decimal BasePrice { get; set; }

    /// <summary>نسبة سبورتا — تُخصم من مستحقات المالك.</summary>
    public decimal SportaCommissionPercent { get; set; }

    /// <summary>سعر ساعة الذروة.</summary>
    public decimal PeakHourPrice { get; set; }

    /// <summary>مفتاح المالك المؤقت (فتح/إغلاق).</summary>
    public bool IsAvailable { get; set; }

    /// <summary>إيقاف من الإدارة — يخفي الملعب عن اللاعبين.</summary>
    public bool IsSuspended { get; set; }
    public string? ImageUrl { get; set; }
}

/// <summary>Minimal venue info for a picker (e.g. coach registration's
/// "preferred training venue" field) — public, no owner/document data.</summary>
public class VenueOptionDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
}

public class CreateVenueRequest
{
    [Required] public string Name { get; set; } = string.Empty;

    /// <summary>اسم الملعب بالإنجليزية.</summary>
    public string? NameEn { get; set; }

    /// <summary>الاسم النصي للمدينة — للعرض فقط؛ المصدر هو <see cref="CityId"/>.</summary>
    public string? City { get; set; }

    /// <summary>معرّف المدينة من قائمة المدن — إلزامي: كل نادٍ لا بد أن يُربط
    /// بمدينة معروفة حتى تعمل فلترة اللاعبين ونطاق الموظفين. يُتحقق منه في
    /// الخدمة ليعود الخطأ بالعربية ضمن غلاف ApiResponse.</summary>
    public int? CityId { get; set; }

    /// <summary>الاسم النصي للحي — للعرض فقط؛ المصدر هو <see cref="DistrictId"/>.</summary>
    public string? District { get; set; }

    /// <summary>معرّف الحي من قائمة أحياء المدينة — إلزامي، ولا بد أن يتبع
    /// <see cref="CityId"/>.</summary>
    public int? DistrictId { get; set; }

    [Required] public string Address { get; set; } = string.Empty;
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    /// <summary>صور الملعب (مرفوعة مسبقًا عبر /api/uploads/image).</summary>
    public List<string> ImageUrls { get; set; } = [];

    /// <summary>عدد الملاعب الداخلية — number of identical physical courts (1..50).</summary>
    [Range(1, 50)] public int CourtCount { get; set; } = 1;

    /// <summary>Legacy hourly rate — used only when no booking tiers are provided.</summary>
    [Range(0, 100000)] public decimal PricePerHour { get; set; }

    /// <summary>Booking price tiers (duration → price), e.g. 20→80, 60→150, 120→260.</summary>
    public List<CourtPriceTierInput> BookingTiers { get; set; } = [];
}

public class CreateCourtRequest
{
    [Required] public string Name { get; set; } = string.Empty;

    /// <summary>اسم الملعب بالإنجليزية.</summary>
    public string? NameEn { get; set; }
    public string Type { get; set; } = "indoor";

    /// <summary>عدد الملاعب — number of identical physical courts (1..50).</summary>
    [Range(1, 50)] public int CourtCount { get; set; } = 1;

    /// <summary>Legacy hourly rate — used only when no booking tiers are provided.</summary>
    [Range(0, 100000)] public decimal PricePerHour { get; set; }

    /// <summary>Booking price tiers (duration → price), e.g. 60→150, 120→200.
    /// Matches on this court use the same tiers, split evenly across players.</summary>
    public List<CourtPriceTierInput> BookingTiers { get; set; } = [];

    /// <summary>دوام الأسبوع — اتركها فارغة لاعتماد الدوام الافتراضي.</summary>
    public List<CourtOpeningHourInput> OpeningHours { get; set; } = [];

    /// <summary>قواعد التسعير حسب اليوم والوقت.</summary>
    public List<CourtPriceRuleInput> PriceRules { get; set; } = [];

    public string? ImageUrl { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}

public class OwnerCourtSlotDto
{
    public int Hour { get; set; }
    public string Time { get; set; } = string.Empty;
    public bool IsBooked { get; set; }
    public bool IsBlocked { get; set; }
    public bool IsAvailable => !IsBooked && !IsBlocked;
}

public class OwnerCourtSlotsDto
{
    public int CourtId { get; set; }
    public string Date { get; set; } = string.Empty;

    /// <summary>الملعب مغلق في هذا اليوم حسب دوام الأسبوع.</summary>
    public bool IsClosed { get; set; }

    public List<OwnerCourtSlotDto> Slots { get; set; } = [];
}

public class ToggleSlotRequest
{
    /// <summary>The day in yyyy-MM-dd.</summary>
    [Required] public string Date { get; set; } = string.Empty;
    [Range(0, 23)] public int Hour { get; set; }
}

/// <summary>تغيير جماعي لحالة عدة مواعيد في يوم واحد — إيقافها أو إتاحتها.</summary>
public class BulkSlotsRequest
{
    /// <summary>The day in yyyy-MM-dd.</summary>
    [Required] public string Date { get; set; } = string.Empty;

    /// <summary>ساعات اليوم المطلوب تغييرها (0..23).</summary>
    [Required, MinLength(1)] public List<int> Hours { get; set; } = [];

    /// <summary>true = إتاحة المواعيد، false = إيقافها.</summary>
    public bool Available { get; set; }
}

public class UpdateCourtRequest
{
    /// <summary>عدد الملاعب — number of identical physical courts (1..50).</summary>
    [Range(1, 50)] public int CourtCount { get; set; } = 1;

    [Range(0, 100000)] public decimal PricePerHour { get; set; }
    public bool IsAvailable { get; set; } = true;

    public string? ImageUrl { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    /// <summary>Replaces the court's booking tiers when non-null (null = leave unchanged).</summary>
    public List<CourtPriceTierInput>? BookingTiers { get; set; }

    /// <summary>Replaces the court's weekly schedule when non-null (null = leave unchanged).</summary>
    public List<CourtOpeningHourInput>? OpeningHours { get; set; }

    /// <summary>Replaces the court's price rules when non-null (null = leave unchanged).</summary>
    public List<CourtPriceRuleInput>? PriceRules { get; set; }
}

public class BookingRespondRequest
{
    public bool Approve { get; set; }
}

public class VenueBookingDto
{
    public int Id { get; set; }
    public string CourtName { get; set; } = string.Empty;
    public string VenueName { get; set; } = string.Empty;
    public string PlayerName { get; set; } = string.Empty;
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public decimal TotalPrice { get; set; }

    /// <summary>"indoor" | "outdoor".</summary>
    public string CourtType { get; set; } = "indoor";

    /// <summary>"Pending" | "Confirmed" | "Cancelled" | "Completed".</summary>
    public string Status { get; set; } = string.Empty;
}

/// <summary>A court's live status right now, for the owner's home dashboard.</summary>
public class CourtLiveStatusDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    /// <summary>"indoor" | "outdoor".</summary>
    public string Type { get; set; } = "indoor";

    /// <summary>"booked" | "available" | "maintenance".</summary>
    public string Status { get; set; } = "available";

    /// <summary>e.g. "4:00 - 5:30 م" — set only when <see cref="Status"/> is "booked".</summary>
    public string? TimeRangeLabel { get; set; }
}

/// <summary>A match-hosting request awaiting the venue owner's approval.</summary>
public class VenueMatchRequestDto
{
    public int Id { get; set; }
    public string CourtName { get; set; } = string.Empty;
    public string VenueName { get; set; } = string.Empty;
    public string CreatorName { get; set; } = string.Empty;
    public DateTime ScheduledAt { get; set; }
    public int DurationMinutes { get; set; }
    public int MaxPlayers { get; set; }

    /// <summary>Per-player share for this match.</summary>
    public decimal PricePerPlayer { get; set; }

    /// <summary>"share" | "full" — whether the creator paid in full.</summary>
    public string PaymentMode { get; set; } = "share";

    /// <summary>Amount the creator paid up-front and is held until you respond.</summary>
    public decimal AmountHeld { get; set; }

    /// <summary>"Open" | "PendingApproval" | "Cancelled" | …</summary>
    public string Status { get; set; } = string.Empty;

    /// <summary>
    /// حدث أنشأه صاحب الملعب نفسه على ملعبه (استضافة): لا موافقة يطلبها من
    /// نفسه، ويملك وحده إلغاءه وردّ حصص المسجّلين.
    /// </summary>
    public bool IsVenueHosted { get; set; }

    /// <summary>عدد المسجّلين المعتمدين — يهمّ المضيف قبل الإلغاء.</summary>
    public int RegisteredPlayers { get; set; }

    /// <summary>"match" | "americano" | "tournament" — نوع الحدث للشارة في التطبيق.</summary>
    public string Kind { get; set; } = "match";

    /// <summary>معرّف الأمريكانو/البطولة (لفتح صفحتها)؛ null للمباراة العادية.</summary>
    public int? AmericanoId { get; set; }

    /// <summary>اسم البطولة الإقصائية إن وُجد.</summary>
    public string? Title { get; set; }
}

/// <summary>One player in a match request (owner-facing details view).</summary>
public class VenueMatchPlayerDto
{
    public int UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public int? Level { get; set; }

    /// <summary>Whether this player already paid their share.</summary>
    public bool HasPaid { get; set; }

    /// <summary>"pending" | "approved".</summary>
    public string Status { get; set; } = "approved";

    /// <summary>The player who created the match.</summary>
    public bool IsCreator { get; set; }

    public DateTime JoinedAt { get; set; }
}

/// <summary>
/// The full picture of one match request: everything the list card shows plus
/// the joined players, how to reach the creator, and the money the owner ends
/// up with. Returned by GET /api/venues/match-requests/{id}.
/// </summary>
public class VenueMatchRequestDetailDto : VenueMatchRequestDto
{
    public int CreatorId { get; set; }
    public string CreatorPhone { get; set; } = string.Empty;
    public string? CreatorAvatarUrl { get; set; }

    /// <summary>Enum name lowercased ("singles" | "doubles" | …).</summary>
    public string MatchType { get; set; } = string.Empty;

    /// <summary>نوع اللاعبين المنضمين — "male" | "female".</summary>
    public string Gender { get; set; } = "male";

    public float MinLevel { get; set; }
    public float MaxLevel { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }

    /// <summary>Players already in the match (creator included).</summary>
    public List<VenueMatchPlayerDto> Players { get; set; } = [];

    public int CurrentPlayers { get; set; }

    /// <summary>Full price of the match: per-player share × max players.</summary>
    public decimal TotalPrice { get; set; }

    /// <summary>نسبة سبورتا applied to what the owner is paid.</summary>
    public decimal SportaCommissionPercent { get; set; }

    /// <summary>
    /// صافي ما سيستلمه المالك من المبلغ المحجوز عند القبول (بعد نسبة سبورتا).
    /// </summary>
    public decimal OwnerEarning { get; set; }
}

/// <summary>Venue-owner home dashboard stats.</summary>
public class VenueDashboardDto
{
    public int VenuesCount { get; set; }
    public int CourtsCount { get; set; }
    public int TodayBookings { get; set; }
    public decimal MonthRevenue { get; set; }

    /// <summary>Owner earnings (net of نسبة سبورتا) for the current week (Sat–Fri).</summary>
    public decimal WeekRevenue { get; set; }

    /// <summary>Today's booked hours ÷ total bookable hours across all owned
    /// courts (accounting for each court's <c>CourtCount</c>), 0–100.</summary>
    public double BookingRatePercent { get; set; }

    /// <summary>Confirmed/completed bookings this week (Sat–Fri).</summary>
    public int WeekBookingsCount { get; set; }

    /// <summary>Total booked hours this week across all owned courts.</summary>
    public double WeekPlayHours { get; set; }

    /// <summary>Average owner rate per hour this week (base price, not gross).</summary>
    public decimal WeekAvgHourlyPrice { get; set; }

    public List<VenueBookingDto> RecentBookings { get; set; } = [];

    /// <summary>Each owned court's status right now (booked/available/maintenance).</summary>
    public List<CourtLiveStatusDto> LiveCourtStatuses { get; set; } = [];

    /// <summary>Future confirmed bookings, nearest first.</summary>
    public List<VenueBookingDto> UpcomingBookings { get; set; } = [];
}

// ── Financial reports ────────────────────────────────────────────────────────

public class RevenueBarDto
{
    public string Label { get; set; } = string.Empty;
    public decimal Amount { get; set; }
}

public class CourtRevenueDto
{
    public string CourtName { get; set; } = string.Empty;
    public decimal Total { get; set; }

    /// <summary>Share of the period's total revenue, 0–100.</summary>
    public double Percent { get; set; }
    public int BookingsCount { get; set; }
}

public class RevenueTransactionDto
{
    public string CourtName { get; set; } = string.Empty;
    public string TimeRangeLabel { get; set; } = string.Empty;
    public string PlayerName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public DateTime Date { get; set; }
}

/// <summary>A revenue report for one period (month or week), for the
/// financial-reports page.</summary>
public class VenueRevenueReportDto
{
    /// <summary>"month" | "week".</summary>
    public string PeriodType { get; set; } = "month";

    /// <summary>e.g. "يونيو 2026" or "الأسبوع 1 - 1-7 يونيو".</summary>
    public string PeriodLabel { get; set; } = string.Empty;

    public decimal Total { get; set; }

    /// <summary>% change vs. the immediately preceding period (null if there's
    /// no data for the previous period to compare against).</summary>
    public double? ChangePercent { get; set; }

    public List<RevenueBarDto> Bars { get; set; } = [];
    public List<CourtRevenueDto> CourtBreakdown { get; set; } = [];
    public List<RevenueTransactionDto> Transactions { get; set; } = [];
}
