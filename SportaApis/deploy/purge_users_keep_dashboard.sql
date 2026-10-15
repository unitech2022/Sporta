-- ═══════════════════════════════════════════════════════════════════════════
--  حذف بيانات المستخدمين — مع إبقاء حسابات لوحة التحكم فقط
--
--  ⚠⚠ عملية هدّامة لا رجعة فيها على قاعدة الإنتاج ⚠⚠
--
--  يُبقي: كل من له دور «مدير» أو «موظف» فقط.
--  يحذف: كل مستخدم آخر — ومعه محفظته ومعاملاتها وحجوزاته ومبارياته وتقييماتها
--        وصداقاته وإشعاراته ونقاطه، وأنديته وملاعبها إن كان مالكاً.
--
--  ── طريقة الاستخدام (ثلاث مراحل، لا تتخطّ أياً منها) ──────────────────────
--
--  ١) نسخة احتياطية — إلزامية:
--       mysqldump -u root -p --single-transaction SportaDb > ~/before_purge.sql
--
--  ٢) معاينة — يعرض من سيُحذف دون حذف أي شيء:
--       mysql -u root -p SportaDb < purge_users_keep_dashboard.sql
--
--  ٣) التنفيذ — بعد مراجعة المعاينة: أزِل التعليق عن كتلة «التنفيذ» أسفل
--     الملف ثم أعد التشغيل.
--
--  الملف كما هو **لا يحذف شيئاً** — كتلة الحذف معلّقة عمداً.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── مَن يبقى: أصحاب دور مدير (3) أو موظف (4) ────────────────────────────────
DROP TEMPORARY TABLE IF EXISTS `keep_users`;
CREATE TEMPORARY TABLE `keep_users` (Id INT PRIMARY KEY);
INSERT INTO `keep_users`
SELECT DISTINCT u.Id FROM `Users` u
JOIN `UserRoles` r ON r.UserId = u.Id
WHERE r.Role IN (3, 4);

-- ── مَن يُحذف ───────────────────────────────────────────────────────────────
DROP TEMPORARY TABLE IF EXISTS `purge_users`;
CREATE TEMPORARY TABLE `purge_users` (Id INT PRIMARY KEY);
INSERT INTO `purge_users`
SELECT u.Id FROM `Users` u
WHERE u.Id NOT IN (SELECT Id FROM `keep_users`);

-- ═══ المعاينة ═══════════════════════════════════════════════════════════════
SELECT 'سيبقى' AS 'الحالة', COUNT(*) AS 'العدد' FROM `keep_users`
UNION ALL
SELECT 'سيُحذف', COUNT(*) FROM `purge_users`;

-- الحسابات الباقية بالاسم — تأكّد أن حساب دخولك بينها قبل التنفيذ
SELECT u.Id, u.PhoneNumber AS 'الجوال',
       CONCAT(u.FirstName,' ',u.LastName) AS 'الاسم',
       CASE u.UserType WHEN 3 THEN 'مدير' WHEN 4 THEN 'موظف' ELSE 'أخرى' END AS 'الدور'
FROM `Users` u JOIN `keep_users` k ON k.Id = u.Id
ORDER BY u.UserType DESC, u.Id;

-- حجم ما سيُحذف من البيانات المرتبطة
SELECT 'الحجوزات' AS 'الجدول',
       (SELECT COUNT(*) FROM `Bookings` b WHERE b.UserId IN (SELECT Id FROM `purge_users`)
           OR b.CourtId IN (SELECT c.Id FROM `Courts` c JOIN `Venues` v ON v.Id=c.VenueId
                             WHERE v.OwnerId IN (SELECT Id FROM `purge_users`))) AS 'العدد'
UNION ALL SELECT 'المباريات',
       (SELECT COUNT(*) FROM `Matches` WHERE CreatorId IN (SELECT Id FROM `purge_users`))
UNION ALL SELECT 'جلسات التدريب',
       (SELECT COUNT(*) FROM `CoachSessions` s WHERE s.PlayerId IN (SELECT Id FROM `purge_users`)
           OR s.CoachProfileId IN (SELECT Id FROM `CoachProfiles`
                                    WHERE UserId IN (SELECT Id FROM `purge_users`)))
UNION ALL SELECT 'الأندية',
       (SELECT COUNT(*) FROM `Venues` WHERE OwnerId IN (SELECT Id FROM `purge_users`))
UNION ALL SELECT 'الملاعب',
       (SELECT COUNT(*) FROM `Courts` c JOIN `Venues` v ON v.Id=c.VenueId
         WHERE v.OwnerId IN (SELECT Id FROM `purge_users`))
UNION ALL SELECT 'معاملات المحفظة',
       (SELECT COUNT(*) FROM `WalletTransactions` t JOIN `Wallets` w ON w.Id=t.WalletId
         WHERE w.UserId IN (SELECT Id FROM `purge_users`))
UNION ALL SELECT 'طلبات السحب',
       (SELECT COUNT(*) FROM `WithdrawalRequests` WHERE UserId IN (SELECT Id FROM `purge_users`))
