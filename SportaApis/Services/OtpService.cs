using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SportaApis.Data;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

/// <summary>
/// منطق رموز التحقق. المزوّد يوصِل الرمز فقط؛ أما مَن يستحق رمزاً، وكم مرة،
/// وما الذي يُجيزه الرمز بعد نجاحه — فهنا.
///
/// نقطتان تحكمان التصميم:
/// • كل رسالة بتكلفة، فالحدود تُفحص قبل أي نداء خارجي لا بعده.
/// • الرمز لا يُقدَّم للخطوة التالية إطلاقاً — يُبدَّل بتذكرة مرتبطة بغرضها،
///   فرمزٌ سُرِّب من إشعار واتساب لا يهدم أكثر من غرضه الواحد.
/// </summary>
public class OtpService : IOtpService
{
    private readonly AppDbContext _db;
    private readonly IOtpSender _sender;
    private readonly OtpOptions _options;
    private readonly ILogger<OtpService> _logger;

    public OtpService(
        AppDbContext db,
        IOtpSender sender,
        IOptions<OtpOptions> options,
        ILogger<OtpService> logger)
    {
        _db = db;
        _sender = sender;
        _options = options.Value;
        _logger = logger;
    }

    // ── طلب رمز ───────────────────────────────────────────────────────────────

    public async Task<OtpRequestResult> RequestAsync(
        string phone, OtpPurpose purpose, CancellationToken ct = default)
    {
        var local = NormalizeOrThrow(phone);
        await EnsurePurposeAllowedAsync(local, purpose);

        // رقم اختبار: لا نداء ولا رسالة ولا تكلفة — رمزه ثابت ويُطابَق عندنا.
        // ولأن لا رسالة تُرسَل فلا شيء تحميه الحدود هنا، ومنعُ مراجعِ المتجر من
        // إعادة الدخول خلال دقيقة عطبٌ بلا مقابل.
        var fixedCode = FixedCodeFor(local);
        if (fixedCode is null) await EnforceSendLimitsAsync(local);

        // إبطال ما سبق لنفس الرقم والغرض: رمز واحد حيّ في كل لحظة، فلا يقبل
        // الخادمُ رمزاً قديماً بعد أن طلب المستخدم بديلاً.
        await _db.OtpCodes
            .Where(o => o.PhoneNumber == local && o.Purpose == purpose && !o.IsUsed)
            .ExecuteUpdateAsync(s => s.SetProperty(o => o.IsUsed, true), ct);

        OtpSendResult sent;
        if (fixedCode is not null)
        {
            _logger.LogInformation(
                "OTP for test number {Phone} — no message sent", PhoneNumber.Mask(local));
            sent = new OtpSendResult("test", fixedCode);
        }
        else
        {
            try
            {
                sent = await _sender.SendAsync(local, ct);
            }
            catch (OtpSendException ex)
            {
                _logger.LogError(ex, "OTP send failed for {Phone}", PhoneNumber.Mask(local));
                throw new AuthException(
                    "Could not send the verification code, please try again",
                    "تعذّر إرسال رمز التحقق، حاول مرة أخرى",
                    "OTP_SEND_FAILED");
            }
        }

        var record = new OtpCode
        {
            PhoneNumber = local,
            Purpose = purpose,
            Channel = sent.Channel,
            // وجود الرمز هنا هو ما يقرّر لاحقاً أين يُطابَق: محفوظاً يعني عندنا
            // (رقم اختبار أو مزوّد محلي)، وفارغاً يعني لدى المزوّد الذي يملكه.
            Code = fixedCode ?? (_sender.OwnsCodeLifecycle ? string.Empty : sent.DevCode ?? string.Empty),
            ExpiresAt = DateTime.UtcNow.AddMinutes(_options.ExpiryMinutes),
        };

        _db.OtpCodes.Add(record);
        await _db.SaveChangesAsync(ct);

        return new OtpRequestResult(
            sent.Channel,
            // الرمز الثابت لأرقام الاختبار قد يخالف طول قالب المزوّد، والشاشة
            // يجب أن ترسم خاناتِ ما وصل فعلاً لا ما تقوله الإعدادات.
            fixedCode?.Length ?? Math.Clamp(_options.CodeLength, 4, 8),
            _options.ExpiryMinutes * 60,
            _options.ResendCooldownSeconds,
            // إعادة الرمز للعميل تعني أن أي شخص يعرف رقماً يدخل به عبر ردّ
            // الـ API. تُربَط بالموافقة الصريحة نفسها التي تُشغّل المزوّد
            // المحلي، لا باسم البيئة — فبيئةٌ خاطئة على خادم حيّ لا تكفي
            // وحدها لكشف الرموز.
            _options.AllowInsecureLocalProvider ? sent.DevCode : null);
    }

