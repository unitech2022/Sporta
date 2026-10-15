using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.Attributes;
using SportaApis.DTOs;
using SportaApis.Helpers;
using SportaApis.Services;

namespace SportaApis.Controllers;

/// <summary>System-wide configurable settings (e.g. the nearby radius used to
/// surface matches/courts closest to the user).</summary>
[ApiController]
[Route("api/settings")]
[Authorize]
public class SettingsController : ControllerBase
{
    private readonly ISettingsService _settings;

    public SettingsController(ISettingsService settings) => _settings = settings;

    // GET /api/settings/nearby-distance
    [HttpGet("nearby-distance")]
    public async Task<IActionResult> GetNearbyDistance()
    {
        var km = await _settings.GetNearbyDistanceKmAsync();
        return Ok(ApiResponse<object>.Ok(new { nearbyDistanceKm = km }));
    }

    // PUT /api/settings/nearby-distance  { km }  (admin only)
    [Authorize(Roles = "admin,staff")]
    [RequirePermission(Permissions.SettingsManage)]
    [HttpPut("nearby-distance")]
    public async Task<IActionResult> SetNearbyDistance(
        [FromBody] NearbyDistanceRequest request)
    {
        if (request.Km <= 0 || request.Km > 100000)
            return BadRequest(ApiResponse<object>.Fail(
                "Invalid distance", "مسافة غير صحيحة", "INVALID_DISTANCE"));
        await _settings.SetNearbyDistanceKmAsync(request.Km);
        return Ok(ApiResponse<object>.Ok(new { nearbyDistanceKm = request.Km }));
    }

    // GET /api/settings/support-phone  (public — needed on the suspended screen)
    [AllowAnonymous]
    [HttpGet("support-phone")]
    public async Task<IActionResult> GetSupportPhone()
    {
        var phone = await _settings.GetSupportPhoneAsync();
        return Ok(ApiResponse<object>.Ok(new { supportPhone = phone }));
    }

    // PUT /api/settings/support-phone  { phone }  (admin only)
    [Authorize(Roles = "admin,staff")]
    [RequirePermission(Permissions.SettingsManage)]
    [HttpPut("support-phone")]
    public async Task<IActionResult> SetSupportPhone([FromBody] SupportPhoneRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Phone))
            return BadRequest(ApiResponse<object>.Fail(
                "Invalid phone", "رقم غير صحيح", "INVALID_PHONE"));
        await _settings.SetSupportPhoneAsync(request.Phone.Trim());
        return Ok(ApiResponse<object>.Ok(new { supportPhone = request.Phone.Trim() }));
    }

    // GET /api/settings/public — non-sensitive settings for the app (maintenance,
    // force-update version, policy text, etc). No auth required.
    [AllowAnonymous]
    [HttpGet("public")]
    public async Task<IActionResult> GetPublic()
    {
        var settings = await _settings.GetPublicAsync();
        return Ok(ApiResponse<List<SettingDto>>.Ok(settings));
    }

    // GET /api/settings/public/{key}
    [AllowAnonymous]
    [HttpGet("public/{key}")]
    public async Task<IActionResult> GetPublicByKey(string key)
    {
        var setting = await _settings.GetByKeyAsync(key);
        if (setting == null || setting.IsSensitive)
            return NotFound(ApiResponse<object>.Fail(
                "Setting not found", "الإعداد غير موجود", "SETTING_NOT_FOUND"));
        return Ok(ApiResponse<SettingDto>.Ok(setting));
    }
}

public class NearbyDistanceRequest
{
    public double Km { get; set; }
}

public class SupportPhoneRequest
{
    public string Phone { get; set; } = string.Empty;
}
