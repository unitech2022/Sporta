using System.Globalization;
using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

public class PointsService : IPointsService
{
    private readonly AppDbContext _db;
    private readonly IWalletService _wallet;
    private readonly ILogger<PointsService> _logger;
    private readonly IAdminContext _admin;

    public PointsService(
        AppDbContext db, IWalletService wallet, ILogger<PointsService> logger,
        IAdminContext admin)
    {
        _db = db;
        _wallet = wallet;
        _logger = logger;
        _admin = admin;
    }

    // مفاتيح SystemSettings (يديرها الأدمن من لوحة التحكم)
    public const string EarnPer10SarKey = "points_earn_per_10sar";
    public const string MatchRewardKey = "points_match_reward";
    public const string RedeemPerRiyalKey = "points_redeem_per_riyal";
    public const string MinRedeemKey = "points_min_redeem";

    /// <summary>نقاط المكافآت المخصومة عن كل انسحاب من حدث.</summary>
    public const string WithdrawalPenaltyKey = "points_withdrawal_penalty";
    public const int DefaultWithdrawalPenalty = 10;

    public const int DefaultEarnPer10Sar = 1;
    public const int DefaultMatchReward = 10;
    // وثيقة «المستويات والنقاط»: 500 نقطة = 50 ريالاً.
    public const int DefaultRedeemPerRiyal = 10;
    public const int DefaultMinRedeem = 500;

    /// <summary>هل يُشترط اعتماد مدرب للمستوى قبل احتساب نقاط المستوى؟</summary>
    public const string LevelRequireCoachKey = "level_points_require_coach";

    /// <summary>
    /// نقاط المكافآت لكل نشاط: (نوع الحركة → مفتاح الإعداد، التسمية، القيمة
    /// الافتراضية). الأدمن يعدّل القيم من لوحة التحكم.
    /// </summary>
    public static readonly IReadOnlyList<(PointsTransactionType Type, string Key, string Ar, string En, int Default)>
        RewardRules =
        [
            (PointsTransactionType.BookingConfirmed, "reward_points_booking", "حجز ملعب", "Court booking", 50),
            (PointsTransactionType.CoachSessionConfirmed, "reward_points_coach_session", "حجز تدريب", "Coach session booking", 50),
            (PointsTransactionType.MatchCreated, "reward_points_match_created", "إنشاء مباراة", "Creating a match", 30),
            (PointsTransactionType.AmericanoOrganized, "reward_points_americano", "تنظيم أمريكانو", "Organizing an americano", 100),
            (PointsTransactionType.TournamentOrganized, "reward_points_tournament", "تنظيم بطولة", "Organizing a tournament", 200),
            (PointsTransactionType.FriendInvited, "reward_points_invite_friend", "دعوة صديق للتطبيق", "Inviting a friend", 100),
            (PointsTransactionType.CourtRated, "reward_points_rate_court", "تقييم ملعب", "Rating a court", 20),
            (PointsTransactionType.CoachRated, "reward_points_rate_coach", "تقييم مدرب", "Rating a coach", 20),
        ];

    /// <summary>
    /// قواعد نقاط المستوى بحسب فرق المستوى بين الفريقين (متوسط كل فريق):
    /// «same» أقل من نصف درجة، «half» نصف درجة، «full» درجة فأكثر.
    /// </summary>
    public static readonly IReadOnlyList<(string Key, string Ar, string En, int Default)> LevelRules =
        [
            ("level_points_win_same", "فوز على خصم بنفس المستوى", "Win vs same level", 20),
            ("level_points_win_higher_half", "فوز على خصم أعلى بـ 0.5", "Win vs +0.5 level", 25),
            ("level_points_win_higher_full", "فوز على خصم أعلى بـ 1.0+", "Win vs +1.0 level", 35),
            ("level_points_win_lower_half", "فوز على خصم أقل بـ 0.5", "Win vs -0.5 level", 12),
            ("level_points_win_lower_full", "فوز على خصم أقل بـ 1.0+", "Win vs -1.0 level", 5),
            ("level_points_loss_same", "خسارة أمام خصم بنفس المستوى", "Loss vs same level", -20),
            ("level_points_loss_higher_half", "خسارة أمام خصم أعلى بـ 0.5", "Loss vs +0.5 level", -12),
            ("level_points_loss_higher_full", "خسارة أمام خصم أعلى بـ 1.0+", "Loss vs +1.0 level", -5),
            ("level_points_loss_lower_half", "خسارة أمام خصم أقل بـ 0.5", "Loss vs -0.5 level", -25),
            ("level_points_loss_lower_full", "خسارة أمام خصم أقل بـ 1.0+", "Loss vs -1.0 level", -35),
        ];

