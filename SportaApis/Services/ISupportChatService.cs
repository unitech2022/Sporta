using SportaApis.DTOs;

namespace SportaApis.Services;

/// <summary>
/// دردشة الدعم الفني بين حسابات التطبيق وفريق الإدارة. REST هو مصدر الحقيقة
/// (يحفظ ويُرقّم السجل)، وكل كتابة تُبَثّ أيضاً عبر
/// <see cref="Hubs.SupportChatHub"/> ليظهر السطر لدى الطرفين بلا تحديث يدوي.
/// </summary>
public interface ISupportChatService
{
    // ── جانب المستخدم ─────────────────────────────────────────────────────────

    /// <summary>محادثتي وأحدث صفحة من رسائلها (Exists=false لو لم أبدأ بعد).</summary>
    Task<SupportMessagePageDto> GetMineAsync(int userId, int? before, int limit);

    /// <summary>يرسل المستخدم سطراً — يُنشئ المحادثة أول مرة ويعيد فتحها لو أُغلقت.</summary>
    Task<SupportMessageDto> SendAsUserAsync(int userId, string body);

    /// <summary>فتح المستخدم للمحادثة ⇒ ردود الإدارة لم تعد غير مقروءة.</summary>
    Task MarkMineReadAsync(int userId);

    /// <summary>عدد ردود الإدارة غير المقروءة — لشارة العدّاد في التطبيق.</summary>
    Task<int> GetMyUnreadCountAsync(int userId);

    // ── جانب الإدارة ──────────────────────────────────────────────────────────

    /// <summary>قائمة المحادثات مرتّبة بالأحدث نشاطاً.</summary>
    Task<SupportInboxDto> GetInboxAsync(
        int page, int pageSize, string? search, string? status, bool unreadOnly);

    /// <summary>محادثة واحدة مع صفحة من رسائلها.</summary>
    Task<SupportMessagePageDto> GetConversationAsync(int conversationId, int? before, int limit);

    /// <summary>ردّ الإدارة على محادثة قائمة.</summary>
    Task<SupportMessageDto> ReplyAsAdminAsync(int conversationId, int adminUserId, string body);

    /// <summary>
    /// تبدأ الإدارة محادثة مع حساب محدد (أو تفتح القائمة إن وُجدت)، مع رسالة
    /// أولى اختيارية.
    /// </summary>
    Task<SupportConversationDto> StartConversationAsync(
        int targetUserId, int adminUserId, string? body);

    /// <summary>فتح الإدارة للمحادثة ⇒ رسائل المستخدم لم تعد غير مقروءة.</summary>
    Task MarkConversationReadAsync(int conversationId);

    /// <summary>إغلاق محادثة أو إعادة فتحها.</summary>
    Task<SupportConversationDto> SetStatusAsync(int conversationId, string status);
}
