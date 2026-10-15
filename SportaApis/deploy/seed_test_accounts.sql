-- ═══════════════════════════════════════════════════════════════════════════
--  حسابات تجريبية لسبورتا — تشغيل مباشر على قاعدة البيانات
--
--  الاستخدام:
--      mysql -u root -p SportaDb < seed_test_accounts.sql
--
--  ▸ idempotent: كل إدراج مشروط بعدم وجود رقم الجوال، فإعادة التشغيل لا تكرّر
--    شيئاً ولا تعدّل حساباً قائماً.
--  ▸ لا يعتمد على معرّفات ثابتة: يستخرج معرّفات الدول والمدن بالاسم، فيصحّ على
--    أي قاعدة (تطوير أو إنتاج) مهما اختلف الترقيم.
--  ▸ تجزئة كلمات المرور بصيغة BCrypt ‎$2a$11$‎ — نفس ما يولّده الخادم.
--
--  ┌──────────────┬──────────────┬─────────────┬──────────────────────────────┐
--  │ الدور        │ الجوال       │ كلمة المرور │ ملاحظات                      │
--  ├──────────────┼──────────────┼─────────────┼──────────────────────────────┤
--  │ لاعب         │ 0512000001   │ Test1234    │ محفظة 1000 ر.س               │
--  │ لاعب         │ 0512000002   │ Test1234    │ محفظة 1000 ر.س               │
--  │ مدرب         │ 0512000010   │ Coach1234   │ 150 ر.س/ساعة                 │
--  │ مالك ملعب    │ 0512000020   │ Owner1234   │ محفظة 1000 ر.س               │
--  │ موظف (عام)   │ 0512000030   │ Staff1234   │ كل المدن · صلاحيات واسعة     │
--  │ موظف (مقيّد) │ 0512000031   │ Staff1234   │ الرياض فقط · عرض فقط         │
--  │ مدير         │ 0512000040   │ Admin1234   │ صلاحيات كاملة                │
--  └──────────────┴──────────────┴─────────────┴──────────────────────────────┘
--
--  ⚠ للتجربة فقط. غيّر كلمات المرور أو احذف الحسابات قبل الاستخدام الحقيقي —
--    السكربت في نهايته يتضمن أمر حذف جاهز (معطّل بالتعليق).
-- ═══════════════════════════════════════════════════════════════════════════

SET @country := (SELECT Id FROM `Countries` WHERE Code = 'SA' LIMIT 1);
SET @riyadh  := (SELECT Id FROM `Cities` WHERE NameAr = 'الرياض' LIMIT 1);
SET @now     := UTC_TIMESTAMP();

-- تحقّق قبل البدء: الدولة شرط لنطاق الموظفين، والمدينة لتقييد أحدهم بالرياض.
-- لو ظهر NULL هنا فالمايجريشن لم يُطبَّق بعد — أوقف التنفيذ وطبّقه أولاً.
SELECT @country AS 'معرّف السعودية', @riyadh AS 'معرّف الرياض',
       IF(@country IS NULL, '⚠ طبّق مايجريشن الدول أولاً', 'جاهز') AS 'الحالة';

-- ── ١) لاعبان ───────────────────────────────────────────────────────────────
INSERT INTO `Users`
  (FirstName, LastName, Email, PasswordHash, PhoneNumber, UserType,
   PreferredLanguage, Gender, IsActive, PointsBalance, Country, City, CityId, CreatedAt)
SELECT 'فهد', 'التجريبي', 't0512000001@sporta.test',
       '$2a$11$6LXPvhddaAkiK5goavUf9ezVDTbvoMspF7keYv4DTrFDobC0xvxvi',
       '0512000001', 0, 0, 0, 1, 0, 'السعودية', 'الرياض', @riyadh, @now
FROM DUAL WHERE NOT EXISTS (
  SELECT 1 FROM `Users`
   WHERE PhoneNumber = '0512000001' OR Email = 't0512000001@sporta.test');

