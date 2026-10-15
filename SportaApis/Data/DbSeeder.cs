using Microsoft.EntityFrameworkCore;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;
using MatchType = SportaApis.Enums.MatchType;

namespace SportaApis.Data;

/// <summary>
/// Development-only seed data so the courts/booking screens have something to
/// show before any venue owner has created real venues. Idempotent: it does
/// nothing once courts already exist.
/// </summary>
public static class DbSeeder
{
    public static async Task SeedCourtsAsync(AppDbContext db)
    {
        if (await db.Courts.AnyAsync())
            return;

        // A venue needs an owner; reuse the first registered user.
        var ownerId = await db.Users
            .OrderBy(u => u.Id)
            .Select(u => (int?)u.Id)
            .FirstOrDefaultAsync();

        if (ownerId is null)
            return; // No users yet — register one and the seed runs next launch.

        var venues = new[]
        {
            new Venue
            {
                Name = "نادي البادل الملكي",
                NameEn = "Royal Padel Club",
                OwnerId = ownerId.Value,
                Country = "السعودية",
                City = "الدمام",
                District = "العزيزية",
                Address = "العزيزية",
                Latitude = 26.4207,
                Longitude = 50.0888,
                GenderPolicy = VenueGenderPolicy.MenOnly,
                IsApproved = true,
                Courts =
                {
                    new Court { Name = "ملعب 1", NameEn = "Court 1", Type = CourtType.Indoor, PricePerHour = 100 },
                    new Court { Name = "ملعب 2", NameEn = "Court 2", Type = CourtType.Indoor, PricePerHour = 100 },
                    new Court { Name = "ملعب 3", NameEn = "Court 3", Type = CourtType.Outdoor, PricePerHour = 80 },
                },
            },
            new Venue
            {
                Name = "بادل كلوب الشرقية",
                NameEn = "Eastern Padel Club",
                OwnerId = ownerId.Value,
                Country = "السعودية",
                City = "الخبر",
                District = "الثقبة",
                Address = "الثقبة",
                Latitude = 26.2794,
                Longitude = 50.2083,
                GenderPolicy = VenueGenderPolicy.WomenOnly,
                IsApproved = true,
                Courts =
                {
                    new Court { Name = "ملعب 1", NameEn = "Court 1", Type = CourtType.Outdoor, PricePerHour = 80 },
                    new Court { Name = "ملعب 2", NameEn = "Court 2", Type = CourtType.Outdoor, PricePerHour = 80 },
                },
            },
            new Venue
            {
                Name = "مركز بادل المدينة",
                NameEn = "City Padel Center",
                OwnerId = ownerId.Value,
                Country = "السعودية",
                City = "الدمام",
                District = "الفيصلية",
                Address = "الفيصلية",
                Latitude = 26.4350,
                Longitude = 50.1033,
                GenderPolicy = VenueGenderPolicy.FamilyOnly,
                IsApproved = true,
                Courts =
                {
                    new Court { Name = "ملعب 1", NameEn = "Court 1", Type = CourtType.Indoor, PricePerHour = 120 },
                    new Court { Name = "ملعب 2", NameEn = "Court 2", Type = CourtType.Indoor, PricePerHour = 120 },
                },
            },
        };

        db.Venues.AddRange(venues);
        await db.SaveChangesAsync();
    }

    /// <summary>
    /// Backfills default booking + match price tiers for courts that have none,
    /// derived from the legacy hourly rate. Idempotent and per-kind.
    /// </summary>
    public static async Task SeedCourtPriceTiersAsync(AppDbContext db)
    {
        var courts = await db.Courts
            .Include(c => c.PriceTiers)
            .ToListAsync();

        var changed = false;
        foreach (var court in courts)
        {
            var hourly = court.PricePerHour > 0 ? court.PricePerHour : 100m;

            if (!court.PriceTiers.Any(t => t.Kind == CourtPriceKind.Booking))
            {
                AddTier(court, CourtPriceKind.Booking, 60, hourly);
                AddTier(court, CourtPriceKind.Booking, 90, Math.Round(hourly * 1.5m, 2));
                AddTier(court, CourtPriceKind.Booking, 120, hourly * 2);
                changed = true;
            }
        }

        if (changed) await db.SaveChangesAsync();

        static void AddTier(Court court, CourtPriceKind kind, int minutes, decimal price) =>
            court.PriceTiers.Add(new CourtPriceTier
            {
                Kind = kind,
                DurationMinutes = minutes,
                Price = price,
            });
    }

    /// <summary>
    /// Backfills geo-coordinates for venues seeded before the map feature
    /// existed (idempotent: only touches venues that still lack coordinates).
    /// </summary>
    public static async Task BackfillVenueCoordinatesAsync(AppDbContext db)
    {
        var coords = new Dictionary<string, (double lat, double lng)>
        {
            ["نادي البادل الملكي"] = (26.4207, 50.0888),
            ["بادل كلوب الشرقية"] = (26.2794, 50.2083),
            ["مركز بادل المدينة"] = (26.4350, 50.1033),
        };

        var venues = await db.Venues
            .Where(v => v.Latitude == null || v.Longitude == null)
            .ToListAsync();
        if (venues.Count == 0) return;

        var changed = false;
        foreach (var v in venues)
        {
            if (coords.TryGetValue(v.Name, out var c))
            {
                v.Latitude = c.lat;
                v.Longitude = c.lng;
                changed = true;
            }
        }
        if (changed) await db.SaveChangesAsync();
    }

    /// <summary>
    /// Development-only demo coaches (each backed by a Coach user + profile).
    /// Idempotent: does nothing once any coach profile exists.
    /// </summary>
    public static async Task SeedCoachesAsync(AppDbContext db)
    {
        if (await db.CoachProfiles.AnyAsync())
            return;

        // التقييم/عدد الجلسات لم يعودا يُخزَّنان هنا — يُحسبان حيًا من الجلسات
        // المكتملة وتقييمات اللاعبين (انظر SeedDemoCoachSessionsAsync).
        var demo = new[]
        {
            (First: "محمد", Last: "أحمد", Phone: "0500000101", Gender: Gender.Male,
             City: "نادي البادل الملكي", Spec: "تقنيات متقدمة، استراتيجية اللعب، التحليل الفني",
             Rate: 200m, Verified: true),
            (First: "سارة", Last: "عبدالله", Phone: "0500000102", Gender: Gender.Female,
             City: "بادل كلوب الشرقية", Spec: "تدريب مبتدئين، الأساسيات، اللياقة البدنية",
             Rate: 150m, Verified: false),
            (First: "خالد", Last: "محمود", Phone: "0500000103", Gender: Gender.Male,
             City: "مركز بادل المدينة", Spec: "إعداد احترافي، المنافسات، التكتيك المتقدم",
             Rate: 280m, Verified: true),
        };

        var passwordHash = BCrypt.Net.BCrypt.HashPassword("Coach1234");

        foreach (var c in demo)
        {
            db.Users.Add(new User
            {
                FirstName = c.First,
                LastName = c.Last,
                Email = $"{c.Phone}@sporta.demo",
                PhoneNumber = c.Phone,
                PasswordHash = passwordHash,
                UserType = UserType.Coach,
                Gender = c.Gender,
                Country = "السعودية",
                City = c.City,
                Roles = { new UserRole { Role = UserType.Coach } },
                CoachProfile = new CoachProfile
                {
                    Bio = $"مدرب بادل - {c.Spec}",
                    Specialization = c.Spec,
                    HourlyRate = c.Rate,
                    IsVerifiedOnPlatform = c.Verified,
                },
            });
        }

        await db.SaveChangesAsync();
    }

    /// <summary>
    /// Development-only demo open matches at the seeded courts.
    /// Idempotent: does nothing once any match exists.
    /// </summary>
    public static async Task SeedMatchesAsync(AppDbContext db)
    {
        if (await db.Matches.AnyAsync())
            return;

        var userIds = await db.Users
            .OrderBy(u => u.Id)
            .Select(u => u.Id)
            .Take(3)
            .ToListAsync();
        if (userIds.Count == 0) return;

        var courtIds = await db.Courts
            .OrderBy(c => c.Id)
            .Select(c => c.Id)
            .Take(3)
            .ToListAsync();
        if (courtIds.Count == 0) return;

        int? courtAt(int i) => courtIds.Count > i ? courtIds[i] : courtIds[0];
        var creator = userIds[0];

        var matches = new[]
        {
            new Match
            {
                CreatorId = creator,
                CourtId = courtAt(0),
                MatchType = MatchType.Competitive,
                Status = MatchStatus.Open,
                ScheduledAt = DateTime.UtcNow.AddDays(1).Date.AddHours(18),
                DurationMinutes = 90,
                MaxPlayers = 4,
                MinLevel = 5,
                MaxLevel = 6,
                PricePerPlayer = 50,
                MatchPlayers = { new MatchPlayer { UserId = creator } },
            },
            new Match
            {
                CreatorId = creator,
                CourtId = courtAt(1),
                MatchType = MatchType.Social,
                Status = MatchStatus.Open,
                ScheduledAt = DateTime.UtcNow.AddDays(2).Date.AddHours(19),
                DurationMinutes = 90,
                MaxPlayers = 4,
                MinLevel = 4,
                MaxLevel = 5,
                PricePerPlayer = 40,
                MatchPlayers = { new MatchPlayer { UserId = creator } },
            },
        };

        // Add a second player to the first match when another user exists.
        if (userIds.Count > 1)
            matches[0].MatchPlayers.Add(new MatchPlayer { UserId = userIds[1] });

        db.Matches.AddRange(matches);
        await db.SaveChangesAsync();
    }

