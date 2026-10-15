namespace SportaApis.DTOs;

/// <summary>نتيجة أدخلها لاعب وتنتظر تأكيد لاعب من الفريق الآخر.</summary>
public class PendingResultDto
{
    public int Team1Score { get; set; }
    public int Team2Score { get; set; }
    public int ProposedById { get; set; }
    public string ProposedByName { get; set; } = string.Empty;

    /// <summary>طرف المقترِح في المباراة (1 أو 2) — يؤكد لاعب من الطرف الآخر.</summary>
    public int? ProposedBySide { get; set; }

    public DateTime ProposedAt { get; set; }
}

/// <summary>المنظّم يحسم خلافاً على النتيجة بإدخالها نهائيةً.</summary>
public class ResolveResultRequest
{
    [System.ComponentModel.DataAnnotations.Range(0, 99)] public int Team1Score { get; set; }
    [System.ComponentModel.DataAnnotations.Range(0, 99)] public int Team2Score { get; set; }

    /// <summary>المباراة العادية: لاعبو الفريق الأول (اختياري؛ الافتراضي التوزيع المحفوظ).</summary>
    public List<int> Team1PlayerIds { get; set; } = [];
}

/// <summary>ردّ لاعب من الفريق الآخر على نتيجة مقترحة: تأكيد أو رفض.</summary>
public class RespondResultRequest
{
    public bool Accept { get; set; }

    /// <summary>
    /// النتيجة التي رآها المؤكِّد. إن تغيّر الاقتراح بعد أن رآه (أرسل أحدهم
    /// نتيجة أخرى في اللحظة نفسها) يُرفض التأكيد بدل اعتماد ما لم يره.
    /// </summary>
    public int? Team1Score { get; set; }
    public int? Team2Score { get; set; }

    /// <summary>تقييمات اللاعبين (المباراة العادية فقط) — تُرسل مع التأكيد.</summary>
    public List<MatchRatingInput> Ratings { get; set; } = [];
}
