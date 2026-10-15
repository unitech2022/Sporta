using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;
using SportaApis.Helpers;

namespace SportaApis.Services;

/// <summary>
/// عميل Authentica لإرسال رموز التحقق عبر واتساب والتحقق منها.
///
/// الرمز لا يمر بخوادمنا: <c>send-otp</c> تولّده وترسله، و<c>verify-otp</c> تحكم
/// عليه. لذلك لا نحفظ رمزاً في قاعدتنا مع هذا المزوّد
/// (<see cref="OwnsCodeLifecycle"/>)، وما نحفظه هو أثر الطلب فقط لحدّ التكرار.
///
/// كل رسالة بتكلفة، فالنداء لا يُطلق قبل أن يُجيز <c>OtpService</c> الطلب.
/// </summary>
public class AuthenticaOtpSender : IOtpSender
{
    private const string SendPath = "api/v2/send-otp";
    private const string VerifyPath = "api/v2/verify-otp";

    private readonly HttpClient _http;
    private readonly AuthenticaOptions _options;
    private readonly ILogger<AuthenticaOtpSender> _logger;

    private static readonly JsonSerializerOptions JsonOpts = new(JsonSerializerDefaults.Web);

    public AuthenticaOtpSender(
        HttpClient http, IOptions<OtpOptions> options, ILogger<AuthenticaOtpSender> logger)
    {
        _options = options.Value.Authentica;
        _logger = logger;
        _http = http;

        _http.BaseAddress = new Uri(_options.BaseUrl.TrimEnd('/') + "/");
        _http.Timeout = TimeSpan.FromSeconds(_options.TimeoutSeconds);
        _http.DefaultRequestHeaders.TryAddWithoutValidation("Accept", "application/json");

        if (!string.IsNullOrWhiteSpace(_options.ApiKey))
            _http.DefaultRequestHeaders.TryAddWithoutValidation(
                "X-Authorization", _options.ApiKey.Trim());
    }

    public string Name => _options.Method;

    public bool OwnsCodeLifecycle => true;

    // ── إرسال ─────────────────────────────────────────────────────────────────

