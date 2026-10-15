namespace SportaApis.Services;

public interface IPushSender
{
    /// <summary>
    /// Sends a push notification to a user (by their app id used as the
    /// OneSignal external id). Best-effort: never throws.
    /// </summary>
    Task SendAsync(int userId, string title, string body, string? type, int? referenceId);

    /// <summary>
    /// Sends a push notification to all subscribed devices (broadcast).
    /// Best-effort: never throws.
    /// </summary>
    Task BroadcastAsync(string title, string body, string? type, int? referenceId);
}
