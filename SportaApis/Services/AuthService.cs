using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Models;

namespace SportaApis.Services;

public class AuthService : IAuthService
{
    private readonly AppDbContext _db;
    private readonly ITokenService _tokenService;
    private readonly IConfiguration _config;

    public AuthService(AppDbContext db, ITokenService tokenService, IConfiguration config)
    {
        _db = db;
        _tokenService = tokenService;
        _config = config;
    }

    // ── Register ──────────────────────────────────────────────────────────────

    public async Task<AuthResponseDto> RegisterAsync(RegisterRequest req)
    {
        // Phone uniqueness
        if (await _db.Users.AnyAsync(u => u.PhoneNumber == req.Phone))
            throw new AuthException(
                "Phone number already registered",
                "رقم الهاتف مسجل من قبل",
                "PHONE_EXISTS");

        // Email uniqueness
        if (await _db.Users.AnyAsync(u => u.Email == req.Email))
            throw new AuthException(
                "Email already registered",
                "البريد الإلكتروني مسجل من قبل",
                "EMAIL_EXISTS");

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

        if (roleTypes.Contains(UserType.VenueOwner) &&
            (string.IsNullOrWhiteSpace(req.Venue?.Name) ||
             string.IsNullOrWhiteSpace(req.Venue?.Address)))
            throw new AuthException(
                "Venue details are required",
                "تفاصيل الملعب مطلوبة",
                "VENUE_DETAILS_REQUIRED");

        var user = new User
        {
            FirstName = req.FirstName,
            LastName = req.LastName,
            Email = req.Email,
            PhoneNumber = req.Phone,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password),
            PreferredLanguage = req.Language == "en" ? Language.English : Language.Arabic,
            Gender = ParseGender(req.Gender),
            Country = req.Country,
            City = req.City,
            District = req.District,
            UserType = roleTypes.First(),
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        // Roles
        var roles = roleTypes
            .Select(r => new UserRole { UserId = user.Id, Role = r })
            .ToList();
        _db.Set<UserRole>().AddRange(roles);

        // Role-specific profiles
        if (roleTypes.Contains(UserType.Player))
        {
            _db.PlayerProfiles.Add(new PlayerProfile { UserId = user.Id });
        }

        if (roleTypes.Contains(UserType.Coach))
        {
            _db.CoachProfiles.Add(new CoachProfile
            {
                UserId = user.Id,
                Bio = req.Coach!.Bio,
                Specialization = req.Coach.Specialization,
                HourlyRate = req.Coach.HourlyRate,
            });
        }

        if (roleTypes.Contains(UserType.VenueOwner))
        {
            _db.Venues.Add(new Venue
            {
                OwnerId = user.Id,
                Name = req.Venue!.Name,
                Description = req.Venue.Description,
                Country = req.Country,
                City = req.Venue.City ?? req.City ?? string.Empty,
                Address = req.Venue.Address,
                GenderPolicy = ParseGenderPolicy(req.Venue.GenderPolicy),
            });
        }

        await _db.SaveChangesAsync();

        // Load roles for token generation
        user.Roles = roles;

        return await BuildAuthResponseAsync(user, persistRefresh: true);
    }

    // ── Login ─────────────────────────────────────────────────────────────────

    public async Task<AuthResponseDto> LoginAsync(LoginRequest req)
    {
        var user = await _db.Users
            .Include(u => u.Roles)
            .FirstOrDefaultAsync(u => u.PhoneNumber == req.Phone);

        if (user == null)
            throw new AuthException(
                "This phone number is not registered",
                "رقم الهاتف غير مسجّل",
                "PHONE_NOT_REGISTERED");

        if (!BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash))
            throw new AuthException(
                "Incorrect password",
                "كلمة السر غير صحيحة",
                "INVALID_PASSWORD");

        if (!user.IsActive)
            throw new AuthException(
                "Account is suspended",
                "الحساب موقوف",
                "ACCOUNT_SUSPENDED");

