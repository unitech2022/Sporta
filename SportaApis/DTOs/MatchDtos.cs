using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

// ── Requests ──────────────────────────────────────────────────────────────────

public class InvitePlayerRequest
{
    [Required] public int UserId { get; set; }
}

public class MatchRatingInput
{
    [Required] public int RatedUserId { get; set; }
    [Range(1, 5)] public int Score { get; set; }
}

public class SubmitMatchResultRequest
{
    public int? Team1Score { get; set; }
    public int? Team2Score { get; set; }

    /// <summary>
    /// لاعبو الفريق الأول (الباقون هم الفريق الثاني). اختياري — بدونه تُحفظ
    /// النتيجة بلا توزيع فرق فلا تُحتسب نقاط المستوى لأحد.
    /// </summary>
    public List<int> Team1PlayerIds { get; set; } = [];

    /// <summary>Peer ratings the current user gives to the other players.</summary>
    public List<MatchRatingInput> Ratings { get; set; } = [];
}

public class CreateMatchRequest
{
    public int? CourtId { get; set; }

    /// <summary>Enum name: open | social | training | competitive | american | americanteam | event | lesson.</summary>
    public string MatchType { get; set; } = "social";

    /// <summary>نوع اللاعبين المنضمين — "male" (رجال) | "female" (نساء). إلزامي.</summary>
    [Required] public string Gender { get; set; } = string.Empty;

    [Required] public DateTime ScheduledAt { get; set; }
    [Range(30, 240)] public int DurationMinutes { get; set; } = 90;
    [Range(2, 8)] public int MaxPlayers { get; set; } = 4;

    [Range(1, 7)] public float MinLevel { get; set; } = 1;
    [Range(1, 7)] public float MaxLevel { get; set; } = 7;

    /// <summary>Per-player share. Ignored for court matches — the venue owner's tier sets it.</summary>
    public decimal PricePerPlayer { get; set; }

    /// <summary>"share" | "full". Full = creator pays the whole match; players join free.</summary>
    public string PaymentMode { get; set; } = "share";

    public string? Notes { get; set; }

    /// <summary>مباراة خاصة: بدعوة المنشئ فقط، ولا تظهر في البحث العام.</summary>
    public bool IsPrivate { get; set; }

    /// <summary>استضافة من حساب الملعب: المنشئ منظّم لا لاعب ولا يدفع (ملعبه فقط).
    /// بدونها يُعامل صاحب الملعب كأي لاعب حتى على ملعبه.</summary>
    public bool HostedByVenue { get; set; }
}

// ── Responses ─────────────────────────────────────────────────────────────────

public class MatchPlayerDto
{
    public int UserId { get; set; }
    public string Name { get; set; } = string.Empty;

    /// <summary>الصورة الشخصية للاعب (من حساب المستخدم).</summary>
    public string? AvatarUrl { get; set; }

    public int? Level { get; set; }
    public bool HasPaid { get; set; }

    /// <summary>ما دفعه اللاعب فعلاً عن حصته (null = لم يدفع بعد).</summary>
    public decimal? PaidAmount { get; set; }

    /// <summary>"pending" | "approved".</summary>
    public string Status { get; set; } = "approved";

    /// <summary>فريق اللاعب في المباراة (1 أو 2) بعد إدخال النتيجة؛ null قبلها.</summary>
    public int? Team { get; set; }

    /// <summary>طلب انسحاب متأخر ينتظر موافقة المنشئ.</summary>
    public bool WithdrawalRequested { get; set; }
}

/// <summary>المنشئ يقبل/يرفض طلب انسحاب لاعب.</summary>
public class WithdrawalRespondRequest
{
    public int UserId { get; set; }
    public bool Approve { get; set; }
}

/// <summary>نتيجة الانسحاب: withdrawn | requested | requestCancelled، مع الحدث بعده.</summary>
public class WithdrawalResultDto<T>
{
    public string Outcome { get; set; } = "withdrawn";
    public T Event { get; set; } = default!;
}

/// <summary>A pending join request (creator-facing).</summary>
public class JoinRequestRespondRequest
{
    public int UserId { get; set; }
    public bool Approve { get; set; }
}

/// <summary>The invited player's response to a match invitation.</summary>
public class InviteRespondRequest
{
    public bool Accept { get; set; }
}

public class MatchDto
{
    public int Id { get; set; }
    public int CreatorId { get; set; }

    /// <summary>Enum name lowercased.</summary>
    public string MatchType { get; set; } = string.Empty;

