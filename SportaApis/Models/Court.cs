using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// الملعب الفردي داخل النادي
/// </summary>
public class Court : BaseEntity
{
    public string Name { get; set; } = string.Empty;

    /// <summary>اسم الملعب بالإنجليزية — يُدخل مع الاسم العربي عند الإنشاء.</summary>
    public string? NameEn { get; set; }

    public int VenueId { get; set; }
    public Venue Venue { get; set; } = null!;

    public CourtType Type { get; set; }

    /// <summary>
    /// عدد الملاعب — number of identical physical courts of this type. Players
    /// pick a court number (1..CourtCount) when booking. Defaults to 1.
    /// </summary>
    public int CourtCount { get; set; } = 1;

    /// <summary>Legacy hourly rate — used as a fallback when no <see cref="PriceTiers"/> are defined.</summary>
    public decimal PricePerHour { get; set; }

    /// <summary>
    /// نسبة سبورتا — platform markup (%) added on top of the owner's base
    /// prices; players see and pay the gross total. Adjustable per court from
    /// the admin dashboard.
    /// </summary>
    public decimal SportaCommissionPercent { get; set; } = DefaultSportaCommissionPercent;

    public const decimal DefaultSportaCommissionPercent = 5m;

    /// <summary>Owner-controlled availability toggle (temporary open/close).</summary>
    public bool IsAvailable { get; set; } = true;

    /// <summary>
    /// Admin-controlled suspension. When true the platform has stopped the
    /// court: it is hidden from players and cannot be booked, independently of
    /// the owner's <see cref="IsAvailable"/> flag. Toggled from the admin
    /// dashboard; the owner is notified on change.
    /// </summary>
    public bool IsSuspended { get; set; }

    public string? ImageUrl { get; set; }

    /// <summary>Court geo-location (falls back to the venue's when null).</summary>
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    /// <summary>
    /// حذف ناعم من لوحة التحكم — الملعب يختفي من كل الشاشات، وحجوزاته السابقة
    /// تبقى في السجل المالي. انظر <see cref="Venue.IsDeleted"/>.
    /// </summary>
    public bool IsDeleted { get; set; }

    public DateTime? DeletedAt { get; set; }

    // Navigation
    /// <summary>متوسط تقييم اللاعبين (0 بلا تقييمات) — يُعاد حسابه مع كل تقييم.</summary>
    public double RatingAverage { get; set; }

    /// <summary>عدد التقييمات.</summary>
    public int RatingCount { get; set; }

    public ICollection<Booking> Bookings { get; set; } = [];
    public ICollection<Match> Matches { get; set; } = [];

    /// <summary>Owner-defined duration→price tiers for bookings and matches.</summary>
    public ICollection<CourtPriceTier> PriceTiers { get; set; } = [];

    /// <summary>دوام الملعب لكل يوم من أيام الأسبوع — فارغة تعني الدوام الافتراضي.</summary>
    public ICollection<CourtOpeningHour> OpeningHours { get; set; } = [];

    /// <summary>قواعد تسعير حسب اليوم والوقت — فارغة تعني سعراً موحّداً طوال الأسبوع.</summary>
    public ICollection<CourtPriceRule> PriceRules { get; set; } = [];
}
