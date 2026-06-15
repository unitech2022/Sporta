using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IAuthService
{
    Task<AuthResponseDto> RegisterAsync(RegisterRequest request);
    Task<AuthResponseDto> LoginAsync(LoginRequest request);
    Task<AuthResponseDto> RefreshTokenAsync(string token);
    Task ForgotPasswordAsync(string phone);
    Task VerifyOtpAsync(string phone, string otp);
    Task ResetPasswordAsync(string phone, string otp, string newPassword);
    Task UpdateLanguageAsync(int userId, string language);
}
