using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

// ── Requests ──────────────────────────────────────────────────────────────────

/// <summary>Books a training session with a coach.</summary>
public class CreateCoachSessionRequest
{
    /// <summary>Session start time (local date+time from the app).</summary>
    [Required] public DateTime ScheduledAt { get; set; }

    [Range(30, 240)] public int DurationMinutes { get; set; } = 60;

    /// <summary>Selected training focus areas (stored in the description).</summary>
    public List<string>? Domains { get; set; }

    public string? TargetLevel { get; set; }

    /// <summary>Optional court the session takes place at.</summary>
    public int? CourtId { get; set; }
}

// ── Responses ─────────────────────────────────────────────────────────────────

/// <summary>
/// A coach (CoachProfile flattened with its User) as consumed by the app's
/// coaches list and detail screens.
/// </summary>
public class CoachDto
{
    public int Id { get; set; }

    /// <summary>The coach's underlying user account id (for admin actions).</summary>
    public int UserId { get; set; }

    public string Name { get; set; } = string.Empty;

    /// <summary>اسم المدرب بالإنجليزية (من بيانات التسجيل) — null للمدربين القدامى.</summary>
    public string? NameEn { get; set; }

    /// <summary>الصورة الشخصية للمدرب (من حساب المستخدم).</summary>
    public string? AvatarUrl { get; set; }

    public string? Bio { get; set; }

    /// <summary>Free-text specialization, plus a split list for chips.</summary>
    public string? Specialization { get; set; }
    public List<string> Specialties { get; set; } = [];

    /// <summary>اللعبة التي يتخصص فيها المدرب.</summary>
    public int? SportId { get; set; }
    public string? SportName { get; set; }
    public string? SportNameEn { get; set; }

    public decimal HourlyRate { get; set; }

    /// <summary>
    /// أعلى نسبة خصم سارية من عروض المدرب على الحجز الفردي (٠ حين لا عرض).
    /// يعرض التطبيق بها السعر قبل/بعد الخصم، والخادم يطبّقها عند الحجز.
    /// </summary>
    public decimal OfferDiscountPercent { get; set; }

    /// <summary>سعر الساعة بعد تطبيق <see cref="OfferDiscountPercent"/>.</summary>
    public decimal HourlyRateAfterOffer { get; set; }

    public float Rating { get; set; }
    public int Reviews { get; set; }
    public int Students { get; set; }

    public string? City { get; set; }

    /// <summary>اسم مدينة المدرب بالإنجليزية (من جدول المدن).</summary>
    public string? CityEn { get; set; }
    public bool IsVerified { get; set; }

    /// <summary>Distance from the requesting player (km); null when either
    /// side has no saved location.</summary>
    public double? DistanceKm { get; set; }

    /// <summary>"male" | "female" | "unknown" (drives the women badge).</summary>
    public string Gender { get; set; } = "unknown";

    // ── Admin-only fields (contact + account status) ─────────────────────────
    public string? Phone { get; set; }

    /// <summary>صورة الهوية/الإقامة المرفوعة عند التسجيل (تُعرض في لوحة التحكم).</summary>
    public string? IdDocumentUrl { get; set; }

    /// <summary>Whether the coach's account is active (false = suspended).</summary>
    public bool IsActive { get; set; } = true;

    public DateTime JoinedAt { get; set; }

    // ── Full profile fields (for the coach's own "my profile" screen) ───────
    public string? Certifications { get; set; }

    /// <summary>"lessThanYear" | "oneToThree" | "threeToFive" | "moreThanFive".</summary>
    public string ExperienceLevel { get; set; } = string.Empty;

    /// <summary>"male" | "female".</summary>
    public string TargetGender { get; set; } = string.Empty;

    public decimal? PackagePrice { get; set; }

    public int? PreferredVenueId { get; set; }
    public string? PreferredVenueName { get; set; }

    /// <summary>Day keys: "sat","sun","mon","tue","wed","thu","fri".</summary>
    public List<string> AvailableDays { get; set; } = [];

    /// <summary>"saudi" | "resident".</summary>
    public string Residency { get; set; } = string.Empty;

    public string? NationalIdFrontUrl { get; set; }
    public string? NationalIdBackUrl { get; set; }

    public List<int> SpecializationIds { get; set; } = [];
    public List<string> SpecializationNames { get; set; } = [];

    /// <summary>العروض والخصومات النشطة (تُعرض للاعبين قبل الحجز).</summary>
    public List<CoachOfferDto> Offers { get; set; } = [];
}

// ── العروض والخصومات ─────────────────────────────────────────────────────────

public class CoachOfferDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public int DiscountPercent { get; set; }

    /// <summary>"individual" | "group" | "all".</summary>
    public string TargetLabel { get; set; } = "all";
    public DateTime ExpiresAt { get; set; }
    public bool IsActive { get; set; }
    public bool IsExpired { get; set; }
}

public class CreateCoachOfferRequest
{
    [Required, MinLength(1)] public string Title { get; set; } = string.Empty;
    [Range(1, 100)] public int DiscountPercent { get; set; }

    /// <summary>"individual" | "group" | "all".</summary>
    [Required] public string TargetLabel { get; set; } = "all";
    [Required] public DateTime ExpiresAt { get; set; }
}

public class SetCoachOfferActiveRequest
{
    public bool IsActive { get; set; }
}

