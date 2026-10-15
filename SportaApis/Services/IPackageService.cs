using SportaApis.DTOs;
using SportaApis.Models;

namespace SportaApis.Services;

public interface IPackageService
{
    /// <summary>Active packages, ordered by sort order — for player-facing selection.</summary>
    Task<List<PackageDto>> GetActiveAsync();

    // Admin management (includes inactive, with real subscriber counts).
    Task<List<PackageDto>> GetAllAsync();
    Task<PackageDto> CreateAsync(SavePackageRequest req);
    Task<PackageDto> UpdateAsync(int id, SavePackageRequest req);
    Task DeleteAsync(int id);

    /// <summary>Resolves a package by id (must be active), or the default legacy
    /// package (Key == PackageService.DefaultKey) when <paramref name="packageId"/> is null.</summary>
    Task<Package> ResolveForSubscribeAsync(int? packageId);
}