INSERT INTO `Users`
  (FirstName, LastName, Email, PasswordHash, PhoneNumber, UserType,
   PreferredLanguage, Gender, IsActive, PointsBalance, Country, City, CityId, CreatedAt)
SELECT 'ريم', 'التجريبية', 't0512000002@sporta.test',
       '$2a$11$6LXPvhddaAkiK5goavUf9ezVDTbvoMspF7keYv4DTrFDobC0xvxvi',
       '0512000002', 0, 0, 1, 1, 0, 'السعودية', 'الرياض', @riyadh, @now
FROM DUAL WHERE NOT EXISTS (
  SELECT 1 FROM `Users`
   WHERE PhoneNumber = '0512000002' OR Email = 't0512000002@sporta.test');

-- ── ٢) مدرب ────────────────────────────────────────────────────────────────
INSERT INTO `Users`
  (FirstName, LastName, Email, PasswordHash, PhoneNumber, UserType,
   PreferredLanguage, Gender, IsActive, PointsBalance, Country, City, CityId, CreatedAt)
SELECT 'سامي', 'المدرب', 't0512000010@sporta.test',
       '$2a$11$9EfIVshDqGAtbgRPawe.r.F2TlUCmzSilA9cH5GHcbt5AQhjMy8lG',
       '0512000010', 1, 0, 0, 1, 0, 'السعودية', 'الرياض', @riyadh, @now
FROM DUAL WHERE NOT EXISTS (
  SELECT 1 FROM `Users`
   WHERE PhoneNumber = '0512000010' OR Email = 't0512000010@sporta.test');

-- ── ٣) مالك ملعب ───────────────────────────────────────────────────────────
INSERT INTO `Users`
  (FirstName, LastName, Email, PasswordHash, PhoneNumber, UserType,
   PreferredLanguage, Gender, IsActive, PointsBalance, Country, City, CityId, CreatedAt)
SELECT 'ماجد', 'المالك', 't0512000020@sporta.test',
       '$2a$11$6kv0/NVktEsBbqLvM0vhMOzPKU7CRR45eYH9n.IlXdhERHk84fLWW',
       '0512000020', 2, 0, 0, 1, 0, 'السعودية', 'الرياض', @riyadh, @now
FROM DUAL WHERE NOT EXISTS (
  SELECT 1 FROM `Users`
   WHERE PhoneNumber = '0512000020' OR Email = 't0512000020@sporta.test');

-- ── ٤) موظفان ──────────────────────────────────────────────────────────────
INSERT INTO `Users`
  (FirstName, LastName, Email, PasswordHash, PhoneNumber, UserType,
   PreferredLanguage, IsActive, PointsBalance, Country, CreatedAt)
SELECT 'نواف', 'المشرف', 't0512000030@sporta.test',
       '$2a$11$CsfWdrb0HS8D9MBQsq/OPuII/cYwJxZMGvyjd9qU5AbV.GP9SyGfC',
       '0512000030', 4, 0, 1, 0, 'السعودية', @now
FROM DUAL WHERE NOT EXISTS (
  SELECT 1 FROM `Users`
   WHERE PhoneNumber = '0512000030' OR Email = 't0512000030@sporta.test');

INSERT INTO `Users`
  (FirstName, LastName, Email, PasswordHash, PhoneNumber, UserType,
   PreferredLanguage, IsActive, PointsBalance, Country, CreatedAt)
SELECT 'لمياء', 'مشرفة الرياض', 't0512000031@sporta.test',
       '$2a$11$CsfWdrb0HS8D9MBQsq/OPuII/cYwJxZMGvyjd9qU5AbV.GP9SyGfC',
       '0512000031', 4, 0, 1, 0, 'السعودية', @now
FROM DUAL WHERE NOT EXISTS (
  SELECT 1 FROM `Users`
   WHERE PhoneNumber = '0512000031' OR Email = 't0512000031@sporta.test');

-- ── ٥) مدير ────────────────────────────────────────────────────────────────
INSERT INTO `Users`
  (FirstName, LastName, Email, PasswordHash, PhoneNumber, UserType,
   PreferredLanguage, IsActive, PointsBalance, Country, CreatedAt)