/// <summary>Coach home dashboard stats for the signed-in coach.</summary>
public class CoachDashboardDto
{
    public int ActiveStudents { get; set; }
    public float Rating { get; set; }
    public int TotalSessions { get; set; }
    public decimal MonthRevenue { get; set; }

    /// <summary>All-time earnings across every paid session.</summary>
    public decimal TotalRevenue { get; set; }
    public int WeekSessions { get; set; }
    public List<CoachSessionDto> UpcomingSessions { get; set; } = [];
    public List<CoachRatingDto> RecentRatings { get; set; } = [];
}

/// <summary>A player's rating of the coach for one completed session (آخر التقييمات).</summary>
public class CoachRatingDto
{
    public int SessionId { get; set; }
    public string PlayerName { get; set; } = string.Empty;
    public int Rating { get; set; }
    public string? Review { get; set; }
    public DateTime ScheduledAt { get; set; }
}

/// <summary>A booked training session with a coach.</summary>
public class CoachSessionDto
{
    public int Id { get; set; }
    public int CoachId { get; set; }
    public string CoachName { get; set; } = string.Empty;
    public DateTime ScheduledAt { get; set; }
    public int DurationMinutes { get; set; }

    /// <summary>ما يدفعه اللاعب فعلاً (بعد خصم عرض المدرب).</summary>
    public decimal Price { get; set; }

    /// <summary>السعر قبل خصم العرض — يساوي <see cref="Price"/> حين لا عرض.</summary>
    public decimal BasePrice { get; set; }

    /// <summary>نسبة خصم عرض المدرب المطبَّقة (٠ حين لا عرض).</summary>
    public decimal OfferDiscountPercent { get; set; }

    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsPaid { get; set; }

    /// <summary>The coach's rating of the player (set after a paid, ended session).</summary>
    public int? CoachRating { get; set; }
    public string? CoachReview { get; set; }

    /// <summary>The player's rating of the coach (set after a paid, ended session).</summary>
    public int? PlayerRating { get; set; }
    public string? PlayerReview { get; set; }

    /// <summary>"pending" | "Upcoming" | "rejected" | "Completed".</summary>
    public string Status { get; set; } = "Upcoming";

    /// <summary>The booking player's name (for the coach's requests view).</summary>
    public string? PlayerName { get; set; }
}

public class SessionRespondRequest
{
    public bool Approve { get; set; }
}

public class RateSessionRequest
{
    [Range(1, 5)] public int Rating { get; set; }
    public string? Review { get; set; }
}

public class UpdateCoachProfileRequest
{
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? City { get; set; }
    public string? Bio { get; set; }
    public string? Specialization { get; set; }
    public int? SportId { get; set; }
    [Range(0, 100000)] public decimal? HourlyRate { get; set; }

    public string? Certifications { get; set; }

    /// <summary>"lessThanYear" | "oneToThree" | "threeToFive" | "moreThanFive".</summary>
    public string? ExperienceLevel { get; set; }

    /// <summary>"male" | "female".</summary>
    public string? TargetGender { get; set; }

    [Range(0, 100000)] public decimal? PackagePrice { get; set; }

    /// <summary>Set to 0 to clear the preferred venue.</summary>
    public int? PreferredVenueId { get; set; }

    /// <summary>Day keys: "sat","sun","mon","tue","wed","thu","fri".</summary>
    public List<string>? AvailableDays { get; set; }

    /// <summary>"saudi" | "resident".</summary>
    public string? Residency { get; set; }

    public string? NationalIdFrontUrl { get; set; }
    public string? NationalIdBackUrl { get; set; }

    public List<int>? SpecializationIds { get; set; }
}

// ── Students (إدارة الطلاب) ─────────────────────────────────────────────────

/// <summary>One player the coach has trained (a paid session together).</summary>
public class CoachStudentDto
{
    public int PlayerId { get; set; }
    public string PlayerName { get; set; } = string.Empty;

    /// <summary>الصورة الشخصية للاعب (من حساب المستخدم).</summary>
    public string? AvatarUrl { get; set; }

    public int SessionsCount { get; set; }
    public decimal TotalSpent { get; set; }
    public DateTime LastSessionAt { get; set; }
}

// ── Financial reports (التقارير) ─────────────────────────────────────────────

/// <summary>A training-level's share of a revenue report period.</summary>
public class CoachRevenueBreakdownDto
{
    public string Label { get; set; } = string.Empty;
    public decimal Total { get; set; }

    /// <summary>Share of the period's total revenue, 0–100.</summary>
    public double Percent { get; set; }
    public int SessionsCount { get; set; }
}

public class CoachRevenueTransactionDto
{
    public string PlayerName { get; set; } = string.Empty;
    public string TargetLevel { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public DateTime Date { get; set; }
}

/// <summary>A coach's earnings report for one period (month or week).</summary>
public class CoachRevenueReportDto
{
    /// <summary>"month" | "week".</summary>
    public string PeriodType { get; set; } = "month";

    /// <summary>e.g. "يونيو 2026" or "1–7 يونيو".</summary>
    public string PeriodLabel { get; set; } = string.Empty;

    public decimal Total { get; set; }

    /// <summary>% change vs. the immediately preceding period (null if there's
    /// no data for the previous period to compare against).</summary>
    public double? ChangePercent { get; set; }

    public List<RevenueBarDto> Bars { get; set; } = [];
    public List<CoachRevenueBreakdownDto> LevelBreakdown { get; set; } = [];
    public List<CoachRevenueTransactionDto> Transactions { get; set; } = [];
}
