using System.Globalization;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SportaApis.Data;
using SportaApis.Helpers;
using SportaApis.Repositories;
using SportaApis.Services;

// The OS/ICU default culture on some hosts (any "..-SA" Saudi-region culture,
// e.g. "en-SA") uses UmAlQuraCalendar (Hijri) as its DEFAULT calendar. Left
// unset, that silently breaks both DateTime.ToString("yyyy-MM-dd") (emits a
// Hijri date under a Gregorian-looking format) and ASP.NET Core's [FromQuery]
// DateTime model binding (parses incoming "2026-07-06" as a Hijri date,
// resolving to the wrong day — e.g. for court availability queries). Force
// Gregorian/invariant everywhere; all API dates are ISO strings anyway.
CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
CultureInfo.DefaultThreadCurrentUICulture = CultureInfo.InvariantCulture;

var builder = WebApplication.CreateBuilder(args);

// Controllers
builder.Services.AddControllers();

// فشل التحقق من النموذج ([Required] وأخواتها) كان يُرجع ValidationProblemDetails
// الافتراضي — شكل لا يحمل "message"، فيعرضه التطبيق كـ "Unknown error" بلا أي
// دلالة. نوحّد الشكل مع بقية الردود ونذكر الحقول الناقصة كي تظهر رسالة مفهومة.
builder.Services.Configure<Microsoft.AspNetCore.Mvc.ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var fields = context.ModelState
            .Where(e => e.Value is not null && e.Value.Errors.Count > 0)
            .Select(e => e.Key)
            .Where(k => !string.IsNullOrWhiteSpace(k))
            .Distinct()
            .ToList();

        var details = context.ModelState
            .Where(e => e.Value is not null && e.Value.Errors.Count > 0)
            .SelectMany(e => e.Value!.Errors.Select(err =>
                $"{e.Key}: {(string.IsNullOrWhiteSpace(err.ErrorMessage) ? "invalid" : err.ErrorMessage)}"))
            .ToList();

        var joined = fields.Count > 0 ? string.Join(", ", fields) : "request";
        return new Microsoft.AspNetCore.Mvc.BadRequestObjectResult(
            SportaApis.DTOs.ApiResponse<object>.Fail(
                details.Count > 0
                    ? $"Invalid request data ({string.Join(" | ", details)})"
                    : "Invalid request data",
                $"بيانات الطلب غير صالحة: {joined}",
                "VALIDATION_ERROR"));
    };
});

// Database (MySQL)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));

// Dependency Injection
builder.Services.AddScoped(typeof(IGenericRepository<>), typeof(GenericRepository<>));
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IPlayerService, PlayerService>();
builder.Services.AddScoped<ICourtService, CourtService>();
builder.Services.AddScoped<IBookingService, BookingService>();
builder.Services.AddScoped<ICoachService, CoachService>();
builder.Services.AddScoped<IMatchService, MatchService>();
builder.Services.AddScoped<IAmericanoService, AmericanoService>();
builder.Services.AddScoped<IWithdrawalService, WithdrawalService>();
builder.Services.AddScoped<IWaitlistService, WaitlistService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<IMembershipService, MembershipService>();
builder.Services.AddScoped<IEventChatService, EventChatService>();
builder.Services.AddScoped<ITournamentService, TournamentService>();
builder.Services.AddScoped<IEventInviteService, EventInviteService>();
builder.Services.AddScoped<IFriendService, FriendService>();
builder.Services.AddScoped<IFollowService, FollowService>();
builder.Services.AddScoped<IFeedService, FeedService>();
builder.Services.AddScoped<IPulseService, PulseService>();
builder.Services.AddHttpClient();
builder.Services.AddScoped<IPushSender, OneSignalPushSender>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IVenueService, VenueService>();
builder.Services.AddScoped<ISubscriptionService, SubscriptionService>();
builder.Services.AddScoped<IShowcaseTournamentService, ShowcaseTournamentService>();
builder.Services.AddScoped<IAdService, AdService>();
builder.Services.AddScoped<ISportService, SportService>();
builder.Services.AddScoped<ICoachSpecializationService, CoachSpecializationService>();
builder.Services.AddScoped<IPackageService, PackageService>();
builder.Services.AddScoped<IAdminService, AdminService>();
builder.Services.AddScoped<IAssessmentService, AssessmentService>();
builder.Services.AddScoped<ISettingsService, SettingsService>();
builder.Services.AddMemoryCache();
builder.Services.AddSingleton<SportaApis.Helpers.AttemptThrottle>();
builder.Services.AddScoped<IServiceZoneService, ServiceZoneService>();
builder.Services.AddScoped<IWalletService, WalletService>();
builder.Services.AddScoped<IPointsService, PointsService>();
builder.Services.AddScoped<ILevelDefinitionService, LevelDefinitionService>();
builder.Services.AddScoped<ILocationService, LocationService>();
builder.Services.AddScoped<IStaffService, StaffService>();
builder.Services.AddScoped<IDiscountService, DiscountService>();
builder.Services.AddScoped<IVenueSubscriptionService, VenueSubscriptionService>();
builder.Services.AddScoped<ISupportChatService, SupportChatService>();

