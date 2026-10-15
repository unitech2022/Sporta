using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using SportaApis.Services;

namespace SportaApis.Hubs;

/// <summary>
/// النقل الفوري لدردشة الأحداث. REST في <see cref="Controllers.EventChatController"/>
/// مصدر الحقيقة؛ هذا الـ hub يدفع الجديد لمن فتح الدردشة. العميل ينادي
/// <see cref="Watch"/> عند فتح الشاشة فيُضاف لمجموعة الحدث بعد التحقق من عضويته.
///
/// أحداث العميل: MessageReceived (رسالة)، MessageDeleted { matchId, id }،
/// ReactionsUpdated { matchId, id, reactions }.
/// </summary>
[Authorize]
public class EventChatHub : Hub
{
    private readonly IEventChatService _chat;

    public EventChatHub(IEventChatService chat) => _chat = chat;

    public static string Group(int matchId) => $"event-chat-{matchId}";

    private int UserId() =>
        int.TryParse(Context.User?.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    /// <summary>يشترك في بثّ دردشة حدث — للأعضاء فقط.</summary>
    public async Task<bool> Watch(int matchId)
    {
        if (!await _chat.IsMemberAsync(UserId(), matchId)) return false;
        await Groups.AddToGroupAsync(Context.ConnectionId, Group(matchId));
        return true;
    }

    public Task Unwatch(int matchId) =>
        Groups.RemoveFromGroupAsync(Context.ConnectionId, Group(matchId));
}
