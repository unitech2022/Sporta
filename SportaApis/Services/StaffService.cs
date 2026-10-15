using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

/// <summary>
/// إدارة موظفي لوحة التحكم: إنشاء الحساب، تحديد نطاقه (دولة + مدينة أو كل
/// المدن)، ومنح صلاحيات مفصّلة لكل عملية.
/// </summary>
public class StaffService : IStaffService
{
    private readonly AppDbContext _db;
    private readonly IAdminContext _admin;

    public StaffService(AppDbContext db, IAdminContext admin)
    {
        _db = db;
        _admin = admin;
    }

    public List<PermissionGroupDto> GetPermissionCatalog() =>
        Permissions.Catalog.Select(g => new PermissionGroupDto
        {
            Key = g.Key,
            Label = g.Label,
            Permissions = g.Permissions
                .Select(p => new PermissionItemDto { Key = p.Key, Label = p.Label })
                .ToList(),
        }).ToList();

    public async Task<MyAccessDto> GetMyAccessAsync()
    {
        var permissions = (await _admin.GetPermissionsAsync()).ToList();

        if (_admin.IsAdmin)
            return new MyAccessDto
            {
                Role = "admin",
                Permissions = permissions,
                AllCities = true,
            };

        var scope = await _admin.GetScopeAsync();
        if (scope is null)
            return new MyAccessDto { Role = "staff", Permissions = permissions };

        var country = await _db.Countries
            .Where(c => c.Id == scope.CountryId)
            .Select(c => c.NameAr)
            .FirstOrDefaultAsync();
        var city = scope.CityId is int cid
            ? await _db.Cities.Where(c => c.Id == cid).Select(c => c.NameAr).FirstOrDefaultAsync()
            : null;

        return new MyAccessDto
        {
            Role = "staff",
            Permissions = permissions,
            CountryId = scope.CountryId,
            CountryNameAr = country,
            CityId = scope.CityId,
            CityNameAr = city,
            AllCities = scope.AllCities,
        };
    }

    public async Task<PagedResult<StaffDto>> GetStaffAsync(string? search, int page, int pageSize)
    {
        (page, pageSize) = Paging.Clamp(page, pageSize);

        var query = _db.StaffProfiles
            .Include(s => s.User)
            .Include(s => s.Country)
            .Include(s => s.City)
            .Include(s => s.Permissions)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(p =>
                p.User.FirstName.Contains(s) || p.User.LastName.Contains(s) ||
                p.User.PhoneNumber.Contains(s) ||
                (p.User.Email != null && p.User.Email.Contains(s)));
        }

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(p => p.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<StaffDto>
        {
            Items = items.Select(ToDto).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    public async Task<StaffDto?> GetStaffMemberAsync(int userId)
    {
        var profile = await LoadAsync(userId);
        return profile is null ? null : ToDto(profile);
    }

    public async Task<StaffDto> CreateStaffAsync(CreateStaffRequest req, int? createdByUserId)
    {
        var phone = req.Phone.Trim();
        var email = req.Email.Trim();

        await ValidateScopeAsync(req.CountryId, req.CityId);
        var permissions = NormalizePermissions(req.Permissions);

        // مستخدم قائم يُرقّى موظفاً: يبقى حسابه ورقمه وأدواره في التطبيق كما
        // هي، ويُضاف إليها دور الموظف وكلمة سرّ يدخل بها اللوحة.
        var user = req.UserId is int existingId
            ? await PromoteExistingUserAsync(existingId, email, req)
            : null;

        if (user is null)
        {
            if (await _db.Users.AnyAsync(u => u.PhoneNumber == phone))
                throw new AuthException(
                    "Phone number already registered", "رقم الهاتف مسجل من قبل", "PHONE_EXISTS");
            if (await _db.Users.AnyAsync(u => u.Email == email))
                throw new AuthException(
                    "Email already registered", "البريد الإلكتروني مسجل من قبل", "EMAIL_EXISTS");

            user = new User
            {
                FirstName = req.FirstName.Trim(),
                LastName = req.LastName.Trim(),
                Email = email,
                PhoneNumber = phone,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password),
                UserType = UserType.Staff,
                IsActive = true,
            };
            _db.Users.Add(user);
        }

        await _db.SaveChangesAsync();

        // الدور قد يكون موجوداً محذوفاً ناعماً من ترقية سابقة، فيُحيا بدل صفٍّ
        // ثانٍ يصطدم بقيد التفرّد (UserId, Role).
        var staffRole = await _db.Set<UserRole>()
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(r => r.UserId == user.Id && r.Role == UserType.Staff);
        if (staffRole is null)
            _db.Set<UserRole>().Add(new UserRole { UserId = user.Id, Role = UserType.Staff });
        else
        {
            staffRole.IsDeleted = false;
            staffRole.DeletedAt = null;
            staffRole.IsApproved = true;
            staffRole.UpdatedAt = DateTime.UtcNow;
        }

        var profile = new StaffProfile
        {
            UserId = user.Id,
            CountryId = req.CountryId,
            CityId = req.CityId,
            JobTitle = string.IsNullOrWhiteSpace(req.JobTitle) ? null : req.JobTitle.Trim(),
            CreatedByUserId = createdByUserId,
            Permissions = permissions
                .Select(p => new StaffPermission { Permission = p })
                .ToList(),
        };
        _db.StaffProfiles.Add(profile);
        await _db.SaveChangesAsync();

        return ToDto((await LoadAsync(user.Id))!);
    }

    /// <summary>
    /// يجهّز مستخدماً قائماً ليصير موظفاً: يتحقق أنه صالح للترقية، ويحدّث اسمه
    /// وبريده، ويضع كلمة سرّ اللوحة، ويحوّل نوعه إلى موظف (وهو شرط الدخول
    /// بكلمة سر). أدواره في التطبيق لا تُمسّ، فيبقى لاعباً أو مدرباً كما كان.
    /// </summary>
    private async Task<User> PromoteExistingUserAsync(
        int userId, string email, CreateStaffRequest req)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException(
                "User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        if (user.IsDeleted)
            throw new AuthException(
                "This account has been deleted", "هذا الحساب محذوف", "ACCOUNT_DELETED");

        if (user.UserType == UserType.Admin)
            throw new AuthException(
                "Admin accounts cannot be converted to staff",
                "لا يمكن تحويل حساب أدمن إلى موظف", "ADMIN_USER");

        if (await _db.StaffProfiles.AnyAsync(p => p.UserId == userId))
            throw new AuthException(
                "This user is already a staff member",
                "هذا المستخدم موظف بالفعل", "STAFF_EXISTS");

        if (await _db.Users.AnyAsync(u => u.Email == email && u.Id != userId))
            throw new AuthException(
                "Email already registered", "البريد الإلكتروني مسجل من قبل", "EMAIL_EXISTS");

        user.FirstName = req.FirstName.Trim();
        user.LastName = req.LastName.Trim();
        user.Email = email;
        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password);
        user.UserType = UserType.Staff;
        user.IsActive = true;
        user.UpdatedAt = DateTime.UtcNow;

        return user;
    }

