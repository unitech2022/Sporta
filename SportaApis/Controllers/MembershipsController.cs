using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

/// <summary>
/// عضويات الأندية.
/// صاحب النادي: GET /api/venues/{venueId}/memberships، POST /api/venues/{venueId}/membership-plans،
/// PUT/DELETE /api/venues/membership-plans/{id}، PUT /api/venues/{venueId}/booking-window.
/// اللاعب: GET /api/memberships/venue/{venueId} (عام)، POST /api/memberships/subscribe،
/// PUT /api/memberships/{id}/auto-renew، GET /api/memberships/me،
/// GET /api/memberships/event-share، GET /api/memberships/court-share.
/// </summary>
[ApiController]
[Authorize]
public class MembershipsController : ControllerBase
{
    private readonly IMembershipService _svc;
    public MembershipsController(IMembershipService svc) => _svc = svc;

    private int Me => int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    [HttpGet("api/venues/{venueId:int}/memberships")]
    public Task<IActionResult> Admin(int venueId) => Run(() => _svc.GetVenueAdminAsync(Me, venueId));

    [HttpPost("api/venues/{venueId:int}/membership-plans")]
    public Task<IActionResult> CreatePlan(int venueId, [FromBody] SaveMembershipPlanRequest req) =>
        Run(() => _svc.CreatePlanAsync(Me, venueId, req));

    [HttpPut("api/venues/membership-plans/{id:int}")]
    public Task<IActionResult> UpdatePlan(int id, [FromBody] SaveMembershipPlanRequest req) =>
        Run(() => _svc.UpdatePlanAsync(Me, id, req));

    [HttpDelete("api/venues/membership-plans/{id:int}")]
    public Task<IActionResult> DeletePlan(int id) =>
        Run(async () => { await _svc.DeletePlanAsync(Me, id); return true; });

    [HttpPut("api/venues/{venueId:int}/booking-window")]
    public Task<IActionResult> Window(int venueId, [FromBody] SetBookingWindowRequest req) =>
        Run(() => _svc.SetBookingWindowAsync(Me, venueId, req.Days));

    [AllowAnonymous]
    [HttpGet("api/memberships/venue/{venueId:int}")]
    public Task<IActionResult> ForVenue(int venueId) => Run(() => _svc.GetForVenueAsync(Me, venueId));

    [HttpPost("api/memberships/subscribe")]
    public Task<IActionResult> Subscribe([FromBody] SubscribeMembershipRequest req) =>
        Run(() => _svc.SubscribeAsync(Me, req.PlanId, req.AutoRenew));

    [HttpPut("api/memberships/{id:int}/auto-renew")]
    public Task<IActionResult> AutoRenew(int id, [FromBody] AutoRenewRequest req) =>
        Run(() => _svc.SetAutoRenewAsync(Me, id, req.AutoRenew));

    [HttpGet("api/memberships/me")]
    public Task<IActionResult> Mine() => Run(() => _svc.GetMineAsync(Me));

    /// <summary>حصتي في حدث قائم بعد خصم العضوية: ?matchId= أو ?americanoId=.</summary>
    [HttpGet("api/memberships/event-share")]
    public Task<IActionResult> EventShare([FromQuery] int? matchId, [FromQuery] int? americanoId) =>
        Run(() => _svc.GetEventShareAsync(Me, matchId, americanoId));

    /// <summary>حصتي كمنشئ حدث جديد على ملعب: ?courtId=&amp;price=&amp;minutes=&amp;scheduledAt=
    /// (scheduledAt اختياري، وقت محلي: الخصم فقط إن غطّت العضوية موعد الحدث).</summary>
    [HttpGet("api/memberships/court-share")]
    public Task<IActionResult> CourtShare(
        [FromQuery] int courtId, [FromQuery] decimal price, [FromQuery] int minutes,
        [FromQuery] DateTime? scheduledAt) =>
        Run(() => _svc.GetCourtShareAsync(Me, courtId, price, minutes, scheduledAt));

    private async Task<IActionResult> Run<T>(Func<Task<T>> action)
    {
        try { return Ok(ApiResponse<T>.Ok(await action())); }
        catch (AuthException ex) { return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code)); }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }
}

public class AutoRenewRequest
{
    public bool AutoRenew { get; set; }
}