// Current dashboard user's permissions + geo scope (staff), resolved per request.
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IAdminContext, AdminContext>();

// App wall-clock offset (KSA = UTC+3, no DST) used for match-timing logic.
SportaApis.Helpers.AppClock.OffsetHours =
    builder.Configuration.GetValue("App:TimeZoneOffsetHours", 3);

// Pushes "match starts in 30 minutes" reminders on a background tick.
builder.Services.AddHostedService<MatchReminderService>();
builder.Services.AddHostedService<ReviewPromptService>();
builder.Services.AddHostedService<MembershipRenewalService>();
builder.Services.AddHostedService<ExpiredMatchCleanupService>();
builder.Services.AddHostedService<WaitlistOfferService>();

// بوابة FINY — إنشاء عمليات الدفع والتحقق منها. صفحة البطاقة مستضافة لديها،
// فلا مفتاح دفع ولا رقم بطاقة يمر بهذا الخادم.
builder.Services.Configure<SportaApis.Helpers.FinyOptions>(
    builder.Configuration.GetSection("Finy"));
builder.Services.AddHttpClient<IFinyPaymentService, FinyPaymentService>();

// Apple Pay — التطبيق يجمع التوكن من ورقة آبل ويرسله لنا، ونمرّره إلى FINY
// كأي توكن بطاقة. لا شهادة ولا مفتاح هنا؛ الإعداد هو Merchant ID فقط.
builder.Services.Configure<SportaApis.Helpers.ApplePayOptions>(
    builder.Configuration.GetSection("ApplePay"));

// رموز التحقق عبر واتساب (Authentica). المزوّد يُحقن خلف IOtpSender، فمنطق
// الحدود والأغراض في OtpService لا يعرف أيّهما يعمل.
builder.Services.Configure<SportaApis.Helpers.OtpOptions>(
    builder.Configuration.GetSection("Otp"));
builder.Services.AddHttpClient<AuthenticaOtpSender>();

// الاختيار يُحسم هنا لا داخل مصنع الخدمة: مصنعُ الخدمة لا يعمل إلا عند أول
// طلب رمز، فخطأُ الإعداد كان يظهر بعد ساعات من النشر على أول مستخدم يحاول
// الدخول — لا عند الإقلاع حيث يراه الناشر.
var otpOptions = builder.Configuration.GetSection("Otp")
    .Get<SportaApis.Helpers.OtpOptions>() ?? new SportaApis.Helpers.OtpOptions();

var useLocalOtp =
    otpOptions.Provider.Equals("Local", StringComparison.OrdinalIgnoreCase)
    || !otpOptions.Authentica.IsConfigured;