    // ── التحقق ────────────────────────────────────────────────────────────────

    public async Task<string> VerifyAsync(
        string phone, string code, OtpPurpose purpose, CancellationToken ct = default)
    {
        var local = NormalizeOrThrow(phone);

        var record = await _db.OtpCodes
            .Where(o => o.PhoneNumber == local && o.Purpose == purpose)
            .OrderByDescending(o => o.CreatedAt)
            .FirstOrDefaultAsync(ct);

        if (record is null || !record.IsValid)
            throw InvalidOtp();

        if (record.Attempts >= _options.MaxVerifyAttempts)
        {
            record.IsUsed = true;
            await _db.SaveChangesAsync(ct);
            throw new AuthException(
                "Too many incorrect attempts, request a new code",
                "محاولات خاطئة كثيرة، اطلب رمزاً جديداً",
                "OTP_ATTEMPTS_EXCEEDED");
        }

        // أين يُطابَق الرمز يقرّره السجلّ لا الإعدادات الحالية: رمزٌ محفوظ يعني
        // أنه وُلِّد عندنا (رقم اختبار أو مزوّد محلي)، وفارغٌ يعني أن المزوّد
        // يملكه. هكذا لا يفسد تبديلُ المزوّد رمزاً أُرسل قبل التبديل بلحظات.
        var ok = string.IsNullOrEmpty(record.Code)
            ? await VerifyWithProviderAsync(local, code, ct)
            : FixedTimeEquals(record.Code, code);

        if (!ok)
        {
            record.Attempts++;
            await _db.SaveChangesAsync(ct);
            throw InvalidOtp();
        }

        record.IsUsed = true;
        record.VerifiedAt = DateTime.UtcNow;
        record.VerificationToken = GenerateToken();
        record.TokenExpiresAt =
            DateTime.UtcNow.AddMinutes(_options.VerificationTokenMinutes);
        await _db.SaveChangesAsync(ct);

        return record.VerificationToken;
    }

    private async Task<bool> VerifyWithProviderAsync(
        string local, string code, CancellationToken ct)
    {
        try
        {
            return await _sender.VerifyAsync(local, code, ct);
        }
        catch (OtpSendException ex)
        {
            _logger.LogError(ex, "OTP verify failed for {Phone}", PhoneNumber.Mask(local));
            throw new AuthException(
                "Verification is temporarily unavailable, please try again",
                "خدمة التحقق غير متاحة مؤقتاً، حاول مرة أخرى",
                "OTP_PROVIDER_UNAVAILABLE");
        }
    }

    // ── استهلاك التذكرة ───────────────────────────────────────────────────────

    public async Task ConsumeTokenAsync(string phone, string token, OtpPurpose purpose)
    {
        var local = NormalizeOrThrow(phone);

        if (string.IsNullOrWhiteSpace(token))
            throw NotVerified();

        var record = await _db.OtpCodes.FirstOrDefaultAsync(o =>
            o.PhoneNumber == local &&
            o.Purpose == purpose &&
            o.VerificationToken == token);

        if (record is null || !record.IsTokenValid)
            throw NotVerified();

        record.TokenConsumed = true;
        record.UpdatedAt = DateTime.UtcNow;
        // الحفظ متروك للمستدعي: الاستهلاك يجب أن يسقط مع العملية إن فشلت،
        // فلا تُحرق تذكرةٌ على تسجيلٍ لم يكتمل.
    }

    // ── شروط الغرض ────────────────────────────────────────────────────────────

