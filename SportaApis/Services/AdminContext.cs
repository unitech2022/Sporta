using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.Helpers;

namespace SportaApis.Services;

/// <inheritdoc cref="IAdminContext"/>
public class AdminContext : IAdminContext
{
    private readonly AppDbContext _db;
    private readonly ClaimsPrincipal? _principal;

    // Loaded lazily once per request.
    private bool _loaded;
    private IReadOnlySet<string> _permissions = new HashSet<string>();
    private GeoScope? _scope;

    public AdminContext(AppDbContext db, IHttpContextAccessor accessor)
    {
        _db = db;
        _principal = accessor.HttpContext?.User;
    }

    public int? UserId =>
        int.TryParse(_principal?.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id)
            ? id : null;

    public bool IsAdmin => _principal?.IsInRole("admin") ?? false;

    public bool IsStaff => _principal?.IsInRole("staff") ?? false;

    public async Task<bool> HasPermissionAsync(string permission)
    {
        if (IsAdmin) return true;
        if (!IsStaff) return false;
        await LoadAsync();
        return _permissions.Contains(permission);
    }

    public async Task<IReadOnlySet<string>> GetPermissionsAsync()
    {
        if (IsAdmin) return Permissions.All;
        if (!IsStaff) return new HashSet<string>();
        await LoadAsync();
        return _permissions;
    }

    public async Task<GeoScope?> GetScopeAsync()
    {
        if (IsAdmin || !IsStaff) return null;
        await LoadAsync();
        return _scope;
    }

    private async Task LoadAsync()
    {
        if (_loaded) return;
        _loaded = true;

        if (UserId is not int uid) return;

        var profile = await _db.StaffProfiles
            .AsNoTracking()
            .Include(s => s.Permissions)
            .FirstOrDefaultAsync(s => s.UserId == uid);

        if (profile is null) return;

        _permissions = profile.Permissions.Select(p => p.Permission).ToHashSet();
        _scope = new GeoScope(profile.CountryId, profile.CityId);
    }
}
