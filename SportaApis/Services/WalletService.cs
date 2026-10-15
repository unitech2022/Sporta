using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

public class WalletService : IWalletService
{
    private const string ThresholdKey = "withdrawal_min_threshold";
    private const decimal DefaultThreshold = 100m;

    /// <summary>
    /// وسم عمليات شحن المحفظة في metadata لدى FINY. منصة الدفع تخدم تطبيقات
    /// أخرى، والوسم هو ما يمنع اعتماد عملية ليست لنا ولا لهذا الغرض.
    /// </summary>
    private const string TopUpPurpose = "wallet_topup";

    private readonly AppDbContext _db;
    private readonly IFinyPaymentService _finy;
    private readonly ISettingsService _settings;
    private readonly IAdminContext _admin;
    private readonly ILogger<WalletService> _logger;

    /// <summary>عنوان انتهاء صفحة الدفع — يرصده التطبيق ليعرف أن العميل انتهى.</summary>
    private readonly string _finyCallbackUrl;

    public WalletService(
        AppDbContext db, IFinyPaymentService finy, ISettingsService settings,
        IAdminContext admin, IOptions<FinyOptions> finyOptions, ILogger<WalletService> logger)
    {
        _db = db;
        _finy = finy;
        _settings = settings;
        _admin = admin;
        _logger = logger;
        _finyCallbackUrl = finyOptions.Value.CallbackUrl;
    }

    // ── Read ───────────────────────────────────────────────────────────────────

    public async Task<WalletDto> GetWalletAsync(int userId)
    {
        var wallet = await GetOrCreateAsync(userId);
        var threshold = await GetWithdrawalThresholdAsync();

        var transactions = await _db.WalletTransactions
            .Where(t => t.WalletId == wallet.Id)
            .OrderByDescending(t => t.CreatedAt)
            .Take(50)
            .ToListAsync();

        var pendingWithdrawal = await _db.WithdrawalRequests
            .Where(w => w.UserId == userId && w.Status == WithdrawalStatus.Pending)
            .SumAsync(w => (decimal?)w.Amount) ?? 0m;

        return new WalletDto
        {
            Balance = wallet.Balance,
            Transactions = transactions.Select(ToDto).ToList(),
            WithdrawalThreshold = threshold,
            PendingWithdrawalAmount = pendingWithdrawal,
        };
    }

    public async Task<PagedResult<WalletTransactionDto>> GetTransactionsAsync(
        int userId, int page, int pageSize)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 20;
        if (pageSize > 100) pageSize = 100;

        var wallet = await GetOrCreateAsync(userId);