// المزوّد المحلي يطبع الرمز في اللوق ويعيده في ردّ الـ API — أي أن من يقرأ
// أياً منهما يدخل أي حساب. لذا لا يعمل إلا بموافقة صريحة في الإعدادات، لا
// بمجرد أن اسم البيئة "Development": خادمٌ أُقلع بالبيئة الخطأ حادثٌ واقع،
// وربطُ أمرٍ بهذا الخطر باسم بيئة يجعل الخطأ المطبعي ثغرةً صامتة.
if (useLocalOtp && !otpOptions.AllowInsecureLocalProvider)
{
    throw new InvalidOperationException(
        "OTP provider is not configured. Set Otp__Authentica__ApiKey to send " +
        "codes through Authentica, or set Otp:AllowInsecureLocalProvider=true " +
        "to use the local provider that logs codes instead of sending them " +
        "(development machines only — it exposes every account).");
}

if (useLocalOtp)
    builder.Services.AddScoped<IOtpSender, LocalOtpSender>();
else
    builder.Services.AddScoped<IOtpSender>(
        sp => sp.GetRequiredService<AuthenticaOtpSender>());

builder.Services.AddScoped<IOtpService, OtpService>();

// JWT Authentication
var jwtSettings = builder.Configuration.GetSection("Jwt");
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSettings["Issuer"],
            ValidAudience = jwtSettings["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtSettings["Key"]!))
        };

        // مصافحة WebSocket لا تحمل ترويسة Authorization، فعملاء SignalR يُلحقون
        // ?access_token=… بدلاً منها. نقبلها على مسارات الـ hubs فقط.
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = ctx =>
            {
                var token = ctx.Request.Query["access_token"];
                if (!string.IsNullOrEmpty(token)
                    && ctx.HttpContext.Request.Path.StartsWithSegments("/hubs"))
                    ctx.Token = token;

                return Task.CompletedTask;
            }
        };
    });
builder.Services.AddAuthorization();

// SignalR — النقل الفوري لدردشة الدعم الفني.
builder.Services.AddSignalR();

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "Sporta APIs", Version = "v1" });
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter your JWT token"
    });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Seed demo data when running in Development, or on any environment when
// "Seeding:Enabled" is true in configuration — so a fresh server can be
// populated with test data (accounts, courts, bookings, matches...) without
// switching it to the Development environment. All seeders are idempotent, so
// leaving the flag on is safe; set it to false once the data exists.
// NOTE: migrations are NOT applied here — run `dotnet ef database update`
// (or the SQL) manually first, or the seeders will fail on a missing schema.
if (app.Environment.IsDevelopment() ||
    app.Configuration.GetValue<bool>("Seeding:Enabled"))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<SportaApis.Data.AppDbContext>();
    await SportaApis.Data.DbSeeder.SeedCourtsAsync(db);
    await SportaApis.Data.DbSeeder.SeedCourtPriceTiersAsync(db);
    await SportaApis.Data.DbSeeder.SeedCoachesAsync(db);
    await SportaApis.Data.DbSeeder.SeedMatchesAsync(db);
    await SportaApis.Data.DbSeeder.SeedAmericanoAsync(db);
    await SportaApis.Data.DbSeeder.SeedFriendshipsAsync(db);
    await SportaApis.Data.DbSeeder.SeedTournamentsAsync(db);
    await SportaApis.Data.DbSeeder.BackfillVenueCoordinatesAsync(db);
    await SportaApis.Data.DbSeeder.SeedAdsAsync(db);
    // إعلانات زُرعت قبل عمودَي النص الإنجليزي — تبقى بلا ترجمة بدون هذا.
    await SportaApis.Data.DbSeeder.BackfillAdEnglishTextAsync(db);
    await SportaApis.Data.DbSeeder.SeedSportsAsync(db);
    await SportaApis.Data.DbSeeder.SeedCoachSpecializationsAsync(db);
    await SportaApis.Data.DbSeeder.SeedPackagesAsync(db);
    await SportaApis.Data.DbSeeder.SeedSystemSettingsAsync(db);
    await SportaApis.Data.DbSeeder.UpgradePoliciesAsync(db);
    await SportaApis.Data.DbSeeder.SeedAssessmentAsync(db);
    await SportaApis.Data.DbSeeder.SeedLevelDefinitionsAsync(db);
    await SportaApis.Data.DbSeeder.SeedCitiesAndDistrictsAsync(db);
    // يربط الأندية والمستخدمين القدامى بجدول المدن حتى تعمل تصفية نطاق الموظفين.
    await SportaApis.Data.DbSeeder.BackfillVenueCityLinksAsync(db);
    await SportaApis.Data.DbSeeder.BackfillUserCityLinksAsync(db);
    await SportaApis.Data.DbSeeder.SeedDemoDataAsync(db);
}

