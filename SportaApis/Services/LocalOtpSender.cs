using System.Security.Cryptography;
using Microsoft.Extensions.Options;
using SportaApis.Helpers;

namespace SportaApis.Services;

/// <summary>
/// مزوّد التطوير: يولّد الرمز ويكتبه في اللوق بدل إرساله، فيمكن اختبار المسار
/// كاملاً بلا استهلاك رصيد Authentica ولا انتظار رسالة.
///
/// يُختار حين <c>Otp:Provider = "Local"</c> أو حين يغيب مفتاح Authentica. في
/// بيئة الإنتاج يُرفض هذا الاختيار عند الإقلاع — رمزٌ يظهر في اللوق يعني أن كل
/// من يقرأ اللوق يدخل أي حساب.
/// </summary>
public class LocalOtpSender(
    ILogger<LocalOtpSender> logger, IOptions<OtpOptions> options) : IOtpSender
{
    public string Name => "local";

    /// <summary>الرمز يُولَّد ويُطابَق عندنا — لا مزوّد خارجي يملك دورته.</summary>
    public bool OwnsCodeLifecycle => false;

    public Task<OtpSendResult> SendAsync(string localPhone, CancellationToken ct = default)
    {
        // بنفس طول رموز المزوّد الحقيقي، وإلا اختبرتَ في التطوير شاشةً
        // بخانات لا تشبه ما يصل المستخدم في الإنتاج.
        var length = Math.Clamp(options.Value.CodeLength, 4, 8);
        var fixedCode = options.Value.LocalFixedCode?.Trim();
        var code = !string.IsNullOrEmpty(fixedCode)
            ? fixedCode
            : RandomNumberGenerator
                .GetInt32(0, (int)Math.Pow(10, length))
                .ToString(new string('0', length));
        logger.LogWarning(
            "[DEV] OTP for {Phone}: {Code}", PhoneNumber.Mask(localPhone), code);
        return Task.FromResult(new OtpSendResult("local", code));
    }

    public Task<bool> VerifyAsync(string localPhone, string code, CancellationToken ct = default) =>
        throw new NotSupportedException(
            "Local OTP codes are matched against the database, not the sender.");
}