    /// <summary>
    /// يمنع صرف رسالة على طلب مستحيل أصلاً: تسجيلٌ برقم قائم، أو دخولٌ برقم
    /// مجهول. الرسالة صريحة عمداً — التطبيق يوجّه المستخدم للمسار الصحيح، وهذا
    /// ليس تسريباً: شاشة التسجيل تكشف الشيء نفسه حين ترفض رقماً مكرراً.
    /// </summary>
    private async Task EnsurePurposeAllowedAsync(string local, OtpPurpose purpose)
    {
        var user = await _db.Users
            .Where(u => u.PhoneNumber == local)
            .Select(u => new
            {
                u.IsActive,
                u.IsDeleted,
                // حساب إدارة/موظف بلا دور في التطبيق يدخل من لوحة التحكم فقط.
                DashboardOnly = (u.UserType == UserType.Admin || u.UserType == UserType.Staff) &&
                                !u.Roles.Any(r => r.Role == UserType.Player ||
                                                  r.Role == UserType.Coach ||
                                                  r.Role == UserType.VenueOwner),
            })
            .FirstOrDefaultAsync();

        if (purpose == OtpPurpose.Register || purpose == OtpPurpose.ChangePhone)
        {
            if (user is not null)
                throw new AuthException(
                    "Phone number already registered",
                    "رقم الهاتف مسجل من قبل",
                    "PHONE_EXISTS");
            return;
        }

        if (user is null)
            throw new AuthException(
                "This phone number is not registered",
                "رقم الهاتف غير مسجّل",
                "PHONE_NOT_REGISTERED");

        if (user.IsDeleted)
            throw new AuthException(
                "This account has been deleted",
                "تم حذف هذا الحساب نهائياً",
                "ACCOUNT_DELETED");

        if (!user.IsActive)
            throw new AuthException(
                "Account is suspended",
                "الحساب موقوف",
                "ACCOUNT_SUSPENDED");

        // لا نرسل رمز دخول لا يُقبل بعدها (AuthService.EnsureAppAccount يرفضه).
        if (purpose == OtpPurpose.Login && user.DashboardOnly)
            throw new AuthException(
                "Admin and staff accounts sign in from the dashboard",
                "حسابات الإدارة والموظفين تسجّل الدخول من لوحة التحكم",
                "DASHBOARD_ACCOUNT");
    }

    // ── حدود الإرسال ──────────────────────────────────────────────────────────

    /// <summary>
    /// حدّان على مستوى الرقم لا الغرض: مهلة بين رسالتين، وسقف في الساعة. لو
    /// كانا لكل غرض على حدة لأمكن تجاوزهما بتبديل الغرض في كل طلب.
    /// </summary>
    private async Task EnforceSendLimitsAsync(string local)
    {
        var now = DateTime.UtcNow;

        var last = await _db.OtpCodes
            .Where(o => o.PhoneNumber == local)
            .OrderByDescending(o => o.CreatedAt)
            .Select(o => (DateTime?)o.CreatedAt)
            .FirstOrDefaultAsync();

        if (last is not null)
        {
            var wait = _options.ResendCooldownSeconds - (int)(now - last.Value).TotalSeconds;
            if (wait > 0)
                throw new AuthException(
                    $"Please wait {wait} seconds before requesting another code",
                    $"انتظر {wait} ثانية قبل طلب رمز جديد",
                    "OTP_COOLDOWN");
        }

        var lastHour = await _db.OtpCodes
            .CountAsync(o => o.PhoneNumber == local && o.CreatedAt >= now.AddHours(-1));

        if (lastHour >= _options.MaxSendsPerHour)
            throw new AuthException(
                "Too many verification codes requested, try again later",
                "طلبت رموز تحقق كثيرة، حاول بعد قليل",
                "OTP_RATE_LIMITED");
    }

    // ── مساعدات ───────────────────────────────────────────────────────────────

    /// <summary>
    /// الرمز الثابت المُعدّ لهذا الرقم إن كان رقم اختبار، وإلا <c>null</c>.
    /// المفاتيح تُطبَّع أيضاً كي لا يفلت الرقم لأنه كُتب في الإعدادات بصيغة أخرى.
    /// </summary>
    private string? FixedCodeFor(string local) =>
        _options.TestNumbers
            .FirstOrDefault(kv => PhoneNumber.TryNormalize(kv.Key) == local)
            .Value;

    /// <summary>
    /// مقارنة ثابتة الزمن: المقارنة النصّية العادية تعود عند أول حرف مختلف،
    /// وفرقُ التوقيت بين رمز يبدأ صحيحاً وآخر لا، يُخمَّن به الرمز رقماً رقماً.
    /// </summary>
    private static bool FixedTimeEquals(string a, string b) =>
        CryptographicOperations.FixedTimeEquals(
            System.Text.Encoding.UTF8.GetBytes(a),
            System.Text.Encoding.UTF8.GetBytes(b));

    private static string NormalizeOrThrow(string phone) =>
        PhoneNumber.TryNormalize(phone)
        ?? throw new AuthException(
            "Invalid phone number", "رقم الجوال غير صحيح", "INVALID_PHONE");

    private static string GenerateToken() =>
        Convert.ToHexString(RandomNumberGenerator.GetBytes(32));

    private static AuthException InvalidOtp() => new(
        "Invalid or expired verification code",
        "رمز التحقق غير صحيح أو منتهي الصلاحية",
        "INVALID_OTP");

    private static AuthException NotVerified() => new(
        "Phone verification required",
        "يجب التحقق من رقم الجوال أولاً",
        "OTP_NOT_VERIFIED");
}