SELECT 'مدير', 'تجريبي', 't0512000040@sporta.test',
       '$2a$11$KYq9EnwjmAmps/xR5mlYc.wNM4pFnoSbTkV/2uIbdMnF6wFYKG6lS',
       '0512000040', 3, 0, 1, 0, 'السعودية', @now
FROM DUAL WHERE NOT EXISTS (
  SELECT 1 FROM `Users`
   WHERE PhoneNumber = '0512000040' OR Email = 't0512000040@sporta.test');

-- ═══ الأدوار ════════════════════════════════════════════════════════════════
-- Player=0 · Coach=1 · VenueOwner=2 · Admin=3 · Staff=4
INSERT INTO `UserRoles` (UserId, Role, CreatedAt)
SELECT u.Id,
       CASE u.PhoneNumber
         WHEN '0512000010' THEN 1
         WHEN '0512000020' THEN 2
         WHEN '0512000040' THEN 3
         WHEN '0512000030' THEN 4
         WHEN '0512000031' THEN 4
         ELSE 0
       END,
       @now
FROM `Users` u
WHERE u.PhoneNumber IN ('0512000001','0512000002','0512000010','0512000020',
                        '0512000030','0512000031','0512000040')
  AND NOT EXISTS (SELECT 1 FROM `UserRoles` r WHERE r.UserId = u.Id);

-- ═══ المحافظ (رصيد تجريبي) ══════════════════════════════════════════════════
INSERT INTO `Wallets` (UserId, Balance, CreatedAt)
SELECT u.Id, 1000.00, @now
FROM `Users` u
WHERE u.PhoneNumber IN ('0512000001','0512000002','0512000010','0512000020')
  AND NOT EXISTS (SELECT 1 FROM `Wallets` w WHERE w.UserId = u.Id);

-- ═══ ملفات اللاعبين ═════════════════════════════════════════════════════════
-- PreferredHand=يمين(0) · CourtPosition=كلاهما(2) · MatchType=مفتوحة(0)
-- PlayTime=لا فرق(3) · Level=متوسط(4)
INSERT INTO `PlayerProfiles`
  (UserId, PreferredHand, CourtPosition, PreferredMatchType, PreferredPlayTime,
   Level, EloRating, ReliabilityScore, TotalMatches, TotalWins,
   PeerRatingAverage, PeerRatingCount, CreatedAt)
SELECT u.Id, 0, 2, 0, 3, 4, 1200, 100, 0, 0, 0, 0, @now
FROM `Users` u
WHERE u.PhoneNumber IN ('0512000001','0512000002')
  AND NOT EXISTS (SELECT 1 FROM `PlayerProfiles` p WHERE p.UserId = u.Id);

-- ═══ ملف المدرب ═════════════════════════════════════════════════════════════
INSERT INTO `CoachProfiles`
  (UserId, HourlyRate, IsVerifiedOnPlatform, Rating, TotalSessions, TotalRatings, CreatedAt)
SELECT u.Id, 150.00, 1, 0, 0, 0, @now
FROM `Users` u
WHERE u.PhoneNumber = '0512000010'
  AND NOT EXISTS (SELECT 1 FROM `CoachProfiles` c WHERE c.UserId = u.Id);

-- ═══ نطاق الموظفين ══════════════════════════════════════════════════════════
-- CityId = NULL تعني «كل مدن الدولة»
INSERT INTO `StaffProfiles` (UserId, CountryId, CityId, JobTitle, CreatedAt)
SELECT u.Id, @country, NULL, 'مشرف عام', @now
FROM `Users` u
WHERE u.PhoneNumber = '0512000030'
  AND NOT EXISTS (SELECT 1 FROM `StaffProfiles` s WHERE s.UserId = u.Id);

INSERT INTO `StaffProfiles` (UserId, CountryId, CityId, JobTitle, CreatedAt)
SELECT u.Id, @country, @riyadh, 'مشرفة الرياض', @now
FROM `Users` u
WHERE u.PhoneNumber = '0512000031'
  AND NOT EXISTS (SELECT 1 FROM `StaffProfiles` s WHERE s.UserId = u.Id);

