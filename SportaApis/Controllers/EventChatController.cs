using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

/// <summary>
/// دردشة أعضاء الحدث بمعرّف المباراة الأساسية (الأمريكانو والبطولة يحملان
/// <c>matchId</c>). البثّ الفوري عبر <c>/hubs/event-chat</c>.
/// </summary>
[ApiController]
[Route("api/event-chat/{matchId:int}")]
[Authorize]
public class EventChatController : ControllerBase
{
    private readonly IEventChatService _chat;
    private readonly IWebHostEnvironment _env;

    public EventChatController(IEventChatService chat, IWebHostEnvironment env)
    {
        _chat = chat;
        _env = env;
    }

    /// <summary>الحد الأقصى لحجم المرفق.</summary>
    private const long MaxAttachmentBytes = 10 * 1024 * 1024;

    private static readonly HashSet<string> ImageExts = [".jpg", ".jpeg", ".png", ".webp", ".heic"];
    private static readonly HashSet<string> FileExts =
        [".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx", ".txt", ".csv"];

    private int CurrentUserId =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    // GET /api/event-chat/{matchId} — الرأس: الأعضاء، الكتابة، غير المقروء
    [HttpGet]
    public Task<IActionResult> Summary(int matchId) =>
        Run(() => _chat.GetSummaryAsync(CurrentUserId, matchId));

    // GET /api/event-chat/{matchId}/messages?beforeId=&limit=
    [HttpGet("messages")]
    public Task<IActionResult> Messages(int matchId, [FromQuery] int? beforeId, [FromQuery] int limit = 30) =>
        Run(() => _chat.GetMessagesAsync(CurrentUserId, matchId, beforeId, limit));

    // POST /api/event-chat/{matchId}/messages { body }
    [HttpPost("messages")]
    public Task<IActionResult> Send(int matchId, [FromBody] SendEventChatMessageRequest request) =>
        Run(() => _chat.SendAsync(CurrentUserId, matchId, request));

    // POST /api/event-chat/{matchId}/attachments  (multipart "file") — صورة أو ملف حتى 10 م.ب
    [HttpPost("attachments")]
    [RequestSizeLimit(MaxAttachmentBytes + 1024 * 1024)]
    public async Task<IActionResult> Upload(int matchId, IFormFile? file)
    {
        if (!await _chat.IsMemberAsync(CurrentUserId, matchId))
            return BadRequest(ApiResponse<object>.Fail(
                "Only members can upload", "الدردشة لأعضاء الحدث فقط", "CHAT_NOT_MEMBER"));
        if (file is null || file.Length == 0)
            return BadRequest(ApiResponse<object>.Fail("No file uploaded", "لم يتم رفع أي ملف", "NO_FILE"));
        if (file.Length > MaxAttachmentBytes)
            return BadRequest(ApiResponse<object>.Fail(
                "File too large (max 10MB)", "حجم الملف كبير (الحد 10 ميجا)", "FILE_TOO_LARGE"));

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        var isImage = ImageExts.Contains(ext);
        if (!isImage && !FileExts.Contains(ext))
            return BadRequest(ApiResponse<object>.Fail(
                "Unsupported file type", "نوع ملف غير مدعوم", "BAD_FILE_TYPE"));

        var root = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
        var dir = Path.Combine(root, "uploads", "chat");
        Directory.CreateDirectory(dir);
        var stored = $"{Guid.NewGuid():N}{ext}";
        await using (var stream = System.IO.File.Create(Path.Combine(dir, stored)))
            await file.CopyToAsync(stream);

        return Ok(ApiResponse<EventChatAttachmentDto>.Ok(new EventChatAttachmentDto
        {
            Url = $"{EventChatService.AttachmentsUrlPrefix}{stored}",
            Name = Path.GetFileName(file.FileName),
            Type = isImage ? "image" : "file",
            Size = file.Length,
        }));
    }

    // POST /api/event-chat/{matchId}/messages/{id}/reaction { emoji } — فارغ يزيل التفاعل
    [HttpPost("messages/{id:int}/reaction")]
    public Task<IActionResult> React(int matchId, int id, [FromBody] EventChatReactRequest request) =>
        Run(() => _chat.ReactAsync(CurrentUserId, matchId, id, request.Emoji));

    // DELETE /api/event-chat/{matchId}/messages/{id}
    [HttpDelete("messages/{id:int}")]
    public Task<IActionResult> Delete(int matchId, int id) =>
        Run(async () => { await _chat.DeleteAsync(CurrentUserId, matchId, id); return true; });

    // POST /api/event-chat/{matchId}/read
    [HttpPost("read")]
    public Task<IActionResult> Read(int matchId) =>
        Run(async () => { await _chat.MarkReadAsync(CurrentUserId, matchId); return true; });

    private async Task<IActionResult> Run<T>(Func<Task<T>> action)
    {
        try
        {
            return Ok(ApiResponse<T>.Ok(await action()));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }
}
