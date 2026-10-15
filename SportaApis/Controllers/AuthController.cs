using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly IOtpService _otpService;
    private readonly IWebHostEnvironment _env;

    public AuthController(
        IAuthService authService, IOtpService otpService, IWebHostEnvironment env)
    {
        _authService = authService;
        _otpService = otpService;
        _env = env;
    }

    // POST /api/auth/register
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        try
        {
            var result = await _authService.RegisterAsync(request);
            return Ok(ApiResponse<AuthResponseDto>.Ok(result));
        }
        catch (AuthException ex)
        {
            return Conflict(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred",
                "حدث خطأ غير متوقع",
                "UNEXPECTED"));
        }
    }

    // POST /api/auth/login
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        try
        {
            var result = await _authService.LoginAsync(request);
            return Ok(ApiResponse<AuthResponseDto>.Ok(result));
        }
        catch (AuthException ex)
        {
            return Unauthorized(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred",
                "حدث خطأ غير متوقع",
                "UNEXPECTED"));
        }
    }

    // POST /api/auth/refresh
    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh([FromBody] RefreshTokenRequest request)
    {
        try
        {
            var result = await _authService.RefreshTokenAsync(request.RefreshToken);
            return Ok(ApiResponse<AuthResponseDto>.Ok(result));
        }
        catch (AuthException ex)
        {
            return Unauthorized(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // POST /api/auth/forgot-password
    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        try
        {
            await _authService.ForgotPasswordAsync(request.Phone);
            return Ok(ApiResponse<object>.Ok(new
            {
                message = "Verification code sent",
                messageAr = "تم إرسال رمز التحقق"
            }));
        }
        catch (AuthException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // POST /api/auth/otp/request
    // يرسل رمز التحقق على واتساب. الغرض يُرسَل مع الطلب لأنه يحدّد الشرط المسبق:
    // register يشترط رقماً غير مسجّل، وبقية الأغراض تشترط حساباً قائماً وفعّالاً.
    [HttpPost("otp/request")]
    public async Task<IActionResult> RequestOtp(
        [FromBody] RequestOtpRequest request, CancellationToken ct)
    {
        try
        {
            var result = await _otpService.RequestAsync(
                request.Phone, ParsePurpose(request.Purpose), ct);

            return Ok(ApiResponse<OtpRequestedDto>.Ok(new OtpRequestedDto
            {
                Channel = result.Channel,
                CodeLength = result.CodeLength,
                ExpiresInSeconds = result.ExpiresInSeconds,
                ResendAfterSeconds = result.ResendAfterSeconds,
                DevCode = result.DevCode,
            }));
        }
        catch (AuthException ex)
        {
            // تجاوز الحدّ يستحق 429 كي يميّزه العميل عن رفضٍ في البيانات.
            return ex.Code is "OTP_COOLDOWN" or "OTP_RATE_LIMITED"
                ? StatusCode(429, ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code))
                : BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // POST /api/auth/login/device
    // الدخول اليومي من هاتف موثوق: الرقم + سرّ الجهاز بعد بصمة النظام. لا رمز.
    [HttpPost("login/device")]
    public async Task<IActionResult> DeviceLogin([FromBody] DeviceLoginRequest request)
    {
        try
        {
            var result = await _authService.LoginWithDeviceAsync(
                request.Phone, request.DeviceId, request.DeviceSecret);
            return Ok(ApiResponse<AuthResponseDto>.Ok(result));
        }
        catch (AuthException ex)
        {
            return Unauthorized(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // POST /api/auth/devices/enroll  (requires auth)
    // يسجّل هذا الهاتف جهازاً موثوقاً بعد بصمة صاحبه ويُسلّم سرّه مرة واحدة.
    [HttpPost("devices/enroll")]
    [Authorize]
    public async Task<IActionResult> EnrollDevice([FromBody] EnrollDeviceRequest request)
    {
        try
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var result = await _authService.EnrollDeviceAsync(userId, request);
            return Ok(ApiResponse<EnrolledDeviceDto>.Ok(result));
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

    // POST /api/auth/otp/login
    // دخول برمز واتساب — للهاتف غير الموثوق قبل أن يسجّل بصمته.
    [HttpPost("otp/login")]
    public async Task<IActionResult> OtpLogin([FromBody] OtpLoginRequest request)
    {
        try
        {
            var result = await _authService.LoginWithOtpAsync(request.Phone, request.Otp);
            return Ok(ApiResponse<AuthResponseDto>.Ok(result));
        }
        catch (AuthException ex)
        {
            return Unauthorized(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // POST /api/auth/otp/verify
    // للأغراض التي يليها إجراء آخر (تسجيل، استعادة كلمة سر، حذف حساب): يُبدّل
    // الرمز بتذكرة قصيرة العمر تُقدَّم لذلك الإجراء وحده.
    [HttpPost("otp/verify")]
    public async Task<IActionResult> VerifyOtpForPurpose(
        [FromBody] VerifyOtpPurposeRequest request, CancellationToken ct)
    {
        try
        {
            var purpose = ParsePurpose(request.Purpose);
            if (purpose == OtpPurpose.Login)
                return BadRequest(ApiResponse<object>.Fail(
                    "Use /api/auth/otp/login for sign-in codes",
                    "استخدم otp/login لرمز تسجيل الدخول",
                    "INVALID_PURPOSE"));

            var token = await _otpService.VerifyAsync(request.Phone, request.Otp, purpose, ct);
            return Ok(ApiResponse<VerificationTokenDto>.Ok(
                new VerificationTokenDto { VerificationToken = token }));
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

    // POST /api/auth/verify-otp  (مسار لوحة التحكم في استعادة كلمة السر)
    [HttpPost("verify-otp")]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequest request)
    {
        try
        {
            var token = await _authService.VerifyOtpAsync(request.Phone, request.Otp);
            return Ok(ApiResponse<VerificationTokenDto>.Ok(
                new VerificationTokenDto { VerificationToken = token }));
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

    /// <summary>
    /// يحوّل الغرض النصّي القادم من العميل إلى قيمته. غرضٌ مجهول يُرفض بدل أن
    /// يسقط على قيمة افتراضية — وإلّا صار بالإمكان طلب رمز بغرض ثم استعماله
    /// لغيره بإرسال نصّ لا نعرفه.
    /// </summary>
    private static OtpPurpose ParsePurpose(string? raw) => raw?.Trim().ToLowerInvariant() switch
    {
        "login" => OtpPurpose.Login,
        "register" => OtpPurpose.Register,
        "reset" or "reset_password" => OtpPurpose.ResetPassword,
        "delete" or "delete_account" => OtpPurpose.DeleteAccount,
        "change_phone" => OtpPurpose.ChangePhone,
        _ => throw new AuthException(
            "Unknown verification purpose", "غرض تحقق غير معروف", "INVALID_PURPOSE"),
    };

    // POST /api/auth/reset-password
    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
    {
        try
        {
            await _authService.ResetPasswordAsync(
                request.Phone, request.VerificationToken, request.NewPassword);
            return Ok(ApiResponse<object>.Ok(new
            {
                message = "Password reset successfully",
                messageAr = "تم تغيير كلمة السر بنجاح"
            }));
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

    // PUT /api/users/language  (requires auth)
    [HttpPut("/api/users/language")]
    [Authorize]
    public async Task<IActionResult> UpdateLanguage([FromBody] UpdateLanguageRequest request)
    {
        try
        {
            var userId = int.Parse(
                User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            await _authService.UpdateLanguageAsync(userId, request.Language);
            return Ok(ApiResponse<object>.Ok(new
            {
                message = "Language updated",
                messageAr = "تم تحديث اللغة"
            }));
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

    // PUT /api/users/me  (requires auth)
    [HttpPut("/api/users/me")]
    [Authorize]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
    {
        try
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var profile = await _authService.UpdateProfileAsync(userId, request);
            return Ok(ApiResponse<UserProfileDto>.Ok(profile));
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

    // PUT /api/users/location  (requires auth) — save/update the user's location
    [HttpPut("/api/users/location")]
    [Authorize]
    public async Task<IActionResult> UpdateLocation(
        [FromBody] UpdateLocationRequest request)
    {
        try
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var profile = await _authService.UpdateLocationAsync(
                userId, request.Latitude, request.Longitude);
            return Ok(ApiResponse<UserProfileDto>.Ok(profile));
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

    // DELETE /api/users/roles/{role}  (requires auth) — حذف ناعم لدور
    [HttpDelete("/api/users/roles/{role}")]
    [Authorize]
    public async Task<IActionResult> DeleteRole(string role)
    {
        try
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var auth = await _authService.DeleteRoleAsync(userId, role);
            return Ok(ApiResponse<AuthResponseDto>.Ok(auth));
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

    // POST /api/users/roles  (requires auth) — add a role to the current user
    [HttpPost("/api/users/roles")]
    [Authorize]
    public async Task<IActionResult> AddRole([FromBody] AddRoleRequest request)
    {
        try
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var profile = await _authService.AddRoleAsync(userId, request);
            return Ok(ApiResponse<UserProfileDto>.Ok(profile));
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

    // POST /api/users/avatar  (multipart, requires auth)
    [HttpPost("/api/users/avatar")]
    [Authorize]
    public async Task<IActionResult> UploadAvatar(IFormFile? file)
    {
        try
        {
            if (file == null || file.Length == 0)
                return BadRequest(ApiResponse<object>.Fail(
                    "No file uploaded", "لم يتم رفع أي ملف", "NO_FILE"));

            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            if (!allowed.Contains(ext))
                return BadRequest(ApiResponse<object>.Fail(
                    "Unsupported file type", "نوع ملف غير مدعوم", "BAD_FILE_TYPE"));

            if (file.Length > 5 * 1024 * 1024)
                return BadRequest(ApiResponse<object>.Fail(
                    "File too large (max 5MB)", "حجم الملف كبير (الحد 5 ميجا)", "FILE_TOO_LARGE"));

            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            var root = _env.WebRootPath
                ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var dir = Path.Combine(root, "uploads", "avatars");
            Directory.CreateDirectory(dir);

            var fileName = $"{userId}_{Guid.NewGuid():N}{ext}";
            await using (var stream = System.IO.File.Create(Path.Combine(dir, fileName)))
            {
                await file.CopyToAsync(stream);
            }

            var relativeUrl = $"/uploads/avatars/{fileName}";
            var profile = await _authService.UpdateAvatarAsync(userId, relativeUrl);
            return Ok(ApiResponse<UserProfileDto>.Ok(profile));
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

    // PUT /api/users/password  (requires auth)
    [HttpPut("/api/users/password")]
    [Authorize]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        try
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            await _authService.ChangePasswordAsync(
                userId, request.CurrentPassword, request.NewPassword);
            return Ok(ApiResponse<object>.Ok(new
            {
                message = "Password changed",
                messageAr = "تم تغيير كلمة المرور"
            }));
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

    // DELETE /api/users/me  (requires auth)
    // حذف الحساب نهائياً بطلب صاحبه — متطلب App Store 5.1.1(v). التأكيد الوحيد
    // رمز واتساب يُتحقق منه أولاً بغرض delete؛ لا إحالة إلى الدعم ولا تعطيل مؤقت.
    // المسار البديل POST موجود لأن بعض الوسائط (بروكسي/شبكات) تُسقط جسم طلب
    // DELETE، والتذكرة تُرسل في الجسم.
    [HttpDelete("/api/users/me")]
    [HttpPost("/api/users/me/delete")]
    [Authorize]
    public async Task<IActionResult> DeleteAccount([FromBody] DeleteAccountRequest request)
    {
        try
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            await _authService.DeleteAccountAsync(
                userId, request.VerificationToken, request.Reason);
            return Ok(ApiResponse<object>.Ok(new
            {
                message = "Account deleted",
                messageAr = "تم حذف الحساب"
            }));
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
}
