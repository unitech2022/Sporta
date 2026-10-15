namespace SportaApis.Helpers;

/// <summary>
/// إعدادات Apple Pay (قسم <c>ApplePay</c> في appsettings). ليست مفاتيح: الـ
/// Merchant ID معرّف عام يُطابق ما في entitlements التطبيق ولوحة ميسر لدى FINY.
/// فك تشفير التوكن يتم لدى ميسر بشهادة المعالجة المرفوعة هناك — لا عندنا.
///
/// الزر يظهر في التطبيق فقط حين يكون <see cref="MerchantId"/> مضبوطاً، فيمكن
/// إيقاف Apple Pay من الخادم بلا إصدار جديد.
/// </summary>
public class ApplePayOptions
{
    /// <summary>مثل <c>merchant.net.sportaapp</c> — كما أُنشئ في حساب آبل للمطورين.</summary>
    public string MerchantId { get; set; } = string.Empty;

    /// <summary>اسم المتجر في ورقة الدفع.</summary>
    public string DisplayName { get; set; } = "Sporta";

    /// <summary>بلد التاجر (ISO 3166-1 alpha-2).</summary>
    public string CountryCode { get; set; } = "SA";

    /// <summary>
    /// الشبكات المسموحة بمفردات PassKit كما يقرؤها التطبيق. تبدأ فارغة عمداً:
    /// رابط الإعدادات في .NET <b>يُلحق</b> قيم الملف بالمصفوفة الموجودة ولا
    /// يستبدلها، فأي قيمة افتراضية هنا كانت تتكرر مع كل ملف إعدادات يعرّفها.
    /// اقرأها عبر <see cref="Networks"/>.
    /// </summary>
    public string[] SupportedNetworks { get; set; } = [];

    private static readonly string[] DefaultNetworks = ["mada", "visa", "masterCard"];

    /// <summary>الشبكات بلا تكرار، وبالقيم الافتراضية حين لا تُضبط.</summary>
    public string[] Networks =>
        SupportedNetworks.Length == 0
            ? DefaultNetworks
            : SupportedNetworks.Distinct(StringComparer.OrdinalIgnoreCase).ToArray();

    public bool Enabled => !string.IsNullOrWhiteSpace(MerchantId);
}
