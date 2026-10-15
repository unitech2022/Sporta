using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// سجلّ طلب رمز تحقق واحد. له دوران بحسب المزوّد:
///
/// • مع Authentica: الرمز نفسه لا يصل إلينا إطلاقاً — تولّده وتتحقق منه لديها.
///   يبقى <see cref="Code"/> فارغاً، والسجل هنا يحدّ من التكرار (تكلفة كل رسالة)
///   ويربط التحقق الناجح بغرضه عبر <see cref="VerificationToken"/>.
///
/// • مع المزوّد المحلي (تطوير/اختبار): نولّد الرمز ونحفظه في <see cref="Code"/>
///   ونطابقه هنا.
///
/// في الحالتين تظل التذكرة (<see cref="VerificationToken"/>) هي ما يُقدَّم للخطوة
/// التالية — لا الرمز — كي لا يُعاد استعمال رمز واحد لغرضين.
/// </summary>
public class OtpCode : BaseEntity
{
    /// <summary>الرقم بالصيغة المحلية <c>05xxxxxxxx</c> كما يُخزَّن في Users.</summary>
    public string PhoneNumber { get; set; } = string.Empty;

    /// <summary>الرمز — يبقى فارغاً حين يتولّى المزوّد الخارجي توليده والتحقق منه.</summary>
    public string Code { get; set; } = string.Empty;

    /// <summary>الغرض الذي طُلب الرمز لأجله؛ يُطابَق وقت التحقق.</summary>
    public OtpPurpose Purpose { get; set; } = OtpPurpose.ResetPassword;

    /// <summary>القناة التي أُرسل عبرها فعلاً: <c>whatsapp</c> | <c>sms</c> | <c>local</c>.</summary>
    public string Channel { get; set; } = string.Empty;

    public DateTime ExpiresAt { get; set; }

    /// <summary>يصير صحيحاً بعد التحقق الناجح أو بعد إبطاله بطلب رمز جديد.</summary>
    public bool IsUsed { get; set; }

    /// <summary>عدد محاولات التحقق الخاطئة — يُبطَل السجل عند تجاوز الحد.</summary>
    public int Attempts { get; set; }

    /// <summary>
    /// تذكرة قصيرة العمر تُصرف بعد التحقق الناجح، ويُقدّمها العميل للخطوة
    /// التالية (إكمال التسجيل، تأكيد الحذف…). عشوائية 256-bit.
    /// </summary>
    public string? VerificationToken { get; set; }

    public DateTime? VerifiedAt { get; set; }

    /// <summary>صلاحية التذكرة — أطول من صلاحية الرمز لأن بعدها خطوة إدخال بيانات.</summary>
    public DateTime? TokenExpiresAt { get; set; }

    /// <summary>تصير صحيحة بعد استهلاك التذكرة، فلا تُستعمل مرتين.</summary>
    public bool TokenConsumed { get; set; }

    public bool IsExpired => DateTime.UtcNow >= ExpiresAt;
    public bool IsValid => !IsUsed && !IsExpired;

    /// <summary>هل التذكرة ما زالت صالحة للاستهلاك؟</summary>
    public bool IsTokenValid =>
        VerificationToken is not null &&
        !TokenConsumed &&
        TokenExpiresAt is not null &&
        DateTime.UtcNow < TokenExpiresAt;
}