    /// <summary>
    /// Development-only demo singles americano (4 players, 3 rounds).
    /// Idempotent: does nothing once any americano exists.
    /// </summary>
    public static async Task SeedAmericanoAsync(AppDbContext db)
    {
        if (await db.AmericanoMatches.AnyAsync())
            return;

        var players = await db.Users
            .OrderBy(u => u.Id)
            .Select(u => u.Id)
            .Take(4)
            .ToListAsync();
        if (players.Count < 4) return; // need 4 players

        var courtId = await db.Courts
            .OrderBy(c => c.Id)
            .Select(c => (int?)c.Id)
            .FirstOrDefaultAsync();

        var match = new Match
        {
            CreatorId = players[0],
            CourtId = courtId,
            MatchType = MatchType.American,
            Status = MatchStatus.Full,
            ScheduledAt = DateTime.UtcNow.AddDays(1).Date.AddHours(17),
            DurationMinutes = 90,
            MaxPlayers = 4,
            MinLevel = 3,
            MaxLevel = 6,
            MatchPlayers = players.Select(id => new MatchPlayer { UserId = id }).ToList(),
        };
        db.Matches.Add(match);
        await db.SaveChangesAsync();

        var americano = new AmericanoMatch
        {
            MatchId = match.Id,
            AmericanoType = MatchType.American,
            MinAllowedLevel = 3,
            MaxAllowedLevel = 6,
            TotalRounds = 3,
        };
        db.AmericanoMatches.Add(americano);
        await db.SaveChangesAsync();

        var (a, b, c, d) = (players[0], players[1], players[2], players[3]);
        var pairings = new (int, int, int, int)[]
        {
            (a, b, c, d),
            (a, c, b, d),
            (a, d, b, c),
        };
        for (var i = 0; i < pairings.Length; i++)
        {
            var (t1p1, t1p2, t2p1, t2p2) = pairings[i];
            db.AmericanoRounds.Add(new AmericanoRound
            {
                AmericanoMatchId = americano.Id,
                RoundNumber = i + 1,
                Team1Player1Id = t1p1,
                Team1Player2Id = t1p2,
                Team2Player1Id = t2p1,
                Team2Player2Id = t2p2,
            });
        }
        await db.SaveChangesAsync();
    }

    /// <summary>
    /// Development-only accepted friendships between the first few demo users so
    /// the friends list / picker isn't empty. Idempotent.
    /// </summary>
    public static async Task SeedFriendshipsAsync(AppDbContext db)
    {
        if (await db.Friendships.AnyAsync())
            return;

        var ids = await db.Users
            .OrderBy(u => u.Id)
            .Select(u => u.Id)
            .Take(4)
            .ToListAsync();
        if (ids.Count < 2) return;

        // Connect the first user with the rest as accepted friends.
        for (var i = 1; i < ids.Count; i++)
        {
            db.Friendships.Add(new Friendship
            {
                SenderId = ids[0],
                ReceiverId = ids[i],
                Status = FriendshipStatus.Accepted,
                RespondedAt = DateTime.UtcNow,
            });
        }
        await db.SaveChangesAsync();
    }

    public static async Task SeedTournamentsAsync(AppDbContext db)
    {
        if (await db.Tournaments.AnyAsync())
            return;

        db.Tournaments.AddRange(
            new Tournament
            {
                Name = "بطولة دبي المفتوحة للبادل",
                StartDate = new DateTime(2026, 7, 15),
                EndDate = new DateTime(2026, 7, 20),
                Location = "دبي، الإمارات العربية المتحدة",
                PrizeLabel = "الجائزة الكبرى",
                PrizeAmount = "$100,000",
                Scope = TournamentScope.International,
            },
            new Tournament
            {
                Name = "كأس العالم للبادل 2026",
                StartDate = new DateTime(2026, 8, 10),
                EndDate = new DateTime(2026, 8, 18),
                Location = "مدريد، إسبانيا",
                PrizeLabel = "الجائزة الكبرى",
                PrizeAmount = "$250,000",
                Scope = TournamentScope.International,
            },
            new Tournament
            {
                Name = "بطولة قطر الدولية للبادل",
                StartDate = new DateTime(2026, 9, 5),
                EndDate = new DateTime(2026, 9, 10),
                Location = "الدوحة، قطر",
                PrizeLabel = "الجائزة الكبرى",
                PrizeAmount = "$75,000",
                Scope = TournamentScope.International,
            },
            new Tournament
            {
                Name = "بطولة الرياض الكبرى للبادل",
                StartDate = new DateTime(2026, 6, 25),
                EndDate = new DateTime(2026, 6, 28),
                Location = "نادي البادل الملكي، الرياض",
                PrizeLabel = "الجائزة",
                PrizeAmount = "50,000 ر.س",
                Scope = TournamentScope.Local,
            },
            new Tournament
            {
                Name = "كأس جدة للبادل",
                StartDate = new DateTime(2026, 7, 10),
                EndDate = new DateTime(2026, 7, 12),
                Location = "نادي الشاطئ، جدة",
                PrizeLabel = "الجائزة",
                PrizeAmount = "30,000 ر.س",
                Scope = TournamentScope.Local,
            },
            new Tournament
            {
                Name = "بطولة الدمام المفتوحة",
                StartDate = new DateTime(2026, 7, 20),
                EndDate = new DateTime(2026, 7, 22),
                Location = "مركز الدمام الرياضي، الدمام",
                PrizeLabel = "الجائزة",
                PrizeAmount = "25,000 ر.س",
                Scope = TournamentScope.Local,
            });

        await db.SaveChangesAsync();
    }

    /// <summary>
    /// Default padel assessment levels + questions (migrated from the old
    /// hardcoded questionnaire). Idempotent per kind. Admins can edit/extend
    /// these and add other sports from the dashboard / APIs.
    /// </summary>
    /// <summary>سُلَّم المستويات من وثيقة «المستويات والنقاط» — يُزرع مرة واحدة
    /// حين يكون الجدول فارغاً، وبعدها يملكه الأدمن من لوحة التحكم.</summary>
    public static async Task SeedLevelDefinitionsAsync(AppDbContext db)
    {
        if (await db.PlayerLevelDefinitions.AnyAsync()) return;

        var levels = new (decimal Value, string Ar, string En, string DescAr, string DescEn)[]
        {
            (3.0m, "مبتدئ", "Beginner",
                "يعرف أساسيات البادل ويحتاج إلى تطوير التحكم والتمركز",
                "Knows the basics of padel and needs to develop control and positioning"),
            (3.5m, "مبتدئ متقدم", "Advanced Beginner",
                "يستطيع تبادل الكرات وبدأ يفهم استخدام الجدران",
                "Can rally and is starting to understand how to use the walls"),
            (4.0m, "متوسط", "Intermediate",
                "تحكم جيد بالكرة ويفهم أساسيات الهجوم والدفاع",
                "Good ball control and understands the basics of attack and defence"),
            (4.5m, "متوسط متقدم", "Upper Intermediate",
                "يمتلك مهارات وتكتيكًا جيدًا ويستطيع المنافسة",
                "Has good skills and tactics and can compete"),
            (5.0m, "متقدم", "Advanced",
                "لاعب قوي ومتمكن هجوميًا ودفاعيًا",
                "A strong player, capable in both attack and defence"),
            (5.5m, "متقدم تنافسي", "Competitive Advanced",
                "مستوى عالٍ وخبرة جيدة في المباريات التنافسية",
                "High level with solid experience in competitive matches"),
            (6.0m, "محترف", "Professional",
                "مستوى احترافي وقدرة عالية على المنافسة",
                "Professional level with a high ability to compete"),
            (6.5m, "محترف متقدم", "Advanced Professional",
                "لاعب ذو مستوى احترافي مرتفع",
                "A player at a high professional level"),
            (7.0m, "محترف — نخبة", "Professional — Elite",
                "أعلى مستوى في Sporta",
                "The highest level in Sporta"),
        };

        db.PlayerLevelDefinitions.AddRange(levels.Select((l, i) => new PlayerLevelDefinition
        {
            Value = l.Value,
            TitleAr = l.Ar,
            TitleEn = l.En,
            DescriptionAr = l.DescAr,
            DescriptionEn = l.DescEn,
            SortOrder = i + 1,
            IsActive = true,
        }));
        await db.SaveChangesAsync();
    }

    public static async Task SeedAssessmentAsync(AppDbContext db)
    {
        const string sport = "padel";

        if (!await db.AssessmentLevels.AnyAsync(l => l.Sport == sport))
        {
            // Thresholds reproduce the legacy 0..15 ratio mapping onto 7 levels.
            var levels = new (string Ar, string En, int Min, int Order)[]
            {
                ("مبتدئ", "Beginner", 0, 1),
                ("ناشئ", "Novice", 2, 2),
                ("متعلم", "Learner", 4, 3),
                ("متوسط", "Intermediate", 7, 4),
                ("متقدم", "Advanced", 9, 5),
                ("محترف", "Professional", 12, 6),
                ("نخبة", "Elite", 14, 7),
            };
            db.AssessmentLevels.AddRange(levels.Select(l => new AssessmentLevel
            {
                Sport = sport,
                NameAr = l.Ar,
                NameEn = l.En,
                MinScore = l.Min,
                SortOrder = l.Order,
                IsActive = true,
            }));
            await db.SaveChangesAsync();
        }

        if (!await db.AssessmentQuestions.AnyAsync(q => q.Sport == sport))
        {
            AssessmentQuestion Q(string ar, string en, int order,
                (string ar, string en, int score)[] opts) => new()
            {
                Sport = sport,
                TextAr = ar,
                TextEn = en,
                SortOrder = order,
                IsActive = true,
                Options = opts.Select((o, i) => new AssessmentOption
                {
                    TextAr = o.ar, TextEn = o.en, Score = o.score, SortOrder = i,
                }).ToList(),
            };

            db.AssessmentQuestions.AddRange(
                Q("منذ متى وأنت تلعب البادل؟", "How long have you been playing padel?", 1, new[]
                {
                    ("لم ألعب من قبل", "Never played before", 0),
                    ("أقل من 6 أشهر", "Less than 6 months", 1),
                    ("من 6 أشهر إلى سنتين", "6 months to 2 years", 2),
                    ("أكثر من سنتين", "More than 2 years", 3),
                }),
                Q("كيف تقيّم تحكمك في المضرب والكرة؟", "How do you rate your racket and ball control?", 2, new[]
                {
                    ("أتعلم الأساسيات", "Learning the basics", 0),
                    ("أستطيع تبادل كرات بسيط", "I can do simple rallies", 1),
                    ("تحكم جيد في معظم الضربات", "Good control on most shots", 2),
                    ("تحكم ممتاز واحترافي", "Excellent control", 3),
                }),
                Q("هل تجيد اللعب باستخدام الجدران؟", "Can you play off the walls?", 3, new[]
                {
                    ("لا أعرف كيف", "I don't know how", 0),
                    ("أحياناً وبصعوبة", "Sometimes, with difficulty", 1),
                    ("نعم في معظم الأحيان", "Yes, most of the time", 2),
                    ("بإتقان تام", "With full mastery", 3),
                }),
                Q("كيف هي ضرباتك الهجومية (سماش / بانديخا)؟", "How are your attacking shots (smash / bandeja)?", 4, new[]
                {
                    ("لا أستخدمها", "I don't use them", 0),
                    ("أحاول أحياناً", "I try sometimes", 1),
                    ("أستخدمها بفعالية", "I use them effectively", 2),
                    ("أتقنها وألعبها بثقة", "I master them confidently", 3),
                }),
                Q("هل شاركت في مباريات أو بطولات تنافسية؟", "Have you played competitive matches or tournaments?", 5, new[]
                {
                    ("لا، ودياً فقط أو لم ألعب", "No, friendly only or never", 0),
                    ("مباريات ودية منتظمة", "Regular friendly matches", 1),
                    ("بطولات محلية", "Local tournaments", 2),
                    ("بطولات تنافسية متقدمة", "Advanced competitive tournaments", 3),
                }));
            await db.SaveChangesAsync();
        }
    }