    /// <summary>"Open" | "Full" | "InProgress" | "Completed" | "Cancelled".</summary>
    public string Status { get; set; } = string.Empty;

    /// <summary>
    /// مباراة يستضيفها صاحب الملعب على ملعبه: هو المنظّم لا لاعب، والتسجيل
    /// مفتوح، وحصص اللاعبين تذهب إليه — والتطبيق يعرض له زر الإلغاء.
    /// </summary>
    public bool IsVenueHosted { get; set; }


    /// <summary>نوع اللاعبين المنضمين — "male" | "female".</summary>
    public string Gender { get; set; } = "male";

    public DateTime ScheduledAt { get; set; }
    public int DurationMinutes { get; set; }

    public int MaxPlayers { get; set; }
    public int CurrentPlayers { get; set; }

    public float MinLevel { get; set; }
    public float MaxLevel { get; set; }
    public decimal PricePerPlayer { get; set; }

    /// <summary>"share" | "full".</summary>
    public string PaymentMode { get; set; } = "share";

    /// <summary>True when the creator paid the whole match and players join for free.</summary>
    public bool CreatorPaidFull { get; set; }

    public int? Team1Score { get; set; }
    public int? Team2Score { get; set; }

    /// <summary>نتيجة أدخلها لاعب وتنتظر تأكيد لاعب من الفريق الآخر.</summary>
    public PendingResultDto? PendingResult { get; set; }

    /// <summary>المستخدم الحالي لاعب في الفريق المقابل للمقترِح فيستطيع التأكيد/الرفض.</summary>
    public bool CanConfirmResult { get; set; }

    /// <summary>رُفضت نتيجة مقترحة ولم تُعتمد بعدها نتيجة — خلاف يحسمه المنظّم.</summary>
    public bool IsResultDisputed { get; set; }

    /// <summary>المستخدم الحالي هو المنظّم والنتيجة محل خلاف.</summary>
    public bool CanResolveResult { get; set; }

    public string? Notes { get; set; }

    /// <summary>مباراة خاصة: بدعوة المنشئ فقط، ولا تظهر في البحث العام.</summary>
    public bool IsPrivate { get; set; }

    public int? CourtId { get; set; }
    public string? VenueName { get; set; }
    public string? VenueNameEn { get; set; }
    public string? City { get; set; }

    /// <summary>اسم المدينة بالإنجليزية (من جدول المدن).</summary>
    public string? CityEn { get; set; }

    /// <summary>الحي كما اختاره صاحب النادي، بالعربية والإنجليزية.</summary>
    public string? District { get; set; }
    public string? DistrictEn { get; set; }

    public string? Neighborhood { get; set; }

    /// <summary>Distance (km) from the requesting user (null if unknown).</summary>
    public double? DistanceKm { get; set; }

    public List<MatchPlayerDto> Players { get; set; } = [];

    /// <summary>True when the current user is an approved member.</summary>
    public bool HasJoined { get; set; }

    /// <summary>True when the current user has a pending join request.</summary>
    public bool HasPendingRequest { get; set; }

    /// <summary>True when the current user has a pending invitation to this match.</summary>
    public bool HasInvite { get; set; }

    /// <summary>Count of pending join requests (for the creator).</summary>
    public int PendingCount { get; set; }

    /// <summary>آخر لحظة للانسحاب بلا موافقة (وقت محلي): الموعد ناقص 24 ساعة.</summary>
    public DateTime WithdrawalFreeUntil { get; set; }

    /// <summary>هل الانسحاب الآن مباشر؟ وإلا يصير طلباً ينتظر المنشئ.</summary>
    public bool CanWithdrawDirectly { get; set; }

    /// <summary>للمستخدم الحالي طلب انسحاب ينتظر المنشئ.</summary>
    public bool WithdrawalRequested { get; set; }

    /// <summary>عدد طلبات الانسحاب المعلّقة (للمنشئ).</summary>
    public int WithdrawalRequestCount { get; set; }

    /// <summary>خاصة والمستخدم هو المنشئ: يستطيع تحويلها إلى عامة.</summary>
    public bool CanMakePublic { get; set; }

    /// <summary>
    /// المدعوون الذين لم يردّوا بعد (لا حصة عليهم ولم يدفعوا) — يراهم المنشئ
    /// واللاعبون المعتمدون فقط.
    /// </summary>
    public List<MatchPlayerDto> InvitedPlayers { get; set; } = [];

    public bool IsFull => CurrentPlayers >= MaxPlayers;
}
