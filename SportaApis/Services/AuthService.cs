using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

public class AuthService : IAuthService
{
    private readonly AppDbContext _db;
    private readonly ITokenService _tokenService;
    private readonly IConfiguration _config;
    private readonly IWalletService _wallet;
    private readonly INotificationService _notifications;
    private readonly IWebHostEnvironment _env;
    private readonly IOtpService _otp;
    private readonly IMatchService _matches;
    private readonly IWaitlistService _waitlist;
    private readonly AttemptThrottle _throttle;

    public AuthService(
        AppDbContext db,
        ITokenService tokenService,
        IConfiguration config,
        IWalletService wallet,
        INotificationService notifications,
        IWebHostEnvironment env,
        IOtpService otp,
        IMatchService matches,
        IWaitlistService waitlist,
        AttemptThrottle throttle)
    {
        _db = db;
        _tokenService = tokenService;
        _config = config;
        _wallet = wallet;
        _notifications = notifications;
        _env = env;
        _otp = otp;
        _matches = matches;
        _waitlist = waitlist;
        _throttle = throttle;
    }

    /// <summary>قفل مؤقت بعد محاولات كلمة مرور فاشلة متتالية على نفس الرقم.</summary>
    private const int MaxPasswordAttempts = 5;
    private static readonly TimeSpan PasswordLockout = TimeSpan.FromMinutes(15);

    // ── Register ──────────────────────────────────────────────────────────────

    public async Task<AuthResponseDto> RegisterAsync(RegisterRequest req)
    {
        // الرقم يُطبَّع مرة واحدة هنا فتُقارَن كل الاستعلامات بصيغة واحدة، ويُخزَّن
        // في القاعدة بها. أي صيغة أخرى يرسلها العميل تُرفض قبل أي عمل.
        var phone = PhoneNumber.TryNormalize(req.Phone)
            ?? throw new AuthException(
                "Invalid phone number", "رقم الجوال غير صحيح", "INVALID_PHONE");

        // Phone uniqueness
        if (await _db.Users.AnyAsync(u => u.PhoneNumber == phone))
            throw new AuthException(
                "Phone number already registered",
                "رقم الهاتف مسجل من قبل",
                "PHONE_EXISTS");

        // لا حساب يُنشأ لرقم لم يُثبت صاحبُ الطلب ملكيته: التذكرة صُرفت بعد رمز
        // واتساب وصل إلى هذا الرقم بعينه. الاستهلاك هنا لا يُحفظ إلا مع نجاح
        // التسجيل كاملاً، فتذكرةٌ لا تنتج حساباً تبقى صالحة للمحاولة التالية.
        await _otp.ConsumeTokenAsync(phone, req.VerificationToken, OtpPurpose.Register);

        // Resolve roles and validate role-specific payloads up-front so we don't
        // create a user record before discovering the request is incomplete.
        var roleTypes = req.Roles
            .Select(ParseUserType)
            .Where(r => r.HasValue)
            .Select(r => r!.Value)
            .Distinct()
            .ToList();

        if (roleTypes.Count == 0)
            throw new AuthException(
                "At least one valid role is required",
                "يجب اختيار دور واحد صالح على الأقل",
                "ROLE_REQUIRED");

        if (roleTypes.Contains(UserType.Coach) &&
            string.IsNullOrWhiteSpace(req.Coach?.Specialization))
            throw new AuthException(
                "Coach details are required",
                "تفاصيل المدرب مطلوبة",
                "COACH_DETAILS_REQUIRED");

        CoachProfile? coachProfile = null;
        if (roleTypes.Contains(UserType.Coach))
            coachProfile = await BuildCoachProfileAsync(req.Coach!);

        if (roleTypes.Contains(UserType.VenueOwner))
            ValidateVenueDetails(req.Venue);

        // الحساب البنكي مطلوب لكل من يستلم مستحقات — يُتحقق منه قبل إنشاء
        // المستخدم حتى لا يبقى حساب ناقص البيانات في القاعدة.
        var bank = roleTypes.Contains(UserType.VenueOwner)
            ? (req.Venue!.Iban, req.Venue.BankName, req.Venue.AccountHolderName)
            : roleTypes.Contains(UserType.Coach)
                ? (req.Coach!.Iban, req.Coach.BankName, req.Coach.AccountHolderName)
                : (null, null, null);
        if (bank.Item1 is not null) ValidateBankAccount(bank.Item1, bank.Item2, bank.Item3);

        var user = new User
        {
            FirstName = req.FirstName,
            LastName = req.LastName,
            PhoneNumber = phone,
            // لا كلمة سر لحسابات التطبيق — الدخول برمز واتساب. نضع تجزئة عشوائية
            // لا يعرفها أحد بدل تركها فارغة، كي لا يمرّ حساب بتجزئة قابلة للتخمين
            // لو أُعيد يوماً تفعيلُ الدخول بكلمة سر لنوع مستخدم ما.
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString("N")),
            PreferredLanguage = req.Language == "en" ? Language.English : Language.Arabic,
            Gender = ParseGender(req.Gender),
            Country = req.Country,
            City = req.City,
            District = req.District,
            Latitude = req.Latitude,
            Longitude = req.Longitude,
            UserType = roleTypes.First(),
            Iban = bank.Item1 is null ? null : Helpers.Iban.Normalize(bank.Item1),
            BankName = bank.Item2?.Trim(),
            AccountHolderName = bank.Item3?.Trim(),
        };
        await ApplyCityDistrictAsync(user, req.CityId, req.DistrictId);

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        // Roles
        // دورا المدرب وصاحب الملعب يبدآن معلّقين لحين موافقة الأدمن؛ صاحبهما
        // يستخدم التطبيق بدور اللاعب فقط حتى ذلك الحين.
        var roles = roleTypes
            .Select(r => new UserRole
            {
                UserId = user.Id,
                Role = r,
                IsApproved = !UserRole.NeedsApproval(r),
                ApprovedAt = UserRole.NeedsApproval(r) ? null : DateTime.UtcNow,
            })
            .ToList();
        _db.Set<UserRole>().AddRange(roles);

        // Role-specific profiles
        if (roleTypes.Contains(UserType.Player))
        {
            _db.PlayerProfiles.Add(new PlayerProfile { UserId = user.Id });
        }

        if (coachProfile is not null)
        {
            coachProfile.UserId = user.Id;
            _db.CoachProfiles.Add(coachProfile);
        }

        if (roleTypes.Contains(UserType.VenueOwner))
            ApplyOwnerDocuments(user, req.Venue!);

        await _db.SaveChangesAsync();

        // Load roles for token generation
        user.Roles = roles;

