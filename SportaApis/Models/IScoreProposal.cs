namespace SportaApis.Models;

/// <summary>
/// نتيجة أدخلها لاعب ولم تُعتمد بعد: أي لاعب من الفريقين يقترحها، ولا تُحتسب
/// (ترتيب، تأهّل، نقاط مستوى) حتى يؤكدها لاعب من الفريق الآخر. تشترك فيها
/// المباراة العادية وجولة الأمريكانو ومباراة البطولة.
/// </summary>
public interface IScoreProposal
{
    int? ProposedTeam1Score { get; set; }
    int? ProposedTeam2Score { get; set; }
    int? ProposedById { get; set; }
    DateTime? ProposedAt { get; set; }

    /// <summary>
    /// رُفضت نتيجة مقترحة ولم تُعتمد نتيجة بعدها: خلاف يحسمه المنظّم بإدخال
    /// النتيجة النهائية مباشرة.
    /// </summary>
    bool IsDisputed { get; set; }
}