-- ═══ صلاحيات الموظفين ═══════════════════════════════════════════════════════
-- الموظف العام: صلاحيات واسعة عدا إدارة الموظفين والإعدادات
INSERT INTO `StaffPermissions` (StaffProfileId, Permission, CreatedAt)
SELECT s.Id, p.perm, @now
FROM `StaffProfiles` s
JOIN `Users` u ON u.Id = s.UserId AND u.PhoneNumber = '0512000030'
JOIN (
  SELECT 'dashboard.view' AS perm UNION ALL SELECT 'venues.view'
  UNION ALL SELECT 'venues.approve'      UNION ALL SELECT 'courts.view'
  UNION ALL SELECT 'courts.suspend'      UNION ALL SELECT 'courts.commission'
  UNION ALL SELECT 'users.view'          UNION ALL SELECT 'users.lock'
  UNION ALL SELECT 'coaches.view'        UNION ALL SELECT 'matches.view'
  UNION ALL SELECT 'bookings.view'       UNION ALL SELECT 'finance.view'
  UNION ALL SELECT 'finance.withdrawals.manage'
  UNION ALL SELECT 'discounts.view'      UNION ALL SELECT 'discounts.manage'
  UNION ALL SELECT 'venueSubscriptions.view'
  UNION ALL SELECT 'ads.view'            UNION ALL SELECT 'ads.manage'
  UNION ALL SELECT 'notifications.view'
) p
WHERE NOT EXISTS (
  SELECT 1 FROM `StaffPermissions` sp
  WHERE sp.StaffProfileId = s.Id AND sp.Permission = p.perm);

-- الموظفة المقيّدة بالرياض: عرض فقط
INSERT INTO `StaffPermissions` (StaffProfileId, Permission, CreatedAt)
SELECT s.Id, p.perm, @now
FROM `StaffProfiles` s
JOIN `Users` u ON u.Id = s.UserId AND u.PhoneNumber = '0512000031'
JOIN (
  SELECT 'dashboard.view' AS perm UNION ALL SELECT 'venues.view'
  UNION ALL SELECT 'courts.view'  UNION ALL SELECT 'users.view'
  UNION ALL SELECT 'bookings.view'
) p
WHERE NOT EXISTS (
  SELECT 1 FROM `StaffPermissions` sp
  WHERE sp.StaffProfileId = s.Id AND sp.Permission = p.perm);

-- ═══ تحقق ═══════════════════════════════════════════════════════════════════
SELECT u.PhoneNumber AS 'الجوال',
       CONCAT(u.FirstName, ' ', u.LastName) AS 'الاسم',
       CASE u.UserType WHEN 0 THEN 'لاعب' WHEN 1 THEN 'مدرب'
                       WHEN 2 THEN 'مالك ملعب' WHEN 3 THEN 'مدير'
                       WHEN 4 THEN 'موظف' END AS 'الدور',
       COALESCE(c.NameAr, IF(u.UserType = 4, 'كل المدن', '—')) AS 'النطاق',
       (SELECT COUNT(*) FROM `StaffPermissions` sp
         JOIN `StaffProfiles` s2 ON s2.Id = sp.StaffProfileId
        WHERE s2.UserId = u.Id) AS 'الصلاحيات',
       COALESCE(w.Balance, 0) AS 'الرصيد'
FROM `Users` u
LEFT JOIN `StaffProfiles` s ON s.UserId = u.Id
LEFT JOIN `Cities` c ON c.Id = s.CityId
LEFT JOIN `Wallets` w ON w.UserId = u.Id
WHERE u.PhoneNumber LIKE '05120000%'
ORDER BY u.UserType, u.PhoneNumber;