        return await BuildAuthResponseAsync(user, persistRefresh: true);
    }

    // ── Refresh Token ─────────────────────────────────────────────────────────

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

        // Rotate: revoke old, issue new
        stored.IsRevoked = true;

        var authResponse = await BuildAuthResponseAsync(stored.User, persistRefresh: true);
        await _db.SaveChangesAsync();

        return authResponse;
    }

    // ── Forgot Password ───────────────────────────────────────────────────────

    public async Task ForgotPasswordAsync(string phone)
    {
        if (!await _db.Users.AnyAsync(u => u.PhoneNumber == phone))
            throw new AuthException(
                "Phone number not found",
                "رقم الهاتف غير مسجل",
                "PHONE_NOT_FOUND");

        // Invalidate previous OTPs for this phone
        var oldOtps = _db.Set<OtpCode>()
            .Where(o => o.PhoneNumber == phone && !o.IsUsed);
        await oldOtps.ForEachAsync(o => o.IsUsed = true);

        var expiryMinutes = int.Parse(
            _config["Otp:ExpiryMinutes"] ?? "10");

        var otp = new OtpCode
        {
            PhoneNumber = phone,
            Code = GenerateOtp(),
            ExpiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes),
        };

        _db.Set<OtpCode>().Add(otp);
        await _db.SaveChangesAsync();

        // TODO: Integrate SMS provider (e.g. Twilio) to send otp.Code to phone.
        // For development the OTP is logged here:
        Console.WriteLine($"[DEV] OTP for {phone}: {otp.Code}");
    }

    // ── Verify OTP ────────────────────────────────────────────────────────────

    public async Task VerifyOtpAsync(string phone, string otp)
    {
        var record = await _db.Set<OtpCode>()
            .Where(o => o.PhoneNumber == phone && o.Code == otp)
            .OrderByDescending(o => o.CreatedAt)
            .FirstOrDefaultAsync();

        if (record == null || !record.IsValid)
            throw new AuthException(
                "Invalid or expired verification code",
                "رمز التحقق غير صحيح أو منتهي الصلاحية",
                "INVALID_OTP");

        // Mark as used so it can't be reused
        record.IsUsed = true;
        await _db.SaveChangesAsync();
    }

    // ── Reset Password ────────────────────────────────────────────────────────

    public async Task ResetPasswordAsync(string phone, string otp, string newPassword)
    {
        // Validate OTP one more time
        var record = await _db.Set<OtpCode>()
            .Where(o => o.PhoneNumber == phone && o.Code == otp && o.IsUsed)
            .OrderByDescending(o => o.CreatedAt)
            .FirstOrDefaultAsync();

        if (record == null)
            throw new AuthException(
                "OTP verification required",
                "يرجى التحقق من رمز OTP أولاً",
                "OTP_NOT_VERIFIED");

        var user = await _db.Users.FirstOrDefaultAsync(u => u.PhoneNumber == phone)
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

        var profile = MapToProfile(user);

        // Attach player level info when a player profile exists.
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

        return new AuthResponseDto
        {
            AccessToken = accessToken,
            RefreshToken = refreshTokenValue,
            User = profile,
        };
    }

    private static UserProfileDto MapToProfile(User user) => new()
    {
        Id = user.Id,
        FirstName = user.FirstName,
        LastName = user.LastName,
        Phone = user.PhoneNumber,
        Email = user.Email,
        AvatarUrl = user.ProfileImageUrl,
        Roles = user.Roles.Select(r => RoleToClientString(r.Role)).ToList(),
        Language = user.PreferredLanguage == Language.English ? "en" : "ar",
        Country = user.Country,
        City = user.City,
        District = user.District,
        FavoriteSport = user.FavoriteSport,
    };

    // Client vocabulary uses "venue" for the venue-owner role.
    private static string RoleToClientString(UserType role) => role switch
    {
        UserType.Coach => "coach",
        UserType.VenueOwner => "venue",
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
        _ => VenueGenderPolicy.Mixed,
    };

    private static UserType? ParseUserType(string role) => role.ToLower() switch
    {
        "player" => UserType.Player,
        "coach" => UserType.Coach,
        "venue" or "venueowner" => UserType.VenueOwner,
        _ => null,
    };

    private static string GenerateOtp() =>
        Random.Shared.Next(100_000, 999_999).ToString();
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
