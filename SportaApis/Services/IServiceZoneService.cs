using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IServiceZoneService
{
    Task<List<ServiceZoneDto>> GetAllAsync();
    Task<ServiceZoneDto> CreateAsync(SaveServiceZoneRequest request);
    Task<ServiceZoneDto> UpdateAsync(int id, SaveServiceZoneRequest request);
    Task DeleteAsync(int id);

    /// <summary>فحص موقع المستخدم ضد المناطق المفعّلة.</summary>
    Task<ServiceZoneCheckDto> CheckAsync(double lat, double lng);

    Task<ServiceZoneMessageDto> GetMessageAsync();
    Task<ServiceZoneMessageDto> SaveMessageAsync(ServiceZoneMessageDto request);
}