    /// <summary>Demo home-slider ads. Idempotent: does nothing once any ad exists.</summary>
    public static async Task SeedAdsAsync(AppDbContext db)
    {
        if (await db.Ads.AnyAsync())
            return;

        db.Ads.AddRange(
            new Ad
            {
                Title = "احجز ملعبك المفضل",
                Subtitle = "أفضل ملاعب البادل في مدينتك بانتظارك",
                TitleEn = "Book your favourite court",
                SubtitleEn = "The best padel courts in your city are waiting",
                ImageUrl =
                    "https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=900&q=80",
                Target = "courts",
                Placements = "home",
                SortOrder = 1,
            },
            new Ad
            {
                Title = "انضم لمباراة قريبة",
                Subtitle = "العب مع لاعبين بمستواك الآن",
                TitleEn = "Join a nearby match",
                SubtitleEn = "Play with people at your level right now",
                ImageUrl =
                    "https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=900&q=80",
                Target = "matches",
                Placements = "home,matches",
                SortOrder = 2,
            },
            new Ad
            {
                Title = "طوّر مستواك مع مدرب",
                Subtitle = "مدربون معتمدون لحجوزات خاصة",
                TitleEn = "Level up with a coach",
                SubtitleEn = "Verified coaches for private sessions",
                ImageUrl =
                    "https://images.unsplash.com/photo-1591491634026-77cd4f70c1f8?w=900&q=80",
                Target = "coaches",
                Placements = "home,coaches",
                SortOrder = 3,
            });

        await db.SaveChangesAsync();
    }

    /// <summary>
    /// يملأ نص الإعلانات التجريبية بالإنجليزية للصفوف التي أُنشئت قبل إضافة
    /// عمودَي <c>TitleEn</c>/<c>SubtitleEn</c>، وإلا ظهر البانر بالعربية داخل
    /// الواجهة الإنجليزية. <see cref="SeedAdsAsync"/> لا يلمسها لأنه يتوقف عند
    /// وجود أي إعلان. يعمل على الصفوف الفارغة فقط فهو آمن للتكرار.
    /// </summary>
    public static async Task BackfillAdEnglishTextAsync(AppDbContext db)
    {
        var texts = new Dictionary<string, (string Title, string Subtitle)>
        {
            ["احجز ملعبك المفضل"] =
                ("Book your favourite court",
                 "The best padel courts in your city are waiting"),
            ["انضم لمباراة قريبة"] =
                ("Join a nearby match", "Play with people at your level right now"),
            ["طوّر مستواك مع مدرب"] =
                ("Level up with a coach", "Verified coaches for private sessions"),
        };

        var ads = await db.Ads
            .Where(a => a.TitleEn == null || a.TitleEn == "")
            .ToListAsync();
        var filled = 0;
        foreach (var ad in ads)
        {
            if (!texts.TryGetValue(ad.Title, out var en)) continue;
            ad.TitleEn = en.Title;
            if (string.IsNullOrEmpty(ad.SubtitleEn)) ad.SubtitleEn = en.Subtitle;
            filled++;
        }

        if (filled > 0) await db.SaveChangesAsync();
    }

    /// <summary>Seeds the one sport currently supported end-to-end (padel) so the
    /// admin-managed Sports list isn't empty on first run.</summary>
    public static async Task SeedSportsAsync(AppDbContext db)
    {
        if (await db.Sports.AnyAsync())
            return;

        db.Sports.Add(new Sport
        {
            Key = "padel",
            NameAr = "البادل",
            NameEn = "Padel",
            Description =
                "رياضة البادل هي لعبة مضرب تُلعب بين فريقين من شخصين لكل فريق، على ملعب مسوّر بزجاج وشبك.",
            PlayersPerMatch = 4,
            DurationMinutes = 60,
            SortOrder = 1,
        });

        await db.SaveChangesAsync();
    }

    /// <summary>Seeds the default coach specializations so the admin-managed
    /// list and the coach registration picker aren't empty on first run.</summary>
    public static async Task SeedCoachSpecializationsAsync(AppDbContext db)
    {
        if (await db.CoachSpecializations.AnyAsync())
            return;

        var items = new (string ar, string en)[]
        {
            ("تدريب المبتدئين", "Beginner Training"),
            ("تطوير المهارات المتقدمة", "Advanced Skills Development"),
            ("اللياقة البدنية", "Physical Fitness"),
            ("الاستراتيجيات التكتيكية", "Tactical Strategies"),
            ("تدريب الناشئين", "Youth Training"),
            ("التحضير للبطولات", "Tournament Preparation"),
        };

        var sortOrder = 1;
        foreach (var (ar, en) in items)
        {
            db.CoachSpecializations.Add(new CoachSpecialization
            {
                NameAr = ar,
                NameEn = en,
                SortOrder = sortOrder++,
            });
        }

        await db.SaveChangesAsync();
    }

    /// <summary>Seeds the two live subscription types (شهري key "sporta-plus" —
    /// see PackageService.DefaultKey — و سنوي key "sporta-plus-yearly") so admin
    /// subscription management has real content, and backfills PackageId on any
    /// pre-existing Sporta Plus subscriptions so subscriber counts are accurate.</summary>
    public static async Task SeedPackagesAsync(AppDbContext db)
    {
        var pkg = await db.Packages.FirstOrDefaultAsync(p => p.Key == "sporta-plus");
        if (pkg is null)
        {
            pkg = new Package
            {
                Key = "sporta-plus",
                Name = "اشتراك شهري",
                Price = 49m,
                Period = SubscriptionPeriod.Monthly,
                DurationDays = SubscriptionPeriod.Monthly.Days() ?? 30,
                FeaturesText = string.Join('\n', new[]
                {
                    "حجوزات وأولوية مميزة",
                    "خصومات على الملاعب والمدربين",
                    "إحصائيات وتحليلات متقدمة",
                    "شارة Sporta Plus على ملفك",
                }),
                SortOrder = 1,
            };
            db.Packages.Add(pkg);
            await db.SaveChangesAsync();
        }

        if (!await db.Packages.AnyAsync(p => p.Key == "sporta-plus-yearly"))
        {
            db.Packages.Add(new Package
            {
                Key = "sporta-plus-yearly",
                Name = "اشتراك سنوي",
                Price = 499m,
                Period = SubscriptionPeriod.Yearly,
                DurationDays = SubscriptionPeriod.Yearly.Days() ?? 365,
                FeaturesText = string.Join('\n', new[]
                {
                    "كل مميزات الاشتراك الشهري",
                    "شهران مجاناً مقارنة بالاشتراك الشهري",
                    "أولوية في الدعم",
                }),
                CommissionDiscountPercent = 20m,
                SortOrder = 2,
            });
            await db.SaveChangesAsync();
        }

        // «بالنسبة»: بلا رسوم ولا انتهاء — سبورتا تأخذ نسبة أعلى من كل عملية.
        // النسبة هنا قيمة ابتدائية يعدّلها الأدمن من لوحة التحكم.
        if (!await db.Packages.AnyAsync(p => p.Key == "sporta-commission"))
        {
            db.Packages.Add(new Package
            {
                Key = "sporta-commission",
                Name = "اشتراك بالنسبة",
                Price = 0m,
                Period = SubscriptionPeriod.Commission,
                DurationDays = 0,
                CommissionPercent = 10m,
                FeaturesText = string.Join('\n', new[]
                {
                    "بلا رسوم اشتراك مقدَّمة",
                    "بلا تاريخ انتهاء — يستمر حتى تلغيه",
                    "سبورتا تأخذ نسبة من كل عملية بدل الاشتراك الثابت",
                }),
                SortOrder = 3,
            });
            await db.SaveChangesAsync();
        }

        var toBackfill = await db.Subscriptions
            .Where(s => s.Plan == SubscriptionPlan.SportaPlus && s.PackageId == null)
            .ToListAsync();
        if (toBackfill.Count > 0)
        {
            foreach (var s in toBackfill) s.PackageId = pkg.Id;
            await db.SaveChangesAsync();
        }
    }

