using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.Attributes;
using SportaApis.DTOs;
using SportaApis.Helpers;
using SportaApis.Services;

namespace SportaApis.Controllers;

/// <summary>
/// دردشة الدعم الفني: أي حساب في التطبيق ⇄ فريق الإدارة في اللوحة.
///
/// REST هو مصدر الحقيقة — يحفظ كل سطر ويُرقّم السجل (بمؤشّر تنازلي على المعرّف)،
/// وكل كتابة تُبَثّ عبر <see cref="Hubs.SupportChatHub"/> ليظهر السطر لدى
/// الطرفين فوراً. لو تعذّر البثّ يبقى السجل سليماً ويلتقطه العميل عند التحميل.
/// </summary>
[ApiController]
[Route("api/support-chat")]
[Authorize]
public class SupportChatController : ControllerBase
{
    private readonly ISupportChatService _chat;

    public SupportChatController(ISupportChatService chat) => _chat = chat;

    private int CurrentUserId() =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    // ══ جانب المستخدم (التطبيق) ═══════════════════════════════════════════════

    // GET /api/support-chat/mine
    /// <summary>محادثتي وأحدث صفحة من رسائلها. Exists=false ⇒ لم تبدأ محادثة بعد.</summary>
    [HttpGet("mine")]
    public async Task<IActionResult> Mine([FromQuery] int? before, [FromQuery] int limit = 30)
    {
        var page = await _chat.GetMineAsync(CurrentUserId(), before, limit);
        return Ok(ApiResponse<SupportMessagePageDto>.Ok(page));
    }

    // POST /api/support-chat/mine/messages
    [HttpPost("mine/messages")]
    public async Task<IActionResult> SendAsUser([FromBody] SendSupportMessageRequest request)
    {
        try
        {
            var msg = await _chat.SendAsUserAsync(CurrentUserId(), request.Body);
            return Ok(ApiResponse<SupportMessageDto>.Ok(msg));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // POST /api/support-chat/mine/read
    [HttpPost("mine/read")]
    public async Task<IActionResult> MarkMineRead()
    {
        await _chat.MarkMineReadAsync(CurrentUserId());
        return Ok(ApiResponse<object>.Ok(new { ok = true }));
    }

    // GET /api/support-chat/mine/unread-count — شارة العدّاد في التطبيق
    [HttpGet("mine/unread-count")]
    public async Task<IActionResult> MyUnreadCount()
    {
        var count = await _chat.GetMyUnreadCountAsync(CurrentUserId());
        return Ok(ApiResponse<UnreadCountDto>.Ok(new UnreadCountDto { Count = count }));
    }

    // ══ جانب الإدارة (اللوحة) ═════════════════════════════════════════════════

    // GET /api/support-chat/conversations
    [HttpGet("conversations")]
    [Authorize(Roles = "admin,staff")]
    [RequirePermission(Permissions.SupportView)]
    public async Task<IActionResult> Conversations(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null,
        [FromQuery] string? status = null,
        [FromQuery] bool unreadOnly = false)
    {
        var inbox = await _chat.GetInboxAsync(page, pageSize, search, status, unreadOnly);
        return Ok(ApiResponse<SupportInboxDto>.Ok(inbox));
    }

    // GET /api/support-chat/conversations/{id}/messages
    [HttpGet("conversations/{id:int}/messages")]
    [Authorize(Roles = "admin,staff")]
    [RequirePermission(Permissions.SupportView)]
    public async Task<IActionResult> ConversationMessages(
        int id, [FromQuery] int? before, [FromQuery] int limit = 30)
    {
        try
        {
            var page = await _chat.GetConversationAsync(id, before, limit);
            return Ok(ApiResponse<SupportMessagePageDto>.Ok(page));
        }
        catch (AuthException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // POST /api/support-chat/conversations/{id}/messages
    [HttpPost("conversations/{id:int}/messages")]
    [Authorize(Roles = "admin,staff")]
    [RequirePermission(Permissions.SupportReply)]
    public async Task<IActionResult> ReplyAsAdmin(
        int id, [FromBody] SendSupportMessageRequest request)
    {
        try
        {
            var msg = await _chat.ReplyAsAdminAsync(id, CurrentUserId(), request.Body);
            return Ok(ApiResponse<SupportMessageDto>.Ok(msg));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // POST /api/support-chat/conversations — تبدأ الإدارة محادثة مع حساب محدد
    [HttpPost("conversations")]
    [Authorize(Roles = "admin,staff")]
    [RequirePermission(Permissions.SupportReply)]
    public async Task<IActionResult> StartConversation(
        [FromBody] StartSupportConversationRequest request)
    {
        try
        {
            var conv = await _chat.StartConversationAsync(
                request.UserId, CurrentUserId(), request.Body);
            return Ok(ApiResponse<SupportConversationDto>.Ok(conv));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // POST /api/support-chat/conversations/{id}/read
    [HttpPost("conversations/{id:int}/read")]
    [Authorize(Roles = "admin,staff")]
    [RequirePermission(Permissions.SupportView)]
    public async Task<IActionResult> MarkConversationRead(int id)
    {
        try
        {
            await _chat.MarkConversationReadAsync(id);
            return Ok(ApiResponse<object>.Ok(new { ok = true }));
        }
        catch (AuthException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // POST /api/support-chat/conversations/{id}/status?status=Closed|Open
    [HttpPost("conversations/{id:int}/status")]
    [Authorize(Roles = "admin,staff")]
    [RequirePermission(Permissions.SupportReply)]
    public async Task<IActionResult> SetStatus(int id, [FromQuery] string status)
    {
        try
        {
            var conv = await _chat.SetStatusAsync(id, status);
            return Ok(ApiResponse<SupportConversationDto>.Ok(conv));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }
}
