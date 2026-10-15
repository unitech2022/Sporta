using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

public class CourtService : ICourtService
{
    private readonly AppDbContext _db;
    private readonly ISettingsService _settings;
    private readonly IAdminContext _admin;

    public CourtService(AppDbContext db, ISettingsService settings, IAdminContext admin)
    {
        _db = db;
        _settings = settings;
        _admin = admin;
    }

    public async Task<PagedResult<CourtDto>> GetCourtsAsync(
        int currentUserId, string? city, string? type, string? gender,
        int page = 1, int pageSize = 20, CourtSlotWindow? window = null)
    {
        // Nearby filtering/sorting is per-row in memory, so the full filtered
        // list is built first and paged afterwards.
        var query = _db.Courts
            .NotDeleted()
            .Include(c => c.Venue).ThenInclude(v => v.CityRef)
            .Include(c => c.Venue).ThenInclude(v => v.DistrictRef)
            .Include(c => c.PriceTiers)
            .Include(c => c.OpeningHours)
            .Include(c => c.PriceRules)
            .AsQueryable();

        // Hide admin-suspended courts, courts of inactive venues, venues pending
        // admin approval, and owners without an active subscription — نفس شروط
        // الحجز المباشر (VenueBookability) حتى لا يختلف البحث عن الحجز.
        query = await query.WhereBookableAsync(_db);

        // بلا فلتر صريح، مدينةُ اللاعب المسجّلة هي النطاق: يرى كل ملاعب مدينته
        // مرتبةً بالأقرب، بدل قائمة يقصّها نصفُ القطر فتبدو له فارغة. لاعب بلا
        // مدينة محفوظة يبقى على سلوك الاستكشاف القديم (قرب فقط).
        //
        // **الحي لا يدخل التصفية إطلاقاً**: لاعب الرياض يرى ملاعب الرياض كلها.
        int? cityId = null;
        if (string.IsNullOrWhiteSpace(city))
        {
            var me = await _db.Users
                .Where(u => u.Id == currentUserId)
                .Select(u => new { u.City, u.CityId })
                .FirstOrDefaultAsync();
            city = me?.City;
            cityId = me?.CityId;
        }

        var name = city?.Trim();
        var scopedToCity = cityId != null || !string.IsNullOrWhiteSpace(name);

        if (scopedToCity)
        {
            // المطابقة بمعرّف المدينة أولاً — لا يخطئ الإملاء ولا يفرّق بين
            // «الرياض» و«الرياض » و«Riyadh». والنص يبقى للسجلات القديمة التي
            // لم تُربط بجدول المدن بعد، فلا يختفي ملعبٌ لمجرد اختلاف الكتابة.
            query = query.Where(c =>
                (cityId != null && c.Venue.CityId == cityId) ||
                (name != null &&
                 (c.Venue.City == name ||
                  (c.Venue.CityRef != null &&
                   (c.Venue.CityRef.NameAr == name || c.Venue.CityRef.NameEn == name)))));
        }

        if (!string.IsNullOrWhiteSpace(type) &&
            Enum.TryParse<CourtType>(type, ignoreCase: true, out var courtType))
            query = query.Where(c => c.Type == courtType);

        if (!string.IsNullOrWhiteSpace(gender) &&
            TryParseGender(gender, out var policy))
            query = query.Where(c => c.Venue.GenderPolicy == policy);

        var courts = await query
            .OrderBy(c => c.Venue.City)
            .ThenBy(c => c.Name)
            .ToListAsync();

        var dtos = courts.Select(ToDto).ToList();
        // مع فلتر مدينة، القرب ترتيبٌ لا حجب: اللاعب طلب ملاعب مدينته كلها،
        // وإسقاط البعيد منها بنصف القطر كان يُفرغ القائمة في المدن الواسعة.
        dtos = await ApplyNearbyAsync(
            currentUserId, dtos, dropBeyondRadius: !scopedToCity);

        if (window != null)
        {
            await ApplySlotWindowAsync(currentUserId, courts, dtos, window);
            // من له مواعيد فارغة أولاً، مع بقاء ترتيب القرب داخل كل فئة
            // (OrderBy مستقر)؛ و«المتاح فقط» يُسقط الباقي.
            dtos = window.OnlyAvailable
                ? [.. dtos.Where(d => d.FreeSlots!.Count > 0)]
                : [.. dtos.OrderBy(d => d.FreeSlots!.Count > 0 ? 0 : 1)];
        }

        await MarkFavoritesAsync(currentUserId, dtos);
        return PagedResult<CourtDto>.Create(dtos, page, pageSize);
    }

