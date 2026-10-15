using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;

namespace SportaApis.Attributes;

/// <summary>
/// يمنع الوصول إلى مسارات دور لم يعتمده الأدمن بعد (المدرب/صاحب الملعب). صاحب
/// الحساب يبقى يستخدم التطبيق بدوره كلاعب، لكن مسارات الدور المعلّق تعيد 403
/// بالرمز <c>ROLE_PENDING_APPROVAL</c> حتى تتم المراجعة.
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false)]
public sealed class RequireApprovedRoleAttribute : Attribute, IAsyncAuthorizationFilter
{
    private readonly UserType _role;

    public RequireApprovedRoleAttribute(UserType role) => _role = role;

    public async Task OnAuthorizationAsync(AuthorizationFilterContext context)
    {
        var idClaim = context.HttpContext.User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idClaim, out var userId)) return; // [Authorize] يتكفّل بغير المصادَق.

        var db = context.HttpContext.RequestServices.GetRequiredService<AppDbContext>();
        var role = await db.UserRoles
            .Where(r => r.UserId == userId && r.Role == _role)
            .Select(r => new { r.IsApproved })
            .FirstOrDefaultAsync();

        // من لا يملك الدور أصلاً تتكفّل به فحوص الملكية داخل الخدمات كما كانت.
        if (role is null || role.IsApproved) return;

        context.Result = new ObjectResult(ApiResponse<object>.Fail(
            "Your account is pending admin approval",
            "حسابك قيد المراجعة من فريق سبورتا، سيتم إشعارك عند الانتهاء",
            "ROLE_PENDING_APPROVAL"))
        {
            StatusCode = StatusCodes.Status403Forbidden,
        };
    }
}
