using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

/// <summary>
/// يحسم أي خصم يسري على رسم مُعيّن لمستخدم مُعيّن، ويدير الخصومات من اللوحة.
/// </summary>
public class DiscountService : IDiscountService
{
    private readonly AppDbContext _db;
    private readonly IAdminContext _admin;

    public DiscountService(AppDbContext db, IAdminContext admin)
    {
        _db = db;
        _admin = admin;
    }

    // ── Resolution (used by every fee calculation) ────────────────────────────

    public Task<decimal> GetPercentAsync(DiscountTarget target, int userId) =>
        ResolveAsync(target, userId, enroll: true);

    public Task<decimal> PeekPercentAsync(DiscountTarget target, int userId) =>
        ResolveAsync(target, userId, enroll: false);

    private async Task<decimal> ResolveAsync(DiscountTarget target, int userId, bool enroll)
    {
        var now = DateTime.UtcNow;

        var candidates = await _db.Discounts
            .Where(d => d.IsActive && d.Target == target)
            .Select(d => new
            {
                Discount = d,
                IsBeneficiary = d.Beneficiaries.Any(b => b.UserId == userId),
                BeneficiariesCount = d.Beneficiaries.Count,
            })
            .ToListAsync();

        // الخصومات المؤهلة لهذا المستخدم الآن. سقف «عدد الحجوزات» يستبعد
        // المستنفَد قبل الاختيار مهما كانت نافذته الزمنية.
        var eligible = new List<(Discount Discount, bool NeedsEnroll)>();
        foreach (var c in candidates)
        {
            var d = c.Discount;
            if (d.MaxUses is int maxUses && d.UsedCount >= maxUses) continue;
            var within = d.IsWithinWindow(now);

            // مستفيد مضموم سلفاً: يسري ما دام العرض قائماً، أو للأبد لو كان
            // العرض يمنح الخصم مدى الحياة.
            if (c.IsBeneficiary)
            {
                if (within || d.GrantsLifetime) eligible.Add((d, false));
                continue;
            }

            // غير مستفيد: الخصومات المخصصة لا تسري عليه إطلاقاً.
            if (!d.IsGeneral || !within) continue;

            // عرض «أول N مستفيد»: لا خصم بعد امتلاء سقف المستفيدين.
            if (d.MaxBeneficiaries is int cap)
            {
                if (c.BeneficiariesCount >= cap) continue;
                eligible.Add((d, true));
            }
            else
            {
                eligible.Add((d, false));
            }
        }

        // الأعلى نسبةً أولاً. عند العرض فقط نُظهر النسبة بلا حجز مقعد ولا عدّ
        // استخدام؛ وعند التحصيل نحجز المقعد ونستهلك استخداماً ذرّياً — وإن
        // خسرنا السباق على أيهما جرّبنا الخصم التالي.
        foreach (var (d, needsEnroll) in
                 eligible.OrderByDescending(e => e.Discount.Percent))
        {
            if (!enroll) return Math.Clamp(d.Percent, 0m, 100m);

            if (needsEnroll &&
                !await TryEnrollAsync(d.Id, userId, d.MaxBeneficiaries!.Value))
                continue;
            if (!await TryConsumeUseAsync(d)) continue;
            return Math.Clamp(d.Percent, 0m, 100m);
        }

        return 0m;
    }

    /// <summary>
    /// يستهلك استخداماً واحداً من سقف «عدد الحجوزات» ذرّياً — يفشل عند نفاد
    /// السقف في سباق متزامن. الخصومات بلا سقف يزيد عدّادها للإحصاء فقط.
    /// </summary>
    private async Task<bool> TryConsumeUseAsync(Discount d)
    {
        if (d.MaxUses is not int maxUses)
        {
            await _db.Discounts
                .Where(x => x.Id == d.Id)
                .ExecuteUpdateAsync(s =>
                    s.SetProperty(x => x.UsedCount, x => x.UsedCount + 1));
            return true;
        }

        var affected = await _db.Discounts
            .Where(x => x.Id == d.Id && x.UsedCount < maxUses)
            .ExecuteUpdateAsync(s =>
                s.SetProperty(x => x.UsedCount, x => x.UsedCount + 1));
        return affected > 0;
    }

    public async Task<decimal> ApplyAsync(DiscountTarget target, int userId, decimal fee)
    {
        if (fee <= 0) return fee;
        var percent = await GetPercentAsync(target, userId);
        return percent <= 0 ? fee : Math.Round(fee * (1m - percent / 100m), 2);
    }

