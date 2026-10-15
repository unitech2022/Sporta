namespace SportaApis.Helpers;

/// <summary>
/// إعدادات الربط بـ Authentica (قسم "Otp:Authentica" في appsettings) — المزوّد
/// الذي يرسل رمز التحقق عبر واتساب ويتحقق منه لدينا.
///
/// <see cref="ApiKey"/> سرّ: من يملكه يرسل رسائل على حسابنا ويستنزف رصيدنا،
/// وكل رسالة بتكلفة. لا يُكتب في appsettings المُودَع في git — بل في متغيّر
/// البيئة <c>Otp__Authentica__ApiKey</c>، أو في dotnet user-secrets أثناء التطوير.
///
/// ملاحظة مهمة: Authentica هي من تولّد الرمز وتخزّنه وتتحقق منه — نحن لا نرى
/// الرمز إطلاقاً. سجلّنا المحلي في <c>OtpCode</c> لا يحفظ رمزاً في هذا الوضع،
/// بل يحدّ من التكرار ويربط التحقق الناجح بغرضه.
/// </summary>
public class AuthenticaOptions
{
    /// <summary>عنوان الـ API الأساسي.</summary>
    public string BaseUrl { get; set; } = "https://api.authentica.sa";

    /// <summary>مفتاح الـ API — يذهب في ترويسة <c>X-Authorization</c>.</summary>
    public string ApiKey { get; set; } = string.Empty;

    /// <summary>قناة الإرسال: <c>whatsapp</c> أو <c>sms</c>.</summary>
    public string Method { get; set; } = "whatsapp";

    /// <summary>
    /// قناة احتياطية تُجرَّب إذا فشل الإرسال على القناة الأساسية — يفيد حين لا
    /// يملك المستخدم واتساب. اتركها فارغة لتعطيل الاحتياط.
    /// </summary>
    public string? FallbackMethod { get; set; } = "sms";

    /// <summary>معرّف قالب الرسالة لدى Authentica.</summary>
    public int TemplateId { get; set; } = 1;

    /// <summary>مهلة النداء الشبكي بالثواني.</summary>
    public int TimeoutSeconds { get; set; } = 20;

    /// <summary>بلا مفتاح لا نداء ممكن — نسقط عندها إلى المزوّد المحلي.</summary>
    public bool IsConfigured => !string.IsNullOrWhiteSpace(ApiKey);
}

/// <summary>إعدادات رموز التحقق العامة (قسم "Otp").</summary>
public class OtpOptions
{
    /// <summary>
    /// المزوّد: <c>Authentica</c> أو <c>Local</c>. <c>Local</c> يولّد الرمز عندنا
    /// ويكتبه في اللوق بدل إرساله — للتطوير والاختبار بلا استهلاك رصيد.
    /// </summary>
    public string Provider { get; set; } = "Authentica";

    /// <summary>صلاحية الرمز بالدقائق (يُستخدم في المزوّد المحلي وفي حدّ التكرار).</summary>
    public int ExpiryMinutes { get; set; } = 10;

    /// <summary>
    /// عدد خانات الرمز. <b>يجب أن يطابق قالب Authentica</b> — هي من تولّد الرمز
    /// فلا نملك فرضه عليها، والقيمة هنا تُخبر التطبيقَ كم خانة يرسم وتُولّد بها
    /// رموزَ المزوّد المحلي.
    ///
    /// خطؤها لا يُنتج رسالة خطأ بل شاشةً لا تقبل الرمز الواصل إطلاقاً: خانات
    /// أكثر من أرقام الرمز تعني زرَّ تحقّقٍ لا يُفعَّل أبداً. لذا يُقرأ الطول من
    /// هنا في الطرفين بدل تثبيته في التطبيق.
    ///
    /// الافتراضي ٤ لأنه ما يرسله قالبنا لدى Authentica فعلاً. الافتراضي هنا هو
    /// ما يحكم على الخادم: ملفات الإعدادات لا تُنشر (deploy.sh يستثنيها)، فقيمةٌ
    /// افتراضية تخالف القالب تعني عطلاً صامتاً على كل خادم لم يُضبط يدوياً.
    /// </summary>
    public int CodeLength { get; set; } = 4;