    // ── قراءة ────────────────────────────────────────────────────────────────

    public async Task<PointsSummaryDto> GetSummaryAsync(int userId, int page, int pageSize)
    {
        var balances = await _db.Users
            .Where(u => u.Id == userId)
            .Select(u => new { u.PointsBalance, u.LevelPoints })
            .FirstOrDefaultAsync();
        var balance = balances?.PointsBalance ?? 0;

        var redeemPerRiyal = await GetSettingAsync(RedeemPerRiyalKey, DefaultRedeemPerRiyal);
        var (multiplier, _) = await GetActiveBenefitsAsync(userId);

        var rewardRules = new List<PointsRuleDto>();
        foreach (var r in RewardRules)
            rewardRules.Add(new PointsRuleDto
            {
                Key = r.Key, LabelAr = r.Ar, LabelEn = r.En,
                Points = await GetSettingAsync(r.Key, r.Default),
            });
        var levelRules = new List<PointsRuleDto>();
        foreach (var r in LevelRules)
            levelRules.Add(new PointsRuleDto
            {
                Key = r.Key, LabelAr = r.Ar, LabelEn = r.En,
                Points = await GetSignedSettingAsync(r.Key, r.Default),
            });

        return new PointsSummaryDto
        {
            Balance = balance,
            LevelPoints = balances?.LevelPoints ?? 0,
            LevelCoachVerified = await IsLevelCoachVerifiedAsync(userId),
            LevelPointsRequireCoachVerification = await GetSwitchAsync(LevelRequireCoachKey, true),
            RewardRules = rewardRules,
            LevelRules = levelRules,
            RedeemPointsPerRiyal = redeemPerRiyal,
            MinRedeemPoints = await GetSettingAsync(MinRedeemKey, DefaultMinRedeem),
            BalanceValueSar = redeemPerRiyal <= 0
                ? 0m
                : Math.Round((decimal)balance / redeemPerRiyal, 2),
            EarnPer10Sar = await GetSettingAsync(EarnPer10SarKey, DefaultEarnPer10Sar),
            MatchReward = await GetSettingAsync(MatchRewardKey, DefaultMatchReward),
            Multiplier = multiplier,
            Transactions = await GetUserTransactionsAsync(userId, page, pageSize),
        };
    }

