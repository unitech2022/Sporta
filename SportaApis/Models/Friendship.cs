using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// طلبات الصداقة بين اللاعبين (3.4 + 2.12)
/// </summary>
public class Friendship : BaseEntity
{
    public int SenderId { get; set; }
    public User Sender { get; set; } = null!;

    public int ReceiverId { get; set; }
    public User Receiver { get; set; } = null!;

    public FriendshipStatus Status { get; set; } = FriendshipStatus.Pending;
    public DateTime? RespondedAt { get; set; }
}
