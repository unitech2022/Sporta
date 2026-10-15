using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

// ── Requests ──────────────────────────────────────────────────────────────────

public class CreateAmericanoRequest
{
    public int? CourtId { get; set; }

    /// <summary>استضافة من حساب الملعب (ملعبه فقط): منظّم لا لاعب ولا يدفع.</summary>
    public bool HostedByVenue { get; set; }

    /// <summary>"singles" (American) | "teams" (AmericanTeam).</summary>
    public string Type { get; set; } = "singles";

    /// <summary>بطولة — same americano system, but may span one or more days.</summary>
    public bool IsTournament { get; set; }

    /// <summary>Tournament last day (date-only). Null or same day = one-day event.</summary>
    public DateTime? EndDate { get; set; }

    [Required] public DateTime ScheduledAt { get; set; }
    [Range(30, 240)] public int DurationMinutes { get; set; } = 90;

    [Range(1, 7)] public float MinLevel { get; set; } = 1;
    [Range(1, 7)] public float MaxLevel { get; set; } = 7;

    /// <summary>The other participants (creator is added automatically).</summary>
    public List<int> PlayerIds { get; set; } = [];

    // ── singles americano/tournament only ──
    /// <summary>How many players take part in total, creator included. At least 4
    /// (one full game) and open-ended above that, so a tournament can host 20 or 50.
    /// Ignored for teams americano, where TeamCount sets the roster.</summary>
    public int PlayerCount { get; set; } = 4;

    // ── teams americano only ──
    /// <summary>How many fixed teams take part (2 players each). At least 2 and
    /// open-ended above that. Teams americano only.</summary>
    [Range(2, int.MaxValue)] public int TeamCount { get; set; } = 2;

    /// <summary>Which team the creator plays on (1..TeamCount). Teams americano only.</summary>
    [Range(1, int.MaxValue)] public int CreatorTeam { get; set; } = 1;

    /// <summary>Optional friend invited as the creator's partner on their team.</summary>
    public int? PartnerId { get; set; }
}

/// <summary>Body for joining a teams americano: the team to take + optional partner.</summary>
public class JoinAmericanoRequest
{
    /// <summary>Team to join (1..TeamCount); out-of-range picks the first free team.</summary>
    [Range(1, int.MaxValue)] public int Team { get; set; } = 2;
    public int? PartnerId { get; set; }
}

/// <summary>A captain invites a friend to their team (teams americano).</summary>
public class AmericanoInviteRequest
{
    [Required] public int UserId { get; set; }
}

/// <summary>The invited partner accepts or declines.</summary>
public class AmericanoInviteRespondRequest
{
    public bool Accept { get; set; }
}

public class SubmitRoundScoreRequest
{
    [Range(0, 99)] public int Team1Score { get; set; }
    [Range(0, 99)] public int Team2Score { get; set; }
}

// ── Responses ─────────────────────────────────────────────────────────────────

public class AmericanoPlayerDto
{
    public int UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int? Level { get; set; }

    /// <summary>الصورة الشخصية (رابط نسبي) — تُعرض بإطار بلون المستوى.</summary>
    public string? AvatarUrl { get; set; }

    /// <summary>Fixed team number (1..TeamCount) for teams americano; null for singles.</summary>
    public int? Team { get; set; }

    /// <summary>"approved" (confirmed member) | "invited" (partner awaiting reply).</summary>
    public string Status { get; set; } = "approved";

    /// <summary>طلب انسحاب متأخر ينتظر موافقة المنظّم.</summary>
    public bool WithdrawalRequested { get; set; }
}

public class AmericanoRoundDto
{
    public int Id { get; set; }
    public int RoundNumber { get; set; }
    public List<AmericanoPlayerDto> Team1 { get; set; } = [];
    public List<AmericanoPlayerDto> Team2 { get; set; } = [];
    public int? Team1Score { get; set; }
    public int? Team2Score { get; set; }
    public bool IsCompleted { get; set; }

    /// <summary>نتيجة أدخلها أحد لاعبي الجولة وتنتظر تأكيد الفريق الآخر.</summary>
    public PendingResultDto? PendingResult { get; set; }

