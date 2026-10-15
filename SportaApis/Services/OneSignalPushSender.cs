using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace SportaApis.Services;

/// <summary>
/// Sends push notifications through the OneSignal REST API. No-op when the
/// AppId / RestApiKey are not configured, so in-app notifications still work.
/// </summary>
public class OneSignalPushSender : IPushSender
{
    private static readonly TimeSpan PushTimeout = TimeSpan.FromSeconds(4);

    private readonly IHttpClientFactory _httpFactory;
    private readonly ILogger<OneSignalPushSender> _logger;
    private readonly string? _appId;
    private readonly string? _apiKey;

    public OneSignalPushSender(
        IHttpClientFactory httpFactory,
        IConfiguration config,
        ILogger<OneSignalPushSender> logger)
    {
        _httpFactory = httpFactory;
        _logger = logger;
        _appId = config["OneSignal:AppId"];
        _apiKey = config["OneSignal:RestApiKey"];
    }

    private bool IsConfigured =>
        !string.IsNullOrWhiteSpace(_appId) && !string.IsNullOrWhiteSpace(_apiKey);

    public Task SendAsync(int userId, string title, string body, string? type, int? referenceId)
    {
        return PostAsync(new
        {
            app_id = _appId,
            target_channel = "push",
            include_aliases = new { external_id = new[] { userId.ToString() } },
            headings = new { en = title, ar = title },
            contents = new { en = body, ar = body },
            data = new { type, referenceId },
        });
    }

    public Task BroadcastAsync(string title, string body, string? type, int? referenceId)
    {
        return PostAsync(new
        {
            app_id = _appId,
            target_channel = "push",
            included_segments = new[] { "Subscribed Users" },
            headings = new { en = title, ar = title },
            contents = new { en = body, ar = body },
            data = new { type, referenceId },
        });
    }

    private async Task PostAsync(object payload)
    {
        if (!IsConfigured) return; // push disabled until keys are set

        try
        {
            var client = _httpFactory.CreateClient();
            // الإرسال يجري داخل طلب المستخدم (انضمام، دعوة…)، فبطء OneSignal كان
            // يعلّق الطلب حتى يتجاوز مهلة التطبيق (15 ثانية) رغم نجاح العملية.
            // الإشعار داخل التطبيق محفوظ مسبقاً، فالدفع الخارجي أفضل جهد فقط.
            client.Timeout = PushTimeout;
            var request = new HttpRequestMessage(
                HttpMethod.Post, "https://onesignal.com/api/v1/notifications")
            {
                Content = new StringContent(
                    JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json"),
            };
            // OneSignal v2 REST API keys (os_v2_app_…) use the "Key" scheme;
            // legacy keys used "Basic". Detect by prefix for backward-compat.
            var scheme = _apiKey!.StartsWith("os_v2_") ? "Key" : "Basic";
            request.Headers.Authorization = new AuthenticationHeaderValue(scheme, _apiKey);

            var response = await client.SendAsync(request);
            if (!response.IsSuccessStatusCode)
            {
                var details = await response.Content.ReadAsStringAsync();
                _logger.LogWarning(
                    "OneSignal push failed ({Status}): {Details}", response.StatusCode, details);
            }
        }
        catch (Exception ex)
        {
            // Never let a push failure break the in-app flow.
            _logger.LogWarning(ex, "OneSignal push threw");
        }
    }
}
