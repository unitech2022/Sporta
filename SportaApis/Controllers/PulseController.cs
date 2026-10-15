using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/pulse")]
[Authorize]
public class PulseController : ControllerBase
{
    private readonly IPulseService _pulseService;

    public PulseController(IPulseService pulseService) =>
        _pulseService = pulseService;

    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // GET /api/pulse
    [HttpGet]
    public async Task<IActionResult> GetPulse()
    {
        var items = await _pulseService.GetPulseAsync(CurrentUserId);
        return Ok(ApiResponse<List<PulseItemDto>>.Ok(items));
    }
}
