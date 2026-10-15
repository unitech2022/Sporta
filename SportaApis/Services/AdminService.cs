using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

public class AdminService : IAdminService
{
    private readonly AppDbContext _db;
    private readonly INotificationService _notifications;
    private readonly IAdminContext _admin;
    private readonly IWalletService _wallet;
    private readonly IAuthService _auth;

    public AdminService(
        AppDbContext db, INotificationService notifications, IAdminContext admin,
        IWalletService wallet, IAuthService auth)
    {
        _db = db;
        _notifications = notifications;
        _admin = admin;
        _wallet = wallet;
        _auth = auth;
    }

    public async Task<AdminStatsDto> GetStatsAsync()
    {
        // كل عدّاد يُحصر في نطاق الموظف الجغرافي (الأدمن: بلا حصر). الإعلانات
        // والبطولات عامة على مستوى المنصة فتبقى كما هي.
        var scope = await _admin.GetScopeAsync();
        var users = _db.Users.InScope(scope);
        var venues = _db.Venues.NotDeleted().InScope(scope);
        var courts = _db.Courts.NotDeleted().InScope(scope);
        var bookings = _db.Bookings.InScope(scope);
        var sessions = _db.CoachSessions
            .Where(s => users.Any(u => u.Id == s.CoachProfile.UserId));

        var bookingRevenue = await bookings
            .Where(b => b.PaidFullAmount)
            .SumAsync(b => (decimal?)b.TotalPrice) ?? 0m;
        var sessionRevenue = await sessions
            .Where(s => s.IsPaid)
            .SumAsync(s => (decimal?)s.Price) ?? 0m;

        return new AdminStatsDto
        {
            TotalUsers = await users.CountAsync(),
            TotalPlayers = await users.CountAsync(u => u.Roles.Any(r => r.Role == UserType.Player)),
            TotalCoaches = await _db.CoachProfiles.CountAsync(c => users.Any(u => u.Id == c.UserId)),
            TotalVenueOwners = await users.CountAsync(u => u.Roles.Any(r => r.Role == UserType.VenueOwner)),
            TotalVenues = await venues.CountAsync(),
            TotalCourts = await courts.CountAsync(),
            TotalMatches = await _db.Matches.InScope(scope).CountAsync(),
            TotalBookings = await bookings.CountAsync(),
            PendingBookings = await bookings.CountAsync(b => b.Status == BookingStatus.Pending),
            TotalCoachSessions = await sessions.CountAsync(),
            TotalAds = await _db.Ads.CountAsync(),
            TotalTournaments = await _db.Tournaments.CountAsync(),
            TotalRevenue = bookingRevenue + sessionRevenue,
        };
    }

    public async Task<PagedResult<AdminUserDto>> GetUsersAsync(
        string? role, string? search, int page, int pageSize)
    {
        var query = _db.Users
            .Include(u => u.Roles)
            .Include(u => u.PlayerProfile)
            .InScope(await _admin.GetScopeAsync())
            // الحسابات المحذوفة مُبهَّمة الهوية ولا يمكن التعامل معها — تُستثنى.
            .Where(u => !u.IsDeleted)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(role))
        {
            var roleType = role.ToLowerInvariant() switch
            {
                "player" => (UserType?)UserType.Player,
                "coach" => UserType.Coach,
                "venue" or "venueowner" => UserType.VenueOwner,
                "admin" => UserType.Admin,
                "staff" => UserType.Staff,
                _ => null,
            };
            if (roleType is UserType rt)
                query = query.Where(u => u.Roles.Any(r => r.Role == rt));
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(u =>
                u.FirstName.Contains(s) || u.LastName.Contains(s) ||
                u.PhoneNumber.Contains(s));
        }

