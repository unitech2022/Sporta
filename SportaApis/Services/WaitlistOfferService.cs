namespace SportaApis.Services;

/// <summary>
/// نبضة كل دقيقة لقوائم الانتظار: تُسقط العروض التي انتهت مهلتها وتعرض
/// مقاعدها على التالين، وتُغلق قوائم الأحداث التي بدأت أو أُلغيت. الخطافات
/// (انسحاب، رفض طلب، مغادرة القائمة) تعالج فوراً؛ هذه تلتقط ما يفوتها والوقت.
/// </summary>
public class WaitlistOfferService : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(1);

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<WaitlistOfferService> _logger;

    public WaitlistOfferService(
        IServiceScopeFactory scopeFactory, ILogger<WaitlistOfferService> logger)
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
                var waitlist = scope.ServiceProvider.GetRequiredService<IWaitlistService>();
                await waitlist.ProcessAllAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                // نبضة فاشلة لا تُسقط الحلقة — تُسجَّل وتُعاد المحاولة لاحقاً.
                _logger.LogError(ex, "Waitlist tick failed");
            }
        }
        while (await timer.WaitForNextTickAsync(stoppingToken));
    }
}