        var query = _db.WalletTransactions
            .Where(t => t.WalletId == wallet.Id)
            .OrderByDescending(t => t.CreatedAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<WalletTransactionDto>
        {
            Items = items.Select(ToDto).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    // ── Top-up ─────────────────────────────────────────────────────────────────

    public async Task<TopUpQuoteDto> QuoteTopUpAsync(decimal amount)
    {
        var (percent, fixedFee, vat) = await _settings.GetTopUpFeeAsync();
        var (fee, total) = TopUpFee.Calculate(amount, percent, fixedFee, vat);
        return new TopUpQuoteDto { Amount = amount, Fee = fee, Total = total };
    }

    /// <summary>بادئة مرجع العملية — تميّز عمليات FINY عن أي بوابة سبقتها.</summary>
    private const string FinyReferencePrefix = "finy_";

    /// <summary>
    /// ما يشترك فيه كل مسارات الشحن (بطاقة عبر الصفحة المستضافة، Apple Pay):
    /// الحدود، عرض السعر، والـ metadata التي يُعرف بها صاحب العملية لاحقاً.
    /// </summary>
    private async Task<(TopUpQuoteDto Quote, Wallet Wallet, string Label,
        Dictionary<string, string> Metadata)> PrepareTopUpAsync(
        int userId, decimal amount, string? description)
    {
        if (amount <= 0)
            throw new AuthException("Invalid amount", "مبلغ غير صحيح", "INVALID_AMOUNT");

        // حدود الشحن يضبطها المدير من لوحة التحكم — تُفرض هنا لا في الـ DTO حتى
        // يبقى التطبيق والخادم على مصدر واحد دون إعادة نشر.
        var (min, max) = await _settings.GetTopUpLimitsAsync();
        if (amount < min)
            throw new AuthException(
                $"Minimum top-up is {min:0.##} SAR",
                $"الحد الأدنى للشحن {min:0.##} ر.س",
                "AMOUNT_BELOW_MIN");
        if (amount > max)
            throw new AuthException(
                $"Maximum top-up is {max:0.##} SAR",
                $"الحد الأقصى للشحن {max:0.##} ر.س",
                "AMOUNT_ABOVE_MAX");

        // المخصوم من البطاقة هو المبلغ + رسوم البوابة؛ والمضاف للمحفظة هو المبلغ
        // وحده. الحساب هنا هو نفسه الذي بُني عليه عرض السعر في التطبيق.
        var quote = await QuoteTopUpAsync(amount);
        var wallet = await GetOrCreateAsync(userId);

        var label = string.IsNullOrWhiteSpace(description) ? "شحن محفظة سبورتا" : description;

        // صاحب العملية والمبلغ المتفق عليه يعيشان في metadata لدى FINY، وتعود
        // كما هي في كل استعلام. فلا جدول جلسات عندنا يُنسى تنظيفه، ولا اعتماد
        // على ما يرسله التطبيق لحظة التأكيد.
        var metadata = new Dictionary<string, string>
        {
            ["purpose"] = TopUpPurpose,
            ["user_id"] = userId.ToString(),
            ["credit"] = amount.ToString("0.##"),
            ["total"] = quote.Total.ToString("0.##"),
            ["callback_url"] = _finyCallbackUrl,
        };

        return (quote, wallet, label, metadata);
    }

    public async Task<TopUpSessionDto> StartTopUpAsync(
        int userId, decimal amount, string? description)
    {
        var (quote, wallet, label, metadata) =
            await PrepareTopUpAsync(userId, amount, description);

        var payment = await _finy.CreatePaymentAsync(
            quote.Total,
            label,
            metadata,
            // مفتاح الجلسة: نقرة مزدوجة على «ادفع» لا تفتح عمليتين خلال الدقيقة.
            idempotencyKey: $"topup_{wallet.Id}_{amount:0.##}_" +
                            $"{DateTime.UtcNow:yyyyMMddHHmm}");

        // بيئة FINY التجريبية بلا مفاتيح مزود «تدفع» فوراً بلا صفحة. نعيد عنوان
        // العودة نفسه رابطاً: يفتحه التطبيق فيلمس عنوان العودة فوراً فيؤكد،
        // فيمر مسار التطوير بنفس خطوات الإنتاج حرفياً.
        var redirectUrl = payment.RedirectUrl;
        if (string.IsNullOrWhiteSpace(redirectUrl) && payment.IsPaid)
            redirectUrl = _finyCallbackUrl;

        if (string.IsNullOrWhiteSpace(redirectUrl))
        {
            _logger.LogError(
                "FINY payment {PaymentId} came back without a checkout URL (status {Status})",
                payment.Id, payment.Status);
            throw new AuthException(
                "Payment session has no checkout page",
                "تعذّر فتح صفحة الدفع",
                "NO_CHECKOUT_URL");
        }

        return new TopUpSessionDto
        {
            PaymentId = payment.Id,
            RedirectUrl = redirectUrl,
            CallbackUrl = _finyCallbackUrl,
            Amount = amount,
            Total = quote.Total,
        };
    }

    public async Task<WalletDto?> TopUpWithApplePayAsync(
        int userId, decimal amount, string token, string? description)
    {
        if (string.IsNullOrWhiteSpace(token))
            throw new AuthException(
                "Apple Pay token is missing", "توكن Apple Pay مفقود", "APPLEPAY_TOKEN_MISSING");

        var (quote, wallet, label, metadata) =
            await PrepareTopUpAsync(userId, amount, description);

        // التوكن يمرّ في metadata كما توثّق FINY، وهي تسحبه قبل التخزين فلا
        // يعود في أي استعلام. ورقة آبل توثّق العميل مسبقاً، فلا 3-D Secure ولا
        // صفحة — تعود العملية محسومة في النداء نفسه.
        metadata["source_type"] = "applepay";
        metadata["source_token"] = token;

        // كل توكن آبل أحادي الاستعمال: مفتاح الإدمبوتنسي من بصمته، فتكرار
        // النداء بنفس التوكن (انقطاع شبكة ثم إعادة) يعيد العملية نفسها، وتوكن
        // جديد يفتح عملية جديدة حتى لو تطابق المبلغ والدقيقة.
        var fingerprint = Convert.ToHexString(
            System.Security.Cryptography.SHA256.HashData(
                System.Text.Encoding.UTF8.GetBytes(token)))[..16];

        var payment = await _finy.CreatePaymentAsync(
            quote.Total,
            label,
            metadata,
            idempotencyKey: $"applepay_{wallet.Id}_{fingerprint}",
            paymentMethod: "applepay");

        if (payment.IsPaid)
            // الاعتماد من سجل FINY لا من هذا الرد: نفس مسار البطاقة والـ webhook.
            return await CompleteTopUpAsync(payment.Id, userId);

        if (string.Equals(payment.Status, "pending", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(payment.Status, "processing", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogInformation(
                "Apple Pay FINY payment {PaymentId} still {Status} — webhook will settle it",
                payment.Id, payment.Status);
            return null;
        }

        _logger.LogWarning(
            "Apple Pay FINY payment {PaymentId} ended {Status} for user {UserId}",
            payment.Id, payment.Status, userId);
        throw new AuthException(
            "Apple Pay payment was declined",
            "لم تُقبل عملية Apple Pay — جرّب بطاقة أخرى",
            "APPLEPAY_DECLINED");
    }

    public async Task<WalletDto?> CompleteTopUpAsync(int finyPaymentId, int? expectedUserId)
    {
        var reference = FinyReferencePrefix + finyPaymentId;

        // عولجت من قبل: نعيد المحفظة كما هي. تكرار التأكيد ليس خطأً — التطبيق
        // والـ webhook كلاهما يؤكد، وأحدهما يصل ثانياً دائماً.
        var existing = await _db.WalletTransactions
            .Include(t => t.Wallet)
            .FirstOrDefaultAsync(t => t.PaymentReference == reference);
        if (existing is not null)
            return await GetWalletAsync(existing.Wallet.UserId);

        // الحقيقة تُسأل من البوابة. ما يقوله التطبيق («دفعتُ») ليس دليلاً.
        var payment = await _finy.GetPaymentAsync(finyPaymentId);
        if (payment is null)
            throw new AuthException(
                "Payment not found", "لم يتم العثور على عملية الدفع", "PAYMENT_NOT_FOUND");

        if (!payment.IsPaid)
        {
            _logger.LogInformation(
                "FINY payment {PaymentId} is not paid yet (status {Status})",
                finyPaymentId, payment.Status);
            return null;
        }

        var metadata = payment.Metadata ?? [];

        // عملية لتطبيق آخر على نفس المنصة، أو لغرض آخر عندنا — لا تشحن محفظة.
        if (!metadata.TryGetValue("purpose", out var purpose) || purpose != TopUpPurpose)
            throw new AuthException(
                "Payment is not a wallet top-up",
                "هذه العملية ليست شحن محفظة",
                "NOT_A_TOPUP");

        if (!metadata.TryGetValue("user_id", out var rawUserId) ||
            !int.TryParse(rawUserId, out var userId))
            throw new AuthException(
                "Payment has no owner", "العملية بلا صاحب", "TOPUP_NO_OWNER");

        // تأكيد التطبيق يشحن محفظة صاحب التوكن فقط. الـ webhook لا يمرّ من هنا:
        // لا مستخدم متصلاً معه، وصاحبها هو ما في metadata.
        if (expectedUserId is int caller && caller != userId)
            throw new AuthException(
                "Payment belongs to another user",
                "هذه العملية تخص مستخدماً آخر",
                "TOPUP_FOREIGN");

        if (!metadata.TryGetValue("credit", out var rawCredit) ||
            !decimal.TryParse(rawCredit, out var credit) || credit <= 0)
            throw new AuthException(
                "Payment has no credit amount",
                "العملية بلا مبلغ شحن",
                "TOPUP_NO_AMOUNT");

        // المدفوع يجب أن يطابق ما اتُّفق عليه لحظة الإنشاء. الطرفان من سجل FINY
        // نفسه، فالاختلاف يعني خللاً لا محاولة تلاعب — ويُوقف الشحن حتى يُفهم.
        if (metadata.TryGetValue("total", out var rawTotal) &&
            decimal.TryParse(rawTotal, out var expectedTotal) &&
            payment.Amount != expectedTotal)
        {
            _logger.LogWarning(
                "FINY payment {PaymentId} amount mismatch: paid {Paid}, expected {Expected}",
                finyPaymentId, payment.Amount, expectedTotal);
            throw new AuthException(
                "Payment amount mismatch", "المبلغ المدفوع لا يطابق المطلوب", "AMOUNT_MISMATCH");
        }

        var wallet = await GetOrCreateAsync(userId);

        var fee = payment.Amount - credit;
        var label = "شحن المحفظة";
        if (fee > 0) label += $" (رسوم {fee:0.##} ر.س)";

        try
        {
            // الإضافة والحركة في معاملة واحدة: إن أوقفنا القيد الفريد على المرجع
            // تُلغى الإضافة معها فلا يُشحن المبلغ مرتين.
            await MoveBalanceAsync(wallet, credit, mustCover: null, () =>
                _db.WalletTransactions.Add(new WalletTransaction
                {
                    WalletId = wallet.Id,
                    Amount = credit,
                    Type = WalletTransactionType.Deposit,
                    Status = PaymentStatus.Completed,
                    Description = label,
                    PaymentReference = reference,
                }));
        }
        catch (DbUpdateException ex) when (IsDuplicateReference(ex))
        {
            // سبقنا نداءٌ متزامن بأجزاء من الثانية وشحن العملية نفسها. القيد
            // الفريد أوقفنا قبل المضاعفة؛ لا شيء نصلحه، فقط نعيد الحالة.
            _logger.LogInformation(
                "FINY payment {PaymentId} was credited concurrently — ignoring", finyPaymentId);
            _db.ChangeTracker.Clear();
            return await GetWalletAsync(userId);
        }

        return await GetWalletAsync(userId);
    }

    /// <summary>هل فشل الحفظ بسبب القيد الفريد على مرجع العملية؟</summary>
    private static bool IsDuplicateReference(DbUpdateException ex) =>
        ex.InnerException?.Message.Contains("Duplicate entry", StringComparison.OrdinalIgnoreCase)
            == true;

    // ── Charge / refund / credit ───────────────────────────────────────────────

    public async Task<bool> TryChargeAsync(
        int userId, decimal amount, WalletTransactionType type,
        string? description, int? referenceId)
    {
        if (amount <= 0) return true;

        var wallet = await GetOrCreateAsync(userId);

        // الخصم ذرّي مشروط بكفاية الرصيد (UPDATE … WHERE Balance >= amount)،
        // فلا يمرّ خصمان متزامنان من رصيد لا يكفي إلا لأحدهما.
        var charged = await MoveBalanceAsync(wallet, -amount, mustCover: amount, () =>
            _db.WalletTransactions.Add(new WalletTransaction
            {
                WalletId = wallet.Id,
                Amount = -amount,
                Type = type,
                Status = PaymentStatus.Completed,
                Description = description,
                ReferenceId = referenceId,
            }));

        // الرصيد لا يكفي: تُسجَّل المحاولة كحركة فاشلة (للتدقيق) دون تحريك أي رصيد.
        if (!charged)
        {
            _db.WalletTransactions.Add(new WalletTransaction
            {
                WalletId = wallet.Id,
                Amount = -amount,
                Type = type,
                Status = PaymentStatus.Failed,
                Description = description,
                ReferenceId = referenceId,
            });
            await _db.SaveChangesAsync();
            return false;
        }

        return true;
    }

    public async Task RefundAsync(
        int userId, decimal amount, string? description, int? referenceId)
    {
        if (amount <= 0) return;

        var wallet = await GetOrCreateAsync(userId);
        await MoveBalanceAsync(wallet, amount, mustCover: null, () =>
            _db.WalletTransactions.Add(new WalletTransaction
            {
                WalletId = wallet.Id,
                Amount = amount,
                Type = WalletTransactionType.Refund,
                Description = description,
                ReferenceId = referenceId,
            }));
    }

    public async Task CreditEarningAsync(
        int userId, decimal amount, WalletTransactionType type,
        string? description, int? referenceId)
    {
        if (amount <= 0) return;

        var wallet = await GetOrCreateAsync(userId);
        await MoveBalanceAsync(wallet, amount, mustCover: null, () =>
            _db.WalletTransactions.Add(new WalletTransaction
            {
                WalletId = wallet.Id,
                Amount = amount,
                Type = type,
                Description = description,
                ReferenceId = referenceId,
            }));
    }

    public async Task ReverseEarningAsync(
        int userId, decimal amount, WalletTransactionType type,
        string? description, int? referenceId)
    {
        if (amount <= 0) return;

        // بلا فحص رصيد عمداً: الأرباح قُيِّدت فعلاً وقد يكون المالك سحبها،
        // فيبقى الفرق ديناً سالباً يُسدَّد من أرباحه القادمة.
        var wallet = await GetOrCreateAsync(userId);
        await MoveBalanceAsync(wallet, -amount, mustCover: null, () =>
            _db.WalletTransactions.Add(new WalletTransaction
            {
                WalletId = wallet.Id,
                Amount = -amount,
                Type = type,
                Description = description,
                ReferenceId = referenceId,
            }));
    }

    // ── Withdrawal ─────────────────────────────────────────────────────────────

    // ── Bank account ─────────────────────────────────────────────────────────

    public async Task<BankAccountDto> GetBankAccountAsync(int userId)
    {
        var u = await _db.Users
            .Where(x => x.Id == userId)
            .Select(x => new { x.Iban, x.BankName, x.AccountHolderName })
            .FirstOrDefaultAsync();

        var iban = u?.Iban;
        return new BankAccountDto
        {
            Iban = iban,
            BankName = u?.BankName,
            AccountHolderName = u?.AccountHolderName,
            IbanMasked = string.IsNullOrWhiteSpace(iban) ? null : Helpers.Iban.Mask(iban),
            IsSet = !string.IsNullOrWhiteSpace(iban),
        };
    }

    public async Task<BankAccountDto> SaveBankAccountAsync(
        int userId, SaveBankAccountRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.BankName) ||
            string.IsNullOrWhiteSpace(request.AccountHolderName))
            throw new AuthException(
                "Bank name and account holder are required",
                "اسم البنك واسم صاحب الحساب مطلوبان",
                "BANK_DETAILS_REQUIRED");

        // mod-97 لا الطول فقط — رقم خاطئ واحد يحوّل المستحقات لحساب آخر.
        if (!Helpers.Iban.IsValid(request.Iban))
            throw new AuthException(
                "Invalid IBAN",
                "رقم الآيبان غير صحيح — تأكد أنه يبدأ بـ SA ويتكوّن من 24 خانة",
                "INVALID_IBAN");

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        user.Iban = Helpers.Iban.Normalize(request.Iban);
        user.BankName = request.BankName.Trim();
        user.AccountHolderName = request.AccountHolderName.Trim();
        user.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return await GetBankAccountAsync(userId);
    }

    public async Task<WithdrawalRequestDto> RequestWithdrawalAsync(
        int userId, CreateWithdrawalRequest request)
    {
        var threshold = await GetWithdrawalThresholdAsync();

        // قفل لكل مستخدم: فحص «طلب معلّق قائم» ثم الإنشاء لا يمرّ لطلبين متزامنين.
        await using var _ = await DbLocks.AcquireAsync(_db, $"withdraw:{userId}");
        var wallet = await GetOrCreateAsync(userId);

        // الحساب البنكي المحفوظ هو مصدر بيانات التحويل — لا يُقبل سحب بدونه،
        // ولا نعتمد على ما يُرسله العميل حتى لا يتحوّل المبلغ لحساب غير موثّق.
        var account = await _db.Users
            .Where(u => u.Id == userId)
            .Select(u => new { u.Iban, u.BankName, u.AccountHolderName })
            .FirstOrDefaultAsync();

        if (account is null || string.IsNullOrWhiteSpace(account.Iban))
            throw new AuthException(
                "Bank account is required before withdrawing",
                "أضف حسابك البنكي (الآيبان) من ملفك الشخصي قبل طلب السحب",
                "BANK_ACCOUNT_REQUIRED");

        if (wallet.Balance < threshold)
            throw new AuthException(
                $"Minimum withdrawal is {threshold} SAR",
                $"الحد الأدنى للسحب هو {threshold} ر.س",
                "BELOW_THRESHOLD");

        if (request.Amount > wallet.Balance)
            throw new AuthException(
                "Insufficient balance",
                "الرصيد غير كافٍ",
                "INSUFFICIENT_BALANCE");

        // Check for an existing pending request
        var hasPending = await _db.WithdrawalRequests
            .AnyAsync(w => w.UserId == userId && w.Status == WithdrawalStatus.Pending);
        if (hasPending)
            throw new AuthException(
                "You already have a pending withdrawal request",
                "لديك طلب سحب قيد المراجعة بالفعل",
                "PENDING_EXISTS");

        var withdrawalRequest = new WithdrawalRequest
        {
            UserId = userId,
            Amount = request.Amount,
            // لقطة من الحساب المحفوظ وقت الطلب، فتغييره لاحقاً لا يمسّ طلباً قائماً.
            Iban = account.Iban!,
            BankName = account.BankName ?? string.Empty,
            AccountHolderName = account.AccountHolderName ?? string.Empty,
        };

        // Deduct balance immediately (held until admin processes) — خصم ذرّي
        // مشروط بالكفاية، فخصمٌ متزامن (حجز مثلاً) لا يُنزل الرصيد تحت الصفر.
        var deducted = await MoveBalanceAsync(
            wallet, -request.Amount, mustCover: request.Amount, () =>
            {
                _db.WalletTransactions.Add(new WalletTransaction
                {
                    WalletId = wallet.Id,
                    Amount = -request.Amount,
                    Type = WalletTransactionType.Withdrawal,
                    Description = $"طلب سحب - {account.BankName}",
                });
                _db.WithdrawalRequests.Add(withdrawalRequest);
            });
        if (!deducted)
            throw new AuthException(
                "Insufficient balance",
                "الرصيد غير كافٍ",
                "INSUFFICIENT_BALANCE");

        var user = await _db.Users.FindAsync(userId);
        return ToWithdrawalDto(withdrawalRequest, user!);
    }

    public async Task<PagedResult<WithdrawalRequestDto>> GetWithdrawalRequestsAsync(
        int page, int pageSize, string? status)
    {
        var query = _db.WithdrawalRequests
            .Include(w => w.User)
            .InScope(await _admin.GetScopeAsync())
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(status) &&
            Enum.TryParse<WithdrawalStatus>(status, ignoreCase: true, out var s))
            query = query.Where(w => w.Status == s);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(w => w.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<WithdrawalRequestDto>
        {
            Items = items.Select(w => ToWithdrawalDto(w, w.User)).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    public async Task<WithdrawalRequestDto> ProcessWithdrawalAsync(
        int requestId, ProcessWithdrawalRequest request)
    {
        // قفل لكل طلب: معالجتان متزامنتان لا تردّان المبلغ مرتين.
        await using var _ = await DbLocks.AcquireAsync(_db, $"withdrawal:{requestId}");

        var withdrawalRequest = await _db.WithdrawalRequests
            .Include(w => w.User)
            .InScope(await _admin.GetScopeAsync())
            .FirstOrDefaultAsync(w => w.Id == requestId)
            ?? throw new AuthException(
                "Withdrawal request not found",
                "طلب السحب غير موجود",
                "NOT_FOUND");

        if (withdrawalRequest.Status != WithdrawalStatus.Pending)
            throw new AuthException(
                "Request already processed",
                "تمت معالجة الطلب مسبقاً",
                "ALREADY_PROCESSED");

        withdrawalRequest.AdminNotes = request.AdminNotes;
        withdrawalRequest.ProcessedAt = DateTime.UtcNow;
        withdrawalRequest.UpdatedAt = DateTime.UtcNow;

        if (request.Approved)
        {
            withdrawalRequest.Status = WithdrawalStatus.Approved;
            await _db.SaveChangesAsync();
        }
        else
        {
            // Rejected → refund balance back to user (الردّ وتغيير الحالة في معاملة واحدة)
            withdrawalRequest.Status = WithdrawalStatus.Rejected;
            var wallet = await GetOrCreateAsync(withdrawalRequest.UserId);
            await MoveBalanceAsync(wallet, withdrawalRequest.Amount, mustCover: null, () =>
                _db.WalletTransactions.Add(new WalletTransaction
                {
                    WalletId = wallet.Id,
                    Amount = withdrawalRequest.Amount,
                    Type = WalletTransactionType.Refund,
                    Description = "رد طلب السحب المرفوض",
                    ReferenceId = withdrawalRequest.Id,
                }));
        }

        return ToWithdrawalDto(withdrawalRequest, withdrawalRequest.User);
    }

    public async Task<decimal> GetWithdrawalThresholdAsync()
    {
        var setting = await _db.SystemSettings
            .FirstOrDefaultAsync(s => s.Key == ThresholdKey);
        if (setting != null && decimal.TryParse(setting.ValueAr, out var v))
            return v;
        return DefaultThreshold;
    }

    // ── helpers ────────────────────────────────────────────────────────────────

    /// <summary>
    /// تحريك الرصيد ذرّياً في قاعدة البيانات (UPDATE Balance = Balance + delta)
    /// بدل القراءة ثم الكتابة من الذاكرة، فلا تضيع عملية متزامنة على نفس المحفظة.
    /// مع <paramref name="mustCover"/> لا يتم التحريك إلا إن كان الرصيد ≥ القيمة
    /// (الصفوف المتأثرة = النجاح). <paramref name="addRows"/> تضيف الحركة وما يرافقها،
    /// وتُحفظ مع التحريك في معاملة واحدة (أو ضمن معاملة المستدعي إن وُجدت).
    /// يُرجع false دون أي حفظ إن لم يكفِ الرصيد.
    /// </summary>
    private async Task<bool> MoveBalanceAsync(
        Wallet wallet, decimal delta, decimal? mustCover, Action addRows)
    {
        var ownTx = _db.Database.CurrentTransaction is null
            ? await _db.Database.BeginTransactionAsync()
            : null;
        try
        {
            var query = _db.Wallets.Where(w => w.Id == wallet.Id);
            if (mustCover is decimal need)
                query = query.Where(w => w.Balance >= need);

            var now = DateTime.UtcNow;
            var rows = await query.ExecuteUpdateAsync(s => s
                .SetProperty(w => w.Balance, w => w.Balance + delta)
                .SetProperty(w => w.UpdatedAt, now));
            if (rows == 0) return false;

            addRows();
            await _db.SaveChangesAsync();
            if (ownTx is not null) await ownTx.CommitAsync();
        }
        finally
        {
            // بلا Commit (فشل أو رصيد غير كافٍ) يُلغى التحريك عند التحرير.
            if (ownTx is not null) await ownTx.DisposeAsync();
        }

        // الكيان المتتبَّع يحمل رصيداً قديماً — نعيد قراءته حتى لا يُكتب فوق الجديد.
        await _db.Entry(wallet).ReloadAsync();
        return true;
    }

    private async Task<Wallet> GetOrCreateAsync(int userId)
    {
        var wallet = await _db.Wallets.FirstOrDefaultAsync(w => w.UserId == userId);
        if (wallet == null)
        {
            wallet = new Wallet { UserId = userId, Balance = 0m };
            _db.Wallets.Add(wallet);
            await _db.SaveChangesAsync();
        }
        return wallet;
    }

    private static WalletTransactionDto ToDto(WalletTransaction t) => new()
    {
        Id = t.Id,
        Amount = t.Amount,
        Type = char.ToLowerInvariant(t.Type.ToString()[0]) + t.Type.ToString()[1..],
        Status = char.ToLowerInvariant(t.Status.ToString()[0]) + t.Status.ToString()[1..],
        ReferenceId = t.ReferenceId,
        Description = t.Description,
        PaymentReference = t.PaymentReference,
        CreatedAt = t.CreatedAt,
    };

    private static WithdrawalRequestDto ToWithdrawalDto(WithdrawalRequest w, User user) => new()
    {
        Id = w.Id,
        UserId = w.UserId,
        UserName = $"{user.FirstName} {user.LastName}".Trim(),
        UserPhone = user.PhoneNumber,
        Amount = w.Amount,
        Status = char.ToLowerInvariant(w.Status.ToString()[0]) + w.Status.ToString()[1..],
        Iban = w.Iban,
        BankName = w.BankName,
        AccountHolderName = w.AccountHolderName,
        AdminNotes = w.AdminNotes,
        CreatedAt = w.CreatedAt,
        ProcessedAt = w.ProcessedAt,
    };
}
