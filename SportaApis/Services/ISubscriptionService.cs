using SportaApis.DTOs;

namespace SportaApis.Services;

public interface ISubscriptionService
{
    Task<SubscriptionDto> GetAsync(int userId);

    /// <summary>Active packages a player can subscribe to.</summary>
    Task<List<PackageDto>> GetPackagesAsync(int userId);

    /// <summary>Subscribes to a package (charges the wallet its real price).
    /// Null packageId falls back to the default legacy package (Sporta Plus).</summary>
    Task<SubscriptionDto> SubscribeAsync(int userId, int? packageId);

/// <summary>Cancels Sporta Plus (back to Free).</summary>
    Task<SubscriptionDto> CancelAsync(int userId);
}
