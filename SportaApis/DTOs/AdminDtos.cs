using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

public class AdminBroadcastRequest
{
    [Required] public string Title { get; set; } = string.Empty;
    [Required] public string Body { get; set; } = string.Empty;
}

public class AdminDeleteNotificationsRequest
{
    [Required, MinLength(1)] public List<int> Ids { get; set; } = [];

    /// <summary>
    /// للبث العام: احذف نسخته من كل المستخدمين لا السطر المحدد وحده
    /// (البث يُخزَّن سطراً لكل مستخدم).
    /// </summary>
    public bool WholeBroadcast { get; set; }
}

public class AdminSendNotificationRequest
{
    [Required] public int UserId { get; set; }
    [Required] public string Title { get; set; } = string.Empty;
    [Required] public string Body { get; set; } = string.Empty;
}

public class AdminStatsDto
{
    public int TotalUsers { get; set; }
    public int TotalPlayers { get; set; }
    public int TotalCoaches { get; set; }
    public int TotalVenueOwners { get; set; }
    public int TotalVenues { get; set; }
    public int TotalCourts { get; set; }
    public int TotalMatches { get; set; }
    public int TotalBookings { get; set; }
    public int PendingBookings { get; set; }
    public int TotalCoachSessions { get; set; }
    public int TotalAds { get; set; }
    public int TotalTournaments { get; set; }
    public decimal TotalRevenue { get; set; }
}

public class AdminUserDto
{
    public int Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? City { get; set; }
    public string? FavoriteSport { get; set; }
    public List<string> Roles { get; set; } = [];

    /// <summary>أدوار بانتظار اعتماد الأدمن — "coach" / "venue". الحساب يعمل
    /// كلاعب حتى الاعتماد، ويظهر عليه زر التفعيل في اللوحة.</summary>
    public List<string> PendingRoles { get; set; } = [];

    public int? Level { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? AvatarUrl { get; set; }
}

/// <summary>
/// كل بيانات الحساب في مكان واحد — تُستخدم في صفحة «تفاصيل الحساب» بلوحة
/// التحكم. ترث حقول <see cref="AdminUserDto"/> فيبقى أي مستهلك قديم يعمل،
/// وتضيف عليها الملف الشخصي والمحفظة والاشتراك والوثائق والإحصائيات.
/// الأقسام الخاصة بدور معيّن (<see cref="Player"/> / <see cref="Coach"/> /
/// <see cref="Staff"/>) تبقى null لمن لا يملك ذلك الدور.
/// </summary>
public class AdminUserDetailDto : AdminUserDto
{
    // ── بيانات شخصية ────────────────────────────────────────────────────────
    /// <summary>"male" | "female" | null.</summary>
    public string? Gender { get; set; }
    public string? Country { get; set; }
    public string? District { get; set; }

    /// <summary>"ar" | "en".</summary>
    public string PreferredLanguage { get; set; } = "ar";

    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    /// <summary>"player" | "coach" | "venue" | "admin" | "staff" — النوع الأساسي.</summary>
    public string UserType { get; set; } = "player";

    public DateTime? UpdatedAt { get; set; }

    // ── الحساب البنكي ───────────────────────────────────────────────────────
    public string? Iban { get; set; }
    public string? BankName { get; set; }
    public string? AccountHolderName { get; set; }

    // ── الوثائق المرفوعة ────────────────────────────────────────────────────
    public string? IdImageUrl { get; set; }
    public string? CommercialRegistrationImageUrl { get; set; }
    public string? TaxCertificateImageUrl { get; set; }

    // ── المالية والولاء ─────────────────────────────────────────────────────
    public decimal WalletBalance { get; set; }
    public int PointsBalance { get; set; }

    // ── الاشتراك ────────────────────────────────────────────────────────────
    public AdminUserSubscriptionDto? Subscription { get; set; }

    // ── نشاط الحساب ─────────────────────────────────────────────────────────
    public AdminUserActivityDto Activity { get; set; } = new();

    // ── أقسام حسب الدور ─────────────────────────────────────────────────────
    public AdminUserPlayerDto? Player { get; set; }
    public AdminUserCoachDto? Coach { get; set; }
    public AdminUserStaffDto? Staff { get; set; }

    /// <summary>الأندية التي يملكها (لمالك الملعب).</summary>
    public List<AdminUserVenueDto> Venues { get; set; } = [];

