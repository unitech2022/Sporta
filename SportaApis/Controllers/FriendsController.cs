using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/friends")]
[Authorize]
public class FriendsController : ControllerBase
{
    private readonly IFriendService _friendService;

    public FriendsController(IFriendService friendService) =>
        _friendService = friendService;

    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // GET /api/friends
    [HttpGet]
    public async Task<IActionResult> GetFriends()
    {
        var friends = await _friendService.GetFriendsAsync(CurrentUserId);
        return Ok(ApiResponse<List<PlayerSummaryDto>>.Ok(friends));
    }

    // GET /api/friends/search?q=
    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] string? q)
    {
        var players = await _friendService.SearchPlayersAsync(CurrentUserId, q);
        return Ok(ApiResponse<List<PlayerSummaryDto>>.Ok(players));
    }

    // GET /api/friends/suggestions
    [HttpGet("suggestions")]
    public async Task<IActionResult> GetSuggestions()
    {
        var players = await _friendService.GetSuggestionsAsync(CurrentUserId);
        return Ok(ApiResponse<List<PlayerSummaryDto>>.Ok(players));
    }

    // GET /api/friends/requests
    [HttpGet("requests")]
    public async Task<IActionResult> GetRequests()
    {
        var requests = await _friendService.GetIncomingRequestsAsync(CurrentUserId);
        return Ok(ApiResponse<List<FriendRequestDto>>.Ok(requests));
    }

    // POST /api/friends/requests
    [HttpPost("requests")]
    public async Task<IActionResult> SendRequest([FromBody] SendFriendRequestRequest request)
    {
        try
        {
            await _friendService.SendRequestAsync(CurrentUserId, request.UserId);
            return Ok(ApiResponse<object>.Ok(new { message = "Request sent" }));
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

    // PUT /api/friends/requests/{id}/respond
    [HttpPut("requests/{id:int}/respond")]
    public async Task<IActionResult> Respond(
        int id, [FromBody] RespondFriendRequestRequest request)
    {
        try
        {
            await _friendService.RespondAsync(CurrentUserId, id, request.Accept);
            return Ok(ApiResponse<object>.Ok(new { message = "Done" }));
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

    // PUT /api/friends/{userId}/favorite
    [HttpPut("{userId:int}/favorite")]
    public async Task<IActionResult> ToggleFavorite(
        int userId, [FromBody] ToggleFavoriteRequest request)
    {
        try
        {
            await _friendService.ToggleFavoriteAsync(CurrentUserId, userId, request.Favorite);
            return Ok(ApiResponse<object>.Ok(new { favorite = request.Favorite }));
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