    /// <summary>يضبط <see cref="CourtDto.IsFavorite"/> لدفعة ملاعب باستعلام
    /// واحد بدل استعلام لكل بطاقة.</summary>
    private async Task MarkFavoritesAsync(int currentUserId, List<CourtDto> dtos)
    {
        if (dtos.Count == 0) return;

        var ids = dtos.Select(d => d.Id).ToList();
        var favorites = await _db.CourtFavorites
            .Where(f => f.UserId == currentUserId && ids.Contains(f.CourtId))
            .Select(f => f.CourtId)
            .ToListAsync();

        if (favorites.Count == 0) return;

        var set = favorites.ToHashSet();
        foreach (var d in dtos) d.IsFavorite = set.Contains(d.Id);
    }

    /// <summary>When the user has a saved location, annotate each court with its
    /// distance and sort nearest first. Courts without coordinates are kept
    /// (listed last).</summary>
    /// <param name="dropBeyondRadius">
    /// When true, courts beyond the configured radius are removed — the
    /// unfiltered "استكشاف" behaviour. City-filtered requests pass false: the
    /// player asked for that city's courts, so distance only orders them.
    /// </param>
    private async Task<List<CourtDto>> ApplyNearbyAsync(
        int currentUserId, List<CourtDto> dtos, bool dropBeyondRadius)
    {
        var user = await _db.Users
            .Where(u => u.Id == currentUserId)
            .Select(u => new { u.Latitude, u.Longitude })
            .FirstOrDefaultAsync();
        if (user?.Latitude == null || user?.Longitude == null) return dtos;

        var maxKm = await _settings.GetNearbyDistanceKmAsync();
        foreach (var d in dtos)
        {
            if (d.Latitude != null && d.Longitude != null)
                d.DistanceKm = Math.Round(
                    Helpers.GeoHelper.DistanceKm(
                        user.Latitude.Value, user.Longitude.Value,
                        d.Latitude.Value, d.Longitude.Value),
                    1);
        }

        if (dropBeyondRadius)
            dtos = dtos.Where(d => d.DistanceKm == null || d.DistanceKm <= maxKm).ToList();

        return dtos.OrderBy(d => d.DistanceKm ?? double.MaxValue).ToList();
    }

    public async Task<List<CourtDto>> GetAllForAdminAsync()
    {
        var courts = await _db.Courts
            .NotDeleted()
            .Include(c => c.Venue).ThenInclude(v => v.CityRef)
            .Include(c => c.Venue).ThenInclude(v => v.DistrictRef)
            .Include(c => c.PriceTiers)
            .Include(c => c.OpeningHours)
            .Include(c => c.PriceRules)
            .InScope(await _admin.GetScopeAsync())
            .OrderBy(c => c.Venue.City)
            .ThenBy(c => c.Venue.Name)
            .ThenBy(c => c.Name)
            .ToListAsync();

        return courts.Select(ToDto).ToList();
    }

    public async Task<CourtDto> GetCourtByIdAsync(int id, int currentUserId)
    {
        var dto = await GetCourtByIdAsync(id, requireApproved: true);

        // التفاصيل تبقى مفتوحة (من المفضّلة مثلاً)، لكن نادٍ معطّل أو بلا اشتراك
        // ساري يظهر ملعبه غير متاح للحجز — والحجز نفسه يرفضه الخادم أيضاً.
        if (!await VenueBookability.IsBookableAsync(_db, id))
            dto.IsAvailable = false;

        dto.IsFavorite = await _db.CourtFavorites
            .AnyAsync(f => f.UserId == currentUserId && f.CourtId == id);

        // نافذة الحجز المسبق لهذا المستخدم (بأولوية عضويته) — يقصر بها التطبيق
        // قائمة الأيام القابلة للحجز.
        var venue = await _db.Venues.AsNoTracking().FirstOrDefaultAsync(v => v.Id == dto.VenueId);
        if (venue?.BookingWindowDays is int w)
        {
            var now = DateTime.UtcNow;
            var priority = currentUserId == 0 ? 0 : await _db.Memberships
                .Where(m => m.UserId == currentUserId && m.VenueId == venue.Id
                            && !m.IsEnded && m.PeriodEnd > now)
                .Select(m => (int?)m.PriorityDays).MaxAsync() ?? 0;
            dto.BookingWindowDays = w + priority;
            dto.IsMember = priority > 0 || await _db.Memberships.AnyAsync(m =>
                m.UserId == currentUserId && m.VenueId == venue.Id && !m.IsEnded && m.PeriodEnd > now);
        }
        else if (currentUserId != 0)
        {
            var now = DateTime.UtcNow;
            dto.IsMember = await _db.Memberships.AnyAsync(m =>
                m.UserId == currentUserId && m.VenueId == dto.VenueId && !m.IsEnded && m.PeriodEnd > now);
        }
        return dto;
    }

