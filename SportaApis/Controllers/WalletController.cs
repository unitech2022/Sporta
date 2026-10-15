using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/wallet")]
[Authorize]
public class WalletController : ControllerBase
{
    private readonly IWalletService _walletService;
    private readonly FinyOptions _finy;
    private readonly ApplePayOptions _applePay;

    public WalletController(
        IWalletService walletService, IOptions<FinyOptions> finy,
        IOptions<ApplePayOptions> applePay)
    {
        _walletService = walletService;
        _finy = finy.Value;
        _applePay = applePay.Value;
    }

    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    private bool IsAdmin =>
        string.Equals(User.FindFirstValue(ClaimTypes.Role),
            UserType.Admin.ToString(), StringComparison.OrdinalIgnoreCase) ||
        User.IsInRole("admin") || User.IsInRole("Admin");

    // GET /api/wallet
    [HttpGet]
    public async Task<IActionResult> GetWallet()
    {
        var wallet = await _walletService.GetWalletAsync(CurrentUserId);
        return Ok(ApiResponse<WalletDto>.Ok(wallet));
    }

    // GET /api/wallet/transactions?page=&pageSize=
    [HttpGet("transactions")]
    public async Task<IActionResult> GetTransactions(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var result = await _walletService.GetTransactionsAsync(
            CurrentUserId, page, pageSize);
        return Ok(ApiResponse<PagedResult<WalletTransactionDto>>.Ok(result));
    }

    // GET /api/wallet/payment-config — ما يحتاجه التطبيق ليفتح شاشة الدفع.
    // لم يعد فيه أي مفتاح: صفحة الدفع مستضافة لدى FINY، والتطبيق يفتح رابطها
    // ويرصد عنوان العودة لا أكثر.
    [HttpGet("payment-config")]
    public IActionResult GetPaymentConfig() =>
        Ok(ApiResponse<object>.Ok(new
        {
            configured = _finy.IsConfigured,
            callbackUrl = _finy.CallbackUrl,
            currency = _finy.Currency,
            // Apple Pay: معرّف التاجر فقط — ليس سراً، لكنه يعيش هنا كي يُطفأ
            // الزر من الخادم بلا إصدار جديد، ويبقى مطابقاً لإعداد FINY.
            applePay = new
            {
                enabled = _finy.IsConfigured && _applePay.Enabled,
                merchantId = _applePay.MerchantId,
                displayName = _applePay.DisplayName,
                countryCode = _applePay.CountryCode,
                supportedNetworks = _applePay.Networks,
            },
        }));

    // GET /api/wallet/bank-account — الحساب البنكي المحفوظ (للمطالبة به في التطبيق)
    [HttpGet("bank-account")]
    public async Task<IActionResult> GetBankAccount()
    {
        var account = await _walletService.GetBankAccountAsync(CurrentUserId);
        return Ok(ApiResponse<BankAccountDto>.Ok(account));
    }

