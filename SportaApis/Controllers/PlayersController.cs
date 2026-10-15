using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/players")]
[Authorize]
public class PlayersController : ControllerBase
{
    private readonly IPlayerService _playerService;
    private readonly IWebHostEnvironment _env;

    public PlayersController(IPlayerService playerService, IWebHostEnvironment env)
    {
        _playerService = playerService;
        _env = env;
    }

    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // POST /api/players/level-assessment/video  (multipart)
    [HttpPost("level-assessment/video")]
    public async Task<IActionResult> SubmitVideoAssessment(IFormFile? file)
    {
        try
        {
            if (file == null || file.Length == 0)
                return BadRequest(ApiResponse<object>.Fail(
                    "No file uploaded", "لم يتم رفع أي ملف", "NO_FILE"));

            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            var allowed = new[] { ".mp4", ".mov", ".webm", ".m4v" };
            if (!allowed.Contains(ext))
                return BadRequest(ApiResponse<object>.Fail(
                    "Unsupported file type", "نوع ملف غير مدعوم", "BAD_FILE_TYPE"));

            if (file.Length > 100 * 1024 * 1024)
                return BadRequest(ApiResponse<object>.Fail(
                    "File too large (max 100MB)", "حجم الملف كبير (الحد 100 ميجا)", "FILE_TOO_LARGE"));

            var root = _env.WebRootPath
                ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var dir = Path.Combine(root, "uploads", "videos");
            Directory.CreateDirectory(dir);

            var fileName = $"{CurrentUserId}_{Guid.NewGuid():N}{ext}";
            await using (var stream = System.IO.File.Create(Path.Combine(dir, fileName)))
            {
                await file.CopyToAsync(stream);
            }

            var dto = await _playerService.SubmitVideoAssessmentAsync(
                CurrentUserId, $"/uploads/videos/{fileName}");
            return Ok(ApiResponse<LevelAssessmentDto>.Ok(dto));
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

    // POST /api/players/level-assessment/coach
    [HttpPost("level-assessment/coach")]
    public async Task<IActionResult> RequestCoachAssessment(
        [FromBody] RequestCoachAssessmentRequest request)
    {
        try
        {
            var dto = await _playerService.RequestCoachAssessmentAsync(
                CurrentUserId, request.CoachId);
            return Ok(ApiResponse<LevelAssessmentDto>.Ok(dto));
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

    // GET /api/players/level-assessments
    [HttpGet("level-assessments")]
    public async Task<IActionResult> GetMyAssessments()
    {
        var items = await _playerService.GetMyAssessmentsAsync(CurrentUserId);
        return Ok(ApiResponse<List<LevelAssessmentDto>>.Ok(items));
    }

    // POST /api/players/level-assessment
    [HttpPost("level-assessment")]
    public async Task<IActionResult> SubmitLevelAssessment(
        [FromBody] LevelAssessmentRequest request)
    {
        try
        {
            var result = await _playerService
                .SubmitLevelAssessmentAsync(CurrentUserId, request);
            return Ok(ApiResponse<LevelAssessmentResultDto>.Ok(result));
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

    // PUT /api/players/favorite-sport
    [HttpPut("favorite-sport")]
    public async Task<IActionResult> SetFavoriteSport(
        [FromBody] FavoriteSportRequest request)
    {
        try
        {
            await _playerService.SetFavoriteSportAsync(CurrentUserId, request.Sport);
            return Ok(ApiResponse<object>.Ok(new
            {
                message = "Favorite sport updated",
                messageAr = "تم تحديث اللعبة المفضلة",
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

    // GET /api/players/me
    [HttpGet("me")]
    public async Task<IActionResult> GetMyProfile()
    {
        try
        {
            var profile = await _playerService.GetMyProfileAsync(CurrentUserId);
            return Ok(ApiResponse<PlayerProfileDto>.Ok(profile));
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
}
