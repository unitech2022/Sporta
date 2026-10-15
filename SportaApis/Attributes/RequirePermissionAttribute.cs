using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Attributes;

/// <summary>
/// يفرض امتلاك صلاحية محددة من <see cref="Helpers.Permissions"/> على الـ endpoint.
/// الأدمن يتجاوزها دائماً؛ الموظف يحتاج المفتاح مُسنَداً له، وإلا 403.
/// تُستخدم فوق <c>[Authorize(Roles = "admin,staff")]</c> على مستوى الكنترولر.
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false)]
public sealed class RequirePermissionAttribute : Attribute, IAsyncAuthorizationFilter
{
    private readonly string _permission;

    public RequirePermissionAttribute(string permission) => _permission = permission;

    public async Task OnAuthorizationAsync(AuthorizationFilterContext context)
    {
        var admin = context.HttpContext.RequestServices.GetRequiredService<IAdminContext>();

        if (await admin.HasPermissionAsync(_permission)) return;

        context.Result = new ObjectResult(ApiResponse<object>.Fail(
            $"Missing permission: {_permission}",
            "ليس لديك صلاحية لهذا الإجراء",
            "PERMISSION_DENIED"))
        {
            StatusCode = StatusCodes.Status403Forbidden,
        };
    }
}
