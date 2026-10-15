using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

// ── Requests ──────────────────────────────────────────────────────────────────

public class SendFriendRequestRequest
{
    [Required] public int UserId { get; set; }
}

public class RespondFriendRequestRequest
{
    public bool Accept { get; set; }
}

public class ToggleFavoriteRequest
{
    public bool Favorite { get; set; }
}

// ── Responses ─────────────────────────────────────────────────────────────────

/// <summary>A player as shown in search / picker / friends lists.</summary>
public class PlayerSummaryDto
{
    public int UserId { get; set; }
    public string Name { get; set; } = string.Empty;

    /// <summary>الصورة الشخصية للاعب (من حساب المستخدم).</summary>
    public string? AvatarUrl { get; set; }

    public int? Level { get; set; }
    public string? City { get; set; }

    /// <summary>اسم المدينة بالإنجليزية (من جدول المدن) — null للمستخدمين غير المرتبطين بمدينة.</summary>
    public string? CityEn { get; set; }

    /// <summary>"player" | "coach".</summary>
    public string UserType { get; set; } = "player";

    /// <summary>"self" | "none" | "pending_sent" | "pending_received" | "friends".</summary>
    public string Relation { get; set; } = "none";

    /// <summary>Whether the current user follows this player.</summary>
    public bool IsFollowing { get; set; }

    /// <summary>Whether the current user marked this friend as a favorite partner.</summary>
    public bool IsFavorite { get; set; }
}

public class FriendRequestDto
{
    public int Id { get; set; }
    public int FromUserId { get; set; }
    public string FromName { get; set; } = string.Empty;

    /// <summary>الصورة الشخصية لمرسل الطلب.</summary>
    public string? AvatarUrl { get; set; }

    public int? Level { get; set; }
    public string? City { get; set; }

    /// <summary>اسم المدينة بالإنجليزية (من جدول المدن).</summary>
    public string? CityEn { get; set; }
}
