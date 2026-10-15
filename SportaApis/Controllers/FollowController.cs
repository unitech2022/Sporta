using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/follow")]
[Authorize]
public class FollowController : ControllerBase
{
    private readonly IFollowService _followService;

    public FollowController(IFollowService followService) =>
        _followService = followService;

    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // GET /api/follow/following
    [HttpGet("following")]
    public async Task<IActionResult> GetFollowing()
    {
        var list = await _followService.GetFollowingAsync(CurrentUserId);
        return Ok(ApiResponse<List<PlayerSummaryDto>>.Ok(list));
    }

    // GET /api/follow/followers
    [HttpGet("followers")]
    public async Task<IActionResult> GetFollowers()
    {
        var list = await _followService.GetFollowersAsync(CurrentUserId);
        return Ok(ApiResponse<List<PlayerSummaryDto>>.Ok(list));
    }

    // POST /api/follow/{userId}
    [HttpPost("{userId:int}")]
    public async Task<IActionResult> Follow(int userId)
    {
        try
        {
            await _followService.FollowAsync(CurrentUserId, userId);
            return Ok(ApiResponse<object>.Ok(new { message = "Followed" }));
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

    // DELETE /api/follow/{userId}
    [HttpDelete("{userId:int}")]
    public async Task<IActionResult> Unfollow(int userId)
    {
        await _followService.UnfollowAsync(CurrentUserId, userId);
        return Ok(ApiResponse<object>.Ok(new { message = "Unfollowed" }));
    }
}