    /// <summary>
    /// المفضّلة تتجاهل شرط اعتماد النادي وحالة التعليق عمداً: الملعب الذي حفظه
    /// اللاعب يبقى ظاهراً في قائمته حتى لو عُلّق مؤقتاً، ويكشف ذلك
    /// <see cref="CourtDto.IsSuspended"/> للواجهة.
    /// </summary>
    public async Task<PagedResult<CourtDto>> GetFavoritesAsync(
        int currentUserId, int page = 1, int pageSize = 20)
    {
        (page, pageSize) = Paging.Clamp(page, pageSize);

        // ترتيب الإضافة يأتي من صفوف المفضّلة (الأحدث أولاً)؛ تُقصّ الصفحة على
        // المعرّفات ثم تُجلب ملاعبها فقط — لا يُحمَّل ما وراء الصفحة من القاعدة.
        var favoriteIds = _db.CourtFavorites
            .Where(f => f.UserId == currentUserId)
            .OrderByDescending(f => f.Id)
            .Select(f => f.CourtId);

        var total = await favoriteIds.CountAsync();
        var orderedIds = await favoriteIds
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var result = new PagedResult<CourtDto>
        {
            Page = page,
            PageSize = pageSize,
            Total = total,
        };
        if (orderedIds.Count == 0) return result;

        var courts = await _db.Courts
            .NotDeleted()
            .Include(c => c.Venue).ThenInclude(v => v.CityRef)
            .Include(c => c.Venue).ThenInclude(v => v.DistrictRef)
            .Include(c => c.PriceTiers)
            .Include(c => c.OpeningHours)
            .Include(c => c.PriceRules)
            .Where(c => orderedIds.Contains(c.Id))
            .ToListAsync();

        var byId = courts.ToDictionary(c => c.Id);
        result.Items = orderedIds
            .Where(byId.ContainsKey)
            .Select(id => ToDto(byId[id]))
            .ToList();

        foreach (var d in result.Items) d.IsFavorite = true;
        return result;
    }

    public async Task<bool> ToggleFavoriteAsync(
        int currentUserId, int courtId, bool favorite)
    {
        if (!await _db.Courts.NotDeleted().AnyAsync(c => c.Id == courtId))
            throw new AuthException(
                "Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        var row = await _db.CourtFavorites.FirstOrDefaultAsync(
            f => f.UserId == currentUserId && f.CourtId == courtId);

        if (favorite && row == null)
            _db.CourtFavorites.Add(new CourtFavorite
            {
                UserId = currentUserId,
                CourtId = courtId,
                CreatedAt = AppClock.Now,
            });
        else if (!favorite && row != null)
            _db.CourtFavorites.Remove(row);
        else
            return favorite;   // لا تغيير — الطلب مكرر.

        await _db.SaveChangesAsync();
        return favorite;
    }

