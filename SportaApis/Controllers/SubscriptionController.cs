using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/subscription")]
[Authorize]
public class SubscriptionController : ControllerBase
{
    private readonly ISubscriptionService _service;

    public SubscriptionController(ISubscriptionService service) =>
        _service = service;

    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // GET /api/subscription
    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var dto = await _service.GetAsync(CurrentUserId);
        return Ok(ApiResponse<SubscriptionDto>.Ok(dto));
    }

    // GET /api/subscription/packages
    [HttpGet("packages")]
    public async Task<IActionResult> Packages()
    {
        var items = await _service.GetPackagesAsync(CurrentUserId);
        return Ok(ApiResponse<List<PackageDto>>.Ok(items));
    }

    // POST /api/subscription/subscribe — body optional, defaults to the legacy package.
    [HttpPost("subscribe")]
    public Task<IActionResult> Subscribe([FromBody] SubscribeRequest? request) =>
        _run(() => _service.SubscribeAsync(CurrentUserId, request?.PackageId));

// POST /api/subscription/cancel
    [HttpPost("cancel")]
    public Task<IActionResult> Cancel() => _run(() => _service.CancelAsync(CurrentUserId));

    private async Task<IActionResult> _run(Func<Task<SubscriptionDto>> action)
    {
        try
        {
            return Ok(ApiResponse<SubscriptionDto>.Ok(await action()));
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
