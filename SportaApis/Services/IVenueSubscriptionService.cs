using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IVenueSubscriptionService
{
    /// <summary>التسعيرة الحالية (تُنشأ بالقيم الافتراضية عند أول استدعاء).</summary>
    Task<VenueSubscriptionPricingDto> GetPricingAsync();

    Task<VenueSubscriptionPricingDto> SavePricingAsync(SaveVenueSubscriptionPricingRequest req);

    /// <summary>سعر الاشتراك لمالك مُعيّن بعدد ملاعبه الحالي، بعد أي خصم ساري.</summary>
    Task<VenueSubscriptionQuoteDto> QuoteAsync(int ownerId, bool yearly);

    /// <summary>اشتراك المالك الساري الآن (null حين لا اشتراك فعّال).</summary>
    Task<VenueSubscriptionDto?> GetCurrentAsync(int ownerId);

    /// <summary>يشتري اشتراكاً من محفظة المالك ويمدّد من نهاية الاشتراك القائم.</summary>
    Task<VenueSubscriptionDto> SubscribeAsync(int ownerId, bool yearly);

    /// <summary>كل الاشتراكات للوحة الأدمن.</summary>
    Task<PagedResult<VenueSubscriptionDto>> GetAllAsync(int page, int pageSize);
}
