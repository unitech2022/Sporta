using SportaApis.Enums;

namespace SportaApis.Services;

/// <summary>نتيجة طلب إرسال رمز، كما تُعاد للعميل.</summary>
/// <param name="Channel">القناة المستخدمة فعلاً — التطبيق يقول «أُرسل عبر واتساب».</param>
/// <param name="CodeLength">عدد خانات الرمز — يرسم بها التطبيق شاشة الإدخال.</param>
/// <param name="ExpiresInSeconds">صلاحية الرمز، ليعرض العميل عدّاداً.</param>
/// <param name="ResendAfterSeconds">متى يُسمح بطلب رمز جديد.</param>
/// <param name="DevCode">الرمز نصّاً في بيئة التطوير فقط، وإلا <c>null</c>.</param>
public record OtpRequestResult(
    string Channel,
    int CodeLength,
    int ExpiresInSeconds,
    int ResendAfterSeconds,
    string? DevCode);

/// <summary>
/// إدارة رموز التحقق: يفرض شروط الغرض وحدود التكرار، ويستدعي المزوّد، ويصرف
/// «تذكرة تحقق» بعد النجاح تُقدَّم للخطوة التالية.
/// </summary>
public interface IOtpService
{
    /// <summary>
    /// يرسل رمزاً للرقم لغرض محدّد. يرمي <see cref="AuthException"/> إذا خالف
    /// الغرضُ حالةَ الرقم (تسجيل برقم مسجّل، دخول برقم غير مسجّل…) أو تجاوز
    /// المستخدم حدود الإرسال.
    /// </summary>
    Task<OtpRequestResult> RequestAsync(
        string phone, OtpPurpose purpose, CancellationToken ct = default);

    /// <summary>
    /// يتحقق من الرمز ويُرجِع تذكرة صالحة لدقائق معدودة. يرمي
    /// <see cref="AuthException"/> عند رمز خاطئ أو منتهٍ أو مستنفَد المحاولات.
    /// </summary>
    Task<string> VerifyAsync(
        string phone, string code, OtpPurpose purpose, CancellationToken ct = default);

    /// <summary>
    /// يستهلك تذكرة صادرة لهذا الرقم والغرض. يرمي إن كانت غير موجودة أو منتهية
    /// أو مستهلكة. تُستدعى داخل نفس معاملة العملية التي تحميها.
    /// </summary>
    Task ConsumeTokenAsync(string phone, string token, OtpPurpose purpose);
}
