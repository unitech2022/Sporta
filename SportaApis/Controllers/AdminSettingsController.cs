using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.Attributes;
using SportaApis.DTOs;
using SportaApis.Helpers;
using SportaApis.Services;

namespace SportaApis.Controllers;

/// <summary>Admin CRUD for the generic system-settings key/value store.</summary>
[ApiController]
[Route("api/admin/settings")]
[Authorize(Roles = "admin,staff")]
public class AdminSettingsController : ControllerBase
{
    private readonly ISettingsService _settings;

    public AdminSettingsController(ISettingsService settings) => _settings = settings;

    // GET /api/admin/settings
    [HttpGet]
    [RequirePermission(Permissions.SettingsView)]
    public async Task<IActionResult> GetAll()
    {
        var items = await _settings.GetAllAsync();
        return Ok(ApiResponse<List<SettingDto>>.Ok(items));
    }

    // GET /api/admin/settings/policies — الوثائق القانونية فقط (صلاحية مستقلة)
    [HttpGet("policies")]
    [RequirePermission(Permissions.PoliciesView)]
    public async Task<IActionResult> GetPolicies()
    {
        var items = await _settings.GetPoliciesAsync();
        return Ok(ApiResponse<List<SettingDto>>.Ok(items));
    }

    // PUT /api/admin/settings/policies/{id} — تعديل نص سياسة
    [HttpPut("policies/{id:int}")]
    [RequirePermission(Permissions.PoliciesManage)]
    public async Task<IActionResult> UpdatePolicy(int id, [FromBody] SavePolicyRequest request)
    {
        try
        {
            var dto = await _settings.UpdatePolicyAsync(id, request);
            return Ok(ApiResponse<SettingDto>.Ok(dto));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // POST /api/admin/settings
    [HttpPost]
    [RequirePermission(Permissions.SettingsManage)]
    public async Task<IActionResult> Create([FromBody] SaveSettingRequest request)
    {
        try
        {
            var dto = await _settings.CreateAsync(request);
            return Ok(ApiResponse<SettingDto>.Ok(dto));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // PUT /api/admin/settings/{id}
    [HttpPut("{id:int}")]
    [RequirePermission(Permissions.SettingsManage)]
    public async Task<IActionResult> Update(int id, [FromBody] SaveSettingRequest request)
    {
        try
        {
            var dto = await _settings.UpdateAsync(id, request);
            return Ok(ApiResponse<SettingDto>.Ok(dto));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // DELETE /api/admin/settings/{id}
    [HttpDelete("{id:int}")]
    [RequirePermission(Permissions.SettingsManage)]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            await _settings.DeleteAsync(id);
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }
}
