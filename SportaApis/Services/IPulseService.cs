using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IPulseService
{
    /// <summary>
    /// نبض المجتمع الرياضي: أحدث أنشطة اللاعبين (مستويات، نقاط، مباريات تبحث عن
    /// لاعبين) مع بند مجمّع في آخر القائمة. أحداث المستخدم نفسه مستثناة.
    /// </summary>
    Task<List<PulseItemDto>> GetPulseAsync(int currentUserId);
}