UNION ALL SELECT 'الصداقات',
       (SELECT COUNT(*) FROM `Friendships` f WHERE f.SenderId IN (SELECT Id FROM `purge_users`)
           OR f.ReceiverId IN (SELECT Id FROM `purge_users`));

-- ⚠ راجع الأرقام أعلاه. «طلبات السحب» و«معاملات المحفظة» سجلات مالية —
--   حذفها يفقدك أثر أي مبالغ حُصِّلت أو صُرِفت لهؤلاء المستخدمين.


-- ═══════════════════════════════════════════════════════════════════════════
--  التنفيذ — أزِل التعليق عن الكتلة كاملةً بعد مراجعة المعاينة
-- ═══════════════════════════════════════════════════════════════════════════
--
-- START TRANSACTION;
--
-- -- (١) تقييمات المباريات ولاعبوها — قبل المباريات والملفات
-- DELETE FROM `MatchRatings`
--  WHERE RaterId IN (SELECT Id FROM `purge_users`)
--     OR RatedUserId IN (SELECT Id FROM `purge_users`);
--
-- DELETE FROM `MatchPlayers` WHERE UserId IN (SELECT Id FROM `purge_users`);
--
-- -- جولات أمريكانو تشير للاعبين بأربعة أعمدة مباشرةً
-- DELETE FROM `AmericanoRounds`
--  WHERE Team1Player1Id IN (SELECT Id FROM `purge_users`)
--     OR Team1Player2Id IN (SELECT Id FROM `purge_users`)
--     OR Team2Player1Id IN (SELECT Id FROM `purge_users`)
--     OR Team2Player2Id IN (SELECT Id FROM `purge_users`);
--
-- -- (٢) الحجوزات والجلسات: للمستخدم، ولملاعبه إن كان مالكاً
-- DELETE FROM `Bookings`
--  WHERE UserId IN (SELECT Id FROM `purge_users`)
--     OR CourtId IN (SELECT c.Id FROM `Courts` c JOIN `Venues` v ON v.Id = c.VenueId
--                     WHERE v.OwnerId IN (SELECT Id FROM `purge_users`));
--
-- DELETE FROM `CoachSessions`
--  WHERE PlayerId IN (SELECT Id FROM `purge_users`)
--     OR CoachProfileId IN (SELECT Id FROM `CoachProfiles`
--                            WHERE UserId IN (SELECT Id FROM `purge_users`))
--     OR CourtId IN (SELECT c.Id FROM `Courts` c JOIN `Venues` v ON v.Id = c.VenueId
--                     WHERE v.OwnerId IN (SELECT Id FROM `purge_users`));
--
-- -- (٣) مباريات المحذوفين (توابعها تُحذف معها بـ CASCADE)
-- DELETE FROM `Matches` WHERE CreatorId IN (SELECT Id FROM `purge_users`);
--
-- -- (٤) مباريات مستخدمين باقين لكنها على ملاعب ستُحذف
-- DELETE FROM `Matches`
--  WHERE CourtId IN (SELECT c.Id FROM `Courts` c JOIN `Venues` v ON v.Id = c.VenueId
--                     WHERE v.OwnerId IN (SELECT Id FROM `purge_users`));
--
-- -- (٥) العلاقات الاجتماعية
-- DELETE FROM `Friendships`
--  WHERE SenderId IN (SELECT Id FROM `purge_users`)
--     OR ReceiverId IN (SELECT Id FROM `purge_users`);
-- DELETE FROM `Follows`
--  WHERE FollowerId IN (SELECT Id FROM `purge_users`)
--     OR FollowingId IN (SELECT Id FROM `purge_users`);
--
-- -- (٦) لاعبو المباريات المرتبطون بملفات اللاعبين (يمنعون حذف PlayerProfiles)
-- DELETE FROM `MatchPlayers`
--  WHERE PlayerProfileId IN (SELECT Id FROM `PlayerProfiles`
--                             WHERE UserId IN (SELECT Id FROM `purge_users`));
--
-- -- (٧) الملاعب ثم الأندية المملوكة للمحذوفين
-- DELETE FROM `Courts`
--  WHERE VenueId IN (SELECT Id FROM `Venues`
--                     WHERE OwnerId IN (SELECT Id FROM `purge_users`));
-- DELETE FROM `Venues` WHERE OwnerId IN (SELECT Id FROM `purge_users`);
--
-- -- (٨) المستخدمون. الباقي يُحذف تلقائياً بـ CASCADE: الأدوار، المحافظ
-- --     ومعاملاتها، ملفات اللاعب والمدرب، الاشتراكات، طلبات السحب،
-- --     الإشعارات، النقاط، التوكنات، ومستفيدو الخصومات.
-- DELETE FROM `Users` WHERE Id IN (SELECT Id FROM `purge_users`);
--
-- -- تحقّق أخير قبل التثبيت
-- SELECT COUNT(*) AS 'المستخدمون المتبقون' FROM `Users`;
--
-- -- ثبّت بـ COMMIT، أو تراجع عن كل ما سبق بـ ROLLBACK
-- COMMIT;