    /// <summary>
    /// صلاحية «تذكرة التحقق» التي تُصرف بعد نجاح الرمز، بالدقائق. المستخدم
    /// يحملها من شاشة الرمز إلى شاشة إكمال التسجيل، فتكفيها مهلة قصيرة.
    /// </summary>
    public int VerificationTokenMinutes { get; set; } = 15;

    /// <summary>أقل فاصل زمني بين طلبَي إرسال لنفس الرقم، بالثواني.</summary>
    public int ResendCooldownSeconds { get; set; } = 60;

    /// <summary>
    /// أقصى عدد رسائل لنفس الرقم خلال ساعة — سقف تكلفة وحماية من الإغراق.
    ///
    /// يُحسب على الرقم لا على الغرض، وإلا تُجووِز بتبديل الغرض في كل طلب.
    /// السقوط من واتساب إلى SMS داخل الطلب الواحد يُحسب إرسالاً واحداً.
    /// </summary>
    public int MaxSendsPerHour { get; set; } = 4;

    /// <summary>
    /// أقصى عدد محاولات إدخال خاطئة للرمز الواحد. عند بلوغه يُبطَل الرمز نهائياً
    /// فلا ينفع حتى لو أُدخل صحيحاً بعدها، ويلزم طلب رمز جديد.
    ///
    /// هذا هو الحدّ الذي يحمي الرمز فعلاً: بلا إبطال، يكفي التخمين المتكرر
    /// لكسر رمزٍ من أربع خانات (١٠٬٠٠٠ احتمال) بلا إرسال رسالة واحدة إضافية،
    /// فلا يوقفه سقف الإرسال.
    /// </summary>
    public int MaxVerifyAttempts { get; set; } = 4;

    /// <summary>
    /// يسمح بتشغيل المزوّد المحلي الذي <b>يطبع الرمز في اللوق ويعيده في ردّ
    /// الـ API</b> بدل إرساله. من يقرأ أياً منهما يدخل أي حساب برقمه وحده.
    ///
    /// افتراضياً <c>false</c>، والسيرفر يرفض الإقلاع بلا مزوّد حقيقي ما لم
    /// تُرفَع صراحةً. لا تُرفع إلا في appsettings.Development.json على جهاز
    /// التطوير — وهو ملف لا يُنشر (deploy.sh يستثني ملفات الإعدادات).
    ///
    /// عمداً لا نربط هذا باسم البيئة: خادمٌ أُقلع بـ ASPNETCORE_ENVIRONMENT
    /// خاطئة حادثٌ واقع، وربطُ أمرٍ بهذا الخطر باسم بيئة يجعل خطأً مطبعياً
    /// ثغرةً صامتة.
    /// </summary>
    public bool AllowInsecureLocalProvider { get; set; }

    /// <summary>
    /// أرقام اختبار برموز ثابتة: <c>"0500000301": "123456"</c>. لا تُرسَل لها
    /// رسالة ولا تُستهلك رصيداً، ويُطابَق رمزها عندنا.
    ///
    /// وجودها ضرورة لا رفاهية: مراجع App Store يحتاج حساباً يدخله وهو لا يملك
    /// أرقامنا، وحسابات الـ seed أرقامها وهمية لا واتساب عليها. لكنها أيضاً باب
    /// خلفي كامل لكل رقم تُدرجه — فتُضبط في متغيّرات البيئة لا في git، ويقتصر
    /// المُدرَج على حسابات العرض، ولا يُدرَج فيها رقم مستخدم حقيقي أبداً.
    /// </summary>
    public Dictionary<string, string> TestNumbers { get; set; } = [];

    /// <summary>
    /// رمز ثابت يعيده المزوّد المحلي لكل رقم بدل رمز عشوائي — للتجربة اليدوية
    /// على المحاكي حيث كتابة رمز معروف أسهل من قراءة اللوق. لا أثر له إلا مع
    /// <c>Provider = Local</c>، ومع <see cref="AllowInsecureLocalProvider"/>
    /// فحسب؛ في الإنتاج لا يعمل المزوّد المحلي أصلاً.
    /// </summary>
    public string? LocalFixedCode { get; set; }

    public AuthenticaOptions Authentica { get; set; } = new();
}