    // PUT /api/wallet/bank-account — إضافة/تعديل الآيبان (مطلوب قبل السحب)
    [HttpPut("bank-account")]
    public async Task<IActionResult> SaveBankAccount([FromBody] SaveBankAccountRequest request)
    {
        try
        {
            var account = await _walletService.SaveBankAccountAsync(CurrentUserId, request);
            return Ok(ApiResponse<BankAccountDto>.Ok(account));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // GET /api/wallet/topup-quote?amount=100 — الرسوم والإجمالي المخصوم من البطاقة
    [HttpGet("topup-quote")]
    public async Task<IActionResult> GetTopUpQuote([FromQuery] decimal amount)
    {
        if (amount <= 0)
            return BadRequest(ApiResponse<object>.Fail(
                "Invalid amount", "مبلغ غير صحيح", "INVALID_AMOUNT"));

        var quote = await _walletService.QuoteTopUpAsync(amount);
        return Ok(ApiResponse<TopUpQuoteDto>.Ok(quote));
    }

    // POST /api/wallet/topup/session — يفتح صفحة دفع لدى FINY (لا يشحن شيئاً)
    [HttpPost("topup/session")]
    public async Task<IActionResult> StartTopUp([FromBody] StartTopUpRequest request)
    {
        try
        {
            var session = await _walletService.StartTopUpAsync(
                CurrentUserId, request.Amount, request.Description);
            return Ok(ApiResponse<TopUpSessionDto>.Ok(session));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // POST /api/wallet/topup/confirm — بعد إغلاق صفحة الدفع في التطبيق
    [HttpPost("topup/confirm")]
    public async Task<IActionResult> ConfirmTopUp([FromBody] ConfirmTopUpRequest request)
    {
        try
        {
            var wallet = await _walletService.CompleteTopUpAsync(request.PaymentId, CurrentUserId);

            // لم تُحسم بعد لدى البوابة: ليست خطأً — قد يسبق إغلاقُ الصفحة وصولَ
            // تأكيد البنك، ويحسمها الـ webhook بعد لحظات.
            if (wallet is null)
                return Accepted(ApiResponse<object>.Fail(
                    "Payment is still pending", "لم تُؤكَّد العملية بعد", "PAYMENT_PENDING"));

            return Ok(ApiResponse<WalletDto>.Ok(wallet));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // POST /api/wallet/topup/applepay — شحن بـ Apple Pay في نداء واحد: التوكن
    // من ورقة آبل يمرّ إلى FINY ثم ميسر، والرصيد يُعتمد من سجل FINY فوراً.
    [HttpPost("topup/applepay")]
    public async Task<IActionResult> ApplePayTopUp([FromBody] ApplePayTopUpRequest request)
    {
        if (!_applePay.Enabled)
            return BadRequest(ApiResponse<object>.Fail(
                "Apple Pay is not enabled", "Apple Pay غير مفعّل", "APPLEPAY_DISABLED"));

        try
        {
            var wallet = await _walletService.TopUpWithApplePayAsync(
                CurrentUserId, request.Amount, request.Token, request.Description);

            if (wallet is null)
                return Accepted(ApiResponse<object>.Fail(
                    "Payment is still pending", "لم تُؤكَّد العملية بعد", "PAYMENT_PENDING"));

            return Ok(ApiResponse<WalletDto>.Ok(wallet));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // POST /api/wallet/withdraw
    [HttpPost("withdraw")]
    public async Task<IActionResult> RequestWithdrawal([FromBody] CreateWithdrawalRequest request)
    {
        try
        {
            var result = await _walletService.RequestWithdrawalAsync(CurrentUserId, request);
            return Ok(ApiResponse<WithdrawalRequestDto>.Ok(result));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/wallet/withdrawals?page=1&pageSize=20&status=pending  (admin only)
    [HttpGet("withdrawals")]
    public async Task<IActionResult> GetWithdrawalRequests(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? status = null)
    {
        if (!IsAdmin)
            return Forbid();

        var result = await _walletService.GetWithdrawalRequestsAsync(page, pageSize, status);
        return Ok(ApiResponse<PagedResult<WithdrawalRequestDto>>.Ok(result));
    }

    // PATCH /api/wallet/withdrawals/{id}  (admin only)
    [HttpPatch("withdrawals/{id:int}")]
    public async Task<IActionResult> ProcessWithdrawal(
        int id, [FromBody] ProcessWithdrawalRequest request)
    {
        if (!IsAdmin)
            return Forbid();

        try
        {
            var result = await _walletService.ProcessWithdrawalAsync(id, request);
            return Ok(ApiResponse<WithdrawalRequestDto>.Ok(result));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/wallet/withdrawal-threshold
    [HttpGet("withdrawal-threshold")]
    public async Task<IActionResult> GetWithdrawalThreshold()
    {
        var threshold = await _walletService.GetWithdrawalThresholdAsync();
        return Ok(ApiResponse<object>.Ok(new { threshold }));
    }
}
