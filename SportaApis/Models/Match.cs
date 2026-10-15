using SportaApis.Enums;
using MatchType = SportaApis.Enums.MatchType;

namespace SportaApis.Models;

/// <summary>
/// المباراة المفتوحة - ينشئها لاعب ويتضمن بطاقة العرض (2.2)
/// </summary>
public class Match : BaseEntity, IScoreProposal
{
    public int CreatorId { get; set; }
    public User Creator { get; set; } = null!;

    public int? CourtId { get; set; }
    public Court? Court { get; set; }

    public MatchType MatchType { get; set; }
    public MatchStatus Status { get; set; } = MatchStatus.Open;

    /// <summary>
    /// حدث يستضيفه صاحب الملعب من حساب الملعب: هو المنظّم لا لاعب، فلا يكون
    /// ضمن اللاعبين. صاحب الملعب الذي ينشئ من حساب اللاعب يكون أول لاعب
    /// (كأي لاعب) ولو كان الملعب ملعبه. يحتاج Court.Venue وMatchPlayers محمّلين.
    /// </summary>
    public bool IsHostedByVenueOwner =>
        Court != null && Court.Venue.OwnerId == CreatorId
        && !MatchPlayers.Any(p => p.UserId == CreatorId);

    /// <summary>نوع اللاعبين المنضمين: رجال أو نساء.</summary>
    public Gender Gender { get; set; } = Gender.Male;

    public DateTime ScheduledAt { get; set; }
    public int DurationMinutes { get; set; } = 90;

    public int MaxPlayers { get; set; } = 4;

    // فلتر المستوى (2.3)
    public float MinLevel { get; set; } = 1;
    public float MaxLevel { get; set; } = 7;

    // سعر حصة كل لاعب (يحدده صاحب الملعب للمباريات على ملعبه)
    public decimal PricePerPlayer { get; set; }

    /// <summary>
    /// نسبة سبورتا وقت إنشاء المباراة (لقطة من الملعب حتى لا تتأثر الحصص
    /// بتغيير النسبة لاحقاً). صفر للمباريات بدون ملعب.
    /// </summary>
    public decimal SportaCommissionPercent { get; set; }

    /// <summary>
    /// صافي مستحقات مالك الملعب من المبلغ المحصَّل. النسبة مضافة فوق سعر
    /// المالك (المحصَّل = سعر المالك × (1 + النسبة/100))، فالصافي يعيد سعر
    /// المالك كما حدده — ونصيب سبورتا هو الفرق.
    /// </summary>
    public decimal NetOfCommission(decimal collectedAmount) =>
        Math.Round(collectedAmount / (1m + SportaCommissionPercent / 100m), 2);

    /// <summary>How the match is paid: each player pays their share, or the creator pays in full.</summary>
    public MatchPaymentMode PaymentMode { get; set; } = MatchPaymentMode.SharePerPlayer;

    // النتيجة النهائية (عند اكتمال المباراة)
    public int? Team1Score { get; set; }
    public int? Team2Score { get; set; }

    // نتيجة مقترحة بانتظار تأكيد لاعب من الفريق الآخر (IScoreProposal).
    public int? ProposedTeam1Score { get; set; }
    public int? ProposedTeam2Score { get; set; }
    public int? ProposedById { get; set; }
    public DateTime? ProposedAt { get; set; }
    public bool IsDisputed { get; set; }

    public string? Notes { get; set; }

    /// <summary>
    /// مباراة خاصة: لا تظهر في البحث ولا في النبض، ولا ينضم إليها إلا من دعاه
    /// المنشئ. يحوّلها المنشئ إلى عامة متى شاء (<c>POST matches/{id}/make-public</c>).
    /// </summary>
    public bool IsPrivate { get; set; }

    /// <summary>
    /// When the "starts in 30 minutes" reminder was pushed to the players.
    /// Null until the reminder fires; set once so it is never sent twice.
    /// </summary>
    public DateTime? ReminderSentAt { get; set; }

    /// <summary>متى أُرسل للاعبين إشعار «قيّم الملعب» بعد انتهاء المباراة
    /// (مرة واحدة) — <see cref="Services.CourtRatingPromptService"/>.</summary>
    public DateTime? RatingPromptSentAt { get; set; }

    /// <summary>
    /// What the creator pays up-front when hosting on a court: the whole match
    /// (price × max players) when they pay in full, otherwise a single share.
    /// </summary>
    public decimal CreatorCharge() => PaymentMode == MatchPaymentMode.FullByCreator
        ? PricePerPlayer * MaxPlayers
        : PricePerPlayer;

    /// <summary>
    /// ما دفعه لاعب بعينه عن حصته: المسجَّل على سطره (بعد خصم العضوية)، وإلا
    /// السعر الموحّد للسجلات القديمة. أساس كل ردّ وكل تحويل للمالك.
    /// </summary>
    public decimal ShareOf(MatchPlayer player) => player.PaidAmount ?? PricePerPlayer;

    /// <summary>
    /// ما حُجز من المنشئ عند الإنشاء: كامل المباراة في النمط القديم، وإلا حصته
    /// كما دفعها فعلاً (تحتاج تحميل MatchPlayers).
    /// </summary>
    public decimal CreatorHeld() => PaymentMode == MatchPaymentMode.FullByCreator
        ? CreatorCharge()
        : MatchPlayers.FirstOrDefault(p => p.UserId == CreatorId) is { } creator
            ? ShareOf(creator)
            : CreatorCharge();

    // Navigation
    public ICollection<MatchPlayer> MatchPlayers { get; set; } = [];
    public ICollection<MatchRating> Ratings { get; set; } = [];
    public AmericanoMatch? AmericanoMatch { get; set; }
}
