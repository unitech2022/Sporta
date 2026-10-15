using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.Attributes;
using SportaApis.DTOs;
using SportaApis.Helpers;
using SportaApis.Services;

namespace SportaApis.Controllers;

/// <summary>فحص موقع المستخدم ضد مناطق الخدمة — عام لأن الزائر يراه أيضاً.</summary>
[ApiController]
[Route("api/service-zones")]
[AllowAnonymous]
public class ServiceZonesController : ControllerBase
{
    private readonly IServiceZoneService _zones;

    public ServiceZonesController(IServiceZoneService zones) => _zones = zones;

    // GET /api/service-zones/check?lat=..&lng=..
    [HttpGet("check")]
    public async Task<IActionResult> Check([FromQuery] double lat, [FromQuery] double lng)
    {
        if (!GeoPolygonHelper.IsValidLat(lat) || !GeoPolygonHelper.IsValidLng(lng))
            return BadRequest(ApiResponse<object>.Fail(
                "Invalid coordinates", "إحداثيات غير صالحة", "INVALID_COORDINATES"));

        var result = await _zones.CheckAsync(lat, lng);
        return Ok(ApiResponse<ServiceZoneCheckDto>.Ok(result));
    }
}

/// <summary>إدارة مناطق الخدمة من لوحة التحكم.</summary>
[ApiController]
[Route("api/admin/service-zones")]
[Authorize(Roles = "admin,staff")]
public class AdminServiceZonesController : ControllerBase
{
    private readonly IServiceZoneService _zones;

    public AdminServiceZonesController(IServiceZoneService zones) => _zones = zones;

    // GET /api/admin/service-zones
    [HttpGet]
    [RequirePermission(Permissions.ServiceZonesView)]
    public async Task<IActionResult> GetAll()
    {
        var items = await _zones.GetAllAsync();
        return Ok(ApiResponse<List<ServiceZoneDto>>.Ok(items));
    }

    // POST /api/admin/service-zones
    [HttpPost]
    [RequirePermission(Permissions.ServiceZonesManage)]
    public async Task<IActionResult> Create([FromBody] SaveServiceZoneRequest request)
    {
        try
        {
            var dto = await _zones.CreateAsync(request);
            return Ok(ApiResponse<ServiceZoneDto>.Ok(dto));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // PUT /api/admin/service-zones/{id}
    [HttpPut("{id:int}")]
    [RequirePermission(Permissions.ServiceZonesManage)]
    public async Task<IActionResult> Update(int id, [FromBody] SaveServiceZoneRequest request)
    {
        try
        {
            var dto = await _zones.UpdateAsync(id, request);
            return Ok(ApiResponse<ServiceZoneDto>.Ok(dto));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // DELETE /api/admin/service-zones/{id}
    [HttpDelete("{id:int}")]
    [RequirePermission(Permissions.ServiceZonesManage)]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            await _zones.DeleteAsync(id);
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // GET /api/admin/service-zones/message
    [HttpGet("message")]
    [RequirePermission(Permissions.ServiceZonesView)]
    public async Task<IActionResult> GetMessage()
    {
        var dto = await _zones.GetMessageAsync();
        return Ok(ApiResponse<ServiceZoneMessageDto>.Ok(dto));
    }

    // PUT /api/admin/service-zones/message
    [HttpPut("message")]
    [RequirePermission(Permissions.ServiceZonesManage)]
    public async Task<IActionResult> SaveMessage([FromBody] ServiceZoneMessageDto request)
    {
        var dto = await _zones.SaveMessageAsync(request);
        return Ok(ApiResponse<ServiceZoneMessageDto>.Ok(dto));
    }
}
