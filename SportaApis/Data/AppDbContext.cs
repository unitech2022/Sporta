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
    public DbSet<PlayerProfile> PlayerProfiles => Set<PlayerProfile>();
    public DbSet<CoachProfile> CoachProfiles => Set<CoachProfile>();
    public DbSet<Venue> Venues => Set<Venue>();
    public DbSet<Court> Courts => Set<Court>();
    public DbSet<Match> Matches => Set<Match>();
    public DbSet<MatchPlayer> MatchPlayers => Set<MatchPlayer>();
    public DbSet<AmericanoMatch> AmericanoMatches => Set<AmericanoMatch>();
    public DbSet<AmericanoRound> AmericanoRounds => Set<AmericanoRound>();
    public DbSet<Booking> Bookings => Set<Booking>();
    public DbSet<CoachSession> CoachSessions => Set<CoachSession>();
    public DbSet<LevelAssessment> LevelAssessments => Set<LevelAssessment>();
    public DbSet<MatchRating> MatchRatings => Set<MatchRating>();
    public DbSet<Wallet> Wallets => Set<Wallet>();
    public DbSet<WalletTransaction> WalletTransactions => Set<WalletTransaction>();
    public DbSet<Subscription> Subscriptions => Set<Subscription>();
    public DbSet<Friendship> Friendships => Set<Friendship>();
    public DbSet<Notification> Notifications => Set<Notification>();

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
        });

        // ── UserRole ──────────────────────────────────────────────────────────
        modelBuilder.Entity<UserRole>(e =>
        {
            e.HasIndex(r => new { r.UserId, r.Role }).IsUnique();
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

        // ── OtpCode ───────────────────────────────────────────────────────────
        modelBuilder.Entity<OtpCode>(e =>
        {
            e.Property(o => o.PhoneNumber).HasMaxLength(20);
            e.Property(o => o.Code).HasMaxLength(10);
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
        });

        // ── Venue ─────────────────────────────────────────────────────────────
        modelBuilder.Entity<Venue>(e =>
        {
            e.HasOne(v => v.Owner)
             .WithMany()
             .HasForeignKey(v => v.OwnerId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── Court ─────────────────────────────────────────────────────────────
        modelBuilder.Entity<Court>(e =>
        {
            e.Property(c => c.PricePerHour).HasPrecision(10, 2);

            e.HasOne(c => c.Venue)
             .WithMany(v => v.Courts)
             .HasForeignKey(c => c.VenueId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── Match ─────────────────────────────────────────────────────────────
        modelBuilder.Entity<Match>(e =>
        {
            e.Property(m => m.PricePerPlayer).HasPrecision(10, 2);

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
        modelBuilder.Entity<MatchPlayer>(e =>
        {
            e.HasIndex(mp => new { mp.MatchId, mp.UserId }).IsUnique();

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

            e.HasOne(s => s.CoachProfile)
             .WithMany(c => c.Sessions)
             .HasForeignKey(s => s.CoachProfileId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(s => s.Player)
             .WithMany()
             .HasForeignKey(s => s.PlayerId)
             .OnDelete(DeleteBehavior.Restrict);
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

        // ── Notification ──────────────────────────────────────────────────────
        modelBuilder.Entity<Notification>(e =>
        {
            e.HasOne(n => n.User)
             .WithMany(u => u.Notifications)
             .HasForeignKey(n => n.UserId)
             .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
