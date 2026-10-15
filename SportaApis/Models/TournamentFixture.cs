using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// مباراة واحدة داخل بطولة إقصائية: في دور المجموعات أو في شجرة خروج
/// المغلوب. الفريق رقمٌ (1..N) يشير إلى <see cref="MatchPlayer.Team"/>؛
/// في الإقصائيات يبقى null حتى يُعرف من المباراة السابقة.
/// </summary>
public class TournamentFixture : BaseEntity, IScoreProposal
{
    public int AmericanoMatchId { get; set; }
    public AmericanoMatch AmericanoMatch { get; set; } = null!;

    public TournamentStage Stage { get; set; }

    /// <summary>رقم المجموعة (0 = أ) في دور المجموعات؛ null في الإقصائيات.</summary>
    public int? GroupIndex { get; set; }

    /// <summary>
    /// في المجموعات: رقم الجولة داخل المجموعة (1..). في الإقصائيات: رقم الدور
    /// (1 = أول دور إقصائي) — والفائز من (الدور r، الموقع i) ينتقل إلى
    /// (الدور r+1، الموقع i/2) في الخانة الأولى إن كان i زوجياً وإلا الثانية.
    /// </summary>
    public int Round { get; set; }

    /// <summary>موقع المباراة داخل دورها (0..).</summary>
    public int Index { get; set; }

    public int? Team1 { get; set; }
    public int? Team2 { get; set; }

    public int? Team1Score { get; set; }
    public int? Team2Score { get; set; }
    public bool IsCompleted { get; set; }

    /// <summary>إعفاء: فريق بلا خصم في الدور الأول يتقدّم تلقائياً.</summary>
    public bool IsBye { get; set; }

    public int? WinnerTeam { get; set; }

    // نتيجة مقترحة بانتظار تأكيد لاعب من الفريق الآخر (IScoreProposal).
    public int? ProposedTeam1Score { get; set; }
    public int? ProposedTeam2Score { get; set; }
    public int? ProposedById { get; set; }
    public DateTime? ProposedAt { get; set; }
    public bool IsDisputed { get; set; }

    // الجدولة: أين ومتى تُلعب (تُملأ عند القرعة).
    public int? CourtId { get; set; }
    public Court? Court { get; set; }
    public DateTime? ScheduledAt { get; set; }
}
