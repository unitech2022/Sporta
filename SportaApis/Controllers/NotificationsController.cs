using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/notifications")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _service;

    public NotificationsController(INotificationService service) =>
        _service = service;

    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // GET /api/notifications?page=&pageSize=
    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var items = await _service.GetAsync(CurrentUserId, page, pageSize);
        return Ok(ApiResponse<PagedResult<NotificationDto>>.Ok(items));
    }

    // GET /api/notifications/unread-count
    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount()
    {
        var count = await _service.GetUnreadCountAsync(CurrentUserId);
        return Ok(ApiResponse<UnreadCountDto>.Ok(new UnreadCountDto { Count = count }));
    }

    // PUT /api/notifications/{id}/read
    [HttpPut("{id:int}/read")]
    public async Task<IActionResult> MarkRead(int id)
    {
        await _service.MarkReadAsync(CurrentUserId, id);
        return Ok(ApiResponse<object>.Ok(new { message = "Done" }));
    }

    // PUT /api/notifications/read-all
    [HttpPut("read-all")]
    public async Task<IActionResult> MarkAllRead()
    {
        await _service.MarkAllReadAsync(CurrentUserId);
        return Ok(ApiResponse<object>.Ok(new { message = "Done" }));
    }
}