    // ── آخر السجلات (أحدث 10 لكل نوع) ───────────────────────────────────────
    public List<AdminUserBookingDto> RecentBookings { get; set; } = [];
    public List<AdminUserMatchDto> RecentMatches { get; set; } = [];

    /// <summary>الجلسات التي حجزها كمتدرّب.</summary>
    public List<AdminUserSessionDto> SessionsAsPlayer { get; set; } = [];

    /// <summary>الجلسات التي درّبها (للمدربين).</summary>
    public List<AdminUserSessionDto> SessionsAsCoach { get; set; } = [];

    public List<AdminUserWalletTxDto> RecentWalletTransactions { get; set; } = [];

    /// <summary>الأصدقاء المقبولون (اسم + صورة، لعرضهم كقائمة).</summary>
    public List<AdminUserFriendDto> Friends { get; set; } = [];
}

public class AdminUserSubscriptionDto
{
    /// <summary>"free" | "sportaPlus".</summary>
    public string Plan { get; set; } = "free";
    public string? PackageName { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public bool IsActive { get; set; }
}

public class AdminUserActivityDto
{
    /// <summary>حجوزات الملاعب التي أنشأها الحساب.</summary>
    public int TotalBookings { get; set; }
    public int CancelledBookings { get; set; }

    /// <summary>إجمالي ما دفعه على الحجوزات المكتملة.</summary>
    public decimal TotalSpent { get; set; }

    /// <summary>المباريات التي شارك فيها.</summary>
    public int TotalMatches { get; set; }

    /// <summary>جلسات التدريب التي حجزها كمتدرّب.</summary>
    public int CoachSessionsAsPlayer { get; set; }

    /// <summary>الجلسات التي درّبها (للمدربين).</summary>
    public int CoachSessionsAsCoach { get; set; }

    public int Friends { get; set; }
    public int Notifications { get; set; }
    public DateTime? LastActivityAt { get; set; }
}

public class AdminUserPlayerDto
{
    /// <summary>1..7 — مستوى اللاعب.</summary>
    public int Level { get; set; }
    public string? AssessmentLevelName { get; set; }

    /// <summary>"right" | "left".</summary>
    public string PreferredHand { get; set; } = string.Empty;

    /// <summary>"right" | "left" | "both".</summary>
    public string CourtPosition { get; set; } = string.Empty;

    /// <summary>"open" | "social" | "training" | ... — نوع المباراة المفضّل.</summary>
    public string PreferredMatchType { get; set; } = string.Empty;

    /// <summary>"morning" | "afternoon" | "evening" | "any".</summary>
    public string PreferredPlayTime { get; set; } = string.Empty;

    public int? PlayStartYear { get; set; }
    public float EloRating { get; set; }
    public float ReliabilityScore { get; set; }
    public int TotalMatches { get; set; }
    public int TotalWins { get; set; }
    public float WinRate { get; set; }
    public float PeerRatingAverage { get; set; }
    public int PeerRatingCount { get; set; }
}

public class AdminUserCoachDto
{
    /// <summary>معرّف ملف المدرب (يُستخدم لفتح صفحة المدرب).</summary>
    public int CoachProfileId { get; set; }
    public string? Bio { get; set; }
    public string? Specialization { get; set; }
    public List<string> SpecializationNames { get; set; } = [];
    public string? SportName { get; set; }
    public decimal HourlyRate { get; set; }
    public decimal? PackagePrice { get; set; }
    public string? Certifications { get; set; }

    /// <summary>"lessThanYear" | "oneToThree" | "threeToFive" | "moreThanFive".</summary>
    public string ExperienceLevel { get; set; } = string.Empty;

    /// <summary>"male" | "female" — الفئة المستهدفة.</summary>
    public string TargetGender { get; set; } = string.Empty;

    /// <summary>"saudi" | "resident".</summary>
    public string Residency { get; set; } = string.Empty;

    public string? PreferredVenueName { get; set; }
    public List<string> AvailableDays { get; set; } = [];
    public bool IsVerified { get; set; }
    public float Rating { get; set; }
    public int TotalRatings { get; set; }
    public int TotalSessions { get; set; }
    public string? NationalIdFrontUrl { get; set; }
    public string? NationalIdBackUrl { get; set; }
    public string? IdDocumentUrl { get; set; }
}

public class AdminUserStaffDto
{
    public string? JobTitle { get; set; }
    public string? CountryName { get; set; }

