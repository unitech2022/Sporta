using SportaApis.DTOs;
using SportaApis.Enums;

namespace SportaApis.Services;

public interface IEventInviteService
{
    /// <summary>يدعو أصدقاء إلى حدث؛ يتخطّى من لا تصلح دعوته ويذكر السبب.</summary>
    Task<SendEventInviteResultDto> SendAsync(int senderId, SendEventInviteRequest req);

    /// <summary>أحدث دعوة للمستخدم إلى هذا الحدث (لبطاقة الدعوة في صفحة الحدث).</summary>
    Task<EventInviteDto?> GetMineForTargetAsync(int userId, string kind, int targetId);

    /// <summary>الدعوات الواردة السارية.</summary>
    Task<List<EventInviteDto>> GetReceivedAsync(int userId);

    Task<EventInviteDto> DeclineAsync(int userId, int inviteId);

    /// <summary>انضم المستخدم إلى الحدث: تُعلَّم دعواته إليه مقبولة ويُبلَّغ من دعاه.</summary>
    Task MarkJoinedAsync(int userId, EventInviteKind kind, int targetId);

    /// <summary>للمستخدم دعوة سارية من <paramref name="senderId"/> إلى هذا الحدث.</summary>
    Task<bool> HasActiveInviteFromAsync(int senderId, int userId, EventInviteKind kind, int targetId);
}
