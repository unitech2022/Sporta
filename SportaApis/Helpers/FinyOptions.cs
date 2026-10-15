namespace SportaApis.Helpers;

/// <summary>
/// إعدادات الربط ببوابة FINY (قسم "Finy" في appsettings).
///
/// <see cref="ApiSecret"/> و<see cref="WebhookSecret"/> سرّان: من يملك الأول
/// يوقّع طلبات دفع باسمنا، ومن يملك الثاني يزوّر إشعار «تم الدفع» فيشحن محفظته
/// مجاناً. لا يُكتبان في appsettings المُودَع في git — بل في متغيّري البيئة
/// <c>Finy__ApiSecret</c> و<c>Finy__WebhookSecret</c>، أو في dotnet user-secrets
/// أثناء التطوير.
/// </summary>
public class FinyOptions
{
    /// <summary>عنوان الـ API الأساسي لـ FINY.</summary>
    public string BaseUrl { get; set; } = "https://apis.finygate.com";

    /// <summary>
    /// رمز منصة الدفع — يذهب في <c>Authorization: Bearer</c>. يعرّف المنصة لا
    /// التطبيق، فلا يكفي وحده لتنفيذ عملية: كل POST يحتاج توقيعاً بـ
    /// <see cref="ApiSecret"/> أيضاً.
    /// </summary>
    public string LinkToken { get; set; } = string.Empty;

    /// <summary>سرّ توقيع طلباتنا الصادرة (fsk_…).</summary>
    public string ApiSecret { get; set; } = string.Empty;

    /// <summary>سرّ التحقق من الإشعارات الواردة (whsec_…).</summary>
    public string WebhookSecret { get; set; } = string.Empty;

    /// <summary>معرّف التطبيق لدى FINY كما في لوحتها.</summary>
    public string Application { get; set; } = "sporta";

    /// <summary>عملة الدفع المتوقعة.</summary>
    public string Currency { get; set; } = "SAR";

    /// <summary>
    /// العنوان الذي تعود إليه صفحة الدفع بعد انتهائها. يفتحه التطبيق في
    /// WebView ويرصد وصوله ليعرف أن العميل انتهى — لا يُفتح فعلياً في متصفح.
    /// </summary>
    public string CallbackUrl { get; set; } = "https://sporta.app/payment-return";

    /// <summary>هل الإعدادات مكتملة فعلاً؟ بلا رمز أو سرّ لا نداء ممكن.</summary>
    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(LinkToken) &&
        !string.IsNullOrWhiteSpace(ApiSecret) &&
        !string.IsNullOrWhiteSpace(Application);
}