    /// <summary>null تعني «كل مدن الدولة».</summary>
    public string? CityName { get; set; }
    public List<string> Permissions { get; set; } = [];
}

public class AdminUserVenueDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? City { get; set; }
    public bool IsActive { get; set; }
    public bool IsApproved { get; set; }
    public int Courts { get; set; }

    /// <summary>صورة الغلاف (تُعرض كمصغّرة في لوحة التحكم).</summary>
    public string? ImageUrl { get; set; }

    /// <summary>باقي صور النادي.</summary>
    public List<string> Images { get; set; } = [];

    // وثائق النادي المرفوعة عند التسجيل
    public string? CommercialRegistrationImageUrl { get; set; }
    public string? NationalAddressImageUrl { get; set; }
    public string? OwnerIdImageUrl { get; set; }
}

public class AdminUserBookingDto
{
    public int Id { get; set; }
    public string CourtName { get; set; } = string.Empty;
    public string? VenueName { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public decimal TotalPrice { get; set; }

    /// <summary>Pending | Confirmed | Cancelled | Completed.</summary>
    public string Status { get; set; } = string.Empty;
    public bool PaidFullAmount { get; set; }
}

public class AdminUserMatchDto
{
    public int Id { get; set; }

    /// <summary>"open" | "social" | "training" | ... — نوع المباراة.</summary>
    public string MatchType { get; set; } = string.Empty;

    /// <summary>Open | Full | InProgress | Completed | Cancelled | PendingApproval.</summary>
    public string Status { get; set; } = string.Empty;

    public DateTime ScheduledAt { get; set; }
    public string? CourtName { get; set; }
    public string? VenueName { get; set; }
    public decimal PricePerPlayer { get; set; }

    /// <summary>هل هذا المستخدم هو منشئ المباراة.</summary>
    public bool IsCreator { get; set; }

    /// <summary>النتيجة النهائية إن سُجّلت (مثل "6 - 4").</summary>
    public string? Score { get; set; }
}

public class AdminUserSessionDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;

    /// <summary>الطرف الآخر: اسم المدرب في جلسات المتدرّب، واسم اللاعب في جلسات المدرب.</summary>
    public string? CounterpartName { get; set; }

    public DateTime ScheduledAt { get; set; }
    public int DurationMinutes { get; set; }
    public decimal Price { get; set; }

    /// <summary>Pending | Confirmed | Rejected.</summary>
    public string Status { get; set; } = string.Empty;
    public bool IsCompleted { get; set; }
    public bool IsPaid { get; set; }
    public string? CourtName { get; set; }
}

public class AdminUserWalletTxDto
{
    public int Id { get; set; }
    public decimal Amount { get; set; }

    /// <summary>Deposit | Refund | BookingPayment | … (WalletTransactionType).</summary>
    public string Type { get; set; } = string.Empty;

    /// <summary>Completed | Failed.</summary>
    public string Status { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class AdminUserFriendDto
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public string? City { get; set; }
}

public class AdminNotificationDto
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;

    /// <summary>
    /// بث عام مجمَّع في سطر واحد (يُخزَّن نسخة لكل مستخدم). عندها
    /// <see cref="RecipientCount"/> عدد المستلمين و<see cref="ReadCount"/> من قرأه.
    /// </summary>
    public bool IsBroadcast { get; set; }
    public int RecipientCount { get; set; } = 1;
    public int ReadCount { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string? Type { get; set; }
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
}

/// <summary>A single court booking, platform-wide (admin "invoices" view).</summary>
public class AdminBookingDto
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string CourtName { get; set; } = string.Empty;
    public string VenueName { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public int DurationMinutes { get; set; }
    /// <summary>ما دفعه اللاعب (سعر المالك؛ نسبة سبورتا مقتطعة منه لا مضافة إليه).</summary>
    public decimal TotalPrice { get; set; }

    /// <summary>حصة سبورتا من هذا الحجز (لقطة وقت الحجز).</summary>
    public decimal SportaCommission { get; set; }

    /// <summary>مستحقات مالك الملعب = المدفوع ناقص حصة سبورتا.</summary>
    public decimal OwnerAmount { get; set; }

    public string Status { get; set; } = string.Empty;
    public bool PaidFullAmount { get; set; }
    public DateTime CreatedAt { get; set; }
}

// ── Finance ────────────────────────────────────────────────────────────────

/// <summary>A single wallet transaction, platform-wide (admin finance view).</summary>
public class AdminTransactionDto
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string UserPhone { get; set; } = string.Empty;

