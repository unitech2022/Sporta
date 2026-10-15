using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using SportaApis.DTOs;
using SportaApis.Helpers;
using SportaApis.Services;

namespace SportaApis.Controllers;

/// <summary>
/// إشعارات بوابة FINY.
///
/// المسار مفتوح بلا توكن — البوابة لا تحمل حساب مستخدم — وحارسُه التوقيع وحده:
/// من يعرف <c>WebhookSecret</c> فقط يستطيع أن يقول «تم الدفع». بدون هذا التحقق
/// يشحن أي أحد محفظته بطلب POST واحد.
/// </summary>
[ApiController]
[Route("api/webhooks/finy")]
[AllowAnonymous]
public class FinyWebhookController : ControllerBase
{
    private readonly IWalletService _wallet;
    private readonly FinyOptions _options;
    private readonly ILogger<FinyWebhookController> _logger;

    private static readonly JsonSerializerOptions JsonOpts = new(JsonSerializerDefaults.Web);

    public FinyWebhookController(
        IWalletService wallet,
        IOptions<FinyOptions> options,
        ILogger<FinyWebhookController> logger)
    {
        _wallet = wallet;
        _options = options.Value;
        _logger = logger;
    }

    // POST /api/webhooks/finy
    [HttpPost]
    public async Task<IActionResult> Receive()
    {
        // الجسم الخام كما وصل: التوقيع محسوب على بايتاته، وأي إعادة تسلسل
        // (ترتيب مفاتيح، مسافات) تُنتج توقيعاً لا يطابق على رسالة سليمة.
        using var reader = new StreamReader(Request.Body);
        var rawBody = await reader.ReadToEndAsync();

        var signature = Request.Headers["X-Finy-Signature"].ToString();
        if (!FinySignature.VerifyWebhook(_options.WebhookSecret, rawBody, signature))
        {
            _logger.LogWarning("Rejected FINY webhook: signature mismatch");
            return Unauthorized(ApiResponse<object>.Fail(
                "Invalid signature", "توقيع غير صحيح", "INVALID_SIGNATURE"));
        }

        // التحليل بعد التحقق لا قبله.
        FinyWebhookEvent? evt;
        try
        {
            evt = JsonSerializer.Deserialize<FinyWebhookEvent>(rawBody, JsonOpts);
        }
        catch (JsonException ex)
        {
            _logger.LogWarning(ex, "FINY webhook body is not valid JSON");
            return BadRequest(ApiResponse<object>.Fail(
                "Invalid payload", "محتوى غير صالح", "INVALID_PAYLOAD"));
        }

        if (evt?.Data is null)
            return BadRequest(ApiResponse<object>.Fail(
                "Missing event data", "بيانات الحدث مفقودة", "MISSING_DATA"));

        // ما يعنينا هو نجاح الدفع وحده. بقية الأحداث تُستلم وتُتجاهَل بهدوء —
        // ردّ غير 2xx يدفع البوابة لإعادة إرسالها بلا فائدة.
        if (!string.Equals(evt.Type, "payment.succeeded", StringComparison.OrdinalIgnoreCase))
            return Ok(ApiResponse<object>.Ok(new { received = true, handled = false }));

        try
        {
            // المرور بنفس مسار التأكيد: يسأل FINY عن الحالة بنفسه ولا يثق بجسم
            // الإشعار، ويمنع تكرارَه الفهرسُ الفريد على مرجع العملية. فوصول
            // الحدث مرتين لا يشحن مرتين.
            var wallet = await _wallet.CompleteTopUpAsync(evt.Data.Id, expectedUserId: null);

            if (wallet is null)
                _logger.LogInformation(
                    "FINY webhook {EventId}: payment {PaymentId} is not paid yet",
                    evt.Id, evt.Data.Id);

            return Ok(ApiResponse<object>.Ok(new { received = true, handled = wallet is not null }));
        }
        catch (AuthException ex)
        {
            // عملية ليست شحن محفظة (تطبيق آخر على نفس المنصة، أو غرض آخر).
            // 200 مقصود: إعادة الإرسال لن تغيّر شيئاً.
            _logger.LogInformation(
                "FINY webhook {EventId} ignored for payment {PaymentId}: {Code}",
                evt.Id, evt.Data.Id, ex.Code);
            return Ok(ApiResponse<object>.Ok(new { received = true, handled = false }));
        }
        catch (Exception ex)
        {
            // خطأ عندنا (قاعدة بيانات، شبكة): 500 كي تعيد FINY المحاولة لاحقاً.
            _logger.LogError(ex,
                "FINY webhook {EventId} failed for payment {PaymentId}", evt.Id, evt.Data.Id);
            return StatusCode(500, ApiResponse<object>.Fail(
                "Processing failed", "تعذّرت المعالجة", "PROCESSING_FAILED"));
        }
    }
}