    public async Task<OtpSendResult> SendAsync(string localPhone, CancellationToken ct = default)
    {
        var e164 = PhoneNumber.ToE164(localPhone);

        if (await TrySendAsync(e164, _options.Method, ct))
            return new OtpSendResult(_options.Method, null);

        // القناة الاحتياطية تُنقذ من لا يملك واتساب على الرقم. لا نجرّبها إلا بعد
        // فشل الأساسية فعلاً حتى لا نضاعف التكلفة على كل طلب.
        var fallback = _options.FallbackMethod;
        if (!string.IsNullOrWhiteSpace(fallback) &&
            !fallback.Equals(_options.Method, StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogWarning(
                "Authentica {Method} send failed for {Phone}; trying {Fallback}",
                _options.Method, PhoneNumber.Mask(localPhone), fallback);

            if (await TrySendAsync(e164, fallback, ct))
                return new OtpSendResult(fallback, null);
        }

        throw new OtpSendException("Failed to send the verification code");
    }

    private async Task<bool> TrySendAsync(string e164, string method, CancellationToken ct)
    {
        var payload = new Dictionary<string, object?>
        {
            ["method"] = method,
            ["phone"] = e164,
            ["template_id"] = _options.TemplateId,
        };

        var response = await PostAsync(SendPath, payload, ct);
        if (response is null) return false;

        var (status, body) = response.Value;
        if (status is System.Net.HttpStatusCode.OK or System.Net.HttpStatusCode.Created)
            return true;

        _logger.LogError(
            "Authentica send-otp failed ({Status}) via {Method}: {Body}", (int)status, method, body);
        return false;
    }

    // ── تحقق ──────────────────────────────────────────────────────────────────

    public async Task<bool> VerifyAsync(
        string localPhone, string code, CancellationToken ct = default)
    {
        var payload = new Dictionary<string, object?>
        {
            ["phone"] = PhoneNumber.ToE164(localPhone),
            ["otp"] = code,
        };

        var (status, body) = await PostAsync(VerifyPath, payload, ct)
            ?? throw new OtpSendException("Could not reach the verification provider");

        // رمز خاطئ أو منتهٍ يعود بحالة غير 200 — وهذا رفض لا عُطل، فنُرجِع false
        // ويصوغ المستدعي رسالة المستخدم. أما 401 فمفتاحنا نحن، وهو عُطل تشغيلي.
        if (status == System.Net.HttpStatusCode.Unauthorized)
        {
            _logger.LogError("Authentica rejected our API key on verify-otp: {Body}", body);
            throw new OtpSendException("Verification provider is not configured correctly");
        }

        if (status != System.Net.HttpStatusCode.OK) return false;

        // الوثائق ترجع {"status": true, ...}، وبعض الردود تستعمل "success" أو
        // تضعها داخل "data"، وبعضها يكتبها نصاً ("true"/"success").
        //
        // **الحكم عند الغموض هو الرفض.** كان هنا `return true` لكل ردٍّ بحالة
        // 200 لا نفهم جسمه، وهو ما يجعل أي رمز عشوائي يفتح أي حساب: المزوّد
        // يردّ 200 على نداءٍ وصله، لا على رمزٍ صحّ. رفضٌ خاطئ يُشتكى منه
        // ويُصلَح، أما قبولٌ خاطئ فبابٌ مفتوح لا يراه أحد.
        try
        {
            using var doc = JsonDocument.Parse(body);
            if (ReadVerdict(doc.RootElement) is bool verdict) return verdict;

            if (doc.RootElement.TryGetProperty("data", out var data) &&
                ReadVerdict(data) is bool nested) return nested;
        }
        catch (JsonException)
        {
            _logger.LogError(
                "Authentica verify-otp returned non-JSON body: {Body}", body);
            return false;
        }

        // شكلٌ غير معروف: يُسجَّل كاملاً ليُضاف للمعالجة أعلاه، ويُرفض الآن.
        _logger.LogError(
            "Authentica verify-otp returned an unrecognized 200 body — treating as "
            + "a failed verification: {Body}", body);
        return false;
    }

    /// <summary>
    /// الحكم المعلن في الجسم: منطقيّاً كان أو نصّاً. <c>null</c> حين لا يحمل
    /// الجسمُ حكماً نعرفه — وحينها يقرّر المستدعي، وقراره الرفض.
    /// </summary>
    private static bool? ReadVerdict(JsonElement element)
    {
        if (element.ValueKind != JsonValueKind.Object) return null;

        foreach (var key in new[] { "status", "success", "verified", "valid" })
        {
            if (!element.TryGetProperty(key, out var flag)) continue;

            switch (flag.ValueKind)
            {
                case JsonValueKind.True:
                    return true;
                case JsonValueKind.False:
                    return false;
                case JsonValueKind.String:
                    var text = flag.GetString()?.Trim().ToLowerInvariant();
                    if (text is "true" or "success" or "verified" or "ok" or "1")
                        return true;
                    if (text is "false" or "failed" or "failure" or "invalid" or "0")
                        return false;
                    break;
            }
        }

        return null;
    }

    // ── نداء مشترك ────────────────────────────────────────────────────────────

    /// <summary>
    /// يُرجِع (الحالة، النص) أو <c>null</c> إن تعذّر الوصول أصلاً. لا يرمي على
    /// أخطاء الشبكة كي يقرّر المستدعي: الإرسال يجرّب القناة الاحتياطية، والتحقق
    /// يرمي لأنه لا بديل لديه.
    /// </summary>
    private async Task<(System.Net.HttpStatusCode Status, string Body)?> PostAsync(
        string path, Dictionary<string, object?> payload, CancellationToken ct)
    {
        if (!_options.IsConfigured)
            throw new OtpSendException("Authentica API key is not configured");

        using var request = new HttpRequestMessage(HttpMethod.Post, path)
        {
            Content = new StringContent(
                JsonSerializer.Serialize(payload, JsonOpts), Encoding.UTF8, "application/json"),
        };

        try
        {
            using var response = await _http.SendAsync(request, ct);
            var body = await response.Content.ReadAsStringAsync(ct);
            return (response.StatusCode, body);
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
        {
            _logger.LogError(ex, "Authentica request to {Path} failed", path);
            return null;
        }
    }
}