    /// <summary>Signed amount as stored (negative = charge/withdrawal, positive = credit).</summary>
    public decimal Amount { get; set; }

    /// <summary>Enum name camelCased: deposit | refund | matchPayment | ... | withdrawal.</summary>
    public string Type { get; set; } = string.Empty;

    /// <summary>"in" when the amount credits the wallet, "out" when it debits it.</summary>
    public string Direction { get; set; } = string.Empty;

    /// <summary>
    /// "completed" | "failed". A failed row is an audit record of a rejected
    /// payment attempt — no money moved, and it is excluded from finance stats.
    /// </summary>
    public string Status { get; set; } = string.Empty;

    public string? Description { get; set; }

    /// <summary>Linked entity id (booking / match / session / withdrawal request).</summary>
    public int? ReferenceId { get; set; }

    /// <summary>Payment-gateway charge id (null until a real gateway is wired).</summary>
    public string? PaymentReference { get; set; }

    /// <summary>Stable internal reference shown in the UI, e.g. "TXN-000123".</summary>
    public string InternalReference { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
}

/// <summary>Amount + count aggregated for one transaction type.</summary>
public class FinanceTypeBreakdown
{
    public string Type { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public int Count { get; set; }
}

/// <summary>Platform-wide financial summary (incoming / outgoing / balances).</summary>
public class FinanceStatsDto
{
    /// <summary>Real money into the platform = wallet top-ups (deposits).</summary>
    public decimal TotalIncoming { get; set; }

    /// <summary>Real money out of the platform = approved withdrawals paid to banks.</summary>
    public decimal TotalOutgoing { get; set; }

    /// <summary>Incoming − Outgoing (net real cash flow).</summary>
    public decimal NetFlow { get; set; }

    public decimal TotalDeposits { get; set; }
    public decimal TotalRefunds { get; set; }
    public decimal TotalEarnings { get; set; }   // coach + venue + creator earnings
    public decimal TotalSpend { get; set; }       // match/booking/coach payments + subscriptions

    /// <summary>Sum of every user's current wallet balance (float the platform holds).</summary>
    public decimal TotalWalletBalance { get; set; }

    public int PendingWithdrawalsCount { get; set; }
    public decimal PendingWithdrawalsAmount { get; set; }

    public int TransactionCount { get; set; }

    public List<FinanceTypeBreakdown> ByType { get; set; } = [];
}

/// <summary>نسبة سبورتا — per-court platform markup set by the admin.</summary>
public class UpdateCourtCommissionRequest
{
    [Range(0, 100)] public decimal Percent { get; set; }
}

/// <summary>Admin suspend/reinstate toggle for a court.</summary>
public class UpdateCourtSuspendedRequest
{
    public bool Suspended { get; set; }
}

/// <summary>Admin approve/revoke toggle for a venue.</summary>
public class UpdateVenueApprovedRequest
{
    public bool Approved { get; set; }
}

/// <summary>تفعيل/إيقاف دور يحتاج اعتماداً — "coach" أو "venue".</summary>
public class ApproveUserRoleRequest
{
    public string? Role { get; set; }
    public bool Approved { get; set; } = true;
}

/// <summary>تعديل مستوى لاعب من اللوحة — تجاوز يدوي لما قرّره التقييم.</summary>
public class SetPlayerLevelRequest
{
    /// <summary>سُلَّم <c>PlayerLevel</c> السباعي: 1 مبتدئ … 7 نخبة.</summary>
    [Range(1, 7)]
    public int Level { get; set; }
}

public class SaveAdRequest
{
    /// <summary>النصوص كلها اختيارية — الصورة وحدها إلزامية (إعلان صورة فقط مقبول).</summary>
    public string Title { get; set; } = string.Empty;
    public string Subtitle { get; set; } = string.Empty;
    public string? TitleEn { get; set; }
    public string? SubtitleEn { get; set; }
    [Required] public string ImageUrl { get; set; } = string.Empty;
    public string? Target { get; set; }
    /// <summary>أماكن الظهور مفصولة بفواصل؛ الفارغ = الرئيسية.</summary>
    public string? Placements { get; set; }
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; } = 0;
}
