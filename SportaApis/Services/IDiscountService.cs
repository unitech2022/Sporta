using SportaApis.DTOs;
using SportaApis.Enums;

namespace SportaApis.Services;

public interface IDiscountService
{
    /// <summary>
    /// نسبة الخصم السارية (٠..١٠٠) على رسم مُعيّن لمستخدم مُعيّن. تُطبَّق على
    /// قيمة الرسم لا على السعر: خصم ٥٠٪ على عمولة ٥٪ يجعلها ٢٫٥٪.
    ///
    /// **تحجز مقعداً** للمستخدم في العروض ذات السقف («أول ١٠ ملاعب»)، فلا
    /// تُستدعى إلا عند تحصيل الرسم فعلياً — لا عند مجرد عرض السعر.
    /// </summary>
    Task<decimal> GetPercentAsync(DiscountTarget target, int userId);

    /// <summary>
    /// نفس الحساب لكن **بلا حجز مقعد** — لعرض السعر في الواجهات. يُظهر نسبة
    /// العرض ذي السقف ما دام فيه متسع، دون أن يستهلك المقعد بمجرد النظر.
    /// </summary>
    Task<decimal> PeekPercentAsync(DiscountTarget target, int userId);

    /// <summary>يطبّق الخصم الساري على قيمة رسم ويعيد الرسم بعد الخصم.</summary>
    Task<decimal> ApplyAsync(DiscountTarget target, int userId, decimal fee);

    // ── Admin ────────────────────────────────────────────────────────────────

    Task<List<DiscountDto>> GetAllAsync();
    Task<DiscountDto?> GetAsync(int id);
    Task<DiscountDto> CreateAsync(SaveDiscountRequest req);
    Task<DiscountDto> UpdateAsync(int id, SaveDiscountRequest req);
    Task DeleteAsync(int id);

    /// <summary>
    /// بحث عن مستخدمين لإضافتهم كمستفيدين. يُقيَّد بنطاق الموظف الجغرافي،
    /// ويُتاح بصلاحية الخصومات وحدها دون الحاجة لصلاحية عرض المستخدمين.
    /// </summary>
    Task<List<DiscountUserOptionDto>> SearchUsersAsync(string? search, DiscountTarget target);

    Task<List<DiscountBeneficiaryDto>> GetBeneficiariesAsync(int discountId);
    Task<DiscountBeneficiaryDto> AddBeneficiaryAsync(int discountId, int userId);
    Task RemoveBeneficiaryAsync(int discountId, int userId);
}
