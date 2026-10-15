using SportaApis.DTOs;
using SportaApis.Enums;

namespace SportaApis.Services;

public interface IWalletService
{
    /// <summary>Returns the user's wallet (created if missing) with recent transactions and threshold.</summary>
    Task<WalletDto> GetWalletAsync(int userId);

    /// <summary>Paged transaction history (newest first).</summary>
    Task<PagedResult<WalletTransactionDto>> GetTransactionsAsync(
        int userId, int page, int pageSize);

    /// <summary>
    /// يفتح جلسة شحن لدى FINY ويعيد صفحة دفعها. لا يتحرك رصيد هنا — الرصيد
    /// يُضاف بعد أن تؤكد البوابة الدفع، لا بعد أن يطلبه التطبيق.
    /// </summary>
    Task<TopUpSessionDto> StartTopUpAsync(int userId, decimal amount, string? description);

    /// <summary>
    /// يحسم جلسة شحن: يسأل FINY عن حالتها، ويشحن المحفظة إن كانت مدفوعة.
    /// يُنادى من التطبيق بعد إغلاق صفحة الدفع، ومن الـ webhook حين يصل — أيّهما
    /// سبق. مكرَّرُ النداء لا يشحن مرتين.
    /// </summary>
    /// <param name="expectedUserId">
    /// حين يأتي النداء من التطبيق: صاحب الجلسة يجب أن يكون صاحب التوكن. بدونه
    /// يؤكد أي مستخدم عملية غيره ويشحن محفظته هو.
    /// </param>
    /// <returns>محفظة المستخدم بعد الشحن، أو null إن لم تُدفع العملية بعد.</returns>
    Task<WalletDto?> CompleteTopUpAsync(int finyPaymentId, int? expectedUserId);

    /// <summary>
    /// شحن بـ Apple Pay في نداء واحد: يمرّر توكن آبل إلى FINY، وإن عادت العملية
    /// مدفوعة يشحن المحفظة بنفس مسار <see cref="CompleteTopUpAsync"/>. null =
    /// لم تُحسم بعد لدى البوابة (نادر مع Apple Pay) ويحسمها الـ webhook.
    /// </summary>
    Task<WalletDto?> TopUpWithApplePayAsync(
        int userId, decimal amount, string token, string? description);

    /// <summary>
    /// What a top-up of <paramref name="amount"/> costs: the gateway fee and the
    /// total charged to the card. The app must charge <c>Total</c> — the server
    /// recomputes this on verification, so a client-side formula would drift.
    /// </summary>
    Task<TopUpQuoteDto> QuoteTopUpAsync(decimal amount);

    /// <summary>
    /// Attempts to charge [amount] from the wallet. Returns true when charged
    /// (sufficient balance), false otherwise — callers decide how to proceed.
    /// </summary>
    Task<bool> TryChargeAsync(
        int userId, decimal amount, WalletTransactionType type,
        string? description, int? referenceId);

    /// <summary>Credits a refund back to the wallet.</summary>
    Task RefundAsync(int userId, decimal amount, string? description, int? referenceId);

    /// <summary>Credits earnings (coach/venue) to the wallet.</summary>
    Task CreditEarningAsync(
        int userId, decimal amount, WalletTransactionType type,
        string? description, int? referenceId);

    /// <summary>
    /// يعكس أرباحاً قُيِّدت سابقاً (مثلاً حجز مؤكد أُلغي واستُردّ للاعب):
    /// يُخصم المبلغ من المحفظة حتى لو صار الرصيد سالباً (دَين على المالك/المدرب).
    /// </summary>
    Task ReverseEarningAsync(
        int userId, decimal amount, WalletTransactionType type,
        string? description, int? referenceId);

    // ── Bank account (مطلوب لملّاك الملاعب والمدربين قبل السحب) ───────────────

    /// <summary>الحساب البنكي المحفوظ للمستخدم (IsSet = false حين لم يُضَف بعد).</summary>
    Task<BankAccountDto> GetBankAccountAsync(int userId);

    /// <summary>يحفظ/يحدّث الحساب البنكي بعد التحقق من صحة الآيبان.</summary>
    Task<BankAccountDto> SaveBankAccountAsync(int userId, SaveBankAccountRequest request);

    // ── Withdrawal ────────────────────────────────────────────────────────────

    /// <summary>User requests a cash withdrawal. Deducts balance and creates a pending request.</summary>
    Task<WithdrawalRequestDto> RequestWithdrawalAsync(
        int userId, CreateWithdrawalRequest request);

    /// <summary>Admin lists all withdrawal requests (paginated).</summary>
    Task<PagedResult<WithdrawalRequestDto>> GetWithdrawalRequestsAsync(
        int page, int pageSize, string? status);

    /// <summary>Admin approves or rejects a withdrawal request.</summary>
    Task<WithdrawalRequestDto> ProcessWithdrawalAsync(
        int requestId, ProcessWithdrawalRequest request);

    /// <summary>Returns the configured minimum withdrawal threshold from SystemSettings.</summary>
    Task<decimal> GetWithdrawalThresholdAsync();
}
