using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

// ── Requests ──────────────────────────────────────────────────────────────────

public class RegisterRequest
{
    [Required] public string FirstName { get; set; } = string.Empty;
    [Required] public string LastName { get; set; } = string.Empty;
    [Required, EmailAddress] public string Email { get; set; } = string.Empty;
    [Required] public string Phone { get; set; } = string.Empty;
    [Required, MinLength(8)] public string Password { get; set; } = string.Empty;
    public string? Gender { get; set; }
    public string Country { get; set; } = "السعودية";
    public string? City { get; set; }
    public string? District { get; set; }
    [Required, MinLength(1)] public List<string> Roles { get; set; } = [];
    public string Language { get; set; } = "ar";

    /// <summary>تفاصيل المدرب - مطلوبة عند اختيار دور "coach".</summary>
    public CoachRegistrationDto? Coach { get; set; }

    /// <summary>تفاصيل الملعب/النادي - مطلوبة عند اختيار دور "venue".</summary>
    public VenueRegistrationDto? Venue { get; set; }
}

/// <summary>بيانات الملف الشخصي للمدرب المُرسلة عند التسجيل.</summary>
public class CoachRegistrationDto
{
    public string? Bio { get; set; }
    [Required] public string Specialization { get; set; } = string.Empty;
    [Range(0, 100000)] public decimal HourlyRate { get; set; }
}

/// <summary>بيانات الملعب/النادي المُرسلة عند تسجيل مالك ملعب.</summary>
public class VenueRegistrationDto
{
    [Required] public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? City { get; set; }
    [Required] public string Address { get; set; } = string.Empty;
    /// <summary>mixed | womenOnly | familyOnly</summary>
    public string? GenderPolicy { get; set; }
}

public class LoginRequest
{
    [Required] public string Phone { get; set; } = string.Empty;
    [Required] public string Password { get; set; } = string.Empty;
}

public class RefreshTokenRequest
{
    [Required] public string RefreshToken { get; set; } = string.Empty;
}

public class ForgotPasswordRequest
{
    [Required] public string Phone { get; set; } = string.Empty;
}

public class VerifyOtpRequest
{
    [Required] public string Phone { get; set; } = string.Empty;
    [Required] public string Otp { get; set; } = string.Empty;
}

public class ResetPasswordRequest
{
    [Required] public string Phone { get; set; } = string.Empty;
    [Required] public string Otp { get; set; } = string.Empty;
    [Required, MinLength(8)] public string NewPassword { get; set; } = string.Empty;
}

public class UpdateLanguageRequest
{
    [Required] public string Language { get; set; } = string.Empty;
}

// ── Responses ─────────────────────────────────────────────────────────────────

public class AuthResponseDto
{
    public string AccessToken { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public UserProfileDto User { get; set; } = null!;
}

public class UserProfileDto
{
    public int Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? AvatarUrl { get; set; }
    public List<string> Roles { get; set; } = [];
    public string Language { get; set; } = "ar";
    public string? Country { get; set; }
    public string? City { get; set; }
    public string? District { get; set; }

    /// <summary>The user's chosen favorite sport (null if not chosen yet).</summary>
    public string? FavoriteSport { get; set; }

    /// <summary>Player level 1..7 (null when the user has no player profile).</summary>
    public int? Level { get; set; }
    /// <summary>Whether the player has completed the level self-assessment.</summary>
    public bool LevelAssessed { get; set; }
}