    public async Task<StaffDto> UpdateStaffAsync(int userId, UpdateStaffRequest req)
    {
        var profile = await LoadAsync(userId, tracked: true)
            ?? throw new AuthException("Staff not found", "الموظف غير موجود", "STAFF_NOT_FOUND");

        // موظف لا يعدّل نفسه (وإلا منح نفسه كل الصلاحيات ووسّع نطاقه)،
        // ولا يمنح غيره صلاحية لا يملكها هو، ولا يغيّر كلمة مرور زميل —
        // ذلك كله للأدمن.
        if (!_admin.IsAdmin)
        {
            if (_admin.UserId == userId)
                throw new AuthException(
                    "You cannot edit your own staff account",
                    "لا يمكنك تعديل حسابك الوظيفي بنفسك", "SELF_EDIT");
            var mine = await _admin.GetPermissionsAsync();
            var extra = NormalizePermissions(req.Permissions).Where(k => !mine.Contains(k)).ToList();
            if (extra.Count > 0)
                throw new AuthException(
                    "You cannot grant permissions you don't have",
                    "لا يمكنك منح صلاحيات لا تملكها", "PERMISSION_ESCALATION");
            if (!string.IsNullOrWhiteSpace(req.Password))
                throw new AuthException(
                    "Only an admin can reset a staff password",
                    "تغيير كلمة مرور موظف للأدمن فقط", "ADMIN_ONLY");
        }

        var email = req.Email.Trim();
        if (await _db.Users.AnyAsync(u => u.Email == email && u.Id != userId))
            throw new AuthException(
                "Email already registered", "البريد الإلكتروني مسجل من قبل", "EMAIL_EXISTS");

        await ValidateScopeAsync(req.CountryId, req.CityId);

        profile.User.FirstName = req.FirstName.Trim();
        profile.User.LastName = req.LastName.Trim();
        profile.User.Email = email;
        profile.User.IsActive = req.IsActive;
        profile.User.UpdatedAt = DateTime.UtcNow;
        if (!string.IsNullOrWhiteSpace(req.Password))
            profile.User.PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password);

        profile.CountryId = req.CountryId;
        profile.CityId = req.CityId;
        profile.JobTitle = string.IsNullOrWhiteSpace(req.JobTitle) ? null : req.JobTitle.Trim();
        profile.UpdatedAt = DateTime.UtcNow;

        // Replace the permission set with what was submitted.
        var wanted = NormalizePermissions(req.Permissions);
        var current = profile.Permissions.ToList();
        foreach (var p in current.Where(p => !wanted.Contains(p.Permission)))
            _db.StaffPermissions.Remove(p);
        var existing = current.Select(p => p.Permission).ToHashSet();
        foreach (var key in wanted.Where(k => !existing.Contains(k)))
            _db.StaffPermissions.Add(new StaffPermission
            {
                StaffProfileId = profile.Id,
                Permission = key,
            });

