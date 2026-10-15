using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/points")]
[Authorize]
public class PointsController : ControllerBase
{
    private readonly IPointsService _points;

    public PointsController(IPointsService points) => _points = points;

    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // GET /api/points?page=&pageSize=
    [HttpGet]
    public async Task<IActionResult> Get(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var summary = await _points.GetSummaryAsync(CurrentUserId, page, pageSize);
        return Ok(ApiResponse<PointsSummaryDto>.Ok(summary));
    }

    // GET /api/points/leaderboard?kind=reward|level&period=all|daily|weekly|monthly&limit=10
    // أعلى الحاصلين على النقاط — يظهر في قسم «نقاط المستوى والمكافآت» بالرئيسية.
    [HttpGet("leaderboard")]
    public async Task<IActionResult> Leaderboard(
        [FromQuery] string kind = "reward",
        [FromQuery] string period = "all",
        [FromQuery] int limit = 10)
    {
        var board = await _points.GetLeaderboardAsync(CurrentUserId, kind, period, limit);
        return Ok(ApiResponse<LeaderboardDto>.Ok(board));
    }

    // POST /api/points/redeem
    [HttpPost("redeem")]
    public async Task<IActionResult> Redeem([FromBody] RedeemPointsRequest request)
    {
        try
        {
            var summary = await _points.RedeemAsync(CurrentUserId, request.Points);
            return Ok(ApiResponse<PointsSummaryDto>.Ok(summary));
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
