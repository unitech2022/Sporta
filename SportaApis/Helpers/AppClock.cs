namespace SportaApis.Helpers;

/// <summary>
/// The app's wall-clock. Match/booking times are stored as naive local time
/// (the value the Saudi user picks on their device, KSA = UTC+3, no DST), so
/// any "how soon does this start" logic must compare against that same wall
/// clock — not the server's OS clock, which is UTC in production.
///
/// <see cref="OffsetHours"/> is set once at startup from configuration
/// (<c>App:TimeZoneOffsetHours</c>, default 3).
/// </summary>
public static class AppClock
{
    /// <summary>Hours to add to UTC to get the app's wall-clock. Default KSA (+3).</summary>
    public static int OffsetHours { get; set; } = 3;

    /// <summary>"Now" on the same wall clock the stored times use.</summary>
    public static DateTime Now => DateTime.UtcNow.AddHours(OffsetHours);
}