    public async Task<PagedResult<PointsTransactionDto>> GetUserTransactionsAsync(
        int userId, int page, int pageSize)
    {
        (page, pageSize) = Paging.Clamp(page, pageSize);
        var query = _db.PointsTransactions.Where(t => t.UserId == userId);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(t => t.CreatedAt)
            .ThenByDescending(t => t.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(t => new PointsTransactionDto
            {
                Id = t.Id,
                Amount = t.Amount,
                Type = t.Type.ToString(),
                Kind = t.Kind == PointsKind.Level ? "level" : "reward",
                Description = t.Description,
                CreatedAt = t.CreatedAt,
            })
            .ToListAsync();

        return new PagedResult<PointsTransactionDto>
        {
            Items = items, Page = page, PageSize = pageSize, Total = total,
        };
    }

    /// <summary>
    /// اشتراك المستخدم الساري — مع شروطه كما نُسخت وقت الشراء. الاشتراكات
    /// القديمة (قبل إضافة اللقطة) تقرأ من الباقة الحالية كتوافق خلفي.
    /// </summary>
    private async Task<Subscription?> ActiveSubscriptionAsync(int userId)
    {
        var now = DateTime.UtcNow;
        // «بالنسبة» مفتوح المدة (EndDate = null)، وغيره ينتهي بتاريخ.
        return await _db.Subscriptions
            .Include(s => s.Package)
            .Where(s => s.UserId == userId &&
                        s.Plan == SubscriptionPlan.SportaPlus &&
                        (s.EndDate == null || s.EndDate > now) &&
                        s.PackageId != null)
            .FirstOrDefaultAsync();
    }

    /// <summary>true حين حُفظت لقطة الشروط على الاشتراك (اشتراك حديث).</summary>
    private static bool HasSnapshot(Subscription s) => s.PackageName != null;

    public async Task<(decimal Multiplier, decimal BookingDiscountPercent)>
        GetActiveBenefitsAsync(int userId)
    {
        var sub = await ActiveSubscriptionAsync(userId);
        if (sub == null) return (1m, 0m);

        // اللقطة أولًا: تعديل الأدمن على الباقة لا يمسّ من اشترك قبله.
        var multiplier = HasSnapshot(sub)
            ? sub.PointsMultiplier
            : sub.Package?.PointsMultiplier ?? 1m;
        var bookingDiscount = HasSnapshot(sub)
            ? sub.BookingDiscountPercent
            : sub.Package?.BookingDiscountPercent ?? 0m;

        return (Math.Max(1m, multiplier), Math.Clamp(bookingDiscount, 0m, 100m));
    }

    public async Task<(decimal DiscountPercent, decimal? OverridePercent)>
        GetActiveCommissionTermsAsync(int userId)
    {
        var sub = await ActiveSubscriptionAsync(userId);
        if (sub == null) return (0m, null);

        var snapshot = HasSnapshot(sub);
        var period = snapshot ? sub.Period : sub.Package?.Period ?? SubscriptionPeriod.Monthly;

        // «بالنسبة»: نسبة الاشتراك تحلّ محل نسبة المنصة بالكامل.
        if (period.IsOpenEnded())
        {
            var percent = snapshot
                ? sub.CommissionPercent
                : sub.Package?.CommissionPercent ?? 0m;
            return (0m, Math.Clamp(percent, 0m, 100m));
        }

        var discount = snapshot
            ? sub.CommissionDiscountPercent
            : sub.Package?.CommissionDiscountPercent ?? 0m;
        return (Math.Clamp(discount, 0m, 100m), null);
    }

    // ── استبدال ──────────────────────────────────────────────────────────────

    public async Task<PointsSummaryDto> RedeemAsync(int userId, int points)
    {
        var minRedeem = await GetSettingAsync(MinRedeemKey, DefaultMinRedeem);
        var redeemPerRiyal = await GetSettingAsync(RedeemPerRiyalKey, DefaultRedeemPerRiyal);
        if (redeemPerRiyal <= 0)
            throw new AuthException(
                "Redemption is disabled", "استبدال النقاط غير متاح حاليًا", "REDEEM_DISABLED");

        if (points < minRedeem)
            throw new AuthException(
                "Below minimum redemption",
                $"الحد الأدنى للاستبدال {minRedeem} نقطة", "BELOW_MIN_REDEEM");

        // استبدالان متزامنان لنفس المستخدم يُسلسَلان بقفل، والخصم ذرّي مشروط
        // بكفاية الرصيد (UPDATE … WHERE PointsBalance >= points) حتى لا يمرّ
        // اثنان من رصيد لا يكفي إلا لأحدهما فيصير سالباً وتُقيَّد المحفظة مرتين.
        await using var _ = await DbLocks.AcquireAsync(_db, $"points:{userId}");

        if (!await _db.Users.AnyAsync(u => u.Id == userId))
            throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        var amountSar = Math.Round((decimal)points / redeemPerRiyal, 2);

        // الخصم وحركة النقاط وقيد المحفظة في معاملة واحدة: فشل أيٍّ منها يُرجع الكل.
        await using var tx = await _db.Database.BeginTransactionAsync();

        var now = DateTime.UtcNow;
        var rows = await _db.Users
            .Where(u => u.Id == userId && u.PointsBalance >= points)
            .ExecuteUpdateAsync(s => s
                .SetProperty(u => u.PointsBalance, u => u.PointsBalance - points)
                .SetProperty(u => u.UpdatedAt, now));
        if (rows == 0)
            throw new AuthException(
                "Insufficient points", "رصيد النقاط غير كافٍ", "INSUFFICIENT_POINTS");

        _db.PointsTransactions.Add(new PointsTransaction
        {
            UserId = userId,
            Amount = -points,
            Type = PointsTransactionType.Redeemed,
            Description = $"استبدال {points} نقطة برصيد {amountSar.ToString("0.##", CultureInfo.InvariantCulture)} ر.س",
        });
        await _db.SaveChangesAsync();

        await _wallet.CreditEarningAsync(
            userId, amountSar, WalletTransactionType.PointsRedemption,
            $"رصيد من استبدال {points} نقطة", null);

        await tx.CommitAsync();

        return await GetSummaryAsync(userId, 1, 10);
    }

    // ── كسب (best-effort) ────────────────────────────────────────────────────

    public async Task EarnForSpendAsync(
        int userId, decimal amountSar, PointsTransactionType type,
        int? referenceId, string? description)
    {
        try
        {
            if (amountSar <= 0) return;
            var per10 = await GetSettingAsync(EarnPer10SarKey, DefaultEarnPer10Sar);
            if (per10 <= 0) return;

            var basePoints = (int)Math.Floor(amountSar / 10m * per10);
            await AwardAsync(userId, basePoints, type, referenceId, description,
                applyMultiplier: true);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Points earn (spend) failed for user {UserId}", userId);
        }
    }

    public async Task EarnFixedAsync(
        int userId, int basePoints, PointsTransactionType type,
        int? referenceId, string? description)
    {
        try
        {
            await AwardAsync(userId, basePoints, type, referenceId, description,
                applyMultiplier: true);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Points earn (fixed) failed for user {UserId}", userId);
        }
    }

    public async Task EarnMatchCompletedAsync(int userId, int matchId)
    {
        try
        {
            var reward = await GetSettingAsync(MatchRewardKey, DefaultMatchReward);
            await AwardAsync(userId, reward, PointsTransactionType.MatchCompleted,
                matchId, "نقاط إتمام مباراة", applyMultiplier: true);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Points earn (match) failed for user {UserId}", userId);
        }
    }

    public async Task EarnActivityAsync(
        int userId, PointsTransactionType activity, int? referenceId, string? description)
    {
        try
        {
            var rule = RewardRules.FirstOrDefault(r => r.Type == activity);
            if (rule.Key == null) return;
            var basePoints = await GetSettingAsync(rule.Key, rule.Default);
            await AwardAsync(userId, basePoints, activity, referenceId,
                description ?? $"نقاط {rule.Ar}", applyMultiplier: true);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Points earn (activity {Activity}) failed for user {UserId}",
                activity, userId);
        }
    }