        await _db.SaveChangesAsync();
        return ToDto((await LoadAsync(userId))!);
    }

    public async Task SetStaffActiveAsync(int userId, bool active)
    {
        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.Id == userId && u.UserType == UserType.Staff)
            ?? throw new AuthException("Staff not found", "الموظف غير موجود", "STAFF_NOT_FOUND");

        user.IsActive = active;
        user.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
    }

    public async Task DeleteStaffAsync(int userId)
    {
        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.Id == userId && u.UserType == UserType.Staff)
            ?? throw new AuthException("Staff not found", "الموظف غير موجود", "STAFF_NOT_FOUND");

        // حساب الموظف مستخدِم عادي أيضاً، وقد يكون له نشاط في التطبيق. الحذف
        // يفشل عندئذ على مفاتيح أجنبية بقاعدة RESTRICT، فنكشف السبب مسبقاً
        // ونسمّيه للمستخدم بدل تركه أمام خطأ قاعدة بيانات غامض.
        var blockers = new List<string>();

        if (await _db.Bookings.AnyAsync(b => b.UserId == userId)) blockers.Add("حجوزات");
        if (await _db.Matches.AnyAsync(m => m.CreatorId == userId)) blockers.Add("مباريات أنشأها");
        if (await _db.MatchPlayers.AnyAsync(p => p.UserId == userId)) blockers.Add("مشاركات في مباريات");
        if (await _db.CoachSessions.AnyAsync(s => s.PlayerId == userId)) blockers.Add("جلسات تدريب");
        if (await _db.Venues.NotDeleted().AnyAsync(v => v.OwnerId == userId)) blockers.Add("أندية يملكها");
        if (await _db.Friendships.AnyAsync(f => f.SenderId == userId || f.ReceiverId == userId))
            blockers.Add("صداقات");
        if (await _db.Follows.AnyAsync(f => f.FollowerId == userId || f.FollowingId == userId))
            blockers.Add("متابعات");
        if (await _db.MatchRatings.AnyAsync(r => r.RaterId == userId || r.RatedUserId == userId))
            blockers.Add("تقييمات مباريات");

        if (blockers.Count > 0)
            throw new AuthException(
                $"Staff has related data: {string.Join(", ", blockers)}",
                $"لا يمكن حذف الموظف لارتباطه بـ: {string.Join("، ", blockers)}. " +
                "أوقِف الحساب بدلاً من حذفه حتى تبقى السجلات سليمة.",
                "STAFF_HAS_DATA");

        // الباقي يُحذف تلقائياً بـ CASCADE: ملف الموظف وصلاحياته، الأدوار،
        // المحفظة ومعاملاتها، الإشعارات، التوكنات، ومستفيدو الخصومات.
        _db.Users.Remove(user);
        await _db.SaveChangesAsync();
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private Task<StaffProfile?> LoadAsync(int userId, bool tracked = false)
    {
        var query = _db.StaffProfiles
            .Include(s => s.User)
            .Include(s => s.Country)
            .Include(s => s.City)
            .Include(s => s.Permissions)
            .AsQueryable();
        if (!tracked) query = query.AsNoTracking();
        return query.FirstOrDefaultAsync(s => s.UserId == userId);
    }

    /// <summary>يتحقق أن الدولة موجودة وأن المدينة (إن وُجدت) تتبعها.</summary>
    private async Task ValidateScopeAsync(int countryId, int? cityId)
    {
        if (!await _db.Countries.AnyAsync(c => c.Id == countryId))
            throw new AuthException("Country not found", "الدولة غير موجودة", "COUNTRY_NOT_FOUND");

        if (cityId is not int cid) return;

        var belongs = await _db.Cities.AnyAsync(c => c.Id == cid && c.CountryId == countryId);
        if (!belongs)
            throw new AuthException(
                "City does not belong to the selected country",
                "المدينة المختارة لا تتبع الدولة المحددة",
                "CITY_COUNTRY_MISMATCH");
    }

    /// <summary>يتجاهل المفاتيح المكررة ويرفض غير المعروفة.</summary>
    private static HashSet<string> NormalizePermissions(IEnumerable<string> keys)
    {
        var set = keys.Select(k => k.Trim()).Where(k => k.Length > 0).ToHashSet();
        var unknown = set.FirstOrDefault(k => !Permissions.IsValid(k));
        if (unknown is not null)
            throw new AuthException(
                $"Unknown permission: {unknown}", "صلاحية غير معروفة", "UNKNOWN_PERMISSION");
        return set;
    }

    private static StaffDto ToDto(StaffProfile p) => new()
    {
        UserId = p.UserId,
        FirstName = p.User.FirstName,
        LastName = p.User.LastName,
        PhoneNumber = p.User.PhoneNumber,
        Email = p.User.Email ?? string.Empty,
        JobTitle = p.JobTitle,
        IsActive = p.User.IsActive,
        CreatedAt = p.CreatedAt,
        CountryId = p.CountryId,
        CountryNameAr = p.Country?.NameAr ?? string.Empty,
        CityId = p.CityId,
        CityNameAr = p.City?.NameAr,
        Permissions = p.Permissions.Select(x => x.Permission).OrderBy(x => x).ToList(),
    };
}
