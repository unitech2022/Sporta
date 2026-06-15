using SportaApis.Enums;

namespace SportaApis.Models;

public class User : BaseEntity
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public UserType UserType { get; set; }
    public Language PreferredLanguage { get; set; } = Language.Arabic;
    public Gender? Gender { get; set; }
    public string? Country { get; set; }
    public string? City { get; set; }
    public string? District { get; set; }
    public string? ProfileImageUrl { get; set; }
    public bool IsActive { get; set; } = true;

    /// <summary>The sport the user picked as their favorite (e.g. "padel").</summary>
    public string? FavoriteSport { get; set; }

    // Navigation
    public ICollection<UserRole> Roles { get; set; } = [];
    public ICollection<RefreshToken> RefreshTokens { get; set; } = [];
    public PlayerProfile? PlayerProfile { get; set; }
    public CoachProfile? CoachProfile { get; set; }
    public Wallet? Wallet { get; set; }
    public Subscription? Subscription { get; set; }
    public ICollection<Friendship> SentFriendRequests { get; set; } = [];
    public ICollection<Friendship> ReceivedFriendRequests { get; set; } = [];
    public ICollection<Notification> Notifications { get; set; } = [];
}