    /// <summary>
    /// <paramref name="requireApproved"/> = false يفتح الملعب حتى قبل اعتماد ناديه —
    /// للوحة التحكم فقط، لأنها تسرد كل الملاعب فيجب أن تفتحها كلها. مسار اللاعبين
    /// يبقى محجوباً عن غير المعتمد.
    /// </summary>
    public async Task<CourtDto> GetCourtByIdAsync(int id, bool requireApproved)
    {
        var query = _db.Courts
            .NotDeleted()
            .Include(c => c.Venue).ThenInclude(v => v.CityRef)
            .Include(c => c.Venue).ThenInclude(v => v.DistrictRef)
            .Include(c => c.PriceTiers)
            .Include(c => c.OpeningHours)
            .Include(c => c.PriceRules)
            .AsQueryable();

        // نطاق الموظف الجغرافي يسري على المسار الإداري (بلا أثر على الأدمن واللاعبين).
        if (!requireApproved) query = query.InScope(await _admin.GetScopeAsync());

        var court = await query
            .FirstOrDefaultAsync(c => c.Id == id && (!requireApproved || c.Venue.IsApproved))
            ?? throw new AuthException("Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        return ToDto(court);
    }

    /// <summary>
    /// Per-slot availability for a day, stepped by <paramref name="durationMinutes"/>
    /// so the player only sees start times that actually fit a session of that
    /// length (e.g. a 120-minute session offers 06:00, 08:00, 10:00… instead of
    /// every hour). Each slot's price is the total for that full session.
    /// </summary>
    public Task<CourtAvailabilityDto> GetAvailabilityAsync(
        int courtId, DateTime date, int durationMinutes = 60) =>
        GetAvailabilityAsync(courtId, date, durationMinutes, requireApproved: true);

    /// <inheritdoc cref="ICourtService.GetAvailabilityAsync(int, DateTime, int, bool, DateTime?)"/>
    public async Task<CourtAvailabilityDto> GetAvailabilityAsync(
        int courtId, DateTime date, int durationMinutes, bool requireApproved,
        DateTime? endDate = null)
    {
        var query = _db.Courts
            .NotDeleted()
            .Include(c => c.PriceTiers)
            .Include(c => c.OpeningHours)
            .Include(c => c.PriceRules)
            .Include(c => c.Venue).ThenInclude(v => v.CityRef)
            .Include(c => c.Venue).ThenInclude(v => v.DistrictRef)
            .AsQueryable();

        if (!requireApproved) query = query.InScope(await _admin.GetScopeAsync());

        var court = await query
            .FirstOrDefaultAsync(c => c.Id == courtId && (!requireApproved || c.Venue.IsApproved))
            ?? throw new AuthException("Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        if (durationMinutes < 30) durationMinutes = 60;

        var day = date.Date;

        // مسار اللاعبين: نادٍ معطّل أو موقوف أو بلا اشتراك ساري لا يعرض مواعيد
        // (يُعامَل كيوم مغلق) — الحجز المباشر يرفضه أيضاً.
        if (requireApproved && !await VenueBookability.IsBookableAsync(_db, court.Id))
            return new CourtAvailabilityDto
            {
                Date = day.ToString("yyyy-MM-dd"),
                IsClosed = true,
                Slots = [],
            };

        // مدى متعدد الأيام (بطولة تشغل نفس الموعد من كل يوم): الموعد متاح فقط
        // إذا كان فارغاً في كل أيام المدى، فنفحص كل يوم ونطرح ما يسقط منه.
        var lastDay = endDate?.Date ?? day;
        if (lastDay < day) lastDay = day;
        if ((lastDay - day).TotalDays > CourtSchedule.MaxMultiDayRangeDays)
            lastDay = day.AddDays(CourtSchedule.MaxMultiDayRangeDays);

        var (isClosed, openHour, closeHour, slots) =
            await DayAvailabilityAsync(court, day, durationMinutes, dropPastSlots: true);

        for (var other = day.AddDays(1); other <= lastDay && !isClosed; other = other.AddDays(1))
        {
            var (otherClosed, _, _, otherSlots) =
                await DayAvailabilityAsync(court, other, durationMinutes, dropPastSlots: false);

            // يوم مغلق داخل المدى يُسقط المدى كله — لا موعد يصلح لكل الأيام.
            if (otherClosed)
            {
                isClosed = true;
                slots.Clear();
                break;
            }

            // دوام الأيام قد يختلف، فموعد لا وجود له في يوم لاحق يُعدّ مشغولاً.
            var freeTimes = otherSlots
                .Where(sl => !sl.IsBooked)
                .Select(sl => sl.Time)
                .ToHashSet();
            foreach (var slot in slots)
                if (!freeTimes.Contains(slot.Time)) slot.IsBooked = true;
        }

        return new CourtAvailabilityDto
        {
            Date = day.ToString("yyyy-MM-dd"),
            IsClosed = isClosed,
            OpenHour = isClosed ? 0 : openHour,
            CloseHour = isClosed ? 0 : closeHour,
            Slots = isClosed ? [] : slots,
        };
    }

    /// <summary>
    /// مواعيد يوم واحد للملعب: الدوام وحالة كل موعد فيه. <paramref name="dropPastSlots"/>
    /// يُسقط مواعيد اليوم التي مضت (يوم البداية فقط؛ الأيام التالية كلها قادمة).
    /// </summary>
    private async Task<(bool IsClosed, int OpenHour, int CloseHour, List<TimeSlotDto> Slots)>
        DayAvailabilityAsync(Court court, DateTime day, int durationMinutes, bool dropPastSlots)
    {
        var nextDay = day.AddDays(1);

        // كل ما يشغل الملعب في هذا اليوم: الحجوزات العادية والمباريات
        // (الأمريكانو والبطولات منها) وجلسات التدريب — لا الحجوزات وحدها.
        var occupied = await CourtOccupancy.ForCourtAsync(_db, court.Id, day, nextDay);

        // Owner-blocked slots are unavailable to players (treated like booked).
        var blockedHours = await _db.CourtBlockedSlots
            .Where(s => s.CourtId == court.Id && s.Date == day)
            .Select(s => s.Hour)
            .ToListAsync();

        return BuildDaySlots(court, day, durationMinutes, occupied, blockedHours, dropPastSlots);
    }

    /// <summary>
    /// حساب مواعيد اليوم من انشغال سبق جلبه — مشترك بين صفحة الحجز وبحث
    /// الملاعب بالوقت حتى لا يعرض البحث موعداً تراه صفحة الحجز محجوزاً.
    /// </summary>
    private static (bool IsClosed, int OpenHour, int CloseHour, List<TimeSlotDto> Slots)
        BuildDaySlots(
            Court court, DateTime day, int durationMinutes,
            IReadOnlyCollection<(DateTime Start, DateTime End)> occupied,
            IReadOnlyCollection<int> blockedHours, bool dropPastSlots)
    {
        // دوام هذا اليوم بالذات — اليوم المغلق لا يُنتج أي مواعيد.
        var (openHour, closeHour, isClosed) = CourtSchedule.HoursOn(court, day);

        var slots = new List<TimeSlotDto>();
        var openMinute = openHour * 60;
        // اليوم المغلق: نافذة صفرية فلا تُنتج الحلقة أي موعد.
        var closeMinute = isClosed ? 0 : closeHour * 60;

        // مواعيد اليوم التي مضت لا تُعرض: لا يُحجز وقت بدأ. المقارنة بساعة
        // السعودية لأن مواعيد الملاعب مخزَّنة بتوقيتها المحلي بلا منطقة.
        var now = AppClock.Now;

        for (var startMinute = openMinute;
             startMinute + durationMinutes <= closeMinute;
             startMinute += durationMinutes)
        {
            var hour = startMinute / 60;
            var minute = startMinute % 60;
            var slotStart = day.AddMinutes(startMinute);
            var slotEnd = slotStart.AddMinutes(durationMinutes);

            if (dropPastSlots && slotStart <= now) continue;

            // Every hour this session would touch must be free of bookings/blocks.
            var coveredHours = CourtSchedule.CoveredHours(slotStart, durationMinutes);

            var isBooked = CourtOccupancy.Overlaps(occupied, slotStart, slotEnd)
                           || coveredHours.Any(blockedHours.Contains);

            slots.Add(new TimeSlotDto
            {
                Time = $"{hour:D2}:{minute:D2}",
                IsBooked = isBooked,
                IsPeak = CourtSchedule.IsPeakSlot(court, slotStart),
                Price = CourtSchedule.BookingPrice(court, slotStart, durationMinutes),
            });
        }

        return (isClosed, openHour, closeHour, slots);
    }

    /// <summary>
    /// بحث الملاعب بالوقت: لكل ملعب مواعيده الفارغة التي تبدأ داخل النافذة
    /// وأقل سعر فيها. الانشغال يُجلب لكل الملاعب باستعلامات ثابتة العدد، لأن
    /// القائمة تشمل مدينة كاملة. الملعب الذي لا يقبل المدة المطلوبة أو يقع
    /// اليوم خارج نافذة حجزه المسبق يظهر بلا مواعيد.
    /// </summary>
    private async Task ApplySlotWindowAsync(
        int currentUserId, List<Court> courts, List<CourtDto> dtos, CourtSlotWindow window)
    {
        if (dtos.Count == 0) return;

        var day = window.Date.Date;
        var ids = dtos.Select(d => d.Id).ToList();
        var byId = courts.ToDictionary(c => c.Id);

        var occupancy = await CourtOccupancy.ForCourtsAsync(_db, ids, day, day.AddDays(1));
        var blocked = (await _db.CourtBlockedSlots
                .Where(s => ids.Contains(s.CourtId) && s.Date == day)
                .Select(s => new { s.CourtId, s.Hour })
                .ToListAsync())
            .ToLookup(s => s.CourtId, s => s.Hour);

        // نافذة الحجز المسبق لكل نادٍ مع أيام أولوية عضوية اللاعب فيه — نفس
        // ما تقصر به صفحة الحجز أيامها.
        var daysAhead = (day - AppClock.Now.Date).Days;
        var venueIds = dtos.Select(d => d.VenueId).Distinct().ToList();
        var windows = await _db.Venues.AsNoTracking()
            .Where(v => venueIds.Contains(v.Id) && v.BookingWindowDays != null)
            .ToDictionaryAsync(v => v.Id, v => v.BookingWindowDays!.Value);
        var priority = new Dictionary<int, int>();
        if (currentUserId != 0 && windows.Count > 0)
        {
            var utcNow = DateTime.UtcNow;
            priority = (await _db.Memberships
                    .Where(m => m.UserId == currentUserId && venueIds.Contains(m.VenueId)
                                && !m.IsEnded && m.PeriodEnd > utcNow)
                    .Select(m => new { m.VenueId, m.PriorityDays })
                    .ToListAsync())
                .GroupBy(m => m.VenueId)
                .ToDictionary(g => g.Key, g => g.Max(m => m.PriorityDays));
        }

        var fromMinute = window.FromHour * 60;
        var toMinute = window.ToHour * 60;

        foreach (var dto in dtos)
        {
            dto.FreeSlots = [];
            dto.FromPrice = null;

            if (windows.TryGetValue(dto.VenueId, out var w) &&
                daysAhead > w + priority.GetValueOrDefault(dto.VenueId))
                continue;
            if (!dto.AvailableDurations.Contains(window.DurationMinutes)) continue;

            var court = byId[dto.Id];
            var (_, _, _, slots) = BuildDaySlots(
                court, day, window.DurationMinutes, occupancy[dto.Id],
                [.. blocked[dto.Id]], dropPastSlots: true);

            var inWindow = slots
                .Where(sl =>
                {
                    var parts = sl.Time.Split(':');
                    var minute = int.Parse(parts[0]) * 60 + int.Parse(parts[1]);
                    return minute >= fromMinute && minute < toMinute;
                })
                .ToList();
            var free = inWindow.Where(sl => !sl.IsBooked).ToList();

            dto.FreeSlots = free.Select(sl => sl.Time).ToList();
            // «من X»: أرخص موعد فارغ، وإن امتلأت النافذة فأرخص موعد فيها.
            var priced = free.Count > 0 ? free : inWindow;
            if (priced.Count > 0) dto.FromPrice = priced.Min(sl => sl.Price);
        }
    }

    // ── mapping ────────────────────────────────────────────────────────────────

    private static CourtDto ToDto(Court c)
    {
        var bookingTiers = TierDtos(c, CourtPriceKind.Booking);
        return new()
        {
            Id = c.Id,
            Name = c.Name,
            NameEn = c.NameEn,
            VenueId = c.VenueId,
            VenueName = c.Venue.Name,
            VenueNameEn = c.Venue.NameEn,
            Country = c.Venue.Country,
            City = c.Venue.City,
            CityEn = c.Venue.CityRef?.NameEn,
            District = c.Venue.District ?? string.Empty,
            DistrictEn = c.Venue.DistrictRef?.NameEn,
            Neighborhood = c.Venue.Address,
            Type = c.Type == CourtType.Indoor ? "indoor" : "outdoor",
            CourtCount = c.CourtCount < 1 ? 1 : c.CourtCount,
            Gender = GenderLabel(c.Venue.GenderPolicy),
            // كل الأسعار المعروضة للاعب تشمل نسبة سبورتا المضافة فوق سعر
            // المالك — اللاعب يرى ما سيدفعه فعلاً، والمالك يستلم سعره كاملاً.
            BasePrice = CourtSchedule.WithCommission(c, CourtSchedule.BasePrice(c)),
            SportaCommissionPercent = c.SportaCommissionPercent,
            TotalPrice = CourtSchedule.WithCommission(c, CourtSchedule.BasePrice(c)),
            // سعر الذروة الحقيقي: أعلى زيادة في قواعد المالك حين توجد قواعد،
            // وإلا القاعدة القديمة. كان يعرض دائماً ×1.5 فيخالف المخصوم.
            PeakHourPrice = CourtSchedule.WithCommission(c, CourtSchedule.EffectivePeakPrice(c)),
            LowestPrice = CourtSchedule.WithCommission(c, CourtSchedule.EffectiveLowestPrice(c)),
            BookingPrices = bookingTiers,
            IsAvailable = c.IsAvailable,
            IsSuspended = c.IsSuspended,
            IsVenueApproved = c.Venue.IsApproved,
            // صورة النادي بديلاً حين لا يرفع المالك صورة للملعب نفسه — البطاقة
            // بلا صورة تبدو عطلاً لا اختياراً.
            ImageUrl = string.IsNullOrWhiteSpace(c.ImageUrl) ? c.Venue.ImageUrl : c.ImageUrl,
            Rating = c.RatingAverage,
            Reviews = c.RatingCount,
            Latitude = c.Venue.Latitude,
            Longitude = c.Venue.Longitude,
            // Bookable durations come from the owner's tiers when defined.
            AvailableDurations = bookingTiers.Count > 0
                ? bookingTiers.Select(t => t.DurationMinutes).ToList()
                : [60, 90, 120],
            AvailableTimes = CourtSchedule.OpeningSlots(c),
            OpeningHours = CourtScheduleMapper.OpeningHourDtos(c),
            PriceRules = CourtScheduleMapper.PriceRuleDtos(c),
        };
    }

    private static List<CourtPriceTierDto> TierDtos(Court c, CourtPriceKind kind) =>
        c.PriceTiers
            .Where(t => t.Kind == kind)
            .OrderBy(t => t.DurationMinutes)
            .Select(t =>
            {
                // نطاق السعر بعد قواعد المالك — الحجز صباحاً أرخص من الذروة.
                var (min, max) = kind == CourtPriceKind.Booking
                    ? CourtSchedule.BookingPriceRange(c, t.DurationMinutes)
                    : (t.Price, t.Price);
                // المعروض للاعب يشمل نسبة سبورتا المضافة فوق سعر المالك.
                return new CourtPriceTierDto
                {
                    DurationMinutes = t.DurationMinutes,
                    BasePrice = CourtSchedule.WithCommission(c, t.Price),
                    Price = CourtSchedule.WithCommission(c, t.Price),
                    MinPrice = CourtSchedule.WithCommission(c, min),
                    MaxPrice = CourtSchedule.WithCommission(c, max),
                };
            })
            .ToList();

    private static string GenderLabel(VenueGenderPolicy policy) => policy switch
    {
        VenueGenderPolicy.WomenOnly => "women",
        VenueGenderPolicy.FamilyOnly => "family",
        _ => "men",
    };

    private static bool TryParseGender(string value, out VenueGenderPolicy policy)
    {
        switch (value.ToLowerInvariant())
        {
            case "women":
                policy = VenueGenderPolicy.WomenOnly;
                return true;
            case "family":
                policy = VenueGenderPolicy.FamilyOnly;
                return true;
            case "men":
            case "mixed": // legacy wire value for what is now "men"
                policy = VenueGenderPolicy.MenOnly;
                return true;
            default: // includes "all" → no gender filter
                policy = VenueGenderPolicy.MenOnly;
                return false;
        }
    }
}
