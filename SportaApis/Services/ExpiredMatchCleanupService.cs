
namespace SportaApis.Services;

/// <summary>
/// عامل خلفي يلغي المباريات والأمريكانو التي لم يكتمل عددها ويقترب موعدها،
/// ويعيد ما دفعه اللاعبون إلى محافظهم. المهلة تُضبط من لوحة التحكم
/// (<c>match_autocancel_hours_before</c>) وتُقرأ كل نبضة، فتغييرها يسري بلا
/// إعادة تشغيل. يعمل على نبضة كل خمس دقائق — الدقة بالدقيقة لا تلزم هنا،
/// والمهم ألّا تتراكم.
/// </summary>
public class ExpiredMatchCleanupService : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(5);

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<ExpiredMatchCleanupService> _logger;

    public ExpiredMatchCleanupService(
        IServiceScopeFactory scopeFactory, ILogger<ExpiredMatchCleanupService> logger)
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
                using var scope = _scopeFactory.CreateScope();
                var matches = scope.ServiceProvider.GetRequiredService<IMatchService>();
                var settings = scope.ServiceProvider.GetRequiredService<ISettingsService>();
                var hours = await settings.GetAutoCancelHoursAsync();
                var count = await matches.CancelIncompleteBeforeStartAsync(
                    TimeSpan.FromHours(hours), stoppingToken);
                if (count > 0)
                    _logger.LogInformation(
                        "Cancelled {Count} incomplete event(s) starting within {Hours}h",
                        count, hours);
            }
            catch (Exception ex)
            {
                // نبضة فاشلة لا تُسقط الحلقة — تُسجَّل وتُعاد المحاولة لاحقاً.
                _logger.LogError(ex, "Expired match cleanup tick failed");
            }
        }
        while (await timer.WaitForNextTickAsync(stoppingToken));
    }
}