    /// <summary>
    /// يضمّ مستفيداً ضمن سقف العرض. يُعيد العدّ داخل المعاملة قبل الإضافة، وأي
    /// تسابق يخسر عند فهرس (DiscountId, UserId) الفريد فيُعامَل كضمّ ناجح سابق.
    /// </summary>
    private async Task<bool> TryEnrollAsync(int discountId, int userId, int cap)
    {
        var row = new DiscountBeneficiary
        {
            DiscountId = discountId,
            UserId = userId,
            AutoEnrolled = true,
        };
        try
        {
            var count = await _db.DiscountBeneficiaries.CountAsync(b => b.DiscountId == discountId);
            if (count >= cap) return false;

            _db.DiscountBeneficiaries.Add(row);
            await _db.SaveChangesAsync();
            return true;
        }
        catch (DbUpdateException)
        {
            // ضُمّ بالفعل عبر طلب متزامن — الخصم يسري عليه. يُفصل الصف الفاشل
            // حتى لا يُعاد حفظه (ويفشل) مع حفظ المستدعي التالي.
            _db.Entry(row).State = EntityState.Detached;
            return true;
        }
    }

    // ── Admin ────────────────────────────────────────────────────────────────

    public async Task<List<DiscountDto>> GetAllAsync()
    {
        var items = await _db.Discounts
            .Include(d => d.Beneficiaries)
            .OrderByDescending(d => d.Id)
            .ToListAsync();
        return items.Select(ToDto).ToList();
    }

    public async Task<DiscountDto?> GetAsync(int id)
    {
        var d = await _db.Discounts
            .Include(x => x.Beneficiaries)
            .FirstOrDefaultAsync(x => x.Id == id);
        return d is null ? null : ToDto(d);
    }

    public async Task<DiscountDto> CreateAsync(SaveDiscountRequest req)
    {
        var discount = new Discount();
        Apply(discount, req);
        _db.Discounts.Add(discount);
        await _db.SaveChangesAsync();
        return ToDto(discount);
    }

    public async Task<DiscountDto> UpdateAsync(int id, SaveDiscountRequest req)
    {
        var discount = await _db.Discounts
            .Include(d => d.Beneficiaries)
            .FirstOrDefaultAsync(d => d.Id == id)
            ?? throw new AuthException("Discount not found", "الخصم غير موجود", "DISCOUNT_NOT_FOUND");

        Apply(discount, req);
        discount.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return ToDto(discount);
    }

    public async Task DeleteAsync(int id)
    {
        var discount = await _db.Discounts.FirstOrDefaultAsync(d => d.Id == id)
            ?? throw new AuthException("Discount not found", "الخصم غير موجود", "DISCOUNT_NOT_FOUND");
        _db.Discounts.Remove(discount); // beneficiaries cascade
        await _db.SaveChangesAsync();
    }

    public async Task<List<DiscountUserOptionDto>> SearchUsersAsync(
        string? search, DiscountTarget target)
    {
        // نرشّح حسب الرسم المستهدَف: خصم عمولة الملاعب لا معنى له إلا لمالك ملعب.
        var role = target switch
        {
            DiscountTarget.VenueCommission or DiscountTarget.VenueSubscription
                => (UserType?)UserType.VenueOwner,
            DiscountTarget.CoachCommission => UserType.Coach,
            DiscountTarget.PlayerSubscription => UserType.Player,
            _ => null,
        };

        var query = _db.Users
            .Include(u => u.Roles)
            .InScope(await _admin.GetScopeAsync())
            .AsQueryable();

        if (role is UserType rt)
            query = query.Where(u => u.Roles.Any(r => r.Role == rt));

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(u =>
                u.FirstName.Contains(s) || u.LastName.Contains(s) ||
                u.PhoneNumber.Contains(s));
        }

        var users = await query
            .OrderBy(u => u.FirstName)
            .Take(15)
            .ToListAsync();