    /// <summary>Seeds the app-facing settings (maintenance/version/commission/policy
    /// text) that don't already exist. Per-key idempotent so re-running after adding
    /// a new key only inserts the new one.</summary>
    public static async Task SeedSystemSettingsAsync(AppDbContext db)
    {
        var defaults = new (string Key, string NameAr, string NameEn, SettingType Type,
            string ValueAr, string ValueEn, bool Sensitive)[]
        {
            ("in_maintenance", "وضع الصيانة", "Maintenance Mode", SettingType.Switch,
                "false", "false", false),
            ("version_android", "أقل نسخة مدعومة (أندرويد)", "Min Supported Version (Android)",
                SettingType.Text, "1.0.0", "1.0.0", false),
            ("version_ios", "أقل نسخة مدعومة (iOS)", "Min Supported Version (iOS)",
                SettingType.Text, "1.0.0", "1.0.0", false),
            ("commission_percentage", "نسبة عمولة المنصة (%)", "Platform Commission (%)",
                SettingType.Number, "10", "10", false),
            ("points_earn_per_10sar", "نقاط مكتسبة لكل 10 ريال إنفاق", "Points per 10 SAR Spent",
                SettingType.Number, "1", "1", false),
            ("points_match_reward", "نقاط إتمام مباراة", "Match Completion Points",
                SettingType.Number, "10", "10", false),
            // مهلة الإلغاء التلقائي: مباراة أو أمريكانو لم يكتمل عدده قبل هذه
            // المدة من موعده يُلغى وتُردّ الحصص، فلا يبقى الملعب محجوزاً لحدث
            // لن يقوم ولا ينتظر اللاعبون حتى تفوت الساعة. صفر = تعطيلها.
            ("match_autocancel_hours_before", "إلغاء المباراة غير المكتملة قبل موعدها (ساعات)",
                "Auto-cancel Incomplete Match Before Start (hours)",
                SettingType.Number, "3", "3", false),
            // وثيقة «المستويات والنقاط»: 500 نقطة = 50 ريالاً.
            ("points_redeem_per_riyal", "نقاط مقابل ريال واحد عند الاستبدال", "Points per 1 SAR (Redemption)",
                SettingType.Number, "10", "10", false),
            ("points_min_redeem", "الحد الأدنى لاستبدال النقاط", "Minimum Points Redemption",
                SettingType.Number, "500", "500", false),
            // خصم نقاط المكافآت عن كل انسحاب من مباراة/أمريكانو/بطولة.
            ("points_withdrawal_penalty", "نقاط تُخصم عند الانسحاب من حدث", "Points Deducted per Withdrawal",
                SettingType.Number, "10", "10", false),
            // ── نقاط المكافآت بالنشاط (تُدار من صفحة «المستويات والنقاط») ──────
            ("reward_points_booking", "نقاط مكافأة: حجز ملعب", "Reward: Court Booking",
                SettingType.Number, "50", "50", false),
            ("reward_points_coach_session", "نقاط مكافأة: حجز تدريب", "Reward: Coach Session",
                SettingType.Number, "50", "50", false),
            ("reward_points_match_created", "نقاط مكافأة: إنشاء مباراة", "Reward: Match Created",
                SettingType.Number, "30", "30", false),
            ("reward_points_americano", "نقاط مكافأة: تنظيم أمريكانو", "Reward: Americano Organized",
                SettingType.Number, "100", "100", false),
            ("reward_points_tournament", "نقاط مكافأة: تنظيم بطولة", "Reward: Tournament Organized",
                SettingType.Number, "200", "200", false),
            ("reward_points_invite_friend", "نقاط مكافأة: دعوة صديق للتطبيق", "Reward: Friend Invited",
                SettingType.Number, "100", "100", false),
            ("reward_points_rate_court", "نقاط مكافأة: تقييم ملعب", "Reward: Court Rated",
                SettingType.Number, "20", "20", false),
            ("reward_points_rate_coach", "نقاط مكافأة: تقييم مدرب", "Reward: Coach Rated",
                SettingType.Number, "20", "20", false),
            // ── نقاط المستوى: فرق المستوى بين متوسط الفريقين ────────────────────
            ("level_points_require_coach", "نقاط المستوى تشترط اعتماد مدرب للمستوى",
                "Level Points Require Coach Verification", SettingType.Switch, "true", "true", false),
            ("level_points_win_same", "نقاط مستوى: فوز على خصم بنفس المستوى", "Level: Win vs Same",
                SettingType.Number, "20", "20", false),
            ("level_points_win_higher_half", "نقاط مستوى: فوز على خصم أعلى بـ 0.5", "Level: Win vs +0.5",
                SettingType.Number, "25", "25", false),
            ("level_points_win_higher_full", "نقاط مستوى: فوز على خصم أعلى بـ 1.0+", "Level: Win vs +1.0",
                SettingType.Number, "35", "35", false),
            ("level_points_win_lower_half", "نقاط مستوى: فوز على خصم أقل بـ 0.5", "Level: Win vs -0.5",
                SettingType.Number, "12", "12", false),
            ("level_points_win_lower_full", "نقاط مستوى: فوز على خصم أقل بـ 1.0+", "Level: Win vs -1.0",
                SettingType.Number, "5", "5", false),
            ("level_points_loss_same", "نقاط مستوى: خسارة أمام خصم بنفس المستوى", "Level: Loss vs Same",
                SettingType.Number, "-20", "-20", false),
            ("level_points_loss_higher_half", "نقاط مستوى: خسارة أمام خصم أعلى بـ 0.5", "Level: Loss vs +0.5",
                SettingType.Number, "-12", "-12", false),
            ("level_points_loss_higher_full", "نقاط مستوى: خسارة أمام خصم أعلى بـ 1.0+", "Level: Loss vs +1.0",
                SettingType.Number, "-5", "-5", false),
            ("level_points_loss_lower_half", "نقاط مستوى: خسارة أمام خصم أقل بـ 0.5", "Level: Loss vs -0.5",
                SettingType.Number, "-25", "-25", false),
            ("level_points_loss_lower_full", "نقاط مستوى: خسارة أمام خصم أقل بـ 1.0+", "Level: Loss vs -1.0",
                SettingType.Number, "-35", "-35", false),
            ("wallet_topup_min", "الحد الأدنى لشحن المحفظة (ر.س)", "Minimum Wallet Top-up (SAR)",
                SettingType.Number, "10", "10", false),
            ("wallet_topup_max", "الحد الأقصى لشحن المحفظة في المرة الواحدة (ر.س)",
                "Maximum Wallet Top-up per Transaction (SAR)",
                SettingType.Number, "5000", "5000", false),
            // Gateway fees charged on top of a top-up. Seeded at zero so nothing
            // changes until an admin enters the real rates from the Moyasar
            // contract — a guessed rate would over-charge real users.
            ("wallet_topup_fee_percent", "نسبة رسوم بوابة الدفع (%)",
                "Payment Gateway Fee (%)", SettingType.Number, "0", "0", false),
            ("wallet_topup_fee_fixed", "رسم ثابت لكل عملية شحن (ر.س)",
                "Fixed Fee per Top-up (SAR)", SettingType.Number, "0", "0", false),
            ("wallet_topup_fee_vat_percent", "ضريبة القيمة المضافة على الرسوم (%)",
                "VAT on Fees (%)", SettingType.Number, "15", "15", false),
            // Free-text notes shown under the top-up limits, one bullet per line.
            // The limit bullets themselves are generated from the two keys above.
            ("wallet_topup_notes", "ملاحظات شحن المحفظة (سطر لكل ملاحظة)",
                "Wallet Top-up Notes (one per line)", SettingType.Text,
                "لا توجد رسوم على عمليات الشحن\nالرصيد صالح للاستخدام فور اكتمال عملية الدفع",
                "No fees on top-up transactions\nThe balance is usable as soon as the payment completes",
                false),
            ("about_app", "عن التطبيق", "About the App", SettingType.Text,
                "سبورتا يساعدك على حجز الملاعب، الانضمام للمباريات، والتدرب مع أفضل المدربين.",
                "Sporta helps you book courts, join matches, and train with top coaches.", false),
            // Full official policy text (Markdown, AR + EN) lives in PolicyContent
            // and is kept current across releases by UpgradePoliciesAsync below.
            ("privacy_policy", "سياسة الخصوصية", "Privacy Policy", SettingType.Text,
                PolicyContent.PrivacyAr, PolicyContent.PrivacyEn, false),
            ("terms_conditions", "الشروط والأحكام", "Terms & Conditions", SettingType.Text,
                PolicyContent.TermsAr, PolicyContent.TermsEn, false),
            ("refund_policy", "سياسة الاسترجاع", "Refund Policy", SettingType.Text,
                PolicyContent.RefundAr, PolicyContent.RefundEn, false),
        };

        var existingKeys = await db.SystemSettings.Select(s => s.Key).ToListAsync();
        var toAdd = defaults.Where(d => !existingKeys.Contains(d.Key)).ToList();
        if (toAdd.Count == 0) return;

        db.SystemSettings.AddRange(toAdd.Select(d => new SystemSetting
        {
            Key = d.Key, NameAr = d.NameAr, NameEn = d.NameEn, Type = d.Type,
            ValueAr = d.ValueAr, ValueEn = d.ValueEn, IsSensitive = d.Sensitive,
        }));
        await db.SaveChangesAsync();
    }

    /// <summary>Force-refreshes the three policy settings (terms/privacy/refund) with
    /// the official content in <see cref="PolicyContent"/> on databases that already
    /// hold the old placeholder text. Version-gated via the hidden
    /// <c>policies_content_version</c> setting so it runs once per content bump and
    /// never clobbers later admin edits until the version is raised again.</summary>
    public static async Task UpgradePoliciesAsync(AppDbContext db)
    {
        const string versionKey = "policies_content_version";
        var marker = await db.SystemSettings.FirstOrDefaultAsync(s => s.Key == versionKey);
        var current = 0;
        if (marker != null) int.TryParse(marker.ValueAr, out current);
        if (current >= PolicyContent.Version) return;

        foreach (var (key, nameAr, nameEn, valueAr, valueEn) in PolicyContent.Policies)
        {
            var s = await db.SystemSettings.FirstOrDefaultAsync(x => x.Key == key);
            if (s == null)
            {
                db.SystemSettings.Add(new SystemSetting
                {
                    Key = key, NameAr = nameAr, NameEn = nameEn, Type = SettingType.Text,
                    ValueAr = valueAr, ValueEn = valueEn,
                });
            }
            else
            {
                s.NameAr = nameAr;
                s.NameEn = nameEn;
                s.Type = SettingType.Text;
                s.ValueAr = valueAr;
                s.ValueEn = valueEn;
                s.UpdatedAt = DateTime.UtcNow;
            }
        }

        var version = PolicyContent.Version.ToString();
        if (marker == null)
        {
            db.SystemSettings.Add(new SystemSetting
            {
                Key = versionKey, NameAr = "إصدار محتوى السياسات", NameEn = "Policies Content Version",
                Type = SettingType.Number, ValueAr = version, ValueEn = version, IsSensitive = true,
            });
        }
        else
        {
            marker.ValueAr = version;
            marker.ValueEn = version;
            marker.UpdatedAt = DateTime.UtcNow;
        }
        await db.SaveChangesAsync();
    }

    // ──────────────────────────────────────────────────────────────────────
    // Rich demo dataset (named players + coaches + matches + americano +
    // coach sessions) so every screen has realistic content for testing.
    // All demo accounts use the "@sporta.demo" email domain (password:
    // "Demo1234"). Idempotent: accounts are created per-email, and the heavy
    // content (matches/americano/sessions) is created only on the run that
    // first inserts the demo players.
    // ──────────────────────────────────────────────────────────────────────
    private const string DemoEmailDomain = "@sporta.demo";