        return await BuildAuthResponseAsync(user, persistRefresh: true);
    }

    // ── Login ─────────────────────────────────────────────────────────────────

    /// <summary>
    /// دخول بكلمة سر — للوحة التحكم وحدها. مستخدمو التطبيق (لاعب/مدرب/مالك
    /// ملعب) لا يملكون كلمة سر أصلاً منذ التحوّل إلى رمز واتساب، فيُرفض دخولهم
    /// من هنا ويوجَّهون إلى <see cref="LoginWithOtpAsync"/>.
    /// </summary>
    public async Task<AuthResponseDto> LoginAsync(LoginRequest req)
    {
        // لا تخمين لكلمة مرور اللوحة: 5 محاولات فاشلة تقفل الرقم ربع ساعة.
        var attemptKey = $"pw-login:{PhoneNumber.TryNormalize(req.Phone) ?? req.Phone}";
        if (_throttle.IsBlocked(attemptKey, MaxPasswordAttempts))
            throw new AuthException(
                "Too many failed attempts, try again later",
                "محاولات كثيرة فاشلة، حاول بعد 15 دقيقة",
                "LOGIN_LOCKED");

        var user = await LoadLoginUserAsync(req.Phone);

        if (user.UserType is not (UserType.Admin or UserType.Staff))
            throw new AuthException(
                "Sign in with the code sent to your WhatsApp",
                "سجّل الدخول برمز التحقق المُرسل على واتساب",
                "OTP_LOGIN_REQUIRED");

        if (!BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash))
        {
            _throttle.Hit(attemptKey, PasswordLockout);
            throw new AuthException(
                "Incorrect password",
                "كلمة السر غير صحيحة",
                "INVALID_PASSWORD");
        }

        EnsureLoginAllowed(user);
        _throttle.Reset(attemptKey);

        return await BuildAuthResponseAsync(user, persistRefresh: true);
    }

    /// <summary>
    /// دخول برمز واتساب — الطريق الوحيد لمستخدمي التطبيق. لا يُصدَّق الرمز هنا
    /// بل في <c>OtpService</c>؛ ما يصل إلينا هو نجاحٌ مُثبَت لرقمٍ بعينه.
    /// </summary>
    public async Task<AuthResponseDto> LoginWithOtpAsync(string phone, string otp)
    {
        var token = await _otp.VerifyAsync(phone, otp, OtpPurpose.Login);

        var user = await LoadLoginUserAsync(phone);
        EnsureLoginAllowed(user);
        EnsureAppAccount(user);

        // الاستهلاك والجلسة يُحفظان معاً: إمّا تُحرق التذكرة ويدخل، أو لا شيء.
        await _otp.ConsumeTokenAsync(user.PhoneNumber, token, OtpPurpose.Login);

        return await BuildAuthResponseAsync(user, persistRefresh: true);
    }

    // ── Trusted devices ───────────────────────────────────────────────────────

    /// <summary>
    /// دخول من جهاز موثوق. الفشل بأي سبب (جهاز مجهول، سرّ خاطئ، جهاز مُلغى،
    /// رقم لا يخصّ الجهاز) يعود بالرمز نفسه <c>DEVICE_NOT_TRUSTED</c>: التطبيق
    /// يمسح ما عنده ويحوّل إلى رمز واتساب، ولا نُعلم من يجرّب أيَّ جزء أصاب.
    /// </summary>
    public async Task<AuthResponseDto> LoginWithDeviceAsync(
        string phone, string deviceId, string deviceSecret)
    {
        var local = PhoneNumber.TryNormalize(phone)
            ?? throw new AuthException(
                "Invalid phone number", "رقم الجوال غير صحيح", "INVALID_PHONE");

        var device = await _db.TrustedDevices
            .Include(d => d.User).ThenInclude(u => u.Roles)
            .FirstOrDefaultAsync(d => d.DeviceId == deviceId);

        if (device is null || !device.IsActive ||
            device.User.PhoneNumber != local ||
            !FixedTimeEquals(device.SecretHash, HashDeviceSecret(deviceSecret)))
            throw DeviceNotTrusted();

        EnsureLoginAllowed(device.User);
        EnsureAppAccount(device.User);

        device.LastUsedAt = DateTime.UtcNow;
        // الحفظ يقع داخل BuildAuthResponseAsync مع توكن التحديث.
        return await BuildAuthResponseAsync(device.User, persistRefresh: true);
    }

    public async Task<EnrolledDeviceDto> EnrollDeviceAsync(int userId, EnrollDeviceRequest req)
    {
        var deviceId = req.DeviceId.Trim();
        if (deviceId.Length is < 8 or > 64)
            throw new AuthException(
                "Invalid device identifier", "معرّف الجهاز غير صالح", "INVALID_DEVICE");

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");
        EnsureLoginAllowed(user);

        // معرّف واحد = صفّ واحد. إعادة التسجيل (تثبيت جديد، أو انتقال الجهاز
        // لحساب آخر) تُسقط الصفّ القديم بسرّه بدل أن تترك سرّين صالحين.
        _db.TrustedDevices.RemoveRange(
            await _db.TrustedDevices.Where(d => d.DeviceId == deviceId).ToListAsync());

        var secret = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        _db.TrustedDevices.Add(new TrustedDevice
        {
            UserId = userId,
            DeviceId = deviceId,
            SecretHash = HashDeviceSecret(secret),
            Name = req.DeviceName?.Trim(),
            Platform = req.Platform?.Trim().ToLowerInvariant(),
            LastUsedAt = DateTime.UtcNow,
        });
        await _db.SaveChangesAsync();

        return new EnrolledDeviceDto { DeviceId = deviceId, DeviceSecret = secret };
    }

    private static string HashDeviceSecret(string secret) =>
        Convert.ToHexString(SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(secret)));

    /// <summary>مقارنة ثابتة الزمن — كي لا يُخمَّن السرّ حرفاً حرفاً من فرق التوقيت.</summary>
    private static bool FixedTimeEquals(string a, string b) =>
        CryptographicOperations.FixedTimeEquals(
            System.Text.Encoding.UTF8.GetBytes(a),
            System.Text.Encoding.UTF8.GetBytes(b));

    private static AuthException DeviceNotTrusted() => new(
        "This device is not trusted, sign in with the code sent to your WhatsApp",
        "هذا الجهاز غير موثوق، سجّل الدخول برمز واتساب",
        "DEVICE_NOT_TRUSTED");

    private async Task<User> LoadLoginUserAsync(string phone)
    {
        var local = PhoneNumber.TryNormalize(phone)
            ?? throw new AuthException(
                "Invalid phone number", "رقم الجوال غير صحيح", "INVALID_PHONE");

        return await _db.Users
            .Include(u => u.Roles)
            .FirstOrDefaultAsync(u => u.PhoneNumber == local)
            ?? throw new AuthException(
                "This phone number is not registered",
                "رقم الهاتف غير مسجّل",
                "PHONE_NOT_REGISTERED");
    }

    private static void EnsureLoginAllowed(User user)
    {
        // حساب محذوف بطلب صاحبه — لا يعود إليه ولو استلم رمزاً على الرقم القديم.
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
    }

    /// <summary>
    /// دخول التطبيق لأصحاب أدوار التطبيق (لاعب/مدرب/ملعب — معتمداً أو معلّقاً).
    /// حساب إدارة أو موظف بلا دور منها كان يدخل بأدوار فارغة لأن التطبيق لا
    /// يعرف دور «staff»، فيُرفض هنا ويُوجَّه إلى لوحة التحكم.
    /// </summary>
    private static void EnsureAppAccount(User user)
    {
        if (user.UserType is not (UserType.Admin or UserType.Staff) ||
            user.Roles.Any(r =>
                r.Role is UserType.Player or UserType.Coach or UserType.VenueOwner))
            return;

        throw new AuthException(
            "Admin and staff accounts sign in from the dashboard",
            "حسابات الإدارة والموظفين تسجّل الدخول من لوحة التحكم",
            "DASHBOARD_ACCOUNT");
    }

    // ── Refresh Token ─────────────────────────────────────────────────────────

    /// <summary>كم يبقى توكن التحديث صالحاً بعد تدويره — انظر RefreshTokenAsync.</summary>
    private static readonly TimeSpan RefreshRotationGrace = TimeSpan.FromSeconds(60);

    public async Task<AuthResponseDto> RefreshTokenAsync(string token)
    {
        var stored = await _db.Set<RefreshToken>()
            .Include(rt => rt.User)
            .ThenInclude(u => u.Roles)
            .FirstOrDefaultAsync(rt => rt.Token == token);

        if (stored == null || !stored.IsActive)
            throw new AuthException(
                "Invalid or expired refresh token",
                "رمز التحديث غير صحيح أو منتهي الصلاحية",
                "INVALID_REFRESH_TOKEN");

        // حساب حُذف أو أُوقف لا يجدّد جلسته — كما لا يدخل من جديد.
        EnsureLoginAllowed(stored.User);

        // التدوير بمهلة: بدل إبطال القديم فوراً تُقصَّر صلاحيته إلى دقيقة. عميلٌ
        // فقد الزوج الجديد (أُغلق التطبيق قبل الحفظ، أو طلبا تحديث متسابقان على
        // التوكن نفسه) يعيد المحاولة به خلالها فيأخذ زوجاً صالحاً بدل أن تسقط
        // جلسته. الإبطال الصريح (IsRevoked) يبقى نهائياً بلا مهلة.
        var graceEnd = DateTime.UtcNow.Add(RefreshRotationGrace);
        if (stored.ExpiresAt > graceEnd) stored.ExpiresAt = graceEnd;
        stored.UpdatedAt = DateTime.UtcNow;

        var authResponse = await BuildAuthResponseAsync(stored.User, persistRefresh: true);
        await _db.SaveChangesAsync();

        return authResponse;
    }

    // ── Forgot Password ───────────────────────────────────────────────────────

    /// <summary>
    /// استعادة كلمة سر حساب أدمن/موظف. حسابات التطبيق بلا كلمة سر، فلا معنى
    /// لاستعادتها لها — تدخل برمز واتساب مباشرة.
    /// </summary>
    public async Task ForgotPasswordAsync(string phone)
    {
        var local = PhoneNumber.TryNormalize(phone)
            ?? throw new AuthException(
                "Invalid phone number", "رقم الجوال غير صحيح", "INVALID_PHONE");

        var type = await _db.Users
            .Where(u => u.PhoneNumber == local)
            .Select(u => (UserType?)u.UserType)
            .FirstOrDefaultAsync();

        if (type is not null && type is not (UserType.Admin or UserType.Staff))
            throw new AuthException(
                "Sign in with the code sent to your WhatsApp",
                "سجّل الدخول برمز التحقق المُرسل على واتساب",
                "OTP_LOGIN_REQUIRED");

        await _otp.RequestAsync(local, OtpPurpose.ResetPassword);
    }

    // ── Verify OTP ────────────────────────────────────────────────────────────

    /// <summary>
    /// يتحقق من رمز استعادة كلمة السر ويُرجِع تذكرة تُقدَّم لخطوة تعيين الكلمة
    /// الجديدة. الرمز نفسه لا يُعاد استعماله في تلك الخطوة.
    /// </summary>
    public Task<string> VerifyOtpAsync(string phone, string otp) =>
        _otp.VerifyAsync(phone, otp, OtpPurpose.ResetPassword);

    // ── Reset Password ────────────────────────────────────────────────────────

    public async Task ResetPasswordAsync(
        string phone, string verificationToken, string newPassword)
    {
        var local = PhoneNumber.TryNormalize(phone)
            ?? throw new AuthException(
                "Invalid phone number", "رقم الجوال غير صحيح", "INVALID_PHONE");

        await _otp.ConsumeTokenAsync(local, verificationToken, OtpPurpose.ResetPassword);

        var user = await _db.Users.FirstOrDefaultAsync(u => u.PhoneNumber == local)
            ?? throw new AuthException(
                "User not found",
                "المستخدم غير موجود",
                "USER_NOT_FOUND");

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
        user.UpdatedAt = DateTime.UtcNow;

        // Revoke all refresh tokens (force re-login)
        var tokens = _db.Set<RefreshToken>().Where(rt => rt.UserId == user.Id);
        await tokens.ForEachAsync(rt => rt.IsRevoked = true);

        await _db.SaveChangesAsync();
    }

    // ── Update Language ───────────────────────────────────────────────────────

    public async Task UpdateLanguageAsync(int userId, string language)
    {
        var user = await _db.Users.FindAsync(userId)
            ?? throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        user.PreferredLanguage = language == "en" ? Language.English : Language.Arabic;
        user.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private async Task<AuthResponseDto> BuildAuthResponseAsync(
        User user,
        bool persistRefresh)
    {
        var accessToken = _tokenService.GenerateAccessToken(user);
        var refreshTokenValue = _tokenService.GenerateRefreshToken();

        if (persistRefresh)
        {
            var refreshDays = int.Parse(
                _config["Jwt:RefreshTokenDurationInDays"] ?? "30");

            var refreshToken = new RefreshToken
            {
                UserId = user.Id,
                Token = refreshTokenValue,
                ExpiresAt = DateTime.UtcNow.AddDays(refreshDays),
            };
            _db.Set<RefreshToken>().Add(refreshToken);
            await _db.SaveChangesAsync();
        }

        return new AuthResponseDto
        {
            AccessToken = accessToken,
            RefreshToken = refreshTokenValue,
            User = await BuildUserProfileAsync(user),
        };
    }

    /// <summary>Maps a user to a profile DTO enriched with player level info.</summary>
    private async Task<UserProfileDto> BuildUserProfileAsync(User user)
    {
        var profile = MapToProfile(user);

        var playerInfo = await _db.PlayerProfiles
            .Where(p => p.UserId == user.Id)
            .Select(p => new
            {
                p.Level,
                Assessed = p.LevelAssessments.Any(a => a.IsCompleted),
            })
            .FirstOrDefaultAsync();
        if (playerInfo != null)
        {
            profile.Level = (int)playerInfo.Level;
            profile.LevelAssessed = playerInfo.Assessed;
        }

        return profile;
    }

    // ── Update profile / password ───────────────────────────────────────────────

    public async Task<UserProfileDto> UpdateProfileAsync(int userId, UpdateProfileRequest req)
    {
        var user = await _db.Users
            .Include(u => u.Roles)
            .FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        user.FirstName = req.FirstName.Trim();
        user.LastName = req.LastName.Trim();
        if (req.Gender != null) user.Gender = ParseGender(req.Gender);
        if (req.City != null) user.City = req.City.Trim();
        if (req.District != null) user.District = req.District.Trim();
        await ApplyCityDistrictAsync(user, req.CityId, req.DistrictId);
        user.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return await BuildUserProfileAsync(user);
    }

    /// <summary>
    /// Sets the user's CityId/DistrictId from the chosen list values and keeps
    /// the free-text City/District names in sync with the canonical records. A
    /// district that doesn't belong to the chosen city is ignored.
    /// </summary>
    private async Task ApplyCityDistrictAsync(User user, int? cityId, int? districtId)
    {
        if (cityId is int cid)
        {
            var city = await _db.Cities.FirstOrDefaultAsync(c => c.Id == cid);
            if (city != null)
            {
                user.CityId = city.Id;
                user.City = city.NameAr;
            }
        }

        if (districtId is int did)
        {
            var district = await _db.Districts.FirstOrDefaultAsync(d => d.Id == did);
            if (district != null && (user.CityId == null || district.CityId == user.CityId))
            {
                user.DistrictId = district.Id;
                user.District = district.NameAr;
            }
        }
    }

    /// <summary>يتحقق أن معرف اللعبة المرسل مع بيانات المدرب موجود وفعّال.</summary>
    private async Task ValidateCoachSportAsync(int? sportId)
    {
        if (sportId is not int sid) return;
        if (!await _db.Sports.AnyAsync(s => s.Id == sid && s.IsActive))
            throw new AuthException(
                "Invalid sport", "اللعبة المختارة غير موجودة", "INVALID_SPORT");
    }

    private static readonly HashSet<string> ValidDayKeys =
        ["sat", "sun", "mon", "tue", "wed", "thu", "fri"];

    private static CoachExperienceLevel ParseExperienceLevel(string value) => value switch
    {
        "lessThanYear" => CoachExperienceLevel.LessThanYear,
        "oneToThree" => CoachExperienceLevel.OneToThree,
        "threeToFive" => CoachExperienceLevel.ThreeToFive,
        "moreThanFive" => CoachExperienceLevel.MoreThanFive,
        _ => throw new AuthException(
            "Invalid experience level", "سنوات الخبرة غير صحيحة", "INVALID_EXPERIENCE_LEVEL"),
    };

    private static CoachResidency ParseResidency(string value) => value switch
    {
        "saudi" => CoachResidency.Saudi,
        "resident" => CoachResidency.Resident,
        _ => throw new AuthException(
            "Invalid residency", "الجنسية غير صحيحة", "INVALID_RESIDENCY"),
    };

    /// <summary>Validates the coach registration payload (sport, experience,
    /// specializations, target gender, available days, residency, documents,
    /// preferred venue) and builds the profile ready to attach a UserId to.</summary>
    private async Task<CoachProfile> BuildCoachProfileAsync(CoachRegistrationDto req)
    {
        await ValidateCoachSportAsync(req.SportId);

        var experience = ParseExperienceLevel(req.ExperienceLevel);
        var residency = ParseResidency(req.Residency);
        var targetGender = ParseGender(req.TargetGender)
            ?? throw new AuthException(
                "Invalid target gender", "الفئة المستهدفة غير صحيحة", "INVALID_TARGET_GENDER");

        var days = req.AvailableDays.Select(d => d.Trim().ToLowerInvariant()).Distinct().ToList();
        if (days.Count == 0 || days.Any(d => !ValidDayKeys.Contains(d)))
            throw new AuthException(
                "Invalid available days", "الأيام المتاحة للتدريب غير صحيحة", "INVALID_AVAILABLE_DAYS");

        if (string.IsNullOrWhiteSpace(req.NationalIdFrontUrl) ||
            string.IsNullOrWhiteSpace(req.NationalIdBackUrl))
            throw new AuthException(
                "ID documents are required",
                "صور الهوية (الوجه الأمامي والخلفي) مطلوبة", "COACH_ID_DOCS_REQUIRED");

        var specializationIds = req.SpecializationIds.Distinct().ToList();
        var validSpecializationCount = await _db.CoachSpecializations
            .CountAsync(s => specializationIds.Contains(s.Id) && s.IsActive);
        if (specializationIds.Count == 0 || validSpecializationCount != specializationIds.Count)
            throw new AuthException(
                "Invalid specializations", "التخصصات المختارة غير صحيحة", "INVALID_SPECIALIZATIONS");

        if (req.PreferredVenueId is int venueId &&
            !await _db.Venues.NotDeleted().AnyAsync(v => v.Id == venueId))
            throw new AuthException(
                "Venue not found", "الملعب المختار غير موجود", "VENUE_NOT_FOUND");

        return new CoachProfile
        {
            Bio = req.Bio,
            NameEn = string.IsNullOrWhiteSpace(req.NameEn) ? null : req.NameEn.Trim(),
            Specialization = req.Specialization,
            SportId = req.SportId,
            HourlyRate = req.HourlyRate,
            PackagePrice = req.PackagePrice,
            Certifications = string.IsNullOrWhiteSpace(req.Certifications)
                ? null : req.Certifications.Trim(),
            ExperienceLevel = experience,
            TargetGender = targetGender,
            PreferredVenueId = req.PreferredVenueId,
            AvailableDays = string.Join(',', days),
            Residency = residency,
            NationalIdFrontUrl = req.NationalIdFrontUrl.Trim(),
            NationalIdBackUrl = req.NationalIdBackUrl.Trim(),
            Specializations = specializationIds
                .Select(id => new CoachProfileSpecialization { SpecializationId = id })
                .ToList(),
        };
    }

    /// <summary>ينقل حقول ملفٍ مبنيٍّ من الطلب إلى ملف المدرب الباقي.</summary>
    private static void ApplyCoachProfile(CoachProfile target, CoachProfile source)
    {
        target.Bio = source.Bio;
        target.NameEn = source.NameEn;
        target.Specialization = source.Specialization;
        target.SportId = source.SportId;
        target.HourlyRate = source.HourlyRate;
        target.PackagePrice = source.PackagePrice;
        target.Certifications = source.Certifications;
        target.ExperienceLevel = source.ExperienceLevel;
        target.TargetGender = source.TargetGender;
        target.PreferredVenueId = source.PreferredVenueId;
        target.AvailableDays = source.AvailableDays;
        target.Residency = source.Residency;
        target.NationalIdFrontUrl = source.NationalIdFrontUrl;
        target.NationalIdBackUrl = source.NationalIdBackUrl;
        target.UpdatedAt = DateTime.UtcNow;

        target.Specializations.Clear();
        foreach (var spec in source.Specializations)
            target.Specializations.Add(
                new CoachProfileSpecialization { SpecializationId = spec.SpecializationId });
    }

    /// <summary>
    /// يعيد ما أُغلق مع إسقاط دور صاحب الملعب: الأندية وملاعبها التي تحمل ختم
    /// اللحظة نفسها التي حُذف فيها الدور. ما حذفته الإدارة أو حُذف في وقت آخر
    /// يبقى محذوفاً — ختمه الزمني مختلف، وهو ما يفصل الحالتين بلا حقل إضافي.
    /// </summary>
    private async Task RestoreOwnerVenuesAsync(int ownerId, DateTime closedAt)
    {
        var venues = await _db.Venues
            .Where(v => v.OwnerId == ownerId && v.IsDeleted && v.DeletedAt == closedAt)
            .ToListAsync();
        if (venues.Count == 0) return;

        var now = DateTime.UtcNow;
        var venueIds = venues.Select(v => v.Id).ToList();

        foreach (var v in venues)
        {
            v.IsDeleted = false;
            v.DeletedAt = null;
            v.IsActive = true;
            // الاعتماد لم يُلغَ عند الإغلاق فلا يُعاد منحه هنا — يبقى كما كان.
            v.UpdatedAt = now;
        }

        var courts = await _db.Courts
            .Where(c => venueIds.Contains(c.VenueId) &&
                        c.IsDeleted && c.DeletedAt == closedAt)
            .ToListAsync();
        foreach (var c in courts)
        {
            c.IsDeleted = false;
            c.DeletedAt = null;
            c.IsSuspended = false;
            c.UpdatedAt = now;
        }
    }

    // ── حذف دور ───────────────────────────────────────────────────────────────

    public async Task<AuthResponseDto> DeleteRoleAsync(int userId, string role)
    {
        var user = await _db.Users
            .Include(u => u.Roles)
            .Include(u => u.CoachProfile)
            .FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        var type = ParseUserType(role)
            ?? throw new AuthException("Invalid role", "الدور غير صحيح", "INVALID_ROLE");

        if (type is UserType.Admin or UserType.Staff)
            throw new AuthException(
                "Staff roles are managed from the dashboard",
                "أدوار الإدارة تُدار من لوحة التحكم", "STAFF_ROLE");

        var row = user.Roles.FirstOrDefault(r => r.Role == type)
            ?? throw new AuthException(
                "Role not found", "هذا الدور غير موجود على حسابك", "ROLE_NOT_FOUND");

        // آخر دور لا يُحذف: حسابٌ بلا دور لا يدخل التطبيق ولا يخرج منه — من
        // أراد ذلك فأمامه حذف الحساب، وله مساره ورمز تحقّقه.
        if (user.Roles.Count <= 1)
            throw new AuthException(
                "You cannot remove your only role, delete the account instead",
                "لا يمكن حذف دورك الوحيد — احذف الحساب بدلاً من ذلك", "LAST_ROLE");

        // ختم زمني (UTC) للسجلات فقط؛ مقارنة المواعيد داخل دوال الإلغاء بـ AppClock.
        var now = DateTime.UtcNow;

        switch (type)
        {
            case UserType.Player:
                await CancelPlayerCommitmentsAsync(
                    userId, now, "حذف صاحب الحجز دور اللاعب", cancelHostedEvents: false);
                break;

            case UserType.Coach when user.CoachProfile is CoachProfile coach:
                // العروض تبقى: الحذف ناعم وملف المدرب محفوظ، فعودةُ الدور تعيدها
                // كما كانت بدل أن يعيد بناءها من الصفر.
                await CancelCoachCommitmentsAsync(
                    coach, now,
                    "أغلق المدرب حسابه كمدرب، فأُلغيت الجلسة المحجوزة معه.",
                    removeOffers: false);
                break;

            case UserType.VenueOwner:
                await CloseOwnerVenuesAsync(
                    userId, now,
                    "أغلق الملعب حسابه",
                    "أُغلق الملعب، وأُعيد المبلغ المدفوع إلى محفظتك.");
                break;
        }

        row.IsDeleted = true;
        row.DeletedAt = now;
        row.UpdatedAt = now;
        user.UpdatedAt = now;
        await _db.SaveChangesAsync();

        // التوكن يحمل الأدوار مطالباتٍ، فيُصدَر جديدٌ فوراً: بلا هذا يبقى الدور
        // المحذوف فاتحاً لمساراته حتى انتهاء صلاحية القديم.
        _db.ChangeTracker.Clear();
        var fresh = await _db.Users
            .Include(u => u.Roles)
            .FirstAsync(u => u.Id == userId);

        return await BuildAuthResponseAsync(fresh, persistRefresh: true);
    }

    public async Task<UserProfileDto> UpdateLocationAsync(
        int userId, double latitude, double longitude)
    {
        var user = await _db.Users
            .Include(u => u.Roles)
            .FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        user.Latitude = latitude;
        user.Longitude = longitude;
        user.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return await BuildUserProfileAsync(user);
    }

    public async Task<UserProfileDto> AddRoleAsync(int userId, AddRoleRequest req)
    {
        var user = await _db.Users
            .Include(u => u.Roles)
            .FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        var role = ParseUserType(req.Role)
            ?? throw new AuthException("Invalid role", "الدور غير صحيح", "INVALID_ROLE");

        if (user.Roles.Any(r => r.Role == role))
            throw new AuthException(
                "Role already added", "هذا الدور مُضاف بالفعل", "ROLE_EXISTS");

        // دورٌ حُذف ناعماً سابقاً: صفّه ما زال موجوداً (وقيد التفرّد يمنع صفّاً
        // ثانياً)، فيُحيا هو بدل إضافة جديد — انظر UserRole.IsDeleted.
        var revived = await _db.Set<UserRole>()
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(r => r.UserId == user.Id && r.Role == role);

        // لحظة إسقاط الدور تُلتقط قبل تصفيرها أدناه: بها تُعرف الأندية التي
        // أُغلقت مع الدور فتُستعاد معه.
        var closedAt = revived is { IsDeleted: true } ? revived.DeletedAt : null;

        // الحساب البنكي مطلوب لكل من يستلم مستحقات. يُقبل الموجود مسبقاً على
        // الحساب، ويُستبدل إن أُرسلت بيانات جديدة مع الطلب.
        if (role is UserType.Coach or UserType.VenueOwner)
        {
            var bank = role == UserType.VenueOwner
                ? (req.Venue?.Iban, req.Venue?.BankName, req.Venue?.AccountHolderName)
                : (req.Coach?.Iban, req.Coach?.BankName, req.Coach?.AccountHolderName);

            if (!string.IsNullOrWhiteSpace(bank.Item1) || string.IsNullOrWhiteSpace(user.Iban))
            {
                ValidateBankAccount(bank.Item1, bank.Item2, bank.Item3);
                user.Iban = Helpers.Iban.Normalize(bank.Item1);
                user.BankName = bank.Item2!.Trim();
                user.AccountHolderName = bank.Item3!.Trim();
            }
        }

        // Validate + create the role-specific profile.
        if (role == UserType.Coach)
        {
            if (string.IsNullOrWhiteSpace(req.Coach?.Specialization))
                throw new AuthException(
                    "Coach details required", "بيانات المدرب مطلوبة", "COACH_DETAILS_REQUIRED");
            var coachProfile = await BuildCoachProfileAsync(req.Coach);

            // ملفٌّ باقٍ من دور مدرّبٍ حُذف ناعماً: يُحدَّث بالبيانات الجديدة بدل
            // إنشاء ملف ثانٍ لنفس المستخدم (والعلاقة واحد-لواحد أصلاً).
            var existingCoach = await _db.CoachProfiles
                .Include(c => c.Specializations)
                .FirstOrDefaultAsync(c => c.UserId == user.Id);
            if (existingCoach != null)
                ApplyCoachProfile(existingCoach, coachProfile);
            else
            {
                coachProfile.UserId = user.Id;
                _db.CoachProfiles.Add(coachProfile);
            }
        }
        else if (role == UserType.VenueOwner)
        {
            ValidateVenueDetails(req.Venue);
            ApplyOwnerDocuments(user, req.Venue!);
        }
        else if (role == UserType.Player)
        {
            if (!await _db.PlayerProfiles.AnyAsync(p => p.UserId == user.Id))
                _db.PlayerProfiles.Add(new PlayerProfile { UserId = user.Id });
        }

        if (role == UserType.VenueOwner && closedAt is DateTime at)
            await RestoreOwnerVenuesAsync(user.Id, at);

        if (revived != null)
        {
            revived.IsDeleted = false;
            revived.DeletedAt = null;
            // العودة تمرّ بالمراجعة من جديد كأي دور مدرب/ملعب.
            revived.IsApproved = !UserRole.NeedsApproval(role);
            revived.ApprovedAt = UserRole.NeedsApproval(role) ? null : DateTime.UtcNow;
            revived.UpdatedAt = DateTime.UtcNow;
        }
        else
        {
            _db.Set<UserRole>().Add(new UserRole
            {
                UserId = user.Id,
                Role = role,
                IsApproved = !UserRole.NeedsApproval(role),
                ApprovedAt = UserRole.NeedsApproval(role) ? null : DateTime.UtcNow,
            });
        }
        user.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        var fresh = await _db.Users
            .Include(u => u.Roles)
            .FirstAsync(u => u.Id == userId);
        return await BuildUserProfileAsync(fresh);
    }

    public async Task<UserProfileDto> UpdateAvatarAsync(int userId, string relativeUrl)
    {
        var user = await _db.Users
            .Include(u => u.Roles)
            .FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        user.ProfileImageUrl = relativeUrl;
        user.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return await BuildUserProfileAsync(user);
    }

    public async Task ChangePasswordAsync(int userId, string currentPassword, string newPassword)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        if (!BCrypt.Net.BCrypt.Verify(currentPassword, user.PasswordHash))
            throw new AuthException(
                "Current password is incorrect",
                "كلمة المرور الحالية غير صحيحة", "INVALID_PASSWORD");

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
        user.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
    }

    // ── Delete account (App Store 5.1.1(v)) ───────────────────────────────────

    /// <summary>
    /// يحذف الحساب نهائياً بطلب صاحبه: يُلغي التزاماته القادمة، يمسح كل بياناته
    /// الشخصية ووثائقه المرفوعة، ويُبطِّل الدخول. لا يُحذف صف المستخدم نفسه —
    /// يبقى مُبهَّم الهوية حتى تظل السجلات المالية (حجوزات، حركات محفظة،
    /// نتائج مباريات لاعبين آخرين) متماسكة، وهذا ما تنص عليه سياسة الخصوصية.
    /// </summary>
    public async Task DeleteAccountAsync(int userId, string verificationToken, string? reason)
    {
        var user = await LoadDeletableUserAsync(userId);

        // خطوة تأكيد واحدة يشترطها المتجر. كانت كلمة المرور، وصارت رمز واتساب
        // بعد أن زالت كلمات السر من حسابات التطبيق — والتأكيد أقوى: الرمز يصل
        // إلى جهاز صاحب الحساب لحظتَها، لا إلى ما قد يكون محفوظاً في متصفّح.
        await _otp.ConsumeTokenAsync(
            user.PhoneNumber, verificationToken, OtpPurpose.DeleteAccount);

        await PerformDeletionAsync(user, reason);
    }

    /// <summary>
    /// حذف يبدأه الأدمن من لوحة التحكم — نفس مسار حذف المستخدم لحسابه تماماً،
    /// بلا كلمة مرور (المصادقة تمّت على حساب الأدمن، والصلاحية تُفرض في الـ
    /// controller). يُستخدم لحذف اللاعبين والمدربين من اللوحة.
    /// </summary>
    public async Task AdminDeleteAccountAsync(int userId, string? reason)
    {
        var user = await LoadDeletableUserAsync(userId);

        // الأدمن والموظف لا يُحذفان من هنا — لهما شاشة الموظفين وصلاحيتها.
        if (user.UserType is UserType.Admin or UserType.Staff)
            throw new AuthException(
                "Staff accounts are deleted from the staff screen",
                "حسابات الإدارة تُحذف من شاشة الموظفين",
                "STAFF_ACCOUNT");

        await PerformDeletionAsync(user, reason ?? "حذف إداري من لوحة التحكم");
    }

    private async Task<User> LoadDeletableUserAsync(int userId)
    {
        var user = await _db.Users
            .Include(u => u.Roles)
            .Include(u => u.CoachProfile)
            .FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        if (user.IsDeleted)
            throw new AuthException(
                "Account already deleted", "الحساب محذوف بالفعل", "ACCOUNT_DELETED");

        return user;
    }

    private async Task PerformDeletionAsync(User user, string? reason)
    {
        // ختم زمني (UTC) للسجلات فقط؛ مقارنة المواعيد داخل دوال الإلغاء بـ AppClock.
        var now = DateTime.UtcNow;

        await CancelUpcomingCommitmentsAsync(user, now);

        // الملفات المرفوعة تُمسح من القرص قبل تصفير روابطها في قاعدة البيانات.
        DeleteUploadedFiles(
            user.ProfileImageUrl,
            user.IdImageUrl,
            user.CommercialRegistrationImageUrl,
            user.TaxCertificateImageUrl,
            user.CoachProfile?.IdDocumentUrl,
            user.CoachProfile?.NationalIdFrontUrl,
            user.CoachProfile?.NationalIdBackUrl);

        await DeletePersonalRecordsAsync(user);
        AnonymizeUser(user, now, reason);

        await _db.SaveChangesAsync();
    }

    /// <summary>
    /// يُنهي كل ما يرتبط بالمستخدم من مواعيد قادمة قبل إخفاء هويته: حجوزاته،
    /// جلساته لاعباً ومدرباً، مبارياته، وملاعبه (مع استرداد أموال من حجزوا فيها).
    /// </summary>
    /// <summary>
    /// يُنهي كل ما يرتبط بالمستخدم من مواعيد قادمة قبل إخفاء هويته: حجوزاته،
    /// جلساته لاعباً ومدرباً، مبارياته، وملاعبه (مع استرداد أموال من حجزوا فيها).
    /// </summary>
    private async Task CancelUpcomingCommitmentsAsync(User user, DateTime now)
    {
        var userId = user.Id;

        await CancelPlayerCommitmentsAsync(
            userId, now, "حذف صاحب الحجز حسابه", cancelHostedEvents: true);

        if (user.CoachProfile is CoachProfile coach)
            await CancelCoachCommitmentsAsync(
                coach, now,
                "أغلق المدرب حسابه، فأُلغيت الجلسة المحجوزة معه.",
                removeOffers: true);

        // طلبات السحب: المعلّق منها يُغلق (الرصيد يسقط بالحذف كما تنص السياسة)،
        // ونُمسح نسخة الآيبان المحفوظة في كل طلب فهي بيانات شخصية.
        var withdrawals = await _db.WithdrawalRequests
            .Where(w => w.UserId == userId)
            .ToListAsync();
        foreach (var w in withdrawals)
        {
            if (w.Status == WithdrawalStatus.Pending)
            {
                w.Status = WithdrawalStatus.Rejected;
                w.AdminNotes = "أُغلق الطلب لحذف صاحب الحساب";
                w.ProcessedAt = now;
            }
            w.Iban = string.Empty;
            w.BankName = string.Empty;
            w.AccountHolderName = string.Empty;
            w.UpdatedAt = now;
        }

        await CloseOwnerVenuesAsync(
            userId, now,
            "أغلق الملعب حسابه",
            "أغلق الملعب حسابه، وأُعيد المبلغ المدفوع إلى محفظتك.");
    }

    /// <summary>
    /// ما يخصّ المستخدم لاعباً: حجوزاته القادمة، وجلساته التدريبية، ومبارياته
    /// (يخرج من القادمة، وما أنشأه منها يُلغى). السابق سجلٌّ يبقى. كل ما دُفع
    /// يُردّ إلى محفظة صاحبه، ويُستردّ من المالك/المدرب/المنشئ ما وصله منه.
    /// <paramref name="now"/> ختم زمني (UTC) للسجلات فقط؛ المقارنة بالمواعيد
    /// (بتوقيت السعودية بلا منطقة) تجري بـ AppClock.
    /// <paramref name="cancelHostedEvents"/>: أحداث أنشأها ولا يلعب فيها (يستضيفها
    /// من حساب الملعب) تُلغى عند حذف الحساب، وتبقى عند إسقاط دور اللاعب وحده.
    /// </summary>
    private async Task CancelPlayerCommitmentsAsync(
        int userId, DateTime now, string bookingReasonAr, bool cancelHostedEvents)
    {
        var wallNow = AppClock.Now;

        var myBookings = await _db.Bookings
            .Include(b => b.Court).ThenInclude(c => c.Venue)
            .Where(b => b.UserId == userId && b.StartTime > wallNow &&
                        (b.Status == BookingStatus.Pending ||
                         b.Status == BookingStatus.Confirmed))
            .ToListAsync();
        var confirmedIds = myBookings
            .Where(b => b.Status == BookingStatus.Confirmed)
            .Select(b => b.Id).ToHashSet();
        foreach (var b in myBookings)
        {
            b.Status = BookingStatus.Cancelled;
            b.CancelledAt = now;
            b.CancellationReason = bookingReasonAr;
            b.UpdatedAt = now;
        }

        // الحفظ قبل الاسترداد: خدمة المحفظة تكتب حركاتها على نفس السياق.
        await _db.SaveChangesAsync();
        foreach (var b in myBookings)
            await BookingRefunds.RefundAsync(
                _wallet, b, confirmedIds.Contains(b.Id), b.Court.Venue.OwnerId,
                $"استرداد حجز ملغى — {bookingReasonAr}");

        var mySessions = await _db.CoachSessions
            .Include(s => s.CoachProfile)
            .Where(s => s.PlayerId == userId && s.ScheduledAt > wallNow &&
                        s.Status != CoachSessionStatus.Rejected)
            .ToListAsync();
        foreach (var s in mySessions)
        {
            s.Status = CoachSessionStatus.Rejected;
            s.UpdatedAt = now;
            await RefundCoachSessionAsync(s, $"استرداد جلسة تدريب ملغاة — {bookingReasonAr}");
            await NotifySilentlyAsync(
                s.CoachProfile.UserId,
                "أُلغيت جلسة تدريبية",
                "أُلغيت جلسة محجوزة معك لخروج اللاعب، وأُعيد إليه ما دفعه.",
                // يصل المدرب لا اللاعب: نوع مستقل يفتح حجوزات المدرب في التطبيق.
                "coach_session_player_cancelled", s.Id);
        }

        var matches = await _db.Matches
            .Include(m => m.MatchPlayers)
            .Include(m => m.Court).ThenInclude(c => c!.Venue)
            .Include(m => m.AmericanoMatch)
            .Where(m => m.ScheduledAt > wallNow &&
                        m.Status != MatchStatus.Completed &&
                        m.Status != MatchStatus.Cancelled &&
                        (m.CreatorId == userId ||
                         m.MatchPlayers.Any(p => p.UserId == userId)))
            .ToListAsync();

        var freedSeats = new List<int>();
        foreach (var m in matches)
        {
            var mine = m.MatchPlayers.FirstOrDefault(p => p.UserId == userId);

            if (m.CreatorId == userId && (mine != null || cancelHostedEvents))
            {
                // قفل الحدث: انضمام تزامن مع الإلغاء إمّا يسبقه (فيُحمَّل هنا
                // وتُردّ حصته) أو يليه (فيرى الحدث ملغى ويُرفض).
                await using var gate = await MatchLock.AcquireAsync(_db, m.Id);
                var players = _db.Entry(m).Collection(x => x.MatchPlayers);
                players.IsLoaded = false;
                await players.LoadAsync();

                // ما أنشأه يُلغى، ويُردّ لكل مشارك ما دفعه — منطق إلغاء المباراة نفسه.
                var others = m.MatchPlayers
                    .Where(p => p.UserId != userId && p.Status != MatchPlayerStatus.Invited)
                    .Select(p => p.UserId).Distinct().ToList();
                await _matches.RefundAllPaidAsync(m, "استرداد حصة — أُلغي الحدث لخروج منظّمه");
                m.Status = MatchStatus.Cancelled;
                m.UpdatedAt = now;
                // يُحفظ تحت القفل حتى يرى الانضمام التالي الحدثَ ملغى.
                await _db.SaveChangesAsync();
                await gate.ReleaseAsync();

                var (label, type, refId) = m.AmericanoMatch is { } a
                    ? (a.IsTournament || a.Format != null
                        ? ("البطولة", "tournament_cancelled", a.Id)
                        : ("الأمريكانو", "americano_cancelled", a.Id))
                    : ("المباراة", "match_cancelled", m.Id);
                foreach (var other in others)
                    await NotifySilentlyAsync(
                        other, $"أُلغيت {label}",
                        $"انسحب المنظّم فأُلغيت {label}، وأُعيد ما دفعته إلى محفظتك.",
                        type, refId);
            }
            else if (mine != null)
            {
                await RefundMatchShareAsync(m, mine, $"استرداد حصة — {bookingReasonAr}");
                if (m.Status == MatchStatus.Full) m.Status = MatchStatus.Open;
                m.UpdatedAt = now;
                freedSeats.Add(m.Id);
            }

            if (mine != null) _db.MatchPlayers.Remove(mine);
        }

        // مقعد تحرّر في حدث قائم: يُعرض على أول المنتظرين كما في الانسحاب.
        if (freedSeats.Count > 0)
        {
            await _db.SaveChangesAsync();
            foreach (var matchId in freedSeats)
                await _waitlist.ProcessAsync(matchId);
        }
    }

    /// <summary>
    /// يردّ حصة لاعب واحد خرج من حدث، ويستردّ ممن وصلته ما وصله منها — كما في
    /// الانسحاب (WithdrawalService.RemoveMemberAsync): الحصة تُصرف لحظة اعتماد
    /// اللاعب، لمالك الملعب صافيةً من نسبة سبورتا أو للمنشئ حين دفع كاملاً، إلا
    /// قبل موافقة الملعب فتبقى محجوزة عندنا.
    /// </summary>
    private async Task RefundMatchShareAsync(Match m, MatchPlayer p, string reason)
    {
        if (!p.HasPaid || m.PricePerPlayer <= 0) return;

        var share = m.ShareOf(p);
        await _wallet.RefundAsync(p.UserId, share, reason, m.Id);

        var credited = p.Status == MatchPlayerStatus.Approved &&
                       m.CourtId != null && m.Status != MatchStatus.PendingApproval;
        // عكس أرباح لا خصم مشروط بالرصيد: ما وصل المستلم يُستردّ دائماً ولو
        // صار رصيده سالباً، وإلا دفعت سبورتا الفرق من حصتها.
        if (credited)
        {
            if (m.PaymentMode == MatchPaymentMode.FullByCreator)
                await _wallet.ReverseEarningAsync(
                    m.CreatorId, share, WalletTransactionType.CreatorEarning, reason, m.Id);
            else if (m.Court != null)
                await _wallet.ReverseEarningAsync(
                    m.Court.Venue.OwnerId, m.NetOfCommission(share),
                    WalletTransactionType.VenueEarning, reason, m.Id);
        }

        p.HasPaid = false;
    }

    /// <summary>
    /// جلسة مدفوعة أُلغيت: يُردّ للاعب ما دفعه (سعر المدرب + نسبة سبورتا) ويُعكس
    /// عن المدرب صافي ما قُيِّد له عند الاعتماد (CoachService.RespondToSessionAsync).
    /// الجلسة المعلّقة لم يُدفع عنها شيء فلا ردّ لها.
    /// </summary>
    private async Task RefundCoachSessionAsync(CoachSession s, string playerDescription)
    {
        if (!s.IsPaid) return;

        await _wallet.RefundAsync(s.PlayerId, s.PlayerTotal(), playerDescription, s.Id);
        await _wallet.ReverseEarningAsync(
            s.CoachProfile.UserId, s.CoachNetAmount(), WalletTransactionType.CoachEarning,
            $"عكس أرباح جلسة ملغاة #{s.Id}", s.Id);
        s.IsPaid = false;
    }

    /// <summary>
    /// جلساته مدرباً: تُرفض ويُخطَر لاعبوها، ويُردّ لهم ما دفعوه.
    /// <paramref name="removeOffers"/> يمسح عروضه — يُستعمل عند حذف الحساب
    /// كاملاً؛ أما إسقاط دور المدرب وحده فيُبقيها كما هي لأن الحذف ناعم والدور
    /// قد يعود.
    /// </summary>
    private async Task CancelCoachCommitmentsAsync(
        CoachProfile coach, DateTime now, string notifyBodyAr, bool removeOffers)
    {
        // ScheduledAt بتوقيت السعودية بلا منطقة: المقارنة بـ AppClock لا بـ now (UTC).
        var wallNow = AppClock.Now;
        var coachSessions = await _db.CoachSessions
            .Where(s => s.CoachProfileId == coach.Id && s.ScheduledAt > wallNow &&
                        s.Status != CoachSessionStatus.Rejected)
            .ToListAsync();
        foreach (var s in coachSessions)
        {
            s.Status = CoachSessionStatus.Rejected;
            s.UpdatedAt = now;
            s.CoachProfile = coach;
            await RefundCoachSessionAsync(s, "استرداد جلسة تدريب ألغاها إغلاق حساب المدرب");
            await NotifySilentlyAsync(
                s.PlayerId,
                "أُلغيت جلستك التدريبية",
                notifyBodyAr,
                "coach_session_cancelled", s.Id);
        }

        if (removeOffers)
        {
            var offers = await _db.CoachOffers
                .Where(o => o.CoachProfileId == coach.Id)
                .ToListAsync();
            _db.CoachOffers.RemoveRange(offers);
        }
    }

    /// <summary>
    /// أنديته وملاعبه: تُخفى من البحث، وتُلغى حجوزات الآخرين القادمة فيها مع ردّ
    /// ما دفعوه إلى محافظهم — لا يجوز أن يخسر لاعبٌ مالَه لقرارٍ من المالك.
    /// </summary>
    private async Task CloseOwnerVenuesAsync(
        int userId, DateTime now, string bookingReasonAr, string notifyBodyAr)
    {
        // المحذوف سلفاً (بيد الإدارة أو بيد المالك في وقت آخر) لا يُلمس: ختمه
        // الزمني هو ما يميّزه، وتغييره هنا يجعل الاستعادة تبعثه بلا وجه حق.
        var venues = await _db.Venues
            .Where(v => v.OwnerId == userId && !v.IsDeleted)
            .ToListAsync();
        if (venues.Count == 0) return;

        var venueIds = venues.Select(v => v.Id).ToList();

        foreach (var v in venues)
        {
            v.IsActive = false;
            v.IsDeleted = true;
            v.DeletedAt = now;
            v.UpdatedAt = now;
        }

        // الملاعب تتبع ناديها — لا يبقى ملعب معروضاً لنادٍ أُغلق.
        var ownedCourts = await _db.Courts
            .Where(c => venueIds.Contains(c.VenueId) && !c.IsDeleted)
            .ToListAsync();
        foreach (var c in ownedCourts)
        {
            c.IsSuspended = true;
            c.IsDeleted = true;
            c.DeletedAt = now;
            c.UpdatedAt = now;
        }

        // StartTime بتوقيت السعودية بلا منطقة: المقارنة بـ AppClock لا بـ now (UTC).
        var affected = await _db.Bookings
            .Include(b => b.Court)
            .Where(b => venueIds.Contains(b.Court.VenueId) && b.StartTime > AppClock.Now &&
                        (b.Status == BookingStatus.Pending ||
                         b.Status == BookingStatus.Confirmed))
            .ToListAsync();

        var confirmedIds = affected
            .Where(b => b.Status == BookingStatus.Confirmed)
            .Select(b => b.Id).ToHashSet();
        foreach (var b in affected)
        {
            b.Status = BookingStatus.Cancelled;
            b.CancelledAt = now;
            b.CancellationReason = bookingReasonAr;
            b.UpdatedAt = now;
        }

        // الحفظ قبل الاسترداد: خدمة المحفظة تكتب حركاتها على نفس السياق.
        await _db.SaveChangesAsync();

        foreach (var b in affected.Where(b => b.UserId != userId))
        {
            // المغلِق هو مالك هذه الملاعب: تُعكس عنه أرباح الحجوزات المؤكدة.
            await BookingRefunds.RefundAsync(
                _wallet, b, confirmedIds.Contains(b.Id), userId,
                "استرداد حجز أُلغي لإغلاق الملعب");

            await NotifySilentlyAsync(
                b.UserId, "أُلغي حجزك", notifyBodyAr, "booking_cancelled", b.Id);
        }
    }
    /// </summary>
    private async Task DeletePersonalRecordsAsync(User user)
    {
        var userId = user.Id;

        _db.RefreshTokens.RemoveRange(
            await _db.RefreshTokens.Where(t => t.UserId == userId).ToListAsync());

        _db.TrustedDevices.RemoveRange(
            await _db.TrustedDevices.Where(d => d.UserId == userId).ToListAsync());

        _db.OtpCodes.RemoveRange(
            await _db.OtpCodes.Where(o => o.PhoneNumber == user.PhoneNumber).ToListAsync());

        _db.Notifications.RemoveRange(
            await _db.Notifications.Where(n => n.UserId == userId).ToListAsync());

        _db.Friendships.RemoveRange(
            await _db.Friendships
                .Where(f => f.SenderId == userId || f.ReceiverId == userId)
                .ToListAsync());

        _db.Follows.RemoveRange(
            await _db.Follows
                .Where(f => f.FollowerId == userId || f.FollowingId == userId)
                .ToListAsync());

        _db.CourtFavorites.RemoveRange(
            await _db.CourtFavorites.Where(f => f.UserId == userId).ToListAsync());

        var conversations = await _db.SupportConversations
            .Where(c => c.UserId == userId)
            .ToListAsync();
        if (conversations.Count > 0)
        {
            var ids = conversations.Select(c => c.Id).ToList();
            _db.SupportMessages.RemoveRange(
                await _db.SupportMessages
                    .Where(m => ids.Contains(m.ConversationId))
                    .ToListAsync());
            _db.SupportConversations.RemoveRange(conversations);
        }
    }

    /// <summary>
    /// يستبدل كل حقل شخصي بقيمة مُبطَّلة. الجوال والبريد يأخذان صيغة فريدة
    /// مشتقة من المعرّف، فيتحرر الرقم الأصلي لتسجيل جديد ولا يتصادم مع أحد.
    /// </summary>
    private void AnonymizeUser(User user, DateTime now, string? reason)
    {
        user.FirstName = "حساب";
        user.LastName = "محذوف";
        user.Email = $"deleted_{user.Id}@deleted.sporta";
        user.PhoneNumber = $"deleted_{user.Id}";
        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString("N"));
        user.ProfileImageUrl = null;
        user.IdImageUrl = null;
        user.CommercialRegistrationImageUrl = null;
        user.TaxCertificateImageUrl = null;
        user.Iban = null;
        user.BankName = null;
        user.AccountHolderName = null;
        user.Latitude = null;
        user.Longitude = null;
        user.Country = null;
        user.City = null;
        user.District = null;
        user.CityId = null;
        user.DistrictId = null;
        user.Gender = null;
        user.FavoriteSport = null;
        user.PointsBalance = 0;
        user.IsActive = false;
        user.IsDeleted = true;
        user.DeletedAt = now;
        user.UpdatedAt = now;

        if (user.CoachProfile is CoachProfile coach)
        {
            coach.Bio = null;
            coach.NameEn = null;
            coach.Certifications = null;
            coach.IdDocumentUrl = null;
            coach.NationalIdFrontUrl = null;
            coach.NationalIdBackUrl = null;
            coach.IsVerifiedOnPlatform = false;
            coach.UpdatedAt = now;
        }

        // السبب الاختياري يُسجَّل في الحركة الأخيرة للمحفظة لا في صف المستخدم،
        // فلا يبقى نص حرّ قد يحمل بيانات شخصية على الحساب المُبهَّم.
        if (!string.IsNullOrWhiteSpace(reason))
            Console.WriteLine(
                $"[account-deleted] user={user.Id} reason={reason.Trim()}");
    }

    /// <summary>حذف أفضل-جهد لملف مرفوع من wwwroot؛ الفشل لا يعطّل حذف الحساب.</summary>
    private void DeleteUploadedFiles(params string?[] relativeUrls)
    {
        var root = _env.WebRootPath
            ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");

        foreach (var url in relativeUrls)
        {
            if (string.IsNullOrWhiteSpace(url) || url.StartsWith("http")) continue;
            try
            {
                var path = Path.Combine(root, url.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
                // لا نخرج خارج wwwroot مهما كان النص المخزَّن.
                var full = Path.GetFullPath(path);
                if (!full.StartsWith(Path.GetFullPath(root), StringComparison.Ordinal)) continue;
                if (File.Exists(full)) File.Delete(full);
            }
            catch
            {
                // ملف مفقود أو مقفل — لا يمنع الحذف.
            }
        }
    }

    /// <summary>إشعار أفضل-جهد: فشله لا يُبطل عملية الحذف.</summary>
    private async Task NotifySilentlyAsync(
        int userId, string title, string body, string type, int? referenceId)
    {
        try
        {
            await _notifications.PushAsync(userId, title, body, type, referenceId);
        }
        catch
        {
            // تجاهل.
        }
    }

    private static UserProfileDto MapToProfile(User user) => new()
    {
        Id = user.Id,
        FirstName = user.FirstName,
        LastName = user.LastName,
        Phone = user.PhoneNumber,
        AvatarUrl = user.ProfileImageUrl,
        // الأدوار المعلّقة لا تُدرَج ضمن Roles حتى لا يفتح لها التطبيق أقسامه؛
        // تُرسَل منفصلة ليعرض التطبيق حالة «قيد المراجعة».
        Roles = user.Roles
            .Where(r => r.IsApproved)
            .Select(r => RoleToClientString(r.Role))
            .ToList(),
        PendingRoles = user.Roles
            .Where(r => !r.IsApproved)
            .Select(r => RoleToClientString(r.Role))
            .ToList(),
        Language = user.PreferredLanguage == Language.English ? "en" : "ar",
        Country = user.Country,
        City = user.City,
        District = user.District,
        CityId = user.CityId,
        DistrictId = user.DistrictId,
        Latitude = user.Latitude,
        Longitude = user.Longitude,
        FavoriteSport = user.FavoriteSport,
    };

    // Client vocabulary uses "venue" for the venue-owner role.
    private static string RoleToClientString(UserType role) => role switch
    {
        UserType.Coach => "coach",
        UserType.VenueOwner => "venue",
        UserType.Admin => "admin",
        UserType.Staff => "staff",
        _ => "player",
    };

    private static Gender? ParseGender(string? gender) => gender?.ToLower() switch
    {
        "male" => Gender.Male,
        "female" => Gender.Female,
        _ => null,
    };

    private static VenueGenderPolicy ParseGenderPolicy(string? policy) => policy?.ToLower() switch
    {
        "womenonly" => VenueGenderPolicy.WomenOnly,
        "familyonly" => VenueGenderPolicy.FamilyOnly,
        _ => VenueGenderPolicy.MenOnly,
    };

    /// <summary>Ensures the venue-owner's personal documents (commercial
    /// registration, ID and tax certificate images) are all supplied. No venue
    /// data is collected at registration.</summary>
    private static void ValidateVenueDetails(VenueRegistrationDto? v)
    {
        if (v is null ||
            string.IsNullOrWhiteSpace(v.CommercialRegistrationImageUrl) ||
            string.IsNullOrWhiteSpace(v.OwnerIdImageUrl) ||
            string.IsNullOrWhiteSpace(v.TaxCertificateUrl))
            throw new AuthException(
                "Owner documents are required",
                "مستندات الملعب مطلوبة (صورة السجل التجاري وصورة الهوية وشهادة الضريبة)",
                "VENUE_DETAILS_REQUIRED");
    }

    /// <summary>Stores the venue-owner's personal documents on their account.
    /// Courts are created later from the owner dashboard.</summary>
    private static void ApplyOwnerDocuments(User user, VenueRegistrationDto v)
    {
        user.CommercialRegistrationImageUrl = v.CommercialRegistrationImageUrl.Trim();
        user.IdImageUrl = v.OwnerIdImageUrl.Trim();
        user.TaxCertificateImageUrl = v.TaxCertificateUrl.Trim();
    }

    /// <summary>
    /// يتحقق من الآيبان بخوارزمية mod-97 لا بالطول فقط — رقم واحد خاطئ يحوّل
    /// المستحقات لحساب آخر، والطول وحده لا يكشفه.
    /// </summary>
    private static void ValidateBankAccount(string? iban, string? bankName, string? holder)
    {
        if (string.IsNullOrWhiteSpace(iban) || string.IsNullOrWhiteSpace(bankName) ||
            string.IsNullOrWhiteSpace(holder))
            throw new AuthException(
                "Bank account details are required",
                "بيانات الحساب البنكي مطلوبة (الآيبان واسم البنك واسم صاحب الحساب)",
                "BANK_DETAILS_REQUIRED");

        if (!Helpers.Iban.IsValid(iban))
            throw new AuthException(
                "Invalid IBAN",
                "رقم الآيبان غير صحيح — تأكد أنه يبدأ بـ SA ويتكوّن من 24 خانة",
                "INVALID_IBAN");
    }

    private static UserType? ParseUserType(string role) => role.ToLower() switch
    {
        "player" => UserType.Player,
        "coach" => UserType.Coach,
        "venue" or "venueowner" => UserType.VenueOwner,
        "admin" => UserType.Admin,
        _ => null,
    };
}

// ── Custom exception ──────────────────────────────────────────────────────────

public class AuthException : Exception
{
    public string? MessageAr { get; }
    public string? Code { get; }

    public AuthException(string message, string? messageAr = null, string? code = null)
        : base(message)
    {
        MessageAr = messageAr;
        Code = code;
    }
}
