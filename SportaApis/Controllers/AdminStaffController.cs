using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.Attributes;
using SportaApis.DTOs;
using SportaApis.Helpers;
using SportaApis.Services;

namespace SportaApis.Controllers;

/// <summary>
/// إدارة موظفي لوحة التحكم وصلاحياتهم. الأدمن يملك كل شيء؛ الموظف يحتاج
/// صلاحيتَي staff.view / staff.manage.
/// </summary>
[ApiController]
[Route("api/admin")]
[Authorize(Roles = "admin,staff")]
public class AdminStaffController : ControllerBase
{
    private readonly IStaffService _staff;

    public AdminStaffController(IStaffService staff) => _staff = staff;

    // GET /api/admin/me/access — صلاحيات ونطاق المستخدم الحالي (بدون صلاحية خاصة)
    [HttpGet("me/access")]
    public async Task<IActionResult> MyAccess()
    {
        var access = await _staff.GetMyAccessAsync();
        return Ok(ApiResponse<MyAccessDto>.Ok(access));
    }

    // GET /api/admin/permissions — كتالوج الصلاحيات لشاشة إضافة موظف
    [HttpGet("permissions")]
    [RequirePermission(Permissions.StaffView)]
    public IActionResult Catalog() =>
        Ok(ApiResponse<List<PermissionGroupDto>>.Ok(_staff.GetPermissionCatalog()));

    // GET /api/admin/staff?search=&page=&pageSize=
    [HttpGet("staff")]
    [RequirePermission(Permissions.StaffView)]
    public async Task<IActionResult> List(
        [FromQuery] string? search, [FromQuery] int page = 1, [FromQuery] int pageSize = 15)
    {
        var items = await _staff.GetStaffAsync(search, page, pageSize);
        return Ok(ApiResponse<PagedResult<StaffDto>>.Ok(items));
    }

    // GET /api/admin/staff/{userId}
    [HttpGet("staff/{userId:int}")]
    [RequirePermission(Permissions.StaffView)]
    public async Task<IActionResult> Get(int userId)
    {
        var member = await _staff.GetStaffMemberAsync(userId);
        return member is null
            ? NotFound(ApiResponse<object>.Fail(
                "Staff not found", "الموظف غير موجود", "STAFF_NOT_FOUND"))
            : Ok(ApiResponse<StaffDto>.Ok(member));
    }

    // POST /api/admin/staff — إضافة موظف بنطاق وصلاحيات
    [HttpPost("staff")]
    [RequirePermission(Permissions.StaffManage)]
    public async Task<IActionResult> Create([FromBody] CreateStaffRequest request)
    {
        try
        {
            var created = await _staff.CreateStaffAsync(request, CurrentUserId());
            return Ok(ApiResponse<StaffDto>.Ok(created));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // PUT /api/admin/staff/{userId}
    [HttpPut("staff/{userId:int}")]
    [RequirePermission(Permissions.StaffManage)]
    public async Task<IActionResult> Update(int userId, [FromBody] UpdateStaffRequest request)
    {
        try
        {
            var updated = await _staff.UpdateStaffAsync(userId, request);
            return Ok(ApiResponse<StaffDto>.Ok(updated));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // PUT /api/admin/staff/{userId}/active  { active }
    [HttpPut("staff/{userId:int}/active")]
    [RequirePermission(Permissions.StaffManage)]
    public async Task<IActionResult> SetActive(
        int userId, [FromBody] SetStaffActiveRequest request)
    {
        if (userId == CurrentUserId())
            return BadRequest(ApiResponse<object>.Fail(
                "Cannot change your own account state",
                "لا يمكنك تغيير حالة حسابك",
                "SELF_STATE_CHANGE"));

        try
        {
            await _staff.SetStaffActiveAsync(userId, request.Active);
            return Ok(ApiResponse<object>.Ok(new { active = request.Active }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // DELETE /api/admin/staff/{userId} — حذف نهائي (صلاحية مستقلة عن التعديل)
    [HttpDelete("staff/{userId:int}")]
    [RequirePermission(Permissions.StaffDelete)]
    public async Task<IActionResult> Delete(int userId)
    {
        if (userId == CurrentUserId())
            return BadRequest(ApiResponse<object>.Fail(
                "Cannot delete your own account",
                "لا يمكنك حذف حسابك",
                "SELF_DELETE"));

        try
        {
            await _staff.DeleteStaffAsync(userId);
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    private int? CurrentUserId() =>
        int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : null;
}

public class SetStaffActiveRequest
{
    public bool Active { get; set; }
}