    public static async Task SeedDemoDataAsync(AppDbContext db)
    {
        await SeedAdminAccountAsync(db);
        await SeedSecondAdminAccountAsync(db);
        await SeedDemoCoachesAsync(db);
        await SeedDemoVenueOwnerAsync(db);
        var (playerIds, createdNow) = await SeedDemoPlayersAsync(db);
        if (playerIds.Count < 2) return;

        if (createdNow && playerIds.Count >= 4)
        {
            await SeedDemoMatchesAsync(db, playerIds);
            await SeedDemoAmericanoAsync(db, playerIds);
        }

        await SeedDemoBookingsAsync(db, playerIds);

        // Runs every startup (self-guarded) so existing dev databases also get
        // the rated-session history the live coach stats are computed from.
        await SeedDemoCoachSessionsAsync(db, playerIds);

        await BackfillEnglishNamesAsync(db);
    }

    /// <summary>
    /// يملأ الاسم الإنجليزي للأندية والملاعب التجريبية التي أُنشئت قبل إضافة
    /// عمود <c>NameEn</c> (أضيف 2026-08-18)، وإلا ظهرت بالعربية داخل الواجهة
    /// الإنجليزية. يعمل على الصفوف الفارغة فقط فهو آمن للتكرار.
    /// </summary>
    private static async Task BackfillEnglishNamesAsync(AppDbContext db)
    {
        var venueNames = new Dictionary<string, string>
        {
            ["نادي البادل الملكي"] = "Royal Padel Club",
            ["بادل كلوب الشرقية"] = "Eastern Padel Club",
            ["مركز بادل المدينة"] = "City Padel Center",
            ["نادي سلطان للبادل"] = "Sultan Padel Club",
        };
        var courtNames = new Dictionary<string, string>
        {
            ["ملعب 1"] = "Court 1",
            ["ملعب 2"] = "Court 2",
            ["ملعب 3"] = "Court 3",
            ["الملعب الأول"] = "Court 1",
            ["الملعب الثاني"] = "Court 2",
            ["الملعب الخارجي"] = "Outdoor Court",
        };

        var venues = await db.Venues.Where(v => v.NameEn == null).ToListAsync();
        foreach (var v in venues)
            if (venueNames.TryGetValue(v.Name, out var en)) v.NameEn = en;

        var courts = await db.Courts.Where(c => c.NameEn == null).ToListAsync();
        foreach (var c in courts)
            if (courtNames.TryGetValue(c.Name, out var en)) c.NameEn = en;

        if (venues.Count > 0 || courts.Count > 0) await db.SaveChangesAsync();
    }

    /// <summary>
    /// A demo venue-owner account (login: 0500000301 / Demo1234) with a club and
    /// courts, so the venue-owner dashboard shows real data. Idempotent by email.
    /// </summary>
    private static async Task SeedDemoVenueOwnerAsync(AppDbContext db)
    {
        const string email = "0500000301" + DemoEmailDomain;
        if (await db.Users.AnyAsync(u => u.Email == email))
            return;

        var hash = BCrypt.Net.BCrypt.HashPassword("Demo1234");
        var owner = new User
        {
            FirstName = "سلطان",
            LastName = "الراشد",
            Email = email,
            PhoneNumber = "0500000301",
            PasswordHash = hash,
            UserType = UserType.VenueOwner,
            Gender = Gender.Male,
            Country = "السعودية",
            City = "الدمام",
            Roles = { new UserRole { Role = UserType.VenueOwner } },
        };
        db.Users.Add(owner);
        await db.SaveChangesAsync();

        db.Venues.Add(new Venue
        {
            Name = "نادي سلطان للبادل",
            NameEn = "Sultan Padel Club",
            OwnerId = owner.Id,
            Country = "السعودية",
            City = "الدمام",
            District = "الشاطئ",
            Address = "حي الشاطئ",
            Latitude = 26.4290,
            Longitude = 50.1100,
            GenderPolicy = VenueGenderPolicy.MenOnly,
            IsApproved = true,
            Courts =
            {
                new Court { Name = "الملعب الأول", NameEn = "Court 1", Type = CourtType.Indoor, PricePerHour = 120 },
                new Court { Name = "الملعب الثاني", NameEn = "Court 2", Type = CourtType.Indoor, PricePerHour = 120 },
                new Court { Name = "الملعب الخارجي", NameEn = "Outdoor Court", Type = CourtType.Outdoor, PricePerHour = 90 },
            },
        });
        await db.SaveChangesAsync();
    }

    /// <summary>
    /// The platform admin account (login: phone 0500000000 / Admin1234) used for
    /// admin-only endpoints (announcements, lock account, …). Self-healing by
    /// email: creates the account, or promotes an existing row to a real Admin.
    /// </summary>
    public static Task SeedAdminAccountAsync(AppDbContext db) =>
        EnsureAdminAsync(db, "0500000000", "admin@sporta.demo", "Admin1234", "مدير", "النظام");

    /// <summary>
    /// Second admin account (login: phone 0500000001 / Admin1234), added on
    /// request as an extra login alongside the original admin above.
    /// </summary>
    public static Task SeedSecondAdminAccountAsync(AppDbContext db) =>
        EnsureAdminAsync(db, "0500000001", "admin2@sporta.demo", "Admin1234", "مدير", "النظام الثاني");

    /// <summary>
    /// حساب أدمن حقيقي من الإعدادات (<c>Admin:Phone</c> + <c>Admin:Password</c>)
    /// يعمل على أي بيئة — الإنتاج خصوصاً — مستقلاً عن بيانات التجربة، فلا يلزم
    /// تفعيل <c>Seeding</c> هناك. بلا جوال أو كلمة مرور لا يفعل شيئاً.
    ///
    /// يُبحث عن المستخدم بالجوال: إن وُجد رُقّي إلى أدمن، وإلا أُنشئ. كلمة
    /// المرور تُعاد كتابتها من الإعدادات في كل تشغيل، فتغييرها هناك يكفي
    /// لاستعادة الدخول.
    /// </summary>
    public static async Task BootstrapAdminAsync(AppDbContext db, IConfiguration config)
    {
        var phone = config["Admin:Phone"]?.Trim();
        var password = config["Admin:Password"];
        if (string.IsNullOrWhiteSpace(phone) || string.IsNullOrWhiteSpace(password))
            return;

        var existing = await db.Users
            .Include(u => u.Roles)
            .FirstOrDefaultAsync(u => u.PhoneNumber == phone);

        await UpsertAdminAsync(
            db, existing, phone,
            // البريد اختياري وفريد — نتركه كما هو للمستخدم الموجود، وفارغاً للجديد.
            existing?.Email,
            password,
            config["Admin:FirstName"] ?? "مدير",
            config["Admin:LastName"] ?? "سبورتا");
    }

    private static async Task EnsureAdminAsync(
        AppDbContext db, string phone, string email, string password, string firstName, string lastName)
    {
        var admin = await db.Users
            .Include(u => u.Roles)
            .FirstOrDefaultAsync(u => u.Email == email);

        await UpsertAdminAsync(db, admin, phone, email, password, firstName, lastName);
    }

    /// <summary>ينشئ الأدمن أو يرقّي الصف الموجود؛ مشترك بين حسابات التجربة وحساب الإعدادات.</summary>
    private static async Task UpsertAdminAsync(
        AppDbContext db, User? admin, string phone, string? email, string password,
        string firstName, string lastName)
    {
        var hash = BCrypt.Net.BCrypt.HashPassword(password);

        if (admin is null)
        {
            db.Users.Add(new User
            {
                FirstName = firstName,
                LastName = lastName,
                Email = email,
                PhoneNumber = phone,
                PasswordHash = hash,
                UserType = UserType.Admin,
                Gender = Gender.Male,
                IsActive = true,
                Country = "السعودية",
                City = "الرياض",
                Roles = { new UserRole { Role = UserType.Admin } },
            });
            await db.SaveChangesAsync();
            return;
        }

        // Promote/repair an existing admin row so it's always a usable Admin,
        // with exactly the Admin role (so it skips player onboarding gates).
        admin.UserType = UserType.Admin;
        admin.PhoneNumber = phone;
        admin.PasswordHash = hash;
        admin.IsActive = true;

        var nonAdminRoles = admin.Roles.Where(r => r.Role != UserType.Admin).ToList();
        if (nonAdminRoles.Count > 0)
            db.UserRoles.RemoveRange(nonAdminRoles);
        if (!admin.Roles.Any(r => r.Role == UserType.Admin))
            admin.Roles.Add(new UserRole { UserId = admin.Id, Role = UserType.Admin });
        await db.SaveChangesAsync();
    }

    private static async Task SeedDemoCoachesAsync(AppDbContext db)
    {
        // الإحصائيات تُحسب حيًا من الجلسات المزروعة في SeedDemoCoachSessionsAsync.
        var demo = new[]
        {
            (First: "محمد", Last: "أحمد", Phone: "0500000101", Gender: Gender.Male,
             City: "الدمام", Lat: 26.4300, Lng: 50.0950,
             Spec: "تقنيات متقدمة، استراتيجية اللعب، التحليل الفني",
             Rate: 200m, Verified: true),
            (First: "سارة", Last: "عبدالله", Phone: "0500000102", Gender: Gender.Female,
             City: "الخبر", Lat: 26.2800, Lng: 50.2080,
             Spec: "تدريب مبتدئين، الأساسيات، اللياقة البدنية",
             Rate: 150m, Verified: false),
            (First: "خالد", Last: "محمود", Phone: "0500000103", Gender: Gender.Male,
             City: "الرياض", Lat: 24.7136, Lng: 46.6753,
             Spec: "إعداد احترافي، المنافسات، التكتيك المتقدم",
             Rate: 280m, Verified: true),
        };

        var hash = BCrypt.Net.BCrypt.HashPassword("Demo1234");
        var added = false;
        foreach (var c in demo)
        {
            var email = $"{c.Phone}{DemoEmailDomain}";
            if (await db.Users.AnyAsync(u => u.Email == email)) continue;

            db.Users.Add(new User
            {
                FirstName = c.First,
                LastName = c.Last,
                Email = email,
                PhoneNumber = c.Phone,
                PasswordHash = hash,
                UserType = UserType.Coach,
                Gender = c.Gender,
                Country = "السعودية",
                City = c.City,
                // موقع المدرب — تُحسب منه المسافة عن اللاعب في قائمة المدربين.
                Latitude = c.Lat,
                Longitude = c.Lng,
                Roles = { new UserRole { Role = UserType.Coach } },
                CoachProfile = new CoachProfile
                {
                    Bio = $"مدرب بادل - {c.Spec}",
                    Specialization = c.Spec,
                    HourlyRate = c.Rate,
                    IsVerifiedOnPlatform = c.Verified,
                },
            });
            added = true;
        }
        if (added) await db.SaveChangesAsync();
    }