    /// <summary>رُفضت نتيجة مقترحة — خلاف يحسمه المنظّم.</summary>
    public bool IsDisputed { get; set; }
}

/// <summary>
/// صف في جدول الترتيب. في أمريكانو الفردي الصف لاعب؛ في أمريكانو الفرق الصف
/// <b>فريق</b>: <see cref="UserId"/> قائده (اللاعب الأول) و<see cref="Name"/>
/// اسما لاعبيه معاً، فيبقى العميل القديم يعرض 8 صفوف صحيحة بلا تغيير.
/// </summary>
public class AmericanoStandingDto
{
    public int Rank { get; set; }
    public int UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int Points { get; set; }
    public int Wins { get; set; }
    public int Played { get; set; }

    /// <summary>النقاط المسجَّلة ناقص النقاط المستقبَلة — فاصل التعادل الثالث.</summary>
    public int Diff { get; set; }

    /// <summary>رقم الفريق (1..N) في أمريكانو الفرق؛ null في الفردي.</summary>
    public int? Team { get; set; }

    /// <summary>لاعبو الصف: واحد في الفردي، اثنان في الفرق.</summary>
    public List<int> UserIds { get; set; } = [];
}

public class AmericanoDto
{
    public int Id { get; set; }
    public int MatchId { get; set; }

    /// <summary>The user who created the americano (only they can enter scores).</summary>
    public int CreatorId { get; set; }

    /// <summary>"singles" | "teams".</summary>
    public string Type { get; set; } = "singles";

    /// <summary>بطولة — americano that may span one or more days.</summary>
    public bool IsTournament { get; set; }

    /// <summary>Tournament last day; null for americano / one-day tournaments.</summary>
    public DateTime? EndDate { get; set; }

    /// <summary>اسم البطولة الإقصائية؛ null للأمريكانو.</summary>
    public string? Name { get; set; }

    /// <summary>"groups" | "knockout" للبطولة الإقصائية؛ null للأمريكانو.</summary>
    public string? Format { get; set; }

    public DateTime ScheduledAt { get; set; }

    /// <summary>مدة اللقاء بالدقائق — نفسها في كل يوم من أيام البطولة.</summary>
    public int DurationMinutes { get; set; }

    public int TotalRounds { get; set; }
    public int MaxPlayers { get; set; }

    /// <summary>Number of fixed teams (2 players each); 0 for a singles americano.</summary>
    public int TeamCount { get; set; }

    public bool IsCompleted { get; set; }

    /// <summary>حالة الحدث: pendingApproval | open | full | inProgress | completed | cancelled.
    /// الملغى والمنتهي لا يُنضمّ إليهما.</summary>
    public string MatchStatus { get; set; } = "open";

    /// <summary>حدث يستضيفه صاحب الملعب (منظّم لا لاعب) — يظهر له زر الإلغاء.</summary>
    public bool IsVenueHosted { get; set; }

    public float MinLevel { get; set; }
    public float MaxLevel { get; set; }

    public int? CourtId { get; set; }
    public string? VenueName { get; set; }
    public string? VenueNameEn { get; set; }
    public string? City { get; set; }
    public string? CityEn { get; set; }

    /// <summary>
    /// حصة اللاعب الواحد التي تُخصم عند الانضمام. صفر للأمريكانو بدون ملعب
    /// (الانضمام مجاني) — انظر <c>AmericanoService.ChargeShareIfCourtAsync</c>.
    /// </summary>
    public decimal PricePerPlayer { get; set; }

    /// <summary>آخر لحظة للانسحاب بلا موافقة (وقت محلي): الموعد ناقص 48 ساعة.</summary>
    public DateTime WithdrawalFreeUntil { get; set; }

    /// <summary>هل الانسحاب الآن مباشر؟ وإلا يصير طلباً ينتظر المنظّم.</summary>
    public bool CanWithdrawDirectly { get; set; }

    public List<AmericanoPlayerDto> Players { get; set; } = [];
    public List<AmericanoRoundDto> Rounds { get; set; } = [];
    public List<AmericanoStandingDto> Standings { get; set; } = [];
}