        return users.Select(u => new DiscountUserOptionDto
        {
            Id = u.Id,
            Name = $"{u.FirstName} {u.LastName}".Trim(),
            PhoneNumber = u.PhoneNumber,
            RoleLabel = RoleLabel(u, role),
        }).ToList();
    }

    /// <summary>
    /// وسم الدور المقصود بالرسم — لا الدور «الأعلى». مستخدم يملك ملعباً ويدرّب
    /// يظهر «مدرب» في بحث عمولة المدربين و«مالك ملعب» في بحث عمولة الملاعب.
    /// </summary>
    private static string RoleLabel(User u, UserType? target)
    {
        if (target is UserType t)
            return t switch
            {
                UserType.VenueOwner => "ملعب",
                UserType.Coach => "مدرب",
                _ => "لاعب",
            };

        var roles = u.Roles.Select(r => r.Role).ToHashSet();
        if (roles.Contains(UserType.VenueOwner)) return "ملعب";
        if (roles.Contains(UserType.Coach)) return "مدرب";
        if (roles.Contains(UserType.Admin)) return "مشرف";
        if (roles.Contains(UserType.Staff)) return "موظف";
        return "لاعب";
    }

    public async Task<List<DiscountBeneficiaryDto>> GetBeneficiariesAsync(int discountId)
    {
        return await _db.DiscountBeneficiaries
            .Where(b => b.DiscountId == discountId)
            .OrderBy(b => b.Id)
            .Select(b => new DiscountBeneficiaryDto
            {
                UserId = b.UserId,
                Name = (b.User.FirstName + " " + b.User.LastName).Trim(),
                PhoneNumber = b.User.PhoneNumber,
                AutoEnrolled = b.AutoEnrolled,
                GrantedAt = b.CreatedAt,
            })
            .ToListAsync();
    }

    public async Task<DiscountBeneficiaryDto> AddBeneficiaryAsync(int discountId, int userId)
    {
        if (!await _db.Discounts.AnyAsync(d => d.Id == discountId))
            throw new AuthException("Discount not found", "الخصم غير موجود", "DISCOUNT_NOT_FOUND");

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        if (await _db.DiscountBeneficiaries.AnyAsync(b => b.DiscountId == discountId && b.UserId == userId))
            throw new AuthException(
                "Already a beneficiary", "المستخدم مستفيد من هذا الخصم مسبقاً", "ALREADY_BENEFICIARY");

        var beneficiary = new DiscountBeneficiary
        {
            DiscountId = discountId,
            UserId = userId,
            AutoEnrolled = false,
        };
        _db.DiscountBeneficiaries.Add(beneficiary);
        await _db.SaveChangesAsync();

        return new DiscountBeneficiaryDto
        {
            UserId = userId,
            Name = $"{user.FirstName} {user.LastName}".Trim(),
            PhoneNumber = user.PhoneNumber,
            AutoEnrolled = false,
            GrantedAt = beneficiary.CreatedAt,
        };
    }

    public async Task RemoveBeneficiaryAsync(int discountId, int userId)
    {
        var beneficiary = await _db.DiscountBeneficiaries
            .FirstOrDefaultAsync(b => b.DiscountId == discountId && b.UserId == userId)
            ?? throw new AuthException(
                "Beneficiary not found", "المستفيد غير موجود", "BENEFICIARY_NOT_FOUND");

        _db.DiscountBeneficiaries.Remove(beneficiary);
        await _db.SaveChangesAsync();
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private static void Apply(Discount d, SaveDiscountRequest req)
    {
        d.NameAr = req.NameAr.Trim();
        d.DescriptionAr = string.IsNullOrWhiteSpace(req.DescriptionAr) ? null : req.DescriptionAr.Trim();
        d.Target = ParseTarget(req.Target);
        d.Percent = Math.Clamp(req.Percent, 0.01m, 100m);
        d.IsGeneral = req.IsGeneral;
        d.StartsAt = req.StartsAt;
        d.EndsAt = req.EndsAt;
        // السقف لا معنى له في الخصم المخصص — المستفيدون فيه مُضافون يدوياً.
        d.MaxBeneficiaries = req.IsGeneral ? req.MaxBeneficiaries : null;
        d.MaxUses = req.MaxUses;
        d.GrantsLifetime = req.GrantsLifetime;
        d.IsActive = req.IsActive;
    }

    public static DiscountTarget ParseTarget(string target) => target.ToLowerInvariant() switch
    {
        "venuecommission" => DiscountTarget.VenueCommission,
        "coachcommission" => DiscountTarget.CoachCommission,
        "venuesubscription" => DiscountTarget.VenueSubscription,
        "playersubscription" => DiscountTarget.PlayerSubscription,
        "playerbooking" => DiscountTarget.PlayerBooking,
        _ => throw new AuthException(
            $"Unknown discount target: {target}", "نوع الرسم غير معروف", "UNKNOWN_TARGET"),
    };

    private static string TargetToString(DiscountTarget target) =>
        char.ToLowerInvariant(target.ToString()[0]) + target.ToString()[1..];

    private static DiscountDto ToDto(Discount d)
    {
        var count = d.Beneficiaries.Count;
        return new DiscountDto
        {
            Id = d.Id,
            NameAr = d.NameAr,
            DescriptionAr = d.DescriptionAr,
            Target = TargetToString(d.Target),
            Percent = d.Percent,
            IsGeneral = d.IsGeneral,
            StartsAt = d.StartsAt,
            EndsAt = d.EndsAt,
            MaxBeneficiaries = d.MaxBeneficiaries,
            MaxUses = d.MaxUses,
            UsedCount = d.UsedCount,
            RemainingUses = d.MaxUses is int mu ? Math.Max(0, mu - d.UsedCount) : null,
            GrantsLifetime = d.GrantsLifetime,
            IsActive = d.IsActive,
            BeneficiariesCount = count,
            RemainingSlots = d.MaxBeneficiaries is int cap ? Math.Max(0, cap - count) : null,
            IsRunning = d.IsActive && d.IsWithinWindow(DateTime.UtcNow) &&
                        (d.MaxUses is not int cap2 || d.UsedCount < cap2),
        };
    }
}