    private static async Task<(List<int> ids, bool createdNow)> SeedDemoPlayersAsync(AppDbContext db)
    {
        var demo = new[]
        {
            (First: "عبدالله", Last: "القحطاني", Phone: "0500000201", Gender: Gender.Male,
             City: "الدمام", Lat: 26.4207, Lng: 50.0888, Level: PlayerLevel.Advanced),
            (First: "فهد", Last: "الشمري", Phone: "0500000202", Gender: Gender.Male,
             City: "الخبر", Lat: 26.2794, Lng: 50.2083, Level: PlayerLevel.Intermediate),
            (First: "نورة", Last: "الدوسري", Phone: "0500000203", Gender: Gender.Female,
             City: "الدمام", Lat: 26.4350, Lng: 50.1033, Level: PlayerLevel.Professional),
            (First: "سعد", Last: "المطيري", Phone: "0500000204", Gender: Gender.Male,
             City: "الرياض", Lat: 24.7136, Lng: 46.6753, Level: PlayerLevel.Learner),
            (First: "ريم", Last: "العنزي", Phone: "0500000205", Gender: Gender.Female,
             City: "الخبر", Lat: 26.2850, Lng: 50.2100, Level: PlayerLevel.Advanced),
            (First: "تركي", Last: "الحربي", Phone: "0500000206", Gender: Gender.Male,
             City: "الدمام", Lat: 26.4180, Lng: 50.1000, Level: PlayerLevel.Intermediate),
            (First: "هند", Last: "السبيعي", Phone: "0500000207", Gender: Gender.Female,
             City: "الرياض", Lat: 24.7200, Lng: 46.6800, Level: PlayerLevel.Professional),
            (First: "ماجد", Last: "الغامدي", Phone: "0500000208", Gender: Gender.Male,
             City: "الخبر", Lat: 26.2900, Lng: 50.2000, Level: PlayerLevel.Advanced),
        };

        var hash = BCrypt.Net.BCrypt.HashPassword("Demo1234");
        var createdNow = false;
        foreach (var p in demo)
        {
            var email = $"{p.Phone}{DemoEmailDomain}";
            if (await db.Users.AnyAsync(u => u.Email == email)) continue;

            db.Users.Add(new User
            {
                FirstName = p.First,
                LastName = p.Last,
                Email = email,
                PhoneNumber = p.Phone,
                PasswordHash = hash,
                UserType = UserType.Player,
                Gender = p.Gender,
                Country = "السعودية",
                City = p.City,
                Latitude = p.Lat,
                Longitude = p.Lng,
                FavoriteSport = "padel",
                Roles = { new UserRole { Role = UserType.Player } },
                Wallet = new Wallet { Balance = 1000m },
                PlayerProfile = new PlayerProfile
                {
                    Level = p.Level,
                    PreferredHand = PreferredHand.Right,
                    CourtPosition = CourtPosition.Right,
                    PreferredMatchType = MatchType.Competitive,
                    PreferredPlayTime = PlayTimePreference.Evening,
                    EloRating = 1000f + ((int)p.Level - 1) * 150f,
                    LevelAssessments =
                    {
                        new LevelAssessment
                        {
                            Type = LevelAssessmentType.SelfAssessment,
                            AssignedLevel = p.Level,
                            IsCompleted = true,
                        },
                    },
                },
            });
            createdNow = true;
        }
        if (createdNow) await db.SaveChangesAsync();

        var ids = await db.Users
            .Where(u => u.Email != null && u.Email.EndsWith(DemoEmailDomain) &&
                        u.UserType == UserType.Player)
            .OrderBy(u => u.Id)
            .Select(u => u.Id)
            .ToListAsync();
        return (ids, createdNow);
    }

    /// <summary>
    /// A spread of court bookings for the demo players — one past (completed),
    /// one upcoming (confirmed), one pending owner approval, one cancelled — so
    /// every booking state has data. Prices/commission are computed exactly like
    /// <c>BookingService</c> so the numbers are real. Idempotent by any booking.
    /// </summary>
    private static async Task SeedDemoBookingsAsync(AppDbContext db, List<int> playerIds)
    {
        if (playerIds.Count == 0) return;
        if (await db.Bookings.AnyAsync()) return;

        var courts = await db.Courts
            .Include(c => c.PriceTiers)
            .OrderBy(c => c.Id)
            .ToListAsync();
        if (courts.Count == 0) return;

        Court court(int i) => courts[i % courts.Count];
        int player(int i) => playerIds[i % playerIds.Count];

        // (dayOffset, startHour, durationMin, status, paidFull)
        var plan = new (int Day, int Hour, int Duration, BookingStatus Status, bool Paid)[]
        {
            (-6, 18, 90, BookingStatus.Completed, true),
            (-2, 20, 60, BookingStatus.Completed, true),
            (2, 17, 90, BookingStatus.Confirmed, true),
            (4, 19, 120, BookingStatus.Confirmed, true),
            (1, 16, 60, BookingStatus.Pending, false),
            (-3, 21, 90, BookingStatus.Cancelled, false),
        };

        var bookings = new List<Booking>();
        for (var i = 0; i < plan.Length; i++)
        {
            var p = plan[i];
            var c = court(i);
            // Naive KSA wall-clock, same convention bookings use elsewhere.
            var start = AppClock.Now.Date.AddDays(p.Day).AddHours(p.Hour);
            var end = start.AddMinutes(p.Duration);

            // اللاعب يدفع سعر المالك، ونسبة سبورتا تُقتطع منه.
            var total = CourtSchedule.BaseBookingPrice(c, start, p.Duration);
            var commission = CourtSchedule.CommissionOn(c, total);

            bookings.Add(new Booking
            {
                CourtId = c.Id,
                UserId = player(i),
                StartTime = start,
                EndTime = end,
                TotalPrice = total,
                SportaCommission = commission,
                Status = p.Status,
                PaidFullAmount = p.Paid,
                CancelledAt = p.Status == BookingStatus.Cancelled ? AppClock.Now : null,
                CancellationReason =
                    p.Status == BookingStatus.Cancelled ? "إلغاء تجريبي" : null,
            });
        }

        db.Bookings.AddRange(bookings);
        await db.SaveChangesAsync();
    }

    private static async Task SeedDemoMatchesAsync(AppDbContext db, List<int> playerIds)
    {
        var courtIds = await db.Courts.OrderBy(c => c.Id).Select(c => c.Id).ToListAsync();
        if (courtIds.Count == 0) return;
        int court(int i) => courtIds[i % courtIds.Count];

        var matches = new List<Match>
        {
            // Open competitive match (creator + 1 joined → 2 spots free).
            new()
            {
                CreatorId = playerIds[0], CourtId = court(0), MatchType = MatchType.Competitive,
                Status = MatchStatus.Open, ScheduledAt = DateTime.UtcNow.AddDays(2).Date.AddHours(18),
                DurationMinutes = 90, MaxPlayers = 4, MinLevel = 4, MaxLevel = 6, PricePerPlayer = 50,
                Notes = "مباراة تنافسية مسائية",
                MatchPlayers =
                {
                    new MatchPlayer { UserId = playerIds[0] },
                    new MatchPlayer { UserId = playerIds[1] },
                },
            },
            // Open social match (creator only → 3 spots free).
            new()
            {
                CreatorId = playerIds[2], CourtId = court(1), MatchType = MatchType.Social,
                Status = MatchStatus.Open, ScheduledAt = DateTime.UtcNow.AddDays(3).Date.AddHours(19),
                DurationMinutes = 90, MaxPlayers = 4, MinLevel = 3, MaxLevel = 5, PricePerPlayer = 40,
                Notes = "مباراة ودية للجميع",
                MatchPlayers = { new MatchPlayer { UserId = playerIds[2] } },
            },
        };

        // Full match (4 approved players → ready for result entry).
        if (playerIds.Count >= 7)
        {
            matches.Add(new Match
            {
                CreatorId = playerIds[3], CourtId = court(2), MatchType = MatchType.Competitive,
                Status = MatchStatus.Full, ScheduledAt = DateTime.UtcNow.AddDays(1).Date.AddHours(20),
                DurationMinutes = 90, MaxPlayers = 4, MinLevel = 4, MaxLevel = 7, PricePerPlayer = 60,
                Notes = "مباراة مكتملة - جاهزة لإدخال النتيجة",
                MatchPlayers =
                {
                    new MatchPlayer { UserId = playerIds[3] },
                    new MatchPlayer { UserId = playerIds[4] },
                    new MatchPlayer { UserId = playerIds[5] },
                    new MatchPlayer { UserId = playerIds[6] },
                },
            });
        }

        db.Matches.AddRange(matches);
        await db.SaveChangesAsync();
    }

    private static async Task SeedDemoAmericanoAsync(AppDbContext db, List<int> playerIds)
    {
        var courtId = await db.Courts
            .OrderBy(c => c.Id)
            .Select(c => (int?)c.Id)
            .FirstOrDefaultAsync();

        // 1) OPEN americano: creator + 1 player → 2 spots free (test joining).
        var openMatch = new Match
        {
            CreatorId = playerIds[0], CourtId = courtId, MatchType = MatchType.American,
            Status = MatchStatus.Open, ScheduledAt = DateTime.UtcNow.AddDays(4).Date.AddHours(18),
            DurationMinutes = 90, MaxPlayers = 4, MinLevel = 3, MaxLevel = 7,
            MatchPlayers =
            {
                new MatchPlayer { UserId = playerIds[0] },
                new MatchPlayer { UserId = playerIds[1] },
            },
        };
        db.Matches.Add(openMatch);
        await db.SaveChangesAsync();
        db.AmericanoMatches.Add(new AmericanoMatch
        {
            MatchId = openMatch.Id, AmericanoType = MatchType.American,
            MinAllowedLevel = 3, MaxAllowedLevel = 7, TotalRounds = 3,
        });
        await db.SaveChangesAsync(); // rounds are generated when it fills up

        // 2) FULL americano (4 players) with rounds + partial scores entered.
        var ps = playerIds.Take(4).ToList();
        var fullMatch = new Match
        {
            CreatorId = ps[0], CourtId = courtId, MatchType = MatchType.American,
            Status = MatchStatus.Full, ScheduledAt = DateTime.UtcNow.AddDays(1).Date.AddHours(17),
            DurationMinutes = 90, MaxPlayers = 4, MinLevel = 3, MaxLevel = 6,
            MatchPlayers = ps.Select(id => new MatchPlayer { UserId = id }).ToList(),
        };
        db.Matches.Add(fullMatch);
        await db.SaveChangesAsync();

        var americano = new AmericanoMatch
        {
            MatchId = fullMatch.Id, AmericanoType = MatchType.American,
            MinAllowedLevel = 3, MaxAllowedLevel = 6, TotalRounds = 3,
        };
        db.AmericanoMatches.Add(americano);
        await db.SaveChangesAsync();

        var (a, b, c, d) = (ps[0], ps[1], ps[2], ps[3]);
        var pairings = new (int t1p1, int t1p2, int t2p1, int t2p2, int? s1, int? s2)[]
        {
            (a, b, c, d, 6, 4),       // round 1 — scored
            (a, c, b, d, 5, 7),       // round 2 — scored
            (a, d, b, c, null, null), // round 3 — pending
        };
        for (var i = 0; i < pairings.Length; i++)
        {
            var p = pairings[i];
            db.AmericanoRounds.Add(new AmericanoRound
            {
                AmericanoMatchId = americano.Id,
                RoundNumber = i + 1,
                Team1Player1Id = p.t1p1,
                Team1Player2Id = p.t1p2,
                Team2Player1Id = p.t2p1,
                Team2Player2Id = p.t2p2,
                Team1Score = p.s1,
                Team2Score = p.s2,
                IsCompleted = p.s1 != null,
            });
        }
        await db.SaveChangesAsync();
    }

