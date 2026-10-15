using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/feed")]
[Authorize]
public class FeedController : ControllerBase
{
    private readonly IFeedService _feedService;

    public FeedController(IFeedService feedService) =>
        _feedService = feedService;

    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // GET /api/feed
    [HttpGet]
    public async Task<IActionResult> GetFeed()
    {
        var items = await _feedService.GetFeedAsync(CurrentUserId);
        return Ok(ApiResponse<List<FeedItemDto>>.Ok(items));
    }
}
