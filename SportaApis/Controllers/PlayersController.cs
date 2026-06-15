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

    public PlayersController(IPlayerService playerService) =>
        _playerService = playerService;

    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

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
