namespace SportaApis.Services;

/// <summary>نتيجة محاولة إرسال رمز.</summary>
/// <param name="Channel">القناة التي نجح الإرسال عبرها: whatsapp | sms | local.</param>
/// <param name="DevCode">
/// الرمز نصّاً — يُملأ فقط في المزوّد المحلي (تطوير)، ويظل <c>null</c> مع أي
/// مزوّد حقيقي. لا يُعاد للعميل إلا في بيئة التطوير.
/// </param>
public record OtpSendResult(string Channel, string? DevCode);

/// <summary>
/// قناة إيصال رموز التحقق. التجريد هنا مقصود: مزوّد واحد يولّد الرمز ويتحقق منه
/// لدى نفسه (Authentica)، وآخر محلي نولّد عنده ونطابق بأنفسنا — والفرق يبقى
/// خلف هذه الواجهة فلا يعرفه <c>OtpService</c>.
/// </summary>
public interface IOtpSender
{
    /// <summary>اسم القناة الأساسية، للسجلّات.</summary>
    string Name { get; }

    /// <summary>
    /// هل يتولّى المزوّد توليد الرمز والتحقق منه؟ حين تكون <c>true</c> لا نحفظ
    /// رمزاً عندنا ولا نطابقه محلياً.
    /// </summary>
    bool OwnsCodeLifecycle { get; }

    /// <summary>يرسل رمزاً إلى الرقم. يرمي <see cref="OtpSendException"/> عند الفشل.</summary>
    Task<OtpSendResult> SendAsync(string localPhone, CancellationToken ct = default);

    /// <summary>
    /// يتحقق من الرمز لدى المزوّد. تُستدعى فقط حين
    /// <see cref="OwnsCodeLifecycle"/> صحيحة.
    /// </summary>
    Task<bool> VerifyAsync(string localPhone, string code, CancellationToken ct = default);
}

/// <summary>فشل إيصال الرمز — مشكلة لدى المزوّد أو في الشبكة، لا خطأ من المستخدم.</summary>
public class OtpSendException(string message) : Exception(message);