        var total = await query.CountAsync();
        var users = await query
            .OrderByDescending(u => u.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<AdminUserDto>
        {
            Items = users.Select(ToUserDto).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    public async Task<AdminUserDetailDto?> GetUserAsync(int userId)
    {
        var u = await _db.Users
            .Include(x => x.Roles)
            .Include(x => x.PlayerProfile)
            .Include(x => x.CoachProfile).ThenInclude(c => c!.Sport)
            .Include(x => x.CoachProfile).ThenInclude(c => c!.PreferredVenue)
            .Include(x => x.CoachProfile).ThenInclude(c => c!.Specializations)
                .ThenInclude(s => s.Specialization)
            .Include(x => x.StaffProfile).ThenInclude(s => s!.Country)
            .Include(x => x.StaffProfile).ThenInclude(s => s!.City)
            .Include(x => x.StaffProfile).ThenInclude(s => s!.Permissions)
            .Include(x => x.Wallet)
            .Include(x => x.Subscription).ThenInclude(s => s!.Package)
            .InScope(await _admin.GetScopeAsync())
            .AsSplitQuery()
            .FirstOrDefaultAsync(x => x.Id == userId);
        if (u is null) return null;

        var dto = new AdminUserDetailDto
        {
            // الحقول المشتركة مع القائمة
            Id = u.Id,
            FirstName = u.FirstName,
            LastName = u.LastName,
            FullName = $"{u.FirstName} {u.LastName}".Trim(),
            Phone = u.PhoneNumber,
            City = u.City,
            FavoriteSport = u.FavoriteSport,
            Roles = RoleKeys(u),
            PendingRoles = PendingRoleKeys(u),
            Level = u.PlayerProfile != null ? (int)u.PlayerProfile.Level : null,
            IsActive = u.IsActive,
            CreatedAt = u.CreatedAt,
            AvatarUrl = u.ProfileImageUrl,

            // بيانات شخصية
            Gender = u.Gender switch
            {
                Enums.Gender.Male => "male",
                Enums.Gender.Female => "female",
                _ => null,
            },
            Country = u.Country,
            District = u.District,
            PreferredLanguage = u.PreferredLanguage == Language.English ? "en" : "ar",
            Latitude = u.Latitude,
            Longitude = u.Longitude,
            UserType = RoleKey(u.UserType),
            UpdatedAt = u.UpdatedAt,

            // الحساب البنكي والوثائق
            Iban = u.Iban,
            BankName = u.BankName,
            AccountHolderName = u.AccountHolderName,
            IdImageUrl = u.IdImageUrl,
            CommercialRegistrationImageUrl = u.CommercialRegistrationImageUrl,
            TaxCertificateImageUrl = u.TaxCertificateImageUrl,

            WalletBalance = u.Wallet?.Balance ?? 0m,
            PointsBalance = u.PointsBalance,
        };

        if (u.Subscription is Models.Subscription sub)
        {
            dto.Subscription = new AdminUserSubscriptionDto
            {
                Plan = sub.Plan == SubscriptionPlan.SportaPlus ? "sportaPlus" : "free",
                PackageName = sub.Package?.Name,
                StartDate = sub.StartDate,
                EndDate = sub.EndDate,
                IsActive = sub.IsActive,
            };
        }

        if (u.PlayerProfile is Models.PlayerProfile p)
        {
            var assessmentName = p.AssessmentLevelId is int levelId
                ? await _db.AssessmentLevels
                    .Where(l => l.Id == levelId)
                    .Select(l => (string?)l.NameAr)
                    .FirstOrDefaultAsync()
                : null;

            dto.Player = new AdminUserPlayerDto
            {
                Level = (int)p.Level,
                AssessmentLevelName = assessmentName,
                PreferredHand = p.PreferredHand == PreferredHand.Left ? "left" : "right",
                CourtPosition = p.CourtPosition switch
                {
                    CourtPosition.Left => "left",
                    CourtPosition.Both => "both",
                    _ => "right",
                },
                PreferredMatchType = p.PreferredMatchType.ToString().ToLowerInvariant(),
                PreferredPlayTime = p.PreferredPlayTime.ToString().ToLowerInvariant(),
                PlayStartYear = p.PlayStartYear,
                EloRating = p.EloRating,
                ReliabilityScore = p.ReliabilityScore,
                TotalMatches = p.TotalMatches,
                TotalWins = p.TotalWins,
                WinRate = p.WinRate,
                PeerRatingAverage = p.PeerRatingAverage,
                PeerRatingCount = p.PeerRatingCount,
            };
        }

        if (u.CoachProfile is Models.CoachProfile c)
        {
            dto.Coach = new AdminUserCoachDto
            {
                CoachProfileId = c.Id,
                Bio = c.Bio,
                Specialization = c.Specialization,
                SpecializationNames = c.Specializations
                    .Where(s => s.Specialization != null)
                    .Select(s => s.Specialization.NameAr)
                    .ToList(),
                SportName = c.Sport?.NameAr,
                HourlyRate = c.HourlyRate,
                PackagePrice = c.PackagePrice,
                Certifications = c.Certifications,
                ExperienceLevel = c.ExperienceLevel switch
                {
                    CoachExperienceLevel.OneToThree => "oneToThree",
                    CoachExperienceLevel.ThreeToFive => "threeToFive",
                    CoachExperienceLevel.MoreThanFive => "moreThanFive",
                    _ => "lessThanYear",
                },
                TargetGender = c.TargetGender == Enums.Gender.Female ? "female" : "male",
                Residency = c.Residency == CoachResidency.Resident ? "resident" : "saudi",
                PreferredVenueName = c.PreferredVenue?.Name,
                AvailableDays = string.IsNullOrWhiteSpace(c.AvailableDays)
                    ? []
                    : c.AvailableDays
                        .Split(',', StringSplitOptions.RemoveEmptyEntries)
                        .ToList(),
                IsVerified = c.IsVerifiedOnPlatform,
                Rating = c.Rating,
                TotalRatings = c.TotalRatings,
                TotalSessions = c.TotalSessions,
                NationalIdFrontUrl = c.NationalIdFrontUrl,
                NationalIdBackUrl = c.NationalIdBackUrl,
                IdDocumentUrl = c.IdDocumentUrl,
            };
        }

        if (u.StaffProfile is Models.StaffProfile st)
        {
            dto.Staff = new AdminUserStaffDto
            {
                JobTitle = st.JobTitle,
                CountryName = st.Country?.NameAr,
                CityName = st.City?.NameAr,
                Permissions = st.Permissions.Select(x => x.Permission).ToList(),
            };
        }

        dto.Venues = await _db.Venues
            .NotDeleted()
            .Where(v => v.OwnerId == u.Id)
            .OrderBy(v => v.Name)
            .Select(v => new AdminUserVenueDto
            {
                Id = v.Id,
                Name = v.Name,
                City = v.City,
                IsActive = v.IsActive,
                IsApproved = v.IsApproved,
                Courts = v.Courts.Count,
                ImageUrl = v.ImageUrl,
                Images = v.Images.Select(i => i.Url).ToList(),
                CommercialRegistrationImageUrl = v.CommercialRegistrationImageUrl,
                NationalAddressImageUrl = v.NationalAddressImageUrl,
                OwnerIdImageUrl = v.OwnerIdImageUrl,
            })
            .ToListAsync();

        dto.Activity = await BuildActivityAsync(u.Id, u.CoachProfile?.Id);
        await FillRecentAsync(dto, u.Id, u.CoachProfile?.Id);
        return dto;
    }

    /// <summary>أحدث <see cref="RecentTake"/> سجل من كل نوع نشاط.</summary>
    private const int RecentTake = 10;

    private async Task FillRecentAsync(AdminUserDetailDto dto, int userId, int? coachProfileId)
    {
        dto.RecentBookings = await _db.Bookings
            .Where(b => b.UserId == userId)
            .OrderByDescending(b => b.StartTime)
            .Take(RecentTake)
            .Select(b => new AdminUserBookingDto
            {
                Id = b.Id,
                CourtName = b.Court.Name,
                VenueName = b.Court.Venue.Name,
                StartTime = b.StartTime,
                EndTime = b.EndTime,
                TotalPrice = b.TotalPrice,
                Status = b.Status.ToString(),
                PaidFullAmount = b.PaidFullAmount,
            })
            .ToListAsync();

        dto.RecentMatches = await _db.MatchPlayers
            .Where(mp => mp.UserId == userId)
            .OrderByDescending(mp => mp.Match.ScheduledAt)
            .Take(RecentTake)
            .Select(mp => new AdminUserMatchDto
            {
                Id = mp.MatchId,
                MatchType = mp.Match.MatchType.ToString(),
                Status = mp.Match.Status.ToString(),
                ScheduledAt = mp.Match.ScheduledAt,
                CourtName = mp.Match.Court != null ? mp.Match.Court.Name : null,
                VenueName = mp.Match.Court != null ? mp.Match.Court.Venue.Name : null,
                PricePerPlayer = mp.Match.PricePerPlayer,
                IsCreator = mp.Match.CreatorId == userId,
                Score = mp.Match.Team1Score != null && mp.Match.Team2Score != null
                    ? mp.Match.Team1Score + " - " + mp.Match.Team2Score
                    : null,
            })
            .ToListAsync();

        dto.SessionsAsPlayer = await _db.CoachSessions
            .Where(s => s.PlayerId == userId)
            .OrderByDescending(s => s.ScheduledAt)
            .Take(RecentTake)
            .Select(s => new AdminUserSessionDto
            {
                Id = s.Id,
                Title = s.Title,
                CounterpartName = s.CoachProfile.User.FirstName + " " + s.CoachProfile.User.LastName,
                ScheduledAt = s.ScheduledAt,
                DurationMinutes = s.DurationMinutes,
                Price = s.Price,
                Status = s.Status.ToString(),
                IsCompleted = s.IsCompleted,
                IsPaid = s.IsPaid,
                CourtName = s.Court != null ? s.Court.Name : null,
            })
            .ToListAsync();

        if (coachProfileId is int cid)
        {
            dto.SessionsAsCoach = await _db.CoachSessions
                .Where(s => s.CoachProfileId == cid)
                .OrderByDescending(s => s.ScheduledAt)
                .Take(RecentTake)
                .Select(s => new AdminUserSessionDto
                {
                    Id = s.Id,
                    Title = s.Title,
                    CounterpartName = s.Player.FirstName + " " + s.Player.LastName,
                    ScheduledAt = s.ScheduledAt,
                    DurationMinutes = s.DurationMinutes,
                    Price = s.Price,
                    Status = s.Status.ToString(),
                    IsCompleted = s.IsCompleted,
                    IsPaid = s.IsPaid,
                    CourtName = s.Court != null ? s.Court.Name : null,
                })
                .ToListAsync();
        }

        dto.RecentWalletTransactions = await _db.WalletTransactions
            .Where(t => t.Wallet.UserId == userId)
            .OrderByDescending(t => t.CreatedAt)
            .Take(RecentTake)
            .Select(t => new AdminUserWalletTxDto
            {
                Id = t.Id,
                Amount = t.Amount,
                Type = t.Type.ToString(),
                Status = t.Status.ToString(),
                Description = t.Description,
                CreatedAt = t.CreatedAt,
            })
            .ToListAsync();

        dto.Friends = await _db.Friendships
            .Where(f => f.Status == FriendshipStatus.Accepted &&
                        (f.SenderId == userId || f.ReceiverId == userId))
            .OrderByDescending(f => f.RespondedAt)
            .Take(RecentTake)
            .Select(f => f.SenderId == userId ? f.Receiver : f.Sender)
            .Select(o => new AdminUserFriendDto
            {
                Id = o.Id,
                FullName = o.FirstName + " " + o.LastName,
                AvatarUrl = o.ProfileImageUrl,
                City = o.City,
            })
            .ToListAsync();
    }

    /// <summary>عدّادات نشاط الحساب — استعلامات عدّ فقط (بلا تحميل صفوف).</summary>
    private async Task<AdminUserActivityDto> BuildActivityAsync(int userId, int? coachProfileId)
    {
        var bookings = _db.Bookings.Where(b => b.UserId == userId);
        var lastBooking = await bookings
            .OrderByDescending(b => b.CreatedAt)
            .Select(b => (DateTime?)b.CreatedAt)
            .FirstOrDefaultAsync();

        return new AdminUserActivityDto
        {
            TotalBookings = await bookings.CountAsync(),
            CancelledBookings =
                await bookings.CountAsync(b => b.Status == BookingStatus.Cancelled),
            TotalSpent = await bookings
                .Where(b => b.Status != BookingStatus.Cancelled)
                .SumAsync(b => (decimal?)b.TotalPrice) ?? 0m,
            TotalMatches = await _db.MatchPlayers.CountAsync(mp => mp.UserId == userId),
            CoachSessionsAsPlayer =
                await _db.CoachSessions.CountAsync(s => s.PlayerId == userId),
            CoachSessionsAsCoach = coachProfileId is int cid
                ? await _db.CoachSessions.CountAsync(s => s.CoachProfileId == cid)
                : 0,
            Friends = await _db.Friendships.CountAsync(f =>
                (f.SenderId == userId || f.ReceiverId == userId) &&
                f.Status == FriendshipStatus.Accepted),
            Notifications = await _db.Notifications.CountAsync(n => n.UserId == userId),
            LastActivityAt = lastBooking,
        };
    }

    public async Task<PagedResult<AdminNotificationDto>> GetNotificationsAsync(
        int page, int pageSize)
    {
        // البث العام يُخزَّن سطراً لكل مستخدم، فكان يظهر في السجل مكرَّراً بعدد
        // المستخدمين. يُجمَّع هنا في سطر واحد: نفس العنوان والنص في الدقيقة
        // نفسها. باقي الإشعارات كلٌّ في مجموعته (مفتاحها معرّفه).
        const string broadcast = "admin_broadcast";
        var groups = _db.Notifications
            .InScope(await _admin.GetScopeAsync())
            .GroupBy(n => new
            {
                Single = n.ReferenceType == broadcast ? 0 : n.Id,
                n.Title,
                n.Body,
                n.CreatedAt.Year,
                n.CreatedAt.Month,
                n.CreatedAt.Day,
                n.CreatedAt.Hour,
                n.CreatedAt.Minute,
            })
            .Select(g => new
            {
                Id = g.Min(n => n.Id),
                IsBroadcast = g.Key.Single == 0,
                Count = g.Count(),
                Read = g.Sum(n => n.IsRead ? 1 : 0),
                CreatedAt = g.Max(n => n.CreatedAt),
            });

        var total = await groups.CountAsync();
        var rows = await groups
            .OrderByDescending(g => g.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var ids = rows.Select(r => r.Id).ToList();
        var heads = await _db.Notifications.Include(n => n.User)
            .Where(n => ids.Contains(n.Id))
            .ToDictionaryAsync(n => n.Id);

        return new PagedResult<AdminNotificationDto>
        {
            Items = rows.Where(r => heads.ContainsKey(r.Id)).Select(r =>
            {
                var n = heads[r.Id];
                return new AdminNotificationDto
                {
                    Id = n.Id,
                    UserId = n.UserId,
                    UserName = r.IsBroadcast || n.User == null
                        ? string.Empty
                        : $"{n.User.FirstName} {n.User.LastName}".Trim(),
                    IsBroadcast = r.IsBroadcast,
                    RecipientCount = r.Count,
                    ReadCount = r.Read,
                    Title = n.Title,
                    Body = n.Body,
                    Type = n.ReferenceType,
                    IsRead = r.Read == r.Count,
                    CreatedAt = r.CreatedAt,
                };
            }).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    public Task<int> GetUnreadNotificationsCountAsync() =>
        _db.Notifications.CountAsync(n => !n.IsRead);

    public async Task<PagedResult<AdminBookingDto>> GetBookingsAsync(
        string? status, int page, int pageSize)
    {
        var query = _db.Bookings
            .Include(b => b.User)
            .Include(b => b.Court).ThenInclude(c => c.Venue)
            .InScope(await _admin.GetScopeAsync())
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(status) &&
            Enum.TryParse<BookingStatus>(status, ignoreCase: true, out var s))
            query = query.Where(b => b.Status == s);

        var total = await query.CountAsync();
        var bookings = await query
            .OrderByDescending(b => b.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<AdminBookingDto>
        {
            Items = bookings.Select(ToBookingDto).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    public async Task<AdminBookingDto?> GetBookingAsync(int bookingId)
    {
        var b = await _db.Bookings
            .Include(x => x.User)
            .Include(x => x.Court).ThenInclude(c => c.Venue)
            .InScope(await _admin.GetScopeAsync())
            .FirstOrDefaultAsync(x => x.Id == bookingId);
        return b is null ? null : ToBookingDto(b);
    }

    // ── Finance ──────────────────────────────────────────────────────────────

    public async Task<FinanceStatsDto> GetFinanceStatsAsync()
    {
        // Aggregate every wallet transaction by type (signed sums). Failed
        // attempts are audit rows that never moved money — they must not count.
        var scope = await _admin.GetScopeAsync();
        var grouped = await _db.WalletTransactions
            .InScope(scope)
            .Where(t => t.Status == PaymentStatus.Completed)
            .GroupBy(t => t.Type)
            .Select(g => new
            {
                Type = g.Key,
                Amount = g.Sum(x => x.Amount),
                Count = g.Count(),
            })
            .ToListAsync();

        decimal SumOf(params WalletTransactionType[] types) =>
            grouped.Where(x => types.Contains(x.Type)).Sum(x => x.Amount);

        var deposits = SumOf(WalletTransactionType.Deposit);
        var refunds = SumOf(WalletTransactionType.Refund);
        var earnings = SumOf(
            WalletTransactionType.CoachEarning,
            WalletTransactionType.VenueEarning,
            WalletTransactionType.CreatorEarning);
        var spend = Math.Abs(SumOf(
            WalletTransactionType.MatchPayment,
            WalletTransactionType.BookingPayment,
            WalletTransactionType.CoachPayment,
            WalletTransactionType.Subscription));

        // Real cash out = withdrawals actually approved and paid to banks.
        // بنفس نطاق الموظف الجغرافي الذي جُمعت به الحركات أعلاه، وإلا اختلطت
        // أرقام عامة بأرقام مدينة واحدة في نفس البطاقة.
        var approvedWithdrawals = await _db.WithdrawalRequests
            .InScope(scope)
            .Where(w => w.Status == WithdrawalStatus.Approved)
            .SumAsync(w => (decimal?)w.Amount) ?? 0m;

        var pendingWithdrawals = await _db.WithdrawalRequests
            .InScope(scope)
            .Where(w => w.Status == WithdrawalStatus.Pending)
            .ToListAsync();

        // المحافظ تتبع مدينة أصحابها.
        var walletBalance = await _db.Users
            .InScope(scope)
            .Where(u => u.Wallet != null)
            .SumAsync(u => (decimal?)u.Wallet!.Balance) ?? 0m;

        return new FinanceStatsDto
        {
            TotalIncoming = deposits,
            TotalOutgoing = approvedWithdrawals,
            NetFlow = deposits - approvedWithdrawals,
            TotalDeposits = deposits,
            TotalRefunds = refunds,
            TotalEarnings = earnings,
            TotalSpend = spend,
            TotalWalletBalance = walletBalance,
            PendingWithdrawalsCount = pendingWithdrawals.Count,
            PendingWithdrawalsAmount = pendingWithdrawals.Sum(w => w.Amount),
            TransactionCount = grouped.Sum(x => x.Count),
            ByType = grouped
                .Select(x => new FinanceTypeBreakdown
                {
                    Type = CamelType(x.Type),
                    Amount = Math.Abs(x.Amount),
                    Count = x.Count,
                })
                .OrderByDescending(x => x.Amount)
                .ToList(),
        };
    }

    public async Task<PagedResult<AdminTransactionDto>> GetTransactionsAsync(
        string? type, string? search, int page, int pageSize, string? status = null)
    {
        var query = _db.WalletTransactions
            .Include(t => t.Wallet).ThenInclude(w => w.User)
            .InScope(await _admin.GetScopeAsync())
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(type) &&
            Enum.TryParse<WalletTransactionType>(type, ignoreCase: true, out var t))
            query = query.Where(x => x.Type == t);

        if (!string.IsNullOrWhiteSpace(status) &&
            Enum.TryParse<PaymentStatus>(status, ignoreCase: true, out var st))
            query = query.Where(x => x.Status == st);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(x =>
                x.Wallet.User.FirstName.Contains(s) ||
                x.Wallet.User.LastName.Contains(s) ||
                x.Wallet.User.PhoneNumber.Contains(s) ||
                (x.PaymentReference != null && x.PaymentReference.Contains(s)));
        }

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<AdminTransactionDto>
        {
            Items = items.Select(ToTransactionDto).ToList(),
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
    }

    public async Task<AdminTransactionDto?> GetTransactionAsync(int transactionId)
    {
        var t = await _db.WalletTransactions
            .Include(x => x.Wallet).ThenInclude(w => w.User)
            .InScope(await _admin.GetScopeAsync())
            .FirstOrDefaultAsync(x => x.Id == transactionId);
        return t is null ? null : ToTransactionDto(t);
    }

    private static AdminTransactionDto ToTransactionDto(Models.WalletTransaction t)
    {
        var user = t.Wallet?.User;
        return new AdminTransactionDto
        {
            Id = t.Id,
            UserId = t.Wallet?.UserId ?? 0,
            UserName = user != null ? $"{user.FirstName} {user.LastName}".Trim() : string.Empty,
            UserPhone = user?.PhoneNumber ?? string.Empty,
            Amount = t.Amount,
            Type = CamelType(t.Type),
            Direction = t.Amount >= 0 ? "in" : "out",
            Status = char.ToLowerInvariant(t.Status.ToString()[0]) + t.Status.ToString()[1..],
            Description = t.Description,
            ReferenceId = t.ReferenceId,
            PaymentReference = t.PaymentReference,
            InternalReference = $"TXN-{t.Id:D6}",
            CreatedAt = t.CreatedAt,
        };
    }

    private static string CamelType(WalletTransactionType type)
    {
        var name = type.ToString();
        return char.ToLowerInvariant(name[0]) + name[1..];
    }

    private static AdminBookingDto ToBookingDto(Models.Booking b) => new()
    {
        Id = b.Id,
        UserId = b.UserId,
        UserName = b.User != null ? $"{b.User.FirstName} {b.User.LastName}".Trim() : string.Empty,
        CourtName = b.Court?.Name ?? string.Empty,
        VenueName = b.Court?.Venue?.Name ?? string.Empty,
        City = b.Court?.Venue?.City ?? string.Empty,
        StartTime = b.StartTime,
        EndTime = b.EndTime,
        DurationMinutes = (int)(b.EndTime - b.StartTime).TotalMinutes,
        TotalPrice = b.TotalPrice,
        SportaCommission = b.SportaCommission,
        OwnerAmount = b.OwnerAmount,
        Status = b.Status.ToString(),
        PaidFullAmount = b.PaidFullAmount,
        CreatedAt = b.CreatedAt,
    };

    private static AdminUserDto ToUserDto(Models.User u) => new()
    {
        Id = u.Id,
        FirstName = u.FirstName,
        LastName = u.LastName,
        FullName = $"{u.FirstName} {u.LastName}".Trim(),
        Phone = u.PhoneNumber,
        City = u.City,
        FavoriteSport = u.FavoriteSport,
        Roles = RoleKeys(u),
        PendingRoles = PendingRoleKeys(u),
        Level = u.PlayerProfile != null ? (int)u.PlayerProfile.Level : null,
        IsActive = u.IsActive,
        CreatedAt = u.CreatedAt,
        AvatarUrl = u.ProfileImageUrl,
    };

    /// <summary>أدوار المستخدم كمفاتيح نصّية تفهمها لوحة التحكم.</summary>
    private static List<string> RoleKeys(Models.User u) =>
        u.Roles.Select(r => RoleKey(r.Role)).Distinct().ToList();

    /// <summary>الأدوار التي تنتظر اعتماد الأدمن (مدرب/صاحب ملعب بعد التسجيل).</summary>
    private static List<string> PendingRoleKeys(Models.User u) =>
        u.Roles.Where(r => !r.IsApproved).Select(r => RoleKey(r.Role)).Distinct().ToList();

    private static string RoleKey(UserType type) => type switch
    {
        UserType.Coach => "coach",
        UserType.VenueOwner => "venue",
        UserType.Admin => "admin",
        UserType.Staff => "staff",
        _ => "player",
    };

    public Task BroadcastAsync(string title, string body) =>
        _notifications.PushToAllAsync(title, body, "admin_broadcast", null);

    /// <summary>
    /// يحذف الإشعارات المحددة (ضمن نطاق الموظف). مع <paramref name="wholeBroadcast"/>
    /// يُحذف البث العام من كل المستخدمين: كل الأسطر بنفس العنوان والنص ونوع
    /// admin_broadcast التي أُنشئت في الدقيقة نفسها. يعيد عدد المحذوف.
    /// </summary>
    public async Task<int> DeleteNotificationsAsync(List<int> ids, bool wholeBroadcast)
    {
        var picked = await _db.Notifications
            .InScope(await _admin.GetScopeAsync())
            .Where(n => ids.Contains(n.Id))
            .ToListAsync();
        var toDelete = picked.ToDictionary(n => n.Id);

        if (wholeBroadcast)
        {
            foreach (var b in picked.Where(n => n.ReferenceType == "admin_broadcast"))
            {
                var from = b.CreatedAt.AddMinutes(-1);
                var to = b.CreatedAt.AddMinutes(1);
                var copies = await _db.Notifications
                    .Where(n => n.ReferenceType == "admin_broadcast"
                                && n.Title == b.Title && n.Body == b.Body
                                && n.CreatedAt >= from && n.CreatedAt <= to)
                    .ToListAsync();
                foreach (var c in copies) toDelete.TryAdd(c.Id, c);
            }
        }

        _db.Notifications.RemoveRange(toDelete.Values);
        await _db.SaveChangesAsync();
        return toDelete.Count;
    }

    public async Task SendToUserAsync(int userId, string title, string body)
    {
        var exists = await _db.Users.AnyAsync(u => u.Id == userId);
        if (!exists)
            throw new AuthException(
                "User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        await _notifications.PushAsync(userId, title, body, "admin_message", null);
    }

    public async Task SetLockedAsync(int userId, bool locked)
    {
        var user = await _db.Users
            .InScope(await _admin.GetScopeAsync())
            // الحساب المحذوف لا يُفعَّل ثانيةً — الحذف نهائي بطلب صاحبه.
            .Where(u => !u.IsDeleted)
            .FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException(
                "User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        user.IsActive = !locked;
        user.UpdatedAt = DateTime.UtcNow;

        if (locked)
        {
            // Revoke active refresh tokens so the session can't be renewed.
            var tokens = await _db.RefreshTokens
                .Where(t => t.UserId == userId && !t.IsRevoked)
                .ToListAsync();
            foreach (var t in tokens) t.IsRevoked = true;
        }

        await _db.SaveChangesAsync();

        await _notifications.PushAsync(
            userId,
            locked ? "تم إيقاف حسابك" : "تم تفعيل حسابك",
            locked
                ? "تم إيقاف حسابك من قبل إدارة المنصة. للاستفسار تواصل مع الدعم."
                : "تم إعادة تفعيل حسابك. يمكنك تسجيل الدخول الآن.",
            locked ? "account_locked" : "account_unlocked",
            null);
    }

    /// <summary>
    /// اعتماد (أو سحب اعتماد) دور المدرب/صاحب الملعب لحساب ما. الحساب يبقى
    /// يعمل كلاعب في الحالتين؛ الاعتماد وحده هو ما يفتح أقسام الدور.
    /// </summary>
    public async Task SetRoleApprovedAsync(int userId, UserType role, bool approved)
    {
        if (!UserRole.NeedsApproval(role))
            throw new AuthException(
                "This role does not require approval",
                "هذا الدور لا يحتاج إلى اعتماد", "ROLE_NOT_APPROVABLE");

        var user = await _db.Users
            .InScope(await _admin.GetScopeAsync())
            .FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException(
                "User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        var userRole = await _db.UserRoles
            .FirstOrDefaultAsync(r => r.UserId == userId && r.Role == role)
            ?? throw new AuthException(
                "User does not have this role",
                "هذا الحساب لا يملك هذا الدور", "ROLE_NOT_FOUND");

        // لا شيء يتغيّر — نتجنّب إشعاراً بلا سبب (نفس سلوك اعتماد الأندية).
        if (userRole.IsApproved == approved) return;

        userRole.IsApproved = approved;
        userRole.ApprovedAt = approved ? DateTime.UtcNow : null;
        userRole.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        var label = role == UserType.Coach ? "المدرب" : "الملعب";
        await _notifications.PushAsync(
            userId,
            approved ? "تم تفعيل حسابك" : "تم إيقاف حسابك مؤقتاً",
            approved
                ? $"تمت مراجعة بياناتك والموافقة على حساب {label}. يمكنك استخدام كل خصائصه الآن."
                : $"أُوقف حساب {label} مؤقتاً بانتظار مراجعة إضافية. للاستفسار تواصل مع الدعم.",
            approved ? "role_approved" : "role_approval_revoked",
            null);
    }

    public async Task<int> SetPlayerLevelAsync(int userId, int level)
    {
        if (level is < 1 or > 7)
            throw new AuthException(
                "Level must be between 1 and 7",
                "المستوى يجب أن يكون بين 1 و7", "INVALID_LEVEL");

        var user = await _db.Users
            .InScope(await _admin.GetScopeAsync())
            .Include(u => u.PlayerProfile)
            .FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException(
                "User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        var profile = user.PlayerProfile
            ?? throw new AuthException(
                "User has no player profile",
                "هذا الحساب ليس لاعباً", "NOT_A_PLAYER");

        var newLevel = (PlayerLevel)level;
        if (profile.Level == newLevel) return level;

        profile.Level = newLevel;

        // اسم المستوى المعروض يأتي من مستويات التقييم المعرّفة للرياضة، وترتيبها
        // هو نفسه الرقم (انظر PlayerService.SubmitSelfAssessment). نُحاذيه مع
        // الرقم الجديد، وإن لم يوجد نظيرٌ له نمسحه: اسمٌ يناقض الرقم أسوأ من
        // لا اسم.
        var sport = user.FavoriteSport;
        profile.AssessmentLevelId = string.IsNullOrWhiteSpace(sport)
            ? null
            : await _db.AssessmentLevels
                .Where(l => l.Sport == sport && l.IsActive && l.SortOrder == level)
                .Select(l => (int?)l.Id)
                .FirstOrDefaultAsync();

        profile.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        // المستوى يحدّد المباريات التي يحقّ له دخولها، فتغييره من طرفنا خبرٌ
        // يخصّه لا تفصيلٌ إداري.
        await _notifications.PushAsync(
            userId,
            "تم تحديث مستواك",
            $"أصبح مستواك الآن {level} ({PlayerLevelInfo.NameAr(newLevel)}).",
            "player_level_updated",
            null);

        return level;
    }

    public async Task SetCourtCommissionAsync(int courtId, decimal percent)
    {
        var court = await _db.Courts
            .NotDeleted()
            .InScope(await _admin.GetScopeAsync())
            .FirstOrDefaultAsync(c => c.Id == courtId)
            ?? throw new AuthException(
                "Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        court.SportaCommissionPercent = percent;
        court.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
    }

    public async Task SetCourtSuspendedAsync(int courtId, bool suspended)
    {
        var court = await _db.Courts
            .NotDeleted()
            .Include(c => c.Venue)
            .InScope(await _admin.GetScopeAsync())
            .FirstOrDefaultAsync(c => c.Id == courtId)
            ?? throw new AuthException(
                "Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        // No-op if the flag is already in the requested state (avoids a needless notification).
        if (court.IsSuspended == suspended) return;

        court.IsSuspended = suspended;
        court.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        await _notifications.PushAsync(
            court.Venue.OwnerId,
            suspended ? "تم إيقاف ملعبك" : "تم إعادة تفعيل ملعبك",
            suspended
                ? $"تم إيقاف ملعب \"{court.Name}\" من قبل إدارة المنصة ولن يظهر للاعبين. للاستفسار تواصل مع الدعم."
                : $"تمت إعادة تفعيل ملعب \"{court.Name}\" وأصبح متاحاً للاعبين مجدداً.",
            suspended ? "court_suspended" : "court_reinstated",
            court.Id);
    }

    public async Task SetVenueApprovedAsync(int venueId, bool approved)
    {
        var venue = await _db.Venues
            .NotDeleted()
            .InScope(await _admin.GetScopeAsync())
            .FirstOrDefaultAsync(v => v.Id == venueId)
            ?? throw new AuthException(
                "Venue not found", "الملعب غير موجود", "VENUE_NOT_FOUND");

        // No-op if the flag is already in the requested state (avoids a needless notification).
        if (venue.IsApproved == approved) return;

        venue.IsApproved = approved;
        venue.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        await _notifications.PushAsync(
            venue.OwnerId,
            approved ? "تمت الموافقة على ملعبك" : "أُلغيت الموافقة على ملعبك",
            approved
                ? $"تمت الموافقة على \"{venue.Name}\" وأصبح ظاهراً للاعبين الآن."
                : $"أُلغيت الموافقة على \"{venue.Name}\" ولن يظهر للاعبين حتى تتم مراجعته مجدداً.",
            approved ? "venue_approved" : "venue_approval_revoked",
            venue.Id);
    }

    public async Task DeleteUserAccountAsync(int userId, string? reason)
    {
        // الموظف لا يحذف إلا داخل نطاقه الجغرافي — نفس حصر بقية شاشات اللوحة.
        var scope = await _admin.GetScopeAsync();
        if (!await _db.Users.InScope(scope).AnyAsync(u => u.Id == userId))
            throw new AuthException(
                "User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        await _auth.AdminDeleteAccountAsync(userId, reason);
    }

    public async Task DeleteVenueAsync(int venueId)
    {
        var venue = await _db.Venues
            .Include(v => v.Courts)
            .InScope(await _admin.GetScopeAsync())
            .FirstOrDefaultAsync(v => v.Id == venueId && !v.IsDeleted)
            ?? throw new AuthException(
                "Venue not found", "النادي غير موجود", "VENUE_NOT_FOUND");

        var now = DateTime.UtcNow;
        var courts = venue.Courts.ToList();

        await CancelAndRefundUpcomingAsync(
            courts.Select(c => c.Id).ToList(),
            now,
            "حُذف النادي من إدارة المنصة",
            "أُلغي حجزك",
            "حُذف النادي من المنصة، وأُعيد المبلغ المدفوع إلى محفظتك.");

        foreach (var court in courts) MarkCourtDeleted(court, now);

        venue.IsDeleted = true;
        venue.DeletedAt = now;
        venue.IsActive = false;
        venue.IsApproved = false;
        venue.UpdatedAt = now;

        await _db.SaveChangesAsync();

        await _notifications.PushAsync(
            venue.OwnerId,
            "تم حذف ناديك",
            $"حُذف \"{venue.Name}\" وملاعبه من المنصة من قبل الإدارة. للاستفسار تواصل مع الدعم.",
            "venue_deleted",
            venue.Id);
    }

    public async Task DeleteCourtAsync(int courtId)
    {
        var court = await _db.Courts
            .Include(c => c.Venue)
            .InScope(await _admin.GetScopeAsync())
            .FirstOrDefaultAsync(c => c.Id == courtId && !c.IsDeleted)
            ?? throw new AuthException(
                "Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        var now = DateTime.UtcNow;

        await CancelAndRefundUpcomingAsync(
            [court.Id],
            now,
            "حُذف الملعب من إدارة المنصة",
            "أُلغي حجزك",
            "حُذف الملعب من المنصة، وأُعيد المبلغ المدفوع إلى محفظتك.");

        MarkCourtDeleted(court, now);
        await _db.SaveChangesAsync();

        await _notifications.PushAsync(
            court.Venue.OwnerId,
            "تم حذف ملعبك",
            $"حُذف ملعب \"{court.Name}\" من المنصة من قبل الإدارة. للاستفسار تواصل مع الدعم.",
            "court_deleted",
            court.Id);
    }

    /// <summary>الحذف ناعم دائماً — قيد قاعدة البيانات على الحجوزات يمنع مسح
    /// الصف، والسجل المالي يجب أن يبقى متماسكاً بعد اختفاء الملعب.</summary>
    private static void MarkCourtDeleted(Court court, DateTime now)
    {
        court.IsDeleted = true;
        court.DeletedAt = now;
        court.IsSuspended = true;
        court.IsAvailable = false;
        court.UpdatedAt = now;
    }

    /// <summary>
    /// يُلغي الحجوزات القادمة على الملاعب المُعطاة ويردّ ما دُفع إلى محافظ
    /// أصحابها — لا يجوز أن يخسر لاعبٌ مالَه لأن الإدارة حذفت الملعب.
    /// </summary>
    private async Task CancelAndRefundUpcomingAsync(
        List<int> courtIds, DateTime now,
        string cancellationReason, string notifyTitle, string notifyBody)
    {
        if (courtIds.Count == 0) return;

        // StartTime مخزّن بتوقيت السعودية بلا منطقة: المقارنة بـ AppClock لا بـ UTC،
        // وإلا عُدّت حجوزات بدأت قبل أقل من 3 ساعات «قادمة» واستُردّت.
        var affected = await _db.Bookings
            .Include(b => b.Court).ThenInclude(c => c.Venue)
            .Where(b => courtIds.Contains(b.CourtId) && b.StartTime > AppClock.Now &&
                        (b.Status == BookingStatus.Pending ||
                         b.Status == BookingStatus.Confirmed))
            .ToListAsync();
        if (affected.Count == 0) return;

        var confirmedIds = affected
            .Where(b => b.Status == BookingStatus.Confirmed)
            .Select(b => b.Id).ToHashSet();
        foreach (var b in affected)
        {
            b.Status = BookingStatus.Cancelled;
            b.CancelledAt = now;
            b.CancellationReason = cancellationReason;
            b.UpdatedAt = now;
        }

        // الحفظ قبل الاسترداد: خدمة المحفظة تكتب حركاتها على نفس السياق.
        await _db.SaveChangesAsync();

        foreach (var b in affected)
        {
            await BookingRefunds.RefundAsync(
                _wallet, b, confirmedIds.Contains(b.Id), b.Court.Venue.OwnerId,
                "استرداد حجز أُلغي لحذف الملعب");

            try
            {
                await _notifications.PushAsync(b.UserId, notifyTitle, notifyBody,
                    "booking_cancelled", b.Id);
            }
            catch
            {
                // إشعار أفضل-جهد: فشله لا يُبطل الحذف.
            }
        }
    }
}
