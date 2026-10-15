using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

/// <summary>دعوة الأصدقاء إلى مباراة/أمريكانو/بطولة — دعوة لها وقت وتصل كإشعار.</summary>
[ApiController]
[Route("api/invites")]
[Authorize]
public class InvitesController : ControllerBase
{
    private readonly IEventInviteService _invites;

    public InvitesController(IEventInviteService invites) => _invites = invites;

    private int CurrentUserId =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    // POST /api/invites { kind, targetId, userIds, expiresInMinutes? }
    [HttpPost]
    public Task<IActionResult> Send([FromBody] SendEventInviteRequest request) =>
        Run(() => _invites.SendAsync(CurrentUserId, request));

    // GET /api/invites/received — الدعوات الواردة السارية
    [HttpGet("received")]
    public Task<IActionResult> Received() => Run(() => _invites.GetReceivedAsync(CurrentUserId));

    // GET /api/invites/mine?kind=match&targetId=5 — دعوتي إلى هذا الحدث (أو null)
    [HttpGet("mine")]
    public Task<IActionResult> Mine([FromQuery] string kind, [FromQuery] int targetId) =>
        Run(() => _invites.GetMineForTargetAsync(CurrentUserId, kind, targetId));

    // POST /api/invites/{id}/decline
    [HttpPost("{id:int}/decline")]
    public Task<IActionResult> Decline(int id) => Run(() => _invites.DeclineAsync(CurrentUserId, id));

    private async Task<IActionResult> Run<T>(Func<Task<T>> action)
    {
        try
        {
            return Ok(ApiResponse<T>.Ok(await action()));
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
