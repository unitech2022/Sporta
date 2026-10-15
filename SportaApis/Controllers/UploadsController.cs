using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Helpers;

namespace SportaApis.Controllers;

/// <summary>Generic image upload — saves to wwwroot/uploads/images, returns a URL.</summary>
[ApiController]
[Route("api/uploads")]
[Authorize]
public class UploadsController : ControllerBase
{
    private readonly IWebHostEnvironment _env;
    private readonly AttemptThrottle _throttle;

    public UploadsController(IWebHostEnvironment env, AttemptThrottle throttle)
    {
        _env = env;
        _throttle = throttle;
    }

    /// <summary>سقف الرفع المجهول لكل عنوان IP في الساعة — يكفي تسجيلاً كاملاً
    /// (هوية + سجل + صور ملعب) ويمنع استخدامنا مستودع صور مجانياً.</summary>
    private const int AnonymousUploadsPerHour = 30;

    // POST /api/uploads/image  (multipart, field name "file")
    // Anonymous so venue-owner registration can upload the required onboarding
    // documents (owner ID, tax certificate, venue photos) before an account
    // (and JWT) exists — same file-type/size limits apply either way.
    [HttpPost("image")]
    [AllowAnonymous]
    public async Task<IActionResult> UploadImage(IFormFile? file)
    {
        if (file is null || file.Length == 0)
            return BadRequest(ApiResponse<object>.Fail(
                "No file uploaded", "لم يتم رفع أي ملف", "NO_FILE"));

        if (User.Identity?.IsAuthenticated != true)
        {
            var ip = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
            var key = $"anon-upload:{ip}";
            if (_throttle.IsBlocked(key, AnonymousUploadsPerHour))
                return StatusCode(StatusCodes.Status429TooManyRequests, ApiResponse<object>.Fail(
                    "Too many uploads, try again later",
                    "محاولات رفع كثيرة، حاول لاحقاً", "UPLOAD_RATE_LIMITED"));
            _throttle.Hit(key, TimeSpan.FromHours(1));
        }

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        if (!allowed.Contains(ext))
            return BadRequest(ApiResponse<object>.Fail(
                "Unsupported file type", "نوع ملف غير مدعوم", "BAD_FILE_TYPE"));

        if (file.Length > 5 * 1024 * 1024)
            return BadRequest(ApiResponse<object>.Fail(
                "File too large (max 5MB)", "حجم الملف كبير (الحد 5 ميجا)", "FILE_TOO_LARGE"));

        // الامتداد وحده لا يكفي: نفحص بصمة الملف حتى لا يُخزَّن ملف تنفيذي/HTML
        // باسم صورة ويُقدَّم من مجلد الرفع العام.
        if (!await LooksLikeImageAsync(file))
            return BadRequest(ApiResponse<object>.Fail(
                "File is not a valid image", "الملف ليس صورة صالحة", "BAD_FILE_TYPE"));

        var root = _env.WebRootPath
            ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
        var dir = Path.Combine(root, "uploads", "images");
        Directory.CreateDirectory(dir);

        var fileName = $"{Guid.NewGuid():N}{ext}";
        await using (var stream = System.IO.File.Create(Path.Combine(dir, fileName)))
        {
            await file.CopyToAsync(stream);
        }

        var url = $"/uploads/images/{fileName}";
        return Ok(ApiResponse<object>.Ok(new { url }));
    }

    private static async Task<bool> LooksLikeImageAsync(IFormFile file)
    {
        var head = new byte[12];
        await using var stream = file.OpenReadStream();
        var read = await stream.ReadAsync(head.AsMemory(0, head.Length));
        if (read < 4) return false;
        // JPEG FF D8 FF
        if (head[0] == 0xFF && head[1] == 0xD8 && head[2] == 0xFF) return true;
        // PNG 89 50 4E 47
        if (head[0] == 0x89 && head[1] == 0x50 && head[2] == 0x4E && head[3] == 0x47) return true;
        // WEBP: "RIFF"...."WEBP"
        if (read >= 12 && head[0] == (byte)'R' && head[1] == (byte)'I' && head[2] == (byte)'F' &&
            head[3] == (byte)'F' && head[8] == (byte)'W' && head[9] == (byte)'E' &&
            head[10] == (byte)'B' && head[11] == (byte)'P') return true;
        return false;
    }
}
