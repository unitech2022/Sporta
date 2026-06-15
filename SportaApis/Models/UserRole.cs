using SportaApis.Enums;

namespace SportaApis.Models;

public class UserRole : BaseEntity
{
    public int UserId { get; set; }
    public UserType Role { get; set; }

    // Navigation
    public User User { get; set; } = null!;
}