    public async Task ApplyLevelPointsAsync(
        IReadOnlyCollection<int> team1, IReadOnlyCollection<int> team2,
        int team1Score, int team2Score,
        PointsTransactionType type, int referenceId, string? description)
    {
        try
        {
            if (team1.Count == 0 || team2.Count == 0 || team1Score == team2Score) return;

            var ids = team1.Concat(team2).Distinct().ToList();
            var levels = await _db.PlayerProfiles
                .Where(p => ids.Contains(p.UserId))
                .Select(p => new { p.UserId, Level = (int)p.Level })
                .ToDictionaryAsync(x => x.UserId, x => x.Level);
            double LevelOf(int id) => levels.TryGetValue(id, out var l) ? l : 1;

            // في الزوجي يُقارن متوسط الفريقين لا لاعب بلاعب (الوثيقة).
            var avg1 = team1.Average(LevelOf);
            var avg2 = team2.Average(LevelOf);
            var requireCoach = await GetSwitchAsync(LevelRequireCoachKey, true);

            async Task ApplyTeamAsync(IReadOnlyCollection<int> team, double mine, double theirs, bool won)
            {
                var key = LevelRuleKey(won, theirs - mine);
                var rule = LevelRules.First(r => r.Key == key);
                var delta = await GetSignedSettingAsync(rule.Key, rule.Default);
                foreach (var userId in team)
                {
                    if (requireCoach && !await IsLevelCoachVerifiedAsync(userId)) continue;
                    await ChangeLevelPointsAsync(userId, delta, type, referenceId,
                        description ?? rule.Ar);
                }
            }

            var team1Won = team1Score > team2Score;
            await ApplyTeamAsync(team1, avg1, avg2, team1Won);
            await ApplyTeamAsync(team2, avg2, avg1, !team1Won);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Level points failed for reference {ReferenceId}", referenceId);
        }
    }

