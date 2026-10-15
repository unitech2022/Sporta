using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;
using SportaApis.DTOs;
using SportaApis.Helpers;

namespace SportaApis.Services;

/// <summary>
/// عميل بوابة FINY. الدفع لا يمر بخوادمنا: ننشئ العملية هنا، ويفتح التطبيق
/// صفحة FINY المستضافة، فلا يلمس رقمُ بطاقةٍ سبورتا في أي خطوة.
/// </summary>
public class FinyPaymentService : IFinyPaymentService
{
    private const string PaymentsPath = "/api/v1/payments";

    private readonly HttpClient _http;
    private readonly FinyOptions _options;
    private readonly ILogger<FinyPaymentService> _logger;

    private static readonly JsonSerializerOptions JsonOpts = new(JsonSerializerDefaults.Web);

    public FinyPaymentService(
        HttpClient http, IOptions<FinyOptions> options, ILogger<FinyPaymentService> logger)
    {
        _options = options.Value;
        _logger = logger;
        _http = http;

        if (!string.IsNullOrWhiteSpace(_options.BaseUrl))
            _http.BaseAddress = new Uri(_options.BaseUrl.TrimEnd('/') + "/");

        if (!string.IsNullOrWhiteSpace(_options.LinkToken))
            _http.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", _options.LinkToken.Trim());
    }

    public bool IsConfigured => _options.IsConfigured;

    // ── إنشاء عملية ───────────────────────────────────────────────────────────

    public async Task<FinyPayment> CreatePaymentAsync(
        decimal amount,
        string description,
        Dictionary<string, string> metadata,
        string? idempotencyKey = null,
        string? paymentMethod = null,
        CancellationToken ct = default)
    {
        EnsureConfigured();

        var payload = new Dictionary<string, object?>
        {
            ["application"] = _options.Application,
            ["amount"] = amount,
            ["currency"] = _options.Currency,
            ["description"] = description,
            ["metadata"] = metadata,
        };
        if (!string.IsNullOrWhiteSpace(paymentMethod))
            payload["paymentMethod"] = paymentMethod;

        // النص يُوقَّع ويُرسَل بعينه. إعادة تسلسله بين الخطوتين تُغيّر البايتات
        // فيفشل التوقيع على طلب سليم — وهي أشيع أخطاء التكامل مع FINY.
        var body = JsonSerializer.Serialize(payload, JsonOpts);

        using var request = new HttpRequestMessage(HttpMethod.Post, PaymentsPath.TrimStart('/'))
        {
            Content = new StringContent(body, Encoding.UTF8, "application/json"),
        };
        request.Headers.TryAddWithoutValidation("X-Finy-Signature",
            FinySignature.ForRequest(
                _options.ApiSecret, "POST", PaymentsPath, body, DateTimeOffset.UtcNow));

        if (!string.IsNullOrWhiteSpace(idempotencyKey))
            request.Headers.TryAddWithoutValidation("Idempotency-Key", idempotencyKey);

        HttpResponseMessage response;
        try
        {
            response = await _http.SendAsync(request, ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "FINY create-payment request failed");
            throw new AuthException(
                "Payment gateway unreachable", "تعذّر الوصول إلى بوابة الدفع", "GATEWAY_UNREACHABLE");
        }

        var json = await response.Content.ReadAsStringAsync(ct);
        var envelope = Parse<FinyPayment>(json);

        if (!response.IsSuccessStatusCode || envelope?.Success != true || envelope.Data is null)
        {
            _logger.LogWarning(
                "FINY rejected create-payment: {Status} {Code} {Message}",
                response.StatusCode, envelope?.Code, envelope?.Message);

            throw new AuthException(
                envelope?.Message ?? "Failed to create payment",
                envelope?.MessageAr ?? "تعذّر إنشاء عملية الدفع",
                envelope?.Code ?? "PAYMENT_CREATE_FAILED");
        }

        return envelope.Data;
    }

    // ── حالة عملية ────────────────────────────────────────────────────────────

    public async Task<FinyPayment?> GetPaymentAsync(int paymentId, CancellationToken ct = default)
    {
        EnsureConfigured();

        HttpResponseMessage response;
        try
        {
            response = await _http.GetAsync($"api/v1/payments/{paymentId}", ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "FINY get-payment request failed for {PaymentId}", paymentId);
            return null;
        }

        var json = await response.Content.ReadAsStringAsync(ct);
        var envelope = Parse<FinyPayment>(json);

        if (!response.IsSuccessStatusCode || envelope?.Success != true || envelope.Data is null)
        {
            _logger.LogWarning(
                "FINY returned {Status} for payment {PaymentId}: {Code}",
                response.StatusCode, paymentId, envelope?.Code);
            return null;
        }

        return envelope.Data;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private void EnsureConfigured()
    {
        if (_options.IsConfigured) return;

        _logger.LogError("FINY is not configured — LinkToken/ApiSecret/Application are required");
        throw new AuthException(
            "Payment gateway is not configured",
            "بوابة الدفع غير مهيأة",
            "GATEWAY_NOT_CONFIGURED");
    }

    private FinyEnvelope<T>? Parse<T>(string json)
    {
        try
        {
            return JsonSerializer.Deserialize<FinyEnvelope<T>>(json, JsonOpts);
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Failed to parse FINY response");
            return null;
        }
    }
}