-- ═══════════════════════════════════════════════════════════════════════════
--  إزالة الحسابات التجريبية
-- ═══════════════════════════════════════════════════════════════════════════
--
--  ▸ الخيار الأول (الموصى به): **التعطيل** بدل الحذف.
--    يمنع الدخول فوراً ويحفظ سجلات الحجوزات والمباريات المرتبطة سليمة:
--
--        UPDATE `Users` SET IsActive = 0 WHERE PhoneNumber LIKE '05120000%';
--
--  ▸ الخيار الثاني: **الحذف الكامل**. ١٥ مفتاحاً أجنبياً على `Users` بقاعدة
--    RESTRICT لا CASCADE (الصداقات والمتابعات والحجوزات والمباريات…)، فحذف
--    المستخدم مباشرةً يفشل بخطأ 1451. لذا نحذف التابع أولاً بالترتيب أدناه.
--    أزِل التعليق عن الكتلة كاملةً وشغّلها مرة واحدة.
--
-- START TRANSACTION;
--
-- SET @del := '05120000%';
--
-- -- (١) تقييمات ولاعبو المباريات قبل المباريات نفسها
-- DELETE FROM `MatchRatings`
--  WHERE RaterId     IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del)
--     OR RatedUserId IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del);
--
-- DELETE FROM `MatchPlayers`
--  WHERE UserId IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del);
--
-- -- (٢) جولات أمريكانو تشير للاعبين مباشرةً بأربعة أعمدة
-- DELETE FROM `AmericanoRounds`
--  WHERE Team1Player1Id IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del)
--     OR Team1Player2Id IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del)
--     OR Team2Player1Id IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del)
--     OR Team2Player2Id IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del);
--
-- -- (٣) الحجوزات والجلسات: للمستخدم نفسه، ولملاعبه إن كان مالكاً
-- DELETE FROM `Bookings`
--  WHERE UserId IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del)
--     OR CourtId IN (SELECT c.Id FROM `Courts` c JOIN `Venues` v ON v.Id = c.VenueId
--                     WHERE v.OwnerId IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del));
--
-- DELETE FROM `CoachSessions`
--  WHERE PlayerId IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del)
--     OR CoachProfileId IN (SELECT Id FROM `CoachProfiles`
--                            WHERE UserId IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del))
--     OR CourtId IN (SELECT c.Id FROM `Courts` c JOIN `Venues` v ON v.Id = c.VenueId
--                     WHERE v.OwnerId IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del));
--
-- -- (٤) المباريات التي أنشأها المستخدم (لاعبوها حُذفوا في الخطوة ١)
-- DELETE FROM `MatchPlayers`
--  WHERE MatchId IN (SELECT Id FROM `Matches`
--                     WHERE CreatorId IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del));
-- DELETE FROM `Matches`
--  WHERE CreatorId IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del);
--
-- -- (٥) العلاقات الاجتماعية
-- DELETE FROM `Friendships`
--  WHERE SenderId   IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del)
--     OR ReceiverId IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del);
-- DELETE FROM `Follows`
--  WHERE FollowerId  IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del)
--     OR FollowingId IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del);
--
-- -- (٦) لاعبو المباريات المرتبطون بملف اللاعب (يمنع حذف PlayerProfiles)
-- DELETE FROM `MatchPlayers`
--  WHERE PlayerProfileId IN (SELECT Id FROM `PlayerProfiles`
--                             WHERE UserId IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del));
--
-- -- (٧) الملاعب ثم الأندية المملوكة
-- DELETE FROM `Courts`
--  WHERE VenueId IN (SELECT Id FROM `Venues`
--                     WHERE OwnerId IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del));
-- DELETE FROM `Venues`
--  WHERE OwnerId IN (SELECT Id FROM `Users` WHERE PhoneNumber LIKE @del);
--
-- -- (٨) المستخدمون — الباقي (الأدوار، المحافظ، الملفات، نطاق الموظف،
-- --     الصلاحيات، الإشعارات، التوكنات) يُحذف تلقائياً بـ CASCADE.
-- DELETE FROM `Users` WHERE PhoneNumber LIKE @del;
--
-- COMMIT;   -- راجع الأعداد قبل التثبيت؛ استخدم ROLLBACK للتراجع