    private static async Task SeedDemoCoachSessionsAsync(AppDbContext db, List<int> playerIds)
    {
        var coaches = await db.CoachProfiles
            .Where(cp => cp.User.Email != null &&
                         cp.User.Email.EndsWith(DemoEmailDomain))
            .OrderBy(cp => cp.Id)
            .Select(cp => new { cp.Id, cp.HourlyRate })
            .ToListAsync();
        if (coaches.Count == 0 || playerIds.Count < 2) return;

        var demoCoachIds = coaches.Select(c => c.Id).ToList();

        var first = coaches[0];
        var hasPending = await db.CoachSessions.AnyAsync(s =>
            demoCoachIds.Contains(s.CoachProfileId) &&
            s.Status == CoachSessionStatus.Pending);
        if (!hasPending)
        {
            db.CoachSessions.AddRange(
                // Two pending requests → test the coach "booking requests" screen.
                new CoachSession
                {
                    CoachProfileId = first.Id, PlayerId = playerIds[0],
                    Title = "جلسة تدريب فردية", Description = "تحسين الإرسال والتحكم",
                    TargetLevel = "متقدم", ScheduledAt = DateTime.UtcNow.AddDays(2).Date.AddHours(16),
                    DurationMinutes = 60, Price = first.HourlyRate, Status = CoachSessionStatus.Pending,
                },
                new CoachSession
                {
                    CoachProfileId = first.Id, PlayerId = playerIds[1],
                    Title = "جلسة لياقة بدنية", Description = "تمارين لياقة وإحماء",
                    TargetLevel = "متوسط", ScheduledAt = DateTime.UtcNow.AddDays(3).Date.AddHours(17),
                    DurationMinutes = 60, Price = first.HourlyRate, Status = CoachSessionStatus.Pending,
                });
        }

        // سجلّ جلسات مكتملة مدفوعة مع تقييمات اللاعبين — منه تُحسب إحصائيات
        // المدرب (التقييم/عدد الجلسات) وشارة "معتمد" بدل أي أرقام ثابتة.
        // سارة (الثانية) تبقى تحت حد الاعتماد التلقائي (10 جلسات) عمدًا حتى
        // تظهر شارة "نساء" في العرض التجريبي.
        var hasHistory = await db.CoachSessions.AnyAsync(s =>
            demoCoachIds.Contains(s.CoachProfileId) && s.PlayerRating != null);
        if (hasHistory)
        {
            await db.SaveChangesAsync();
            return;
        }

        var history = new (int CoachIndex, int[] Ratings)[]
        {
            (0, [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 5]),          // محمد ≈ 4.9
            (1, [5, 5, 5, 4, 5, 4, 5, 4]),                       // سارة ≈ 4.6
            (2, [5, 5, 4, 5, 5, 5, 4, 5, 5, 5, 4, 5, 5, 5, 5]),  // خالد ≈ 4.8
        };
        foreach (var (coachIndex, ratings) in history)
        {
            if (coachIndex >= coaches.Count) continue;
            var coach = coaches[coachIndex];
            for (var i = 0; i < ratings.Length; i++)
            {
                // ScheduledAt is naive KSA wall-clock time (AppClock).
                db.CoachSessions.Add(new CoachSession
                {
                    CoachProfileId = coach.Id,
                    PlayerId = playerIds[i % playerIds.Count],
                    Title = "جلسة تدريبية",
                    TargetLevel = "متوسط",
                    ScheduledAt = AppClock.Now.Date.AddDays(-(i + 3)).AddHours(17),
                    DurationMinutes = 60,
                    Price = coach.HourlyRate,
                    Status = CoachSessionStatus.Confirmed,
                    IsPaid = true,
                    IsCompleted = true,
                    PlayerRating = ratings[i],
                });
            }
        }
        await db.SaveChangesAsync();
    }

    /// <summary>
    /// Seeds Saudi cities across all 13 regions (with center coordinates for the
    /// map) plus districts for the major metros. Idempotent: no-op once cities
    /// exist. The dataset is intentionally a curated subset — extend it from the
    /// dashboard (cities/districts admin) or a full official dataset later.
    /// </summary>
    /// <summary>
    /// يضمن وجود الدولة الافتراضية (السعودية) ويربط بها أي مدينة غير مرتبطة —
    /// idempotent، ويعمل قبل بذر المدن وبعد ترقية قاعدة قائمة على السواء.
    /// </summary>
    public static async Task<Country> SeedCountriesAsync(AppDbContext db)
    {
        var saudi = await db.Countries.FirstOrDefaultAsync(c => c.Code == "SA");
        if (saudi is null)
        {
            saudi = new Country
            {
                NameAr = "السعودية",
                NameEn = "Saudi Arabia",
                Code = "SA",
                PhoneCode = "966",
                CurrencyCode = "SAR",
                SortOrder = 0,
            };
            db.Countries.Add(saudi);
            await db.SaveChangesAsync();
        }

        // المدن التي بُذرت قبل إضافة جدول الدول تُنسب للسعودية.
        var orphans = await db.Cities.Where(c => c.CountryId == 0).ToListAsync();
        if (orphans.Count > 0)
        {
            foreach (var c in orphans) c.CountryId = saudi.Id;
            await db.SaveChangesAsync();
        }

        return saudi;
    }

    /// <summary>
    /// يربط الأندية القديمة بجداول الدول/المدن/الأحياء اعتماداً على أسمائها
    /// النصية، حتى تظهر لموظفي المدينة/الدولة وتعمل فلترة المدينة والحي. الأندية
    /// الجديدة ترسل المعرّفات عند الإنشاء؛ وما لا يطابق اسمه أي سجل يبقى بلا ربط
    /// (لا نخمّن له مدينة أو حياً).
    /// </summary>
    public static async Task BackfillVenueCityLinksAsync(AppDbContext db)
    {
        var pending = await db.Venues
            .Where(v => v.CityId == null || v.DistrictId == null)
            .ToListAsync();
        if (pending.Count == 0) return;

        var cities = await db.Cities.ToListAsync();
        var districts = await db.Districts.ToListAsync();
        var linked = 0;
        foreach (var venue in pending)
        {
            if (venue.CityId == null)
            {
                var name = venue.City?.Trim();
                if (string.IsNullOrEmpty(name)) continue;

                var city = cities.FirstOrDefault(c => c.NameAr == name || c.NameEn == name);
                if (city is null) continue;

                venue.CityId = city.Id;
                venue.CountryId = city.CountryId;
                linked++;
            }

            if (venue.DistrictId != null) continue;

            // الأندية القديمة قد تحمل اسم الحي في العنوان النصي فقط، فنجرّبه
            // كبديل حتى تُربط بسجل الحي (وبذلك يظهر اسمه الإنجليزي أيضاً).
            var districtName = venue.District?.Trim();
            if (string.IsNullOrEmpty(districtName)) districtName = venue.Address?.Trim();
            if (string.IsNullOrEmpty(districtName)) continue;
            // العناوين تُكتب غالباً "حي الشاطئ" بينما القائمة تحفظه "الشاطئ".
            if (districtName.StartsWith("حي "))
                districtName = districtName["حي ".Length..].Trim();

            var district = districts.FirstOrDefault(d =>
                d.CityId == venue.CityId &&
                (d.NameAr == districtName || d.NameEn == districtName));
            if (district is null) continue;

            venue.DistrictId = district.Id;
            venue.District = district.NameAr;
            linked++;
        }

        if (linked > 0) await db.SaveChangesAsync();
    }

    /// <summary>
    /// يربط المستخدمين القدامى بجدول المدن اعتماداً على نص المدينة، حتى يظهروا
    /// لموظفي مدينتهم. (المستخدمون الجدد يرسلون CityId عند التسجيل.)
    /// </summary>
    public static async Task BackfillUserCityLinksAsync(AppDbContext db)
    {
        var pending = await db.Users
            .Where(u => u.CityId == null && u.City != null && u.City != "")
            .ToListAsync();
        if (pending.Count == 0) return;

        var cities = await db.Cities.ToListAsync();
        var linked = 0;
        foreach (var user in pending)
        {
            var name = user.City!.Trim();
            var city = cities.FirstOrDefault(c => c.NameAr == name || c.NameEn == name);
            if (city is null) continue;

            user.CityId = city.Id;
            linked++;
        }

        if (linked > 0) await db.SaveChangesAsync();
    }