    /// <summary>مفتاح القاعدة من نتيجة الفريق وفرق المستوى (خصم − أنا).</summary>
    private static string LevelRuleKey(bool won, double diff)
    {
        var outcome = won ? "win" : "loss";
        var abs = Math.Abs(diff);
        if (abs < 0.25) return $"level_points_{outcome}_same";
        var side = diff > 0 ? "higher" : "lower";
        var size = abs < 1.0 ? "half" : "full";
        return $"level_points_{outcome}_{side}_{size}";
    }

    /// <summary>
    /// اعتماد مدرب للمستوى: تقييم مستوى مكتمل عبر جلسة مدرب، أو جلسة تدريب
    /// قيّم فيها المدرب اللاعب.
    /// </summary>
    private async Task<bool> IsLevelCoachVerifiedAsync(int userId)
    {
        var assessed = await _db.LevelAssessments.AnyAsync(a =>
            a.PlayerProfile.UserId == userId && a.IsCompleted &&
            a.Type == LevelAssessmentType.CoachSession);
        if (assessed) return true;
        return await _db.CoachSessions.AnyAsync(s => s.PlayerId == userId && s.CoachRating != null);
    }

    public async Task ReverseLevelPointsAsync(PointsTransactionType type, int referenceId)
    {
        var rows = await _db.PointsTransactions
            .Where(t => t.Type == type && t.ReferenceId == referenceId && t.Kind == PointsKind.Level)
            .ToListAsync();
        if (rows.Count == 0) return;

        var ids = rows.Select(r => r.UserId).Distinct().ToList();
        var users = await _db.Users.Where(u => ids.Contains(u.Id)).ToListAsync();
        foreach (var row in rows)
        {
            var user = users.FirstOrDefault(u => u.Id == row.UserId);
            if (user == null) continue;
            user.LevelPoints -= row.Amount;
            user.UpdatedAt = DateTime.UtcNow;
        }
        _db.PointsTransactions.RemoveRange(rows);
        await _db.SaveChangesAsync();
    }

    /// <summary>حركة نقاط مستوى (موجبة أو سالبة) — مرة واحدة لكل (لاعب، نوع، مرجع).</summary>
    private async Task ChangeLevelPointsAsync(
        int userId, int delta, PointsTransactionType type, int referenceId, string? description)
    {
        if (delta == 0) return;
        var already = await _db.PointsTransactions.AnyAsync(t =>
            t.UserId == userId && t.Type == type && t.ReferenceId == referenceId);
        if (already) return;

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null) return;

