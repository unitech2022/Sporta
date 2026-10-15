using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.Enums;
using SportaApis.Helpers;

namespace SportaApis.Services;

/// <summary>
/// Background worker that pushes a "your match starts in 30 minutes" reminder
/// to every approved player, once per match. Runs on a one-minute tick and
/// stamps <see cref="Models.Match.ReminderSentAt"/> so a reminder is never
/// sent twice.
/// </summary>
public class MatchReminderService : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(1);

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<MatchReminderService> _logger;

    public MatchReminderService(
        IServiceScopeFactory scopeFactory, ILogger<MatchReminderService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval);
        do
        {
            try
            {
                await SendDueRemindersAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                // Never let a bad tick kill the loop.
                _logger.LogError(ex, "Match reminder tick failed");
            }
        }
        while (await timer.WaitForNextTickAsync(stoppingToken));
    }

    private async Task SendDueRemindersAsync(CancellationToken ct)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var notifications =
            scope.ServiceProvider.GetRequiredService<INotificationService>();

        var now = AppClock.Now;
        var windowEnd = now.AddMinutes(30);

        // Live matches kicking off within the next 30 minutes that we haven't
        // reminded about yet.
        var due = await db.Matches
            .Include(m => m.MatchPlayers)
            .Where(m => m.ReminderSentAt == null)
            .Where(m => m.Status == MatchStatus.Open
                     || m.Status == MatchStatus.Full
                     || m.Status == MatchStatus.InProgress)
            .Where(m => m.ScheduledAt > now && m.ScheduledAt <= windowEnd)
            .ToListAsync(ct);

        if (due.Count == 0) return;

        var sent = 0;
        foreach (var match in due)
        {
            // نختم المباراة ونحفظ قبل الإرسال: لو انفجر الإرسال في منتصف الدفعة
            // لا تُعاد التذكيرات في النبضة التالية لمن وصلته.
            match.ReminderSentAt = DateTime.UtcNow;
            await db.SaveChangesAsync(ct);
            sent++;

            var minutes = (int)Math.Round((match.ScheduledAt - now).TotalMinutes);
            var body = minutes <= 1
                ? "مباراتك على وشك أن تبدأ"
                : $"مباراتك تبدأ خلال {minutes} دقيقة";

            var recipients = match.MatchPlayers
                .Where(p => p.Status == MatchPlayerStatus.Approved)
                .Select(p => p.UserId)
                .Distinct();

            foreach (var userId in recipients)
                await notifications.PushAsync(
                    userId, "تذكير بموعد المباراة", body, "match_reminder", match.Id);
        }

        _logger.LogInformation("Sent reminders for {Count} match(es)", sent);
    }
}