// حساب أدمن حقيقي من الإعدادات (Admin:Phone / Admin:Password) على كل بيئة —
// حسابات التجربة أعلاه لا تُنشأ على الإنتاج، وهذا ما يفتح لوحة التحكم هناك.
// فشله لا يُسقط الخادم: يُسجَّل ويستمر التشغيل.
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<SportaApis.Data.AppDbContext>();
    try
    {
        await SportaApis.Data.DbSeeder.BootstrapAdminAsync(db, app.Configuration);
    }
    catch (Exception ex)
    {
        app.Logger.LogError(ex, "Bootstrap admin account failed");
    }
}

app.UseHttpsRedirection();

// Serve uploaded files (avatars, venue images) from wwwroot.
app.UseStaticFiles();

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

// Block suspended (deactivated) accounts on every authenticated request so the
// app can show the account-suspended screen immediately. Auth + the public
// support-phone endpoint are exempt so login errors and the suspended screen
// still work.
app.Use(async (context, next) =>
{
    var path = context.Request.Path.Value ?? string.Empty;
    var exempt = path.StartsWith("/api/auth", StringComparison.OrdinalIgnoreCase)
        || path.StartsWith("/api/settings/support-phone", StringComparison.OrdinalIgnoreCase);

    if (!exempt && context.User.Identity?.IsAuthenticated == true)
    {
        var idClaim = context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (int.TryParse(idClaim, out var uid))
        {
            var db = context.RequestServices.GetRequiredService<AppDbContext>();
            var status = await db.Users.Where(u => u.Id == uid)
                .Select(u => new { u.IsActive, u.IsDeleted })
                .FirstOrDefaultAsync();

            // الحساب المحذوف يُميَّز عن الموقوف: التطبيق ينهي الجلسة بلا شاشة
            // «الحساب موقوف»، فالمستخدم هو من طلب الحذف.
            if (status?.IsDeleted == true)
            {
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                await context.Response.WriteAsJsonAsync(
                    SportaApis.DTOs.ApiResponse<object>.Fail(
                        "Account deleted", "تم حذف هذا الحساب", "ACCOUNT_DELETED"));
                return;
            }

            if (status?.IsActive == false)
            {
                context.Response.StatusCode = StatusCodes.Status403Forbidden;
                await context.Response.WriteAsJsonAsync(
                    SportaApis.DTOs.ApiResponse<object>.Fail(
                        "Account suspended", "الحساب موقوف", "ACCOUNT_SUSPENDED"));
                return;
            }
        }
    }
    await next();
});

app.MapControllers();

// دردشة الدعم الفورية — التطبيق واللوحة يتصلان بهذا المسار.
app.MapHub<SportaApis.Hubs.SupportChatHub>("/hubs/support-chat");
app.MapHub<SportaApis.Hubs.EventChatHub>("/hubs/event-chat");

app.Run();
