using Microsoft.EntityFrameworkCore;
using SportaApis.Models;

namespace SportaApis.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<OtpCode> OtpCodes => Set<OtpCode>();
    public DbSet<TrustedDevice> TrustedDevices => Set<TrustedDevice>();
    public DbSet<PlayerProfile> PlayerProfiles => Set<PlayerProfile>();
    public DbSet<CoachProfile> CoachProfiles => Set<CoachProfile>();
    public DbSet<Venue> Venues => Set<Venue>();
    public DbSet<VenueImage> VenueImages => Set<VenueImage>();
    public DbSet<Court> Courts => Set<Court>();
    public DbSet<CourtPriceTier> CourtPriceTiers => Set<CourtPriceTier>();
    public DbSet<CourtOpeningHour> CourtOpeningHours => Set<CourtOpeningHour>();
    public DbSet<CourtPriceRule> CourtPriceRules => Set<CourtPriceRule>();
    public DbSet<Match> Matches => Set<Match>();
    public DbSet<MatchPlayer> MatchPlayers => Set<MatchPlayer>();
    public DbSet<MatchWaitlistEntry> MatchWaitlist => Set<MatchWaitlistEntry>();
    public DbSet<EventChatMessage> EventChatMessages => Set<EventChatMessage>();
    public DbSet<EventChatReadState> EventChatReads => Set<EventChatReadState>();
    public DbSet<EventChatReaction> EventChatReactions => Set<EventChatReaction>();
    public DbSet<AmericanoMatch> AmericanoMatches => Set<AmericanoMatch>();
    public DbSet<AmericanoRound> AmericanoRounds => Set<AmericanoRound>();
    public DbSet<TournamentFixture> TournamentFixtures => Set<TournamentFixture>();
    public DbSet<TournamentCourt> TournamentCourts => Set<TournamentCourt>();
    public DbSet<TournamentTeamName> TournamentTeamNames => Set<TournamentTeamName>();
    public DbSet<EventInvite> EventInvites => Set<EventInvite>();
    public DbSet<Booking> Bookings => Set<Booking>();
    public DbSet<CoachSession> CoachSessions => Set<CoachSession>();
    public DbSet<CoachOffer> CoachOffers => Set<CoachOffer>();
    public DbSet<LevelAssessment> LevelAssessments => Set<LevelAssessment>();
    public DbSet<MatchRating> MatchRatings => Set<MatchRating>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<MembershipPlan> MembershipPlans => Set<MembershipPlan>();
    public DbSet<Membership> Memberships => Set<Membership>();
    public DbSet<Wallet> Wallets => Set<Wallet>();
    public DbSet<WalletTransaction> WalletTransactions => Set<WalletTransaction>();
    public DbSet<PointsTransaction> PointsTransactions => Set<PointsTransaction>();
    public DbSet<PlayerLevelDefinition> PlayerLevelDefinitions => Set<PlayerLevelDefinition>();
    public DbSet<Subscription> Subscriptions => Set<Subscription>();
    public DbSet<Friendship> Friendships => Set<Friendship>();
    public DbSet<Follow> Follows => Set<Follow>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<Tournament> Tournaments => Set<Tournament>();
    public DbSet<SystemSetting> SystemSettings => Set<SystemSetting>();
    public DbSet<Ad> Ads => Set<Ad>();
    public DbSet<Sport> Sports => Set<Sport>();
    public DbSet<SportSetting> SportSettings => Set<SportSetting>();
    public DbSet<Package> Packages => Set<Package>();
    public DbSet<AssessmentLevel> AssessmentLevels => Set<AssessmentLevel>();
    public DbSet<AssessmentQuestion> AssessmentQuestions => Set<AssessmentQuestion>();
    public DbSet<AssessmentOption> AssessmentOptions => Set<AssessmentOption>();
    public DbSet<CourtBlockedSlot> CourtBlockedSlots => Set<CourtBlockedSlot>();
    public DbSet<CourtFavorite> CourtFavorites => Set<CourtFavorite>();
    public DbSet<WithdrawalRequest> WithdrawalRequests => Set<WithdrawalRequest>();
    public DbSet<Country> Countries => Set<Country>();
    public DbSet<City> Cities => Set<City>();
    public DbSet<District> Districts => Set<District>();
    public DbSet<StaffProfile> StaffProfiles => Set<StaffProfile>();
    public DbSet<StaffPermission> StaffPermissions => Set<StaffPermission>();
    public DbSet<Discount> Discounts => Set<Discount>();
    public DbSet<DiscountBeneficiary> DiscountBeneficiaries => Set<DiscountBeneficiary>();
    public DbSet<VenueSubscriptionPricing> VenueSubscriptionPricings => Set<VenueSubscriptionPricing>();
    public DbSet<VenueSubscription> VenueSubscriptions => Set<VenueSubscription>();
    public DbSet<CoachSpecialization> CoachSpecializations => Set<CoachSpecialization>();
    public DbSet<CoachProfileSpecialization> CoachProfileSpecializations => Set<CoachProfileSpecialization>();
    public DbSet<SupportConversation> SupportConversations => Set<SupportConversation>();
    public DbSet<SupportMessage> SupportMessages => Set<SupportMessage>();
    public DbSet<ServiceZone> ServiceZones => Set<ServiceZone>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // ── User ──────────────────────────────────────────────────────────────
        modelBuilder.Entity<User>(e =>
        {
            e.HasIndex(u => u.Email).IsUnique();
            e.HasIndex(u => u.PhoneNumber).IsUnique();
            e.Property(u => u.FirstName).HasMaxLength(100);
            e.Property(u => u.LastName).HasMaxLength(100);
            e.Property(u => u.Email).HasMaxLength(150);

            // الحساب البنكي: أطوال محدّدة بدل longtext، والآيبان مفهرس لأنه
            // يُبحث به عند مطابقة التحويلات البنكية.
            e.Property(u => u.Iban).HasMaxLength(34);
            e.Property(u => u.BankName).HasMaxLength(100);
            e.Property(u => u.AccountHolderName).HasMaxLength(150);
            e.HasIndex(u => u.Iban);

            e.HasOne(u => u.CityRef)
             .WithMany()
             .HasForeignKey(u => u.CityId)
             .OnDelete(DeleteBehavior.SetNull);
            e.HasOne(u => u.DistrictRef)
             .WithMany()
             .HasForeignKey(u => u.DistrictId)
             .OnDelete(DeleteBehavior.SetNull);
        });

        // ── Country / City / District ─────────────────────────────────────────
        modelBuilder.Entity<Country>(e =>
        {
            e.Property(c => c.NameAr).HasMaxLength(120);
            e.Property(c => c.NameEn).HasMaxLength(120);
            e.Property(c => c.Code).HasMaxLength(2);
            e.Property(c => c.PhoneCode).HasMaxLength(6);
            e.Property(c => c.CurrencyCode).HasMaxLength(3);
            e.HasIndex(c => c.Code).IsUnique();
        });
        modelBuilder.Entity<City>(e =>
        {
            e.Property(c => c.NameAr).HasMaxLength(120);
            e.Property(c => c.NameEn).HasMaxLength(120);
            e.HasIndex(c => c.NameAr);
            e.HasOne(c => c.Country)
             .WithMany(co => co.Cities)
             .HasForeignKey(c => c.CountryId)
             .OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(c => c.CountryId);
        });
        modelBuilder.Entity<District>(e =>
        {
            e.Property(d => d.NameAr).HasMaxLength(120);
            e.Property(d => d.NameEn).HasMaxLength(120);
            e.HasOne(d => d.City)
             .WithMany(c => c.Districts)
             .HasForeignKey(d => d.CityId)
             .OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(d => d.CityId);
        });

        // ── StaffProfile / StaffPermission ────────────────────────────────────
        modelBuilder.Entity<StaffProfile>(e =>
        {
            e.HasIndex(s => s.UserId).IsUnique();
            e.Property(s => s.JobTitle).HasMaxLength(120);
            e.HasOne(s => s.User)
             .WithOne(u => u.StaffProfile)
             .HasForeignKey<StaffProfile>(s => s.UserId)
             .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(s => s.Country)
             .WithMany()
             .HasForeignKey(s => s.CountryId)
             .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(s => s.City)
             .WithMany()
             .HasForeignKey(s => s.CityId)
             .OnDelete(DeleteBehavior.Restrict);
        });
        modelBuilder.Entity<StaffPermission>(e =>
        {
            e.Property(p => p.Permission).HasMaxLength(80);
            e.HasIndex(p => new { p.StaffProfileId, p.Permission }).IsUnique();
            e.HasOne(p => p.StaffProfile)
             .WithMany(s => s.Permissions)
             .HasForeignKey(p => p.StaffProfileId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── Discount / DiscountBeneficiary ────────────────────────────────────
        modelBuilder.Entity<Discount>(e =>
        {
            e.Property(d => d.NameAr).HasMaxLength(150);
            e.Property(d => d.Percent).HasPrecision(5, 2);
            e.HasIndex(d => new { d.Target, d.IsActive });
        });
        modelBuilder.Entity<DiscountBeneficiary>(e =>
        {
            // يمنع ازدواج المستفيد ويحمي سقف «أول N» من التسابق.
            e.HasIndex(b => new { b.DiscountId, b.UserId }).IsUnique();
            e.HasOne(b => b.Discount)
             .WithMany(d => d.Beneficiaries)
             .HasForeignKey(b => b.DiscountId)
             .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(b => b.User)
             .WithMany()
             .HasForeignKey(b => b.UserId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── Venue subscriptions ───────────────────────────────────────────────
        modelBuilder.Entity<VenueSubscriptionPricing>(e =>
        {
            e.Property(p => p.MonthlyOneCourt).HasPrecision(10, 2);
            e.Property(p => p.MonthlyTwoCourts).HasPrecision(10, 2);
            e.Property(p => p.MonthlyExtraCourt).HasPrecision(10, 2);
            e.Property(p => p.YearlyOneCourt).HasPrecision(10, 2);
            e.Property(p => p.YearlyTwoCourts).HasPrecision(10, 2);
            e.Property(p => p.YearlyExtraCourt).HasPrecision(10, 2);
        });
        modelBuilder.Entity<VenueSubscription>(e =>
        {
            e.Property(s => s.BasePrice).HasPrecision(10, 2);
            e.Property(s => s.DiscountPercent).HasPrecision(5, 2);
            e.Property(s => s.PaidAmount).HasPrecision(10, 2);
            e.HasOne(s => s.Owner)
             .WithMany()
             .HasForeignKey(s => s.OwnerId)
             .OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(s => new { s.OwnerId, s.EndsAt });
        });

        // ── UserRole ──────────────────────────────────────────────────────────
        modelBuilder.Entity<UserRole>(e =>
        {
            e.HasIndex(r => new { r.UserId, r.Role }).IsUnique();
            // الأدوار القديمة (قبل ميزة الاعتماد) تُقرأ معتمدة افتراضياً.
            e.Property(r => r.IsApproved).HasDefaultValue(true);
            // الدور المحذوف ناعماً يختفي من كل استعلام وملاحة (User.Roles) بلا
            // شرط يُكرَّر في كل موضع — ومن يحتاجه (إحياء الدور) يستخدم
            // IgnoreQueryFilters صراحةً. الصفّ يبقى فيبقى قيد التفرّد صالحاً،
            // فلا يُنشأ صفّ ثانٍ لنفس الدور.
            e.HasQueryFilter(r => !r.IsDeleted);
            e.HasOne(r => r.User)
             .WithMany(u => u.Roles)
             .HasForeignKey(r => r.UserId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── RefreshToken ──────────────────────────────────────────────────────
        modelBuilder.Entity<RefreshToken>(e =>
        {
            e.HasIndex(rt => rt.Token).IsUnique();
            e.Property(rt => rt.Token).HasMaxLength(256);
            e.HasOne(rt => rt.User)
             .WithMany(u => u.RefreshTokens)
             .HasForeignKey(rt => rt.UserId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── TrustedDevice ─────────────────────────────────────────────────────
        modelBuilder.Entity<TrustedDevice>(e =>
        {
            e.Property(d => d.DeviceId).HasMaxLength(64);
            e.Property(d => d.SecretHash).HasMaxLength(64);
            e.Property(d => d.Name).HasMaxLength(100);
            e.Property(d => d.Platform).HasMaxLength(20);
            // الجهاز الواحد لحساب واحد في كل لحظة؛ الدخول يبحث بمعرّفه.
            e.HasIndex(d => d.DeviceId).IsUnique();
            e.HasOne(d => d.User)
             .WithMany(u => u.TrustedDevices)
             .HasForeignKey(d => d.UserId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── OtpCode ───────────────────────────────────────────────────────────
        modelBuilder.Entity<OtpCode>(e =>
        {
            e.Property(o => o.PhoneNumber).HasMaxLength(20);
            e.Property(o => o.Code).HasMaxLength(10);
            e.Property(o => o.Channel).HasMaxLength(20);
            e.Property(o => o.VerificationToken).HasMaxLength(64);

            // كل طلب رمز يقرأ آخر سجلات الرقم (حدود الإرسال، آخر رمز حيّ)،
            // وكل استهلاك تذكرة يبحث بها. فهرسان يمنعان مسحاً كاملاً للجدول
            // على مسار الدخول — وهو أكثر مسارات التطبيق طَرْقاً.
            e.HasIndex(o => new { o.PhoneNumber, o.Purpose, o.CreatedAt });
            e.HasIndex(o => o.VerificationToken);
        });

        // ── PlayerProfile ─────────────────────────────────────────────────────
        modelBuilder.Entity<PlayerProfile>(e =>
        {
            e.HasOne(p => p.User)
             .WithOne(u => u.PlayerProfile)
             .HasForeignKey<PlayerProfile>(p => p.UserId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── CoachProfile ──────────────────────────────────────────────────────
        modelBuilder.Entity<CoachProfile>(e =>
        {
            e.HasOne(c => c.User)
             .WithOne(u => u.CoachProfile)
             .HasForeignKey<CoachProfile>(c => c.UserId)
             .OnDelete(DeleteBehavior.Cascade);

            e.Property(c => c.HourlyRate).HasPrecision(10, 2);
            e.Property(c => c.PackagePrice).HasPrecision(10, 2);

            e.HasOne(c => c.Sport)
             .WithMany()
             .HasForeignKey(c => c.SportId)
             .OnDelete(DeleteBehavior.SetNull);

            e.HasOne(c => c.PreferredVenue)
             .WithMany()
             .HasForeignKey(c => c.PreferredVenueId)
             .OnDelete(DeleteBehavior.SetNull);
        });

        // ── CoachSpecialization ───────────────────────────────────────────────
        modelBuilder.Entity<CoachProfileSpecialization>(e =>
        {
            e.HasKey(cs => new { cs.CoachProfileId, cs.SpecializationId });

            e.HasOne(cs => cs.CoachProfile)
             .WithMany(c => c.Specializations)
             .HasForeignKey(cs => cs.CoachProfileId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(cs => cs.Specialization)
             .WithMany(s => s.CoachProfiles)
             .HasForeignKey(cs => cs.SpecializationId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── Venue ─────────────────────────────────────────────────────────────
        modelBuilder.Entity<Venue>(e =>
        {
            e.HasOne(v => v.Owner)
             .WithMany()
             .HasForeignKey(v => v.OwnerId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasMany(v => v.Images)
             .WithOne(i => i.Venue)
             .HasForeignKey(i => i.VenueId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(v => v.CountryRef)
             .WithMany()
             .HasForeignKey(v => v.CountryId)
             .OnDelete(DeleteBehavior.SetNull);
            e.HasOne(v => v.CityRef)
             .WithMany()
             .HasForeignKey(v => v.CityId)
             .OnDelete(DeleteBehavior.SetNull);
            e.HasIndex(v => v.CityId);

            e.HasOne(v => v.DistrictRef)
             .WithMany()
             .HasForeignKey(v => v.DistrictId)
             .OnDelete(DeleteBehavior.SetNull);
            e.HasIndex(v => v.DistrictId);
        });

        // ── Court ─────────────────────────────────────────────────────────────
        modelBuilder.Entity<Court>(e =>
        {
            e.Property(c => c.PricePerHour).HasPrecision(10, 2);
            e.Property(c => c.SportaCommissionPercent)
             .HasPrecision(5, 2)
             .HasDefaultValue(Court.DefaultSportaCommissionPercent);

            e.HasOne(c => c.Venue)
             .WithMany(v => v.Courts)
             .HasForeignKey(c => c.VenueId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── CourtPriceTier ────────────────────────────────────────────────────
        modelBuilder.Entity<CourtPriceTier>(e =>
        {
            e.Property(t => t.Price).HasPrecision(10, 2);

            e.HasOne(t => t.Court)
             .WithMany(c => c.PriceTiers)
             .HasForeignKey(t => t.CourtId)
             .OnDelete(DeleteBehavior.Cascade);

            // One price per (court, kind, duration).
            e.HasIndex(t => new { t.CourtId, t.Kind, t.DurationMinutes }).IsUnique();
        });

        // ── CourtOpeningHour ──────────────────────────────────────────────────
        modelBuilder.Entity<CourtOpeningHour>(e =>
        {
            e.HasOne(h => h.Court)
             .WithMany(c => c.OpeningHours)
             .HasForeignKey(h => h.CourtId)
             .OnDelete(DeleteBehavior.Cascade);

            // صف واحد لكل (ملعب، يوم).
            e.HasIndex(h => new { h.CourtId, h.Day }).IsUnique();
        });

        // ── CourtPriceRule ────────────────────────────────────────────────────
        modelBuilder.Entity<CourtPriceRule>(e =>
        {
            e.Property(r => r.AdjustmentPercent).HasPrecision(6, 2);

            e.HasOne(r => r.Court)
             .WithMany(c => c.PriceRules)
             .HasForeignKey(r => r.CourtId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasIndex(r => r.CourtId);
        });

        // ── CourtFavorite ─────────────────────────────────────────────────────
        modelBuilder.Entity<CourtFavorite>(e =>
        {
            // يمنع تكرار نفس الملعب لنفس المستخدم، ويخدم فحص «هل هو مفضّل؟».
            e.HasIndex(f => new { f.UserId, f.CourtId }).IsUnique();

            e.HasOne(f => f.User)
             .WithMany()
             .HasForeignKey(f => f.UserId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(f => f.Court)
             .WithMany()
             .HasForeignKey(f => f.CourtId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── Match ─────────────────────────────────────────────────────────────
        modelBuilder.Entity<Match>(e =>
        {
            e.Property(m => m.PricePerPlayer).HasPrecision(10, 2);
            e.Property(m => m.SportaCommissionPercent).HasPrecision(5, 2);

            e.HasOne(m => m.Creator)
             .WithMany()
             .HasForeignKey(m => m.CreatorId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(m => m.Court)
             .WithMany(c => c.Matches)
             .HasForeignKey(m => m.CourtId)
             .OnDelete(DeleteBehavior.SetNull);
        });

        // ── MatchPlayer ───────────────────────────────────────────────────────
        // دردشة الحدث: تسقط بحذف الحدث؛ الصفحات تُقرأ بالمعرّف داخل كل حدث.
        modelBuilder.Entity<EventChatMessage>(e =>
        {
            e.HasIndex(x => new { x.MatchId, x.Id });
            e.Property(x => x.Body).HasMaxLength(1000);
            e.Property(x => x.SenderName).HasMaxLength(200);
            e.Property(x => x.AttachmentUrl).HasMaxLength(300);
            e.Property(x => x.AttachmentName).HasMaxLength(200);
            e.Property(x => x.AttachmentType).HasMaxLength(10);
            e.Property(x => x.MentionedUserIds).HasMaxLength(500);
            e.HasOne(x => x.Match)
             .WithMany()
             .HasForeignKey(x => x.MatchId)
             .OnDelete(DeleteBehavior.Cascade);
        });
        modelBuilder.Entity<EventChatReadState>(e =>
        {
            e.HasIndex(x => new { x.MatchId, x.UserId }).IsUnique();
        });
        modelBuilder.Entity<EventChatReaction>(e =>
        {
            e.HasIndex(x => new { x.MessageId, x.UserId }).IsUnique();
            e.Property(x => x.Emoji).HasMaxLength(16);
            e.HasOne(x => x.Message)
             .WithMany(m => m.Reactions)
             .HasForeignKey(x => x.MessageId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // قائمة الانتظار: لاعب مرة واحدة في قائمة كل حدث، وتسقط بحذف الحدث.
        modelBuilder.Entity<MatchWaitlistEntry>(e =>
        {
            e.HasIndex(w => new { w.MatchId, w.UserId }).IsUnique();
            e.HasIndex(w => w.OfferExpiresAt);

            e.HasOne(w => w.Match)
             .WithMany()
             .HasForeignKey(w => w.MatchId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(w => w.User)
             .WithMany()
             .HasForeignKey(w => w.UserId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<MatchPlayer>(e =>
        {
            e.HasIndex(mp => new { mp.MatchId, mp.UserId }).IsUnique();
            e.Property(mp => mp.PaidAmount).HasPrecision(10, 2);
            e.HasIndex(mp => mp.MembershipId);

            e.HasOne(mp => mp.Match)
             .WithMany(m => m.MatchPlayers)
             .HasForeignKey(mp => mp.MatchId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(mp => mp.User)
             .WithMany()
             .HasForeignKey(mp => mp.UserId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── AmericanoMatch ────────────────────────────────────────────────────
        modelBuilder.Entity<AmericanoMatch>(e =>
        {
            e.HasOne(a => a.Match)
             .WithOne(m => m.AmericanoMatch)
             .HasForeignKey<AmericanoMatch>(a => a.MatchId)
             .OnDelete(DeleteBehavior.Cascade);
            e.Property(a => a.Name).HasMaxLength(80);
        });

        // ── TournamentFixture / TournamentCourt ──────────────────────────────
        modelBuilder.Entity<TournamentFixture>(e =>
        {
            e.HasOne(f => f.AmericanoMatch)
             .WithMany(a => a.Fixtures)
             .HasForeignKey(f => f.AmericanoMatchId)
             .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(f => f.Court)
             .WithMany()
             .HasForeignKey(f => f.CourtId)
             .OnDelete(DeleteBehavior.SetNull);
            e.HasIndex(f => new { f.AmericanoMatchId, f.Stage, f.Round, f.Index });
        });

        modelBuilder.Entity<TournamentCourt>(e =>
        {
            e.HasOne(c => c.AmericanoMatch)
             .WithMany(a => a.Courts)
             .HasForeignKey(c => c.AmericanoMatchId)
             .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(c => c.Court)
             .WithMany()
             .HasForeignKey(c => c.CourtId)
             .OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(c => new { c.AmericanoMatchId, c.CourtId }).IsUnique();
        });

        modelBuilder.Entity<EventInvite>(e =>
        {
            e.HasOne(i => i.Sender).WithMany().HasForeignKey(i => i.SenderId)
             .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(i => i.Receiver).WithMany().HasForeignKey(i => i.ReceiverId)
             .OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(i => new { i.ReceiverId, i.Kind, i.TargetId });
        });

        modelBuilder.Entity<TournamentTeamName>(e =>
        {
            e.HasOne(t => t.AmericanoMatch)
             .WithMany(a => a.TeamNames)
             .HasForeignKey(t => t.AmericanoMatchId)
             .OnDelete(DeleteBehavior.Cascade);
            e.Property(t => t.Name).HasMaxLength(30);
            e.HasIndex(t => new { t.AmericanoMatchId, t.Team }).IsUnique();
        });

        // ── AmericanoRound ────────────────────────────────────────────────────
        modelBuilder.Entity<AmericanoRound>(e =>
        {
            e.HasOne(r => r.AmericanoMatch)
             .WithMany(a => a.Rounds)
             .HasForeignKey(r => r.AmericanoMatchId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(r => r.Team1Player1).WithMany().HasForeignKey(r => r.Team1Player1Id).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(r => r.Team1Player2).WithMany().HasForeignKey(r => r.Team1Player2Id).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(r => r.Team2Player1).WithMany().HasForeignKey(r => r.Team2Player1Id).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(r => r.Team2Player2).WithMany().HasForeignKey(r => r.Team2Player2Id).OnDelete(DeleteBehavior.Restrict);
        });

        // ── Booking ───────────────────────────────────────────────────────────
        modelBuilder.Entity<Booking>(e =>
        {
            e.Property(b => b.TotalPrice).HasPrecision(10, 2);
            e.Property(b => b.SportaCommission).HasPrecision(10, 2);
            e.Property(b => b.MemberDiscountAmount).HasPrecision(10, 2);

            e.HasOne(b => b.Court)
             .WithMany(c => c.Bookings)
             .HasForeignKey(b => b.CourtId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(b => b.User)
             .WithMany()
             .HasForeignKey(b => b.UserId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── CoachSession ──────────────────────────────────────────────────────
        modelBuilder.Entity<CoachSession>(e =>
        {
            e.Property(s => s.Price).HasPrecision(10, 2);
            e.Property(s => s.SportaCommissionPercent).HasPrecision(5, 2);

            e.HasOne(s => s.CoachProfile)
             .WithMany(c => c.Sessions)
             .HasForeignKey(s => s.CoachProfileId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(s => s.Player)
             .WithMany()
             .HasForeignKey(s => s.PlayerId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── CoachOffer ────────────────────────────────────────────────────────
        modelBuilder.Entity<CoachOffer>(e =>
        {
            e.HasOne(o => o.CoachProfile)
             .WithMany(c => c.Offers)
             .HasForeignKey(o => o.CoachProfileId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── LevelAssessment ───────────────────────────────────────────────────
        modelBuilder.Entity<LevelAssessment>(e =>
        {
            e.HasOne(la => la.PlayerProfile)
             .WithMany(p => p.LevelAssessments)
             .HasForeignKey(la => la.PlayerProfileId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(la => la.Coach)
             .WithMany()
             .HasForeignKey(la => la.CoachId)
             .OnDelete(DeleteBehavior.SetNull);
        });

        // ── MatchRating ───────────────────────────────────────────────────────
        modelBuilder.Entity<MatchRating>(e =>
        {
            e.HasIndex(r => new { r.MatchId, r.RaterId, r.RatedUserId }).IsUnique();

            e.HasOne(r => r.Match)
             .WithMany(m => m.Ratings)
             .HasForeignKey(r => r.MatchId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(r => r.Rater)
             .WithMany()
             .HasForeignKey(r => r.RaterId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(r => r.RatedUser)
             .WithMany()
             .HasForeignKey(r => r.RatedUserId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── Memberships ───────────────────────────────────────────────────────
        modelBuilder.Entity<MembershipPlan>(e =>
        {
            e.Property(p => p.MonthlyPrice).HasPrecision(18, 2);
            e.Property(p => p.DiscountPercent).HasPrecision(5, 2);
            e.Property(p => p.Name).HasMaxLength(80);
            e.Property(p => p.NameEn).HasMaxLength(80);
            e.Property(p => p.Description).HasMaxLength(500);
            e.HasIndex(p => p.VenueId);
            e.HasOne(p => p.Venue).WithMany().HasForeignKey(p => p.VenueId)
             .OnDelete(DeleteBehavior.Cascade);
        });
        modelBuilder.Entity<Membership>(e =>
        {
            e.Property(m => m.Price).HasPrecision(18, 2);
            e.Property(m => m.DiscountPercent).HasPrecision(5, 2);
            e.Property(m => m.PlanName).HasMaxLength(80);
            e.HasIndex(m => new { m.UserId, m.VenueId });
            e.HasIndex(m => new { m.IsEnded, m.PeriodEnd });
            e.HasOne(m => m.Plan).WithMany().HasForeignKey(m => m.PlanId)
             .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(m => m.Venue).WithMany().HasForeignKey(m => m.VenueId)
             .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(m => m.User).WithMany().HasForeignKey(m => m.UserId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── Review ────────────────────────────────────────────────────────────
        modelBuilder.Entity<Review>(e =>
        {
            // تقييم واحد لكل (تجربة، مقيِّم، هدف).
            e.HasIndex(r => new { r.ContextType, r.ContextId, r.RaterId, r.TargetType, r.TargetId })
             .IsUnique();
            e.HasIndex(r => new { r.TargetType, r.TargetId, r.CreatedAt });
            e.Property(r => r.Tags).HasMaxLength(200);
            e.Property(r => r.Comment).HasMaxLength(500);

            e.HasOne(r => r.Rater)
             .WithMany()
             .HasForeignKey(r => r.RaterId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── Wallet ────────────────────────────────────────────────────────────
        modelBuilder.Entity<Wallet>(e =>
        {
            e.Property(w => w.Balance).HasPrecision(12, 2);

            e.HasOne(w => w.User)
             .WithOne(u => u.Wallet)
             .HasForeignKey<Wallet>(w => w.UserId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── WalletTransaction ─────────────────────────────────────────────────
        modelBuilder.Entity<WalletTransaction>(e =>
        {
            e.Property(t => t.Amount).HasPrecision(12, 2);
            e.Property(t => t.PaymentReference).HasMaxLength(100);

            // عملية دفع واحدة = حركة واحدة. الفحص بـ AnyAsync قبل الإضافة لا
            // يكفي: تأكيدُ التطبيق وإشعارُ البوابة قد يصلان معاً، فيمرّان كلاهما
            // من الفحص ويشحنان مرتين. القيد هنا يجعل الثانية تفشل لا تُضاعف.
            // NULL لا يتزاحم في MySQL، فالحركات الداخلية بلا مرجع لا تتأثر.
            e.HasIndex(t => t.PaymentReference).IsUnique();

            e.HasOne(t => t.Wallet)
             .WithMany(w => w.Transactions)
             .HasForeignKey(t => t.WalletId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── Subscription ──────────────────────────────────────────────────────
        modelBuilder.Entity<Subscription>(e =>
        {
            e.HasOne(s => s.User)
             .WithOne(u => u.Subscription)
             .HasForeignKey<Subscription>(s => s.UserId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(s => s.Package)
             .WithMany(p => p.Subscriptions)
             .HasForeignKey(s => s.PackageId)
             .OnDelete(DeleteBehavior.SetNull);
        });

        // ── Package ───────────────────────────────────────────────────────────
        modelBuilder.Entity<Package>(e =>
        {
            e.HasIndex(p => p.Key).IsUnique();
            e.Property(p => p.Price).HasPrecision(10, 2);
            e.Property(p => p.PointsMultiplier).HasPrecision(5, 2);
            e.Property(p => p.BookingDiscountPercent).HasPrecision(5, 2);
        });

        // ── PointsTransaction ─────────────────────────────────────────────────
        modelBuilder.Entity<PointsTransaction>(e =>
        {
            e.HasIndex(t => t.UserId);
            e.HasIndex(t => new { t.UserId, t.Type, t.ReferenceId });
            // لوحات المتصدرين تجمع حركات نوع واحد ضمن فترة زمنية.
            e.HasIndex(t => new { t.Kind, t.CreatedAt });

            e.HasOne(t => t.User)
             .WithMany()
             .HasForeignKey(t => t.UserId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── PlayerLevelDefinition (سُلَّم المستويات المعروض) ────────────────────
        modelBuilder.Entity<PlayerLevelDefinition>(e =>
        {
            e.Property(l => l.Value).HasPrecision(3, 1);
            e.Property(l => l.TitleAr).HasMaxLength(100);
            e.Property(l => l.TitleEn).HasMaxLength(100);
            e.Property(l => l.DescriptionAr).HasMaxLength(500);
            e.Property(l => l.DescriptionEn).HasMaxLength(500);
            e.HasIndex(l => l.Value).IsUnique();
        });

        // ── Friendship ────────────────────────────────────────────────────────
        modelBuilder.Entity<Friendship>(e =>
        {
            e.HasIndex(f => new { f.SenderId, f.ReceiverId }).IsUnique();

            e.HasOne(f => f.Sender)
             .WithMany(u => u.SentFriendRequests)
             .HasForeignKey(f => f.SenderId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(f => f.Receiver)
             .WithMany(u => u.ReceivedFriendRequests)
             .HasForeignKey(f => f.ReceiverId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── Follow (one-directional) ────────────────────────────────────────────
        modelBuilder.Entity<Follow>(e =>
        {
            e.HasIndex(f => new { f.FollowerId, f.FollowingId }).IsUnique();

            e.HasOne(f => f.Follower)
             .WithMany()
             .HasForeignKey(f => f.FollowerId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(f => f.Following)
             .WithMany()
             .HasForeignKey(f => f.FollowingId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── Sport ─────────────────────────────────────────────────────────────
        modelBuilder.Entity<Sport>(e =>
        {
            e.HasIndex(s => s.Key).IsUnique();
        });

        // ── SportSetting ──────────────────────────────────────────────────────
        modelBuilder.Entity<SportSetting>(e =>
        {
            e.Property(s => s.Title).HasMaxLength(200);
            e.HasOne(s => s.Sport)
             .WithMany(sp => sp.Settings)
             .HasForeignKey(s => s.SportId)
             .OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(s => s.SportId);
        });

        // ── Notification ──────────────────────────────────────────────────────
        modelBuilder.Entity<Notification>(e =>
        {
            e.HasOne(n => n.User)
             .WithMany(u => u.Notifications)
             .HasForeignKey(n => n.UserId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── SupportConversation (الدعم الفني) ──────────────────────────────────
        modelBuilder.Entity<SupportConversation>(e =>
        {
            e.Property(c => c.LastMessageText).HasMaxLength(300);

            // محادثة واحدة لكل مستخدم — الفهرس الفريد يمنع ازدواج المحادثات لو
            // ضغط المستخدم "إرسال" مرتين في آنٍ واحد.
            e.HasIndex(c => c.UserId).IsUnique();

            // ترتيب قائمة الإدارة (الأحدث نشاطاً أولاً).
            e.HasIndex(c => c.LastMessageAt);

            e.HasOne(c => c.User)
             .WithMany()
             .HasForeignKey(c => c.UserId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── SupportMessage ────────────────────────────────────────────────────
        modelBuilder.Entity<ServiceZone>(e =>
        {
            e.Property(z => z.NameAr).HasMaxLength(200);
            e.Property(z => z.NameEn).HasMaxLength(200);
            e.Property(z => z.PolygonJson).HasColumnType("longtext");
            e.Property(z => z.Color).HasMaxLength(20);
        });

        modelBuilder.Entity<SupportMessage>(e =>
        {
            e.Property(m => m.Body).HasMaxLength(4000);
            e.Property(m => m.SenderName).HasMaxLength(200);

            // ترقيم صفحات السجل يمشي على (المحادثة، المعرّف) تنازلياً.
            e.HasIndex(m => new { m.ConversationId, m.Id });

            e.HasOne(m => m.Conversation)
             .WithMany(c => c.Messages)
             .HasForeignKey(m => m.ConversationId)
             .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
