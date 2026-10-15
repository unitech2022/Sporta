using SportaApis.DTOs;
using SportaApis.Models;
using SportaApis.Services;

namespace SportaApis.Helpers;

/// <summary>
/// قاعدة اعتماد النتيجة المشتركة: لاعب من أحد الطرفين يقترح، ولاعب من الطرف
/// الآخر يؤكد أو يرفض. «الطرف» هنا 1 أو 2 داخل المباراة نفسها (لا رقم الفريق
/// في البطولة).
/// </summary>
public static class ScoreProposals
{
    public static bool HasProposal(this IScoreProposal p) =>
        p.ProposedById != null && p.ProposedTeam1Score != null && p.ProposedTeam2Score != null;

    public static void Propose(this IScoreProposal p, int userId, int team1Score, int team2Score)
    {
        p.ProposedTeam1Score = team1Score;
        p.ProposedTeam2Score = team2Score;
        p.ProposedById = userId;
        p.ProposedAt = DateTime.UtcNow;
    }

    /// <summary>رفض الفريق الآخر للنتيجة المقترحة: تُمسح ويُعلَّم خلاف.</summary>
    public static void Reject(this IScoreProposal p)
    {
        p.ClearProposal();
        p.IsDisputed = true;
    }

    public static void ClearProposal(this IScoreProposal p)
    {
        p.ProposedTeam1Score = null;
        p.ProposedTeam2Score = null;
        p.ProposedById = null;
        p.ProposedAt = null;
    }

    /// <summary>المقترِح من الطرف الآخر وأدخل النتيجة نفسها ⇐ تُعدّ تأكيداً.</summary>
    public static bool IsSameAsProposal(this IScoreProposal p, int team1Score, int team2Score) =>
        p.HasProposal() && p.ProposedTeam1Score == team1Score && p.ProposedTeam2Score == team2Score;

    public static AuthException NotAPlayer() => new(
        "Only the match players can enter the result",
        "فقط لاعبو المباراة يمكنهم إدخال النتيجة", "NOT_A_PLAYER");

    public static AuthException NoProposal() => new(
        "There is no result awaiting confirmation",
        "لا توجد نتيجة بانتظار التأكيد", "NO_PENDING_RESULT");

    public static AuthException SameSide() => new(
        "A player from the other team must confirm the result",
        "يجب أن يؤكد النتيجة لاعب من الفريق الآخر", "RESULT_SAME_TEAM");

    /// <summary>
    /// يتحقق أن من يردّ على الاقتراح لاعب في الطرف المقابل للمقترِح.
    /// </summary>
    public static void EnsureCanRespond(
        IScoreProposal p, int? responderSide, int? proposerSide, RespondResultRequest? seen = null)
    {
        if (!p.HasProposal()) throw NoProposal();
        if (responderSide is null) throw NotAPlayer();
        if (responderSide == proposerSide) throw SameSide();
        if (seen is { Team1Score: int s1, Team2Score: int s2 } && !p.IsSameAsProposal(s1, s2))
            throw new AuthException(
                "The proposed result changed — review it again",
                "تغيّرت النتيجة المقترحة للتو — راجعها من جديد", "RESULT_CHANGED");
    }

    /// <summary>المنظّم يحسم الخلاف: لا يُقبل إلا بعد رفض نتيجة مقترحة.</summary>
    public static void EnsureCanResolve(IScoreProposal p, int userId, int organizerId)
    {
        if (userId != organizerId)
            throw new AuthException(
                "Only the organizer can resolve a dispute",
                "فقط المنظّم يمكنه حسم الخلاف على النتيجة", "NOT_OWNER");
        if (!p.IsDisputed)
            throw new AuthException(
                "There is no dispute on this result",
                "لا يوجد خلاف على هذه النتيجة — يحسم المنظّم فقط بعد رفض نتيجة مقترحة",
                "RESULT_NOT_DISPUTED");
    }

    public static PendingResultDto? ToDto(IScoreProposal p, int? proposerSide, string proposerName) =>
        p.HasProposal()
            ? new PendingResultDto
            {
                Team1Score = p.ProposedTeam1Score!.Value,
                Team2Score = p.ProposedTeam2Score!.Value,
                ProposedById = p.ProposedById!.Value,
                ProposedByName = proposerName,
                ProposedBySide = proposerSide,
                ProposedAt = p.ProposedAt ?? DateTime.UtcNow,
            }
            : null;
}
