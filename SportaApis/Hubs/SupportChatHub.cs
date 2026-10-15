using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.Helpers;

namespace SportaApis.Hubs;

/// <summary>
/// النقل الفوري لدردشة الدعم. مصدر الحقيقة يبقى REST في
/// <see cref="Controllers.SupportChatController"/> (هو من يحفظ السجل ويرقّم صفحاته)،
/// وهذا الـ hub يدفع ما حدث للتو إلى من هو متصل فقط:
///
///   • مجموعة "support-admins"     — كل إداري/موظف متصل (شاشة اللوحة)
///   • مجموعة "support-user-{id}"  — اتصالات مستخدم واحد (قد تكون عدة أجهزة)
///
/// أحداث العميل: MessageReceived, ConversationUpdated, ConversationRead, Typing.
/// </summary>
[Authorize]
public class SupportChatHub : Hub
{
    public const string AdminsGroup = "support-admins";

    public static string UserGroup(int userId) => $"support-user-{userId}";

    /// <summary>الأدوار التي تدير صندوق الدعم (نفس ما يفرضه الكنترولر).</summary>
    private static readonly string[] AdminRoles = ["admin", "staff"];

    private readonly AppDbContext _db;
    public SupportChatHub(AppDbContext db) => _db = db;

    private async Task<bool> CanViewSupportAsync(int userId)
    {
        if (Context.User?.IsInRole("admin") == true) return true;
        return await _db.StaffProfiles
            .Where(s => s.UserId == userId)
            .SelectMany(s => s.Permissions)
            .AnyAsync(p => p.Permission == Permissions.SupportView);
    }

    private int? UserId()
    {
        var raw = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
        return int.TryParse(raw, out var id) ? id : null;
    }

    /// <summary>
    /// الحساب قد يحمل أكثر من دور (لاعب + أدمن مثلاً)، لذا نفحص كل أدوار التوكن
    /// لا الأول فقط.
    /// </summary>
    private bool IsAdmin() =>
        Context.User?.FindAll(ClaimTypes.Role)
            .Any(c => AdminRoles.Contains(c.Value, StringComparer.OrdinalIgnoreCase)) == true;

    public override async Task OnConnectedAsync()
    {
        var uid = UserId();
        if (uid == null)
        {
            // لا هوية صالحة → لا شيء يمكن الاشتراك فيه. نُنهي الاتصال بدل ترك
            // وصلة لن تستقبل أي حدث.
            Context.Abort();
            return;
        }

        await Groups.AddToGroupAsync(Context.ConnectionId, UserGroup(uid.Value));
        // الموظف ينضم لصندوق الدعم فقط بصلاحية عرض الدعم — نفس ما يفرضه
        // الكنترولر، وإلا وصلته كل الرسائل حيّةً بلا صلاحية.
        if (IsAdmin() && await CanViewSupportAsync(uid.Value))
            await Groups.AddToGroupAsync(Context.ConnectionId, AdminsGroup);

        await base.OnConnectedAsync();
    }

    /// <summary>
    /// نبضة "يكتب الآن". الإداري يوجّهها لمستخدم محدد، ورسالة المستخدم تصل لكل
    /// صندوق الإدارة. لا يُحفظ منها شيء.
    /// </summary>
    public async Task Typing(int conversationId, int targetUserId)
    {
        var uid = UserId();
        if (uid == null) return;

        if (IsAdmin())
        {
            if (targetUserId > 0)
                await Clients.Group(UserGroup(targetUserId))
                    .SendAsync("Typing", new { conversationId, fromAdmin = true });
        }
        else
        {
            await Clients.Group(AdminsGroup)
                .SendAsync("Typing", new { conversationId, fromAdmin = false, userId = uid.Value });
        }
    }
}