    public static async Task SeedCitiesAndDistrictsAsync(AppDbContext db)
    {
        var saudi = await SeedCountriesAsync(db);

        if (await db.Cities.AnyAsync())
            return;

        (string ar, string en)[] D(params (string, string)[] items) => items;
        var none = System.Array.Empty<(string ar, string en)>();

        // (NameAr, NameEn, Region, Lat, Lng, districts)
        var data = new (string ar, string en, string region, double lat, double lng, (string ar, string en)[] districts)[]
        {
            // ── منطقة الرياض ──
            ("الرياض", "Riyadh", "منطقة الرياض", 24.7136, 46.6753, D(
                ("العليا","Al Olaya"), ("النخيل","Al Nakheel"), ("الملز","Al Malaz"),
                ("السليمانية","As Sulimaniyah"), ("الياسمين","Al Yasmin"), ("النرجس","An Narjis"),
                ("الملقا","Al Malqa"), ("حطين","Hittin"), ("الربيع","Ar Rabi"),
                ("الصحافة","As Sahafah"), ("المروج","Al Muruj"), ("الورود","Al Wurud"),
                ("غرناطة","Granada"), ("قرطبة","Qurtubah"), ("اليرموك","Al Yarmuk"),
                ("الروضة","Ar Rawdah"), ("النسيم","An Naseem"), ("السويدي","As Suwaidi"),
                ("العزيزية","Al Aziziyah"), ("الشفا","Ash Shifa"), ("المصيف","Al Maseef"),
                ("النزهة","An Nuzhah"), ("الرحمانية","Ar Rahmaniyah"), ("المونسية","Al Munsiyah"))),
            ("الخرج", "Al Kharj", "منطقة الرياض", 24.1554, 47.3346, none),
            ("الدرعية", "Ad Diriyah", "منطقة الرياض", 24.7333, 46.5717, none),
            ("المجمعة", "Al Majmaah", "منطقة الرياض", 25.9039, 45.3450, none),
            ("الزلفي", "Az Zulfi", "منطقة الرياض", 26.2833, 44.8000, none),
            ("الدوادمي", "Ad Dawadmi", "منطقة الرياض", 24.5074, 44.3921, none),
            ("وادي الدواسر", "Wadi ad-Dawasir", "منطقة الرياض", 20.4485, 44.7930, none),

            // ── منطقة مكة المكرمة ──
            ("مكة المكرمة", "Makkah", "منطقة مكة المكرمة", 21.3891, 39.8579, D(
                ("العزيزية","Al Aziziyah"), ("الششة","Ash Shisha"), ("الزاهر","Az Zahir"),
                ("النسيم","An Naseem"), ("الشوقية","Ash Shawqiyah"), ("العوالي","Al Awali"),
                ("بطحاء قريش","Batha Quraish"), ("الكعكية","Al Kakiyah"), ("الرصيفة","Ar Rusaifah"),
                ("جرول","Jarwal"), ("المسفلة","Al Misfalah"), ("الهجرة","Al Hijrah"))),
            ("جدة", "Jeddah", "منطقة مكة المكرمة", 21.4858, 39.1925, D(
                ("الحمراء","Al Hamra"), ("الروضة","Ar Rawdah"), ("السلامة","As Salamah"),
                ("الشاطئ","Ash Shati"), ("النعيم","An Naim"), ("الصفا","As Safa"),
                ("المرجان","Al Murjan"), ("أبحر الشمالية","Obhur Al Shamaliyah"),
                ("أبحر الجنوبية","Obhur Al Janubiyah"), ("الفيصلية","Al Faisaliyah"),
                ("النزهة","An Nuzhah"), ("البوادي","Al Bawadi"), ("الزهراء","Az Zahra"),
                ("الربوة","Ar Rabwah"), ("الحمدانية","Al Hamdaniyah"), ("النسيم","An Naseem"),
                ("بريمان","Buraiman"), ("السليمانية","As Sulimaniyah"))),
            ("الطائف", "Taif", "منطقة مكة المكرمة", 21.2703, 40.4158, none),
            ("القنفذة", "Al Qunfudhah", "منطقة مكة المكرمة", 19.1264, 41.0789, none),
            ("رابغ", "Rabigh", "منطقة مكة المكرمة", 22.7986, 39.0349, none),

            // ── منطقة المدينة المنورة ──
            ("المدينة المنورة", "Madinah", "منطقة المدينة المنورة", 24.5247, 39.5692, D(
                ("العوالي","Al Awali"), ("قباء","Quba"), ("الحرة الشرقية","Al Harrah Ash Sharqiyah"),
                ("العزيزية","Al Aziziyah"), ("الدفاع","Ad Difa"), ("شوران","Shuran"),
                ("الأزهري","Al Azhari"), ("الحزام","Al Hizam"), ("الرانوناء","Ar Ranuna"),
                ("بني معاوية","Bani Muawiyah"))),
            ("ينبع", "Yanbu", "منطقة المدينة المنورة", 24.0895, 38.0618, none),
            ("العلا", "Al Ula", "منطقة المدينة المنورة", 26.6167, 37.9167, none),
            ("بدر", "Badr", "منطقة المدينة المنورة", 23.7810, 38.7906, none),

            // ── المنطقة الشرقية ──
            ("الدمام", "Dammam", "المنطقة الشرقية", 26.4207, 50.0888, D(
                ("الشاطئ","Ash Shati"), ("الفيصلية","Al Faisaliyah"), ("الجلوية","Al Jalawiyah"),
                ("النور","An Nur"), ("العزيزية","Al Aziziyah"), ("الأندلس","Al Andalus"),
                ("الفنار","Al Fanar"), ("الريان","Ar Rayyan"), ("الروضة","Ar Rawdah"),
                ("المزروعية","Al Mazruiyah"), ("أحد","Uhud"), ("بدر","Badr"),
                ("النزهة","An Nuzhah"), ("الأمانة","Al Amanah"))),
            ("الخبر", "Al Khobar", "المنطقة الشرقية", 26.2794, 50.2083, D(
                ("العقربية","Al Aqrabiyah"), ("الثقبة","Ath Thuqbah"), ("الراكة","Ar Rakah"),
                ("الحزام الذهبي","Al Hizam Adh Dhahabi"), ("الجسر","Al Jisr"), ("اليرموك","Al Yarmuk"),
                ("التحلية","At Tahliyah"), ("الخزامى","Al Khuzama"), ("الكورنيش","Al Kurnaish"),
                ("البندرية","Al Bandariyah"), ("العليا","Al Olaya"), ("الحمراء","Al Hamra"))),
            ("الظهران", "Dhahran", "المنطقة الشرقية", 26.2361, 50.0393, D(
                ("الدوحة الشمالية","Ad Dawhah Ash Shamaliyah"), ("الدوحة الجنوبية","Ad Dawhah Al Janubiyah"),
                ("هجر","Hajar"), ("القشلة","Al Qashlah"), ("تهامة","Tihamah"))),
            ("الأحساء", "Al Ahsa", "المنطقة الشرقية", 25.3833, 49.5869, D(
                ("النايفية","An Naifiyah"), ("الصالحية","As Salihiyah"), ("الرقيقة","Ar Ruqaiqah"),
                ("المزروع","Al Mazru"), ("المبرز","Al Mubarraz"), ("الهفوف","Al Hufuf"))),
            ("الجبيل", "Jubail", "المنطقة الشرقية", 27.0174, 49.6225, none),
            ("القطيف", "Qatif", "المنطقة الشرقية", 26.5196, 49.9962, none),
            ("حفر الباطن", "Hafar Al Batin", "المنطقة الشرقية", 28.4342, 45.9636, none),
            ("الخفجي", "Khafji", "المنطقة الشرقية", 28.4390, 48.4910, none),
            ("رأس تنورة", "Ras Tanura", "المنطقة الشرقية", 26.6449, 50.1583, none),

            // ── منطقة عسير ──
            ("أبها", "Abha", "منطقة عسير", 18.2164, 42.5053, none),
            ("خميس مشيط", "Khamis Mushait", "منطقة عسير", 18.3000, 42.7333, none),
            ("بيشة", "Bisha", "منطقة عسير", 19.9764, 42.6009, none),
            ("النماص", "An Namas", "منطقة عسير", 19.1500, 42.1500, none),

            // ── منطقة تبوك ──
            ("تبوك", "Tabuk", "منطقة تبوك", 28.3835, 36.5662, none),
            ("ضباء", "Duba", "منطقة تبوك", 27.3493, 35.6962, none),
            ("الوجه", "Al Wajh", "منطقة تبوك", 26.2333, 36.4667, none),

            // ── منطقة حائل ──
            ("حائل", "Hail", "منطقة حائل", 27.5114, 41.7208, none),

            // ── منطقة الحدود الشمالية ──
            ("عرعر", "Arar", "منطقة الحدود الشمالية", 30.9753, 41.0381, none),
            ("رفحاء", "Rafha", "منطقة الحدود الشمالية", 29.6386, 43.4990, none),
            ("طريف", "Turaif", "منطقة الحدود الشمالية", 31.6725, 38.6637, none),

            // ── منطقة جازان ──
            ("جازان", "Jazan", "منطقة جازان", 16.8894, 42.5706, none),
            ("صبيا", "Sabya", "منطقة جازان", 17.1494, 42.6258, none),
            ("أبو عريش", "Abu Arish", "منطقة جازان", 16.9689, 42.8319, none),

            // ── منطقة نجران ──
            ("نجران", "Najran", "منطقة نجران", 17.4917, 44.1322, none),
            ("شرورة", "Sharurah", "منطقة نجران", 17.4838, 47.1084, none),

            // ── منطقة الباحة ──
            ("الباحة", "Al Bahah", "منطقة الباحة", 20.0129, 41.4677, none),
            ("بلجرشي", "Baljurashi", "منطقة الباحة", 19.8590, 41.5670, none),

            // ── منطقة الجوف ──
            ("سكاكا", "Sakaka", "منطقة الجوف", 29.9697, 40.2064, none),
            ("القريات", "Al Qurayyat", "منطقة الجوف", 31.3320, 37.3428, none),
            ("دومة الجندل", "Dumat Al Jandal", "منطقة الجوف", 29.8117, 39.8664, none),

            // ── منطقة القصيم ──
            ("بريدة", "Buraydah", "منطقة القصيم", 26.3260, 43.9750, none),
            ("عنيزة", "Unayzah", "منطقة القصيم", 26.0843, 43.9935, none),
            ("الرس", "Ar Rass", "منطقة القصيم", 25.8693, 43.4974, none),
        };

        var order = 0;
        foreach (var c in data)
        {
            var city = new City
            {
                CountryId = saudi.Id,
                NameAr = c.ar,
                NameEn = c.en,
                Region = c.region,
                Latitude = c.lat,
                Longitude = c.lng,
                SortOrder = order++,
            };
            var dOrder = 0;
            foreach (var d in c.districts)
                city.Districts.Add(new District { NameAr = d.ar, NameEn = d.en, SortOrder = dOrder++ });
            db.Cities.Add(city);
        }

        await db.SaveChangesAsync();
    }
}