        user.LevelPoints += delta;
        user.UpdatedAt = DateTime.UtcNow;
        _db.PointsTransactions.Add(new PointsTransaction
        {
            UserId = userId,
            Amount = delta,
            Type = type,
            Kind = PointsKind.Level,
            ReferenceId = referenceId,
            Description = description,
        });
        await _db.SaveChangesAsync();
    }

    public async Task<LeaderboardDto> GetLeaderboardAsync(
        int? currentUserId, string kind, string period, int limit)
    {
        var pointsKind = string.Equals(kind, "level", StringComparison.OrdinalIgnoreCase)
            ? PointsKind.Level
            : PointsKind.Reward;
        period = (period ?? "all").ToLowerInvariant();
        limit = Math.Clamp(limit, 1, 100);

        // حدود الفترة بتوقيت السعودية ثم تُحوَّل إلى UTC (CreatedAt بالـUTC).
        var nowKsa = AppClock.Now;
        DateTime? sinceKsa = period switch
        {
            "daily" => nowKsa.Date,
            "weekly" => nowKsa.Date.AddDays(-6),
            "monthly" => nowKsa.Date.AddDays(1 - nowKsa.Day),
            _ => null,
        };
        var since = sinceKsa?.AddHours(-AppClock.OffsetHours);

        var query = _db.PointsTransactions.Where(t => t.Kind == pointsKind);
        if (since != null) query = query.Where(t => t.CreatedAt >= since);
        // المكافآت: ما كُسب فعلاً (لا ما استُبدل)؛ المستوى: الصافي بالخصومات.
        if (pointsKind == PointsKind.Reward) query = query.Where(t => t.Amount > 0);

        var totals = query
            .GroupBy(t => t.UserId)
            .Select(g => new { UserId = g.Key, Points = g.Sum(t => t.Amount) })
            .Where(x => x.Points > 0);

        var top = await totals
            .Join(_db.Users.Where(u => u.IsActive && !u.IsDeleted),
                x => x.UserId, u => u.Id,
                (x, u) => new
                {
                    x.UserId,
                    x.Points,
                    u.FirstName,
                    u.LastName,
                    u.ProfileImageUrl,
                    Level = u.PlayerProfile != null ? (int?)u.PlayerProfile.Level : null,
                })
            .OrderByDescending(x => x.Points)
            .ThenBy(x => x.UserId)
            .Take(limit)
            .ToListAsync();

        var entries = top.Select((x, i) => new LeaderboardEntryDto
        {
            Rank = i + 1,
            UserId = x.UserId,
            Name = $"{x.FirstName} {x.LastName}".Trim(),
            AvatarUrl = x.ProfileImageUrl,
            Level = x.Level,
            Points = x.Points,
            IsMe = x.UserId == currentUserId,
        }).ToList();

        LeaderboardEntryDto? me = entries.FirstOrDefault(e => e.IsMe);
        if (me == null && currentUserId is int uid)
        {
            var mine = await totals.Where(x => x.UserId == uid).Select(x => x.Points).FirstOrDefaultAsync();
            if (mine > 0)
            {
                var ahead = await totals.CountAsync(x => x.Points > mine);
                var user = await _db.Users
                    .Where(u => u.Id == uid)
                    .Select(u => new
                    {
                        u.FirstName, u.LastName, u.ProfileImageUrl,
                        Level = u.PlayerProfile != null ? (int?)u.PlayerProfile.Level : null,
                    })
                    .FirstOrDefaultAsync();
                me = new LeaderboardEntryDto
                {
                    Rank = ahead + 1,
                    UserId = uid,
                    Name = user == null ? string.Empty : $"{user.FirstName} {user.LastName}".Trim(),
                    AvatarUrl = user?.ProfileImageUrl,
                    Level = user?.Level,
                    Points = mine,
                    IsMe = true,
                };
            }
        }

        return new LeaderboardDto
        {
            Kind = pointsKind == PointsKind.Level ? "level" : "reward",
            Period = period is "daily" or "weekly" or "monthly" ? period : "all",
            Entries = entries,
            Me = me,
        };
    }

    public async Task<int> PenalizeWithdrawalAsync(int userId, int matchId, string? description)
    {
        try
        {
            var penalty = await GetSettingAsync(WithdrawalPenaltyKey, DefaultWithdrawalPenalty);
            if (penalty <= 0) return 0;

            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null) return 0;

            // نفس قاعدة العكس: لا يُنزل الرصيد تحت الصفر.
            var toDeduct = Math.Min(penalty, user.PointsBalance);
            if (toDeduct <= 0) return 0;

            user.PointsBalance -= toDeduct;
            user.UpdatedAt = DateTime.UtcNow;
            _db.PointsTransactions.Add(new PointsTransaction
            {
                UserId = userId,
                Amount = -toDeduct,
                Type = PointsTransactionType.WithdrawalPenalty,
                Kind = PointsKind.Reward,
                ReferenceId = matchId,
                Description = description,
            });
            await _db.SaveChangesAsync();
            return toDeduct;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Withdrawal penalty failed for user {UserId}", userId);
            return 0;
        }
    }

    public async Task GrantAsync(
        int userId, int points, PointsTransactionType type,
        int? referenceId, string? description)
    {
        try
        {
            await AwardAsync(userId, points, type, referenceId, description,
                applyMultiplier: false);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Points grant failed for user {UserId}", userId);
        }
    }

    public async Task ReverseAsync(
        int userId, PointsTransactionType earnedType, int referenceId,
        string? description)
    {
        try
        {
            // ما مُنح فعلًا لهذا المرجع مطروحًا منه أي عكس سابق له.
            var earned = await _db.PointsTransactions
                .Where(t => t.UserId == userId && t.Type == earnedType &&
                            t.ReferenceId == referenceId && t.Amount > 0)
                .SumAsync(t => (int?)t.Amount) ?? 0;
            var reversed = await _db.PointsTransactions
                .Where(t => t.UserId == userId &&
                            t.Type == PointsTransactionType.Reversal &&
                            t.ReferenceId == referenceId && t.Amount < 0)
                .SumAsync(t => (int?)-t.Amount) ?? 0;

            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null) return;

            // لا نُنزل الرصيد تحت الصفر لو سبق أن استبدل نقاطه.
            var toDeduct = Math.Min(earned - reversed, user.PointsBalance);
            if (toDeduct <= 0) return;

            user.PointsBalance -= toDeduct;
            user.UpdatedAt = DateTime.UtcNow;
            _db.PointsTransactions.Add(new PointsTransaction
            {
                UserId = userId,
                Amount = -toDeduct,
                Type = PointsTransactionType.Reversal,
                ReferenceId = referenceId,
                Description = description,
            });
            await _db.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Points reversal failed for user {UserId}", userId);
        }
    }

    // ── Admin ────────────────────────────────────────────────────────────────

    public async Task<int> AdminAdjustAsync(int userId, int amount, string? reason)
    {
        if (amount == 0)
            throw new AuthException(
                "Amount cannot be zero", "قيمة النقاط لا يمكن أن تكون صفرًا", "INVALID_AMOUNT");

        var user = await _db.Users
            .InScope(await _admin.GetScopeAsync())
            .FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new AuthException("User not found", "المستخدم غير موجود", "USER_NOT_FOUND");

        if (amount < 0 && -amount > user.PointsBalance)
            throw new AuthException(
                "Deduction exceeds balance",
                "الخصم يتجاوز رصيد نقاط المستخدم", "EXCEEDS_BALANCE");

        user.PointsBalance += amount;
        user.UpdatedAt = DateTime.UtcNow;
        _db.PointsTransactions.Add(new PointsTransaction
        {
            UserId = userId,
            Amount = amount,
            Type = PointsTransactionType.AdminAdjustment,
            Description = string.IsNullOrWhiteSpace(reason)
                ? (amount > 0 ? "منح إداري" : "خصم إداري")
                : reason,
        });
        await _db.SaveChangesAsync();
        return user.PointsBalance;
    }

    public async Task<PointsStatsDto> GetStatsAsync()
    {
        // إجماليات مستخدمي نطاق الموظف فقط (الأدمن: كل المنصة).
        var users = _db.Users.InScope(await _admin.GetScopeAsync());
        var transactions = _db.PointsTransactions.Where(t => users.Any(u => u.Id == t.UserId));

        return new PointsStatsDto
        {
            TotalEarned = await transactions
                .Where(t => t.Amount > 0)
                .SumAsync(t => (long?)t.Amount) ?? 0,
            TotalRedeemed = await transactions
                .Where(t => t.Type == PointsTransactionType.Redeemed)
                .SumAsync(t => (long?)-t.Amount) ?? 0,
            OutstandingBalance = await users.SumAsync(u => (long?)u.PointsBalance) ?? 0,
        };
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    private async Task AwardAsync(
        int userId, int basePoints, PointsTransactionType type,
        int? referenceId, string? description, bool applyMultiplier)
    {
        if (basePoints <= 0) return;

        // منحة واحدة لكل (مستخدم، نوع، مرجع) — تحمي من إعادة إدخال نتيجة
        // المباراة أو أي استدعاء مكرر لنفس الحدث.
        if (referenceId != null)
        {
            var already = await _db.PointsTransactions.AnyAsync(t =>
                t.UserId == userId && t.Type == type &&
                t.ReferenceId == referenceId && t.Amount > 0);
            if (already) return;
        }

        var points = basePoints;
        if (applyMultiplier)
        {
            var (multiplier, _) = await GetActiveBenefitsAsync(userId);
            points = (int)Math.Floor(basePoints * multiplier);
        }
        if (points <= 0) return;

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null) return;

        user.PointsBalance += points;
        user.UpdatedAt = DateTime.UtcNow;
        _db.PointsTransactions.Add(new PointsTransaction
        {
            UserId = userId,
            Amount = points,
            Type = type,
            Kind = PointsKind.Reward,
            ReferenceId = referenceId,
            Description = description,
        });
        await _db.SaveChangesAsync();
    }

    /// <summary>إعداد رقمي قد يكون سالباً (قواعد خسارة نقاط المستوى).</summary>
    private async Task<int> GetSignedSettingAsync(string key, int fallback)
    {
        var raw = await _db.SystemSettings
            .Where(s => s.Key == key)
            .Select(s => s.ValueAr)
            .FirstOrDefaultAsync();
        return raw != null &&
               int.TryParse(raw, NumberStyles.Any, CultureInfo.InvariantCulture, out var v)
            ? v
            : fallback;
    }

    /// <summary>إعداد مفتاح تشغيل ("true"/"false").</summary>
    private async Task<bool> GetSwitchAsync(string key, bool fallback)
    {
        var raw = await _db.SystemSettings
            .Where(s => s.Key == key)
            .Select(s => s.ValueAr)
            .FirstOrDefaultAsync();
        return raw != null && bool.TryParse(raw, out var v) ? v : fallback;
    }

    /// <summary>يقرأ إعدادًا رقميًا صحيحًا من SystemSettings (نمط commission_percentage).</summary>
    private async Task<int> GetSettingAsync(string key, int fallback)
    {
        var raw = await _db.SystemSettings
            .Where(s => s.Key == key)
            .Select(s => s.ValueAr)
            .FirstOrDefaultAsync();
        if (raw != null &&
            int.TryParse(raw, NumberStyles.Any, CultureInfo.InvariantCulture, out var v) &&
            v >= 0)
            return v;
        return fallback;
    }
}
