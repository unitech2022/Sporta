START TRANSACTION;
DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    ALTER TABLE `Venues` ADD `CityId` int NULL;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    ALTER TABLE `Venues` ADD `CountryId` int NULL;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    ALTER TABLE `Cities` ADD `CountryId` int NOT NULL DEFAULT 0;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    CREATE TABLE `Countries` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `NameAr` varchar(120) CHARACTER SET utf8mb4 NOT NULL,
        `NameEn` varchar(120) CHARACTER SET utf8mb4 NOT NULL,
        `Code` varchar(2) CHARACTER SET utf8mb4 NOT NULL,
        `PhoneCode` varchar(6) CHARACTER SET utf8mb4 NULL,
        `CurrencyCode` varchar(3) CHARACTER SET utf8mb4 NULL,
        `IsActive` tinyint(1) NOT NULL,
        `SortOrder` int NOT NULL,
        `CreatedAt` datetime(6) NOT NULL,
        `UpdatedAt` datetime(6) NULL,
        CONSTRAINT `PK_Countries` PRIMARY KEY (`Id`)
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    CREATE TABLE `StaffProfiles` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `UserId` int NOT NULL,
        `CountryId` int NOT NULL,
        `CityId` int NULL,
        `JobTitle` varchar(120) CHARACTER SET utf8mb4 NULL,
        `CreatedByUserId` int NULL,
        `CreatedAt` datetime(6) NOT NULL,
        `UpdatedAt` datetime(6) NULL,
        CONSTRAINT `PK_StaffProfiles` PRIMARY KEY (`Id`),
        CONSTRAINT `FK_StaffProfiles_Cities_CityId` FOREIGN KEY (`CityId`) REFERENCES `Cities` (`Id`) ON DELETE RESTRICT,
        CONSTRAINT `FK_StaffProfiles_Countries_CountryId` FOREIGN KEY (`CountryId`) REFERENCES `Countries` (`Id`) ON DELETE RESTRICT,
        CONSTRAINT `FK_StaffProfiles_Users_UserId` FOREIGN KEY (`UserId`) REFERENCES `Users` (`Id`) ON DELETE CASCADE
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    CREATE TABLE `StaffPermissions` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `StaffProfileId` int NOT NULL,
        `Permission` varchar(80) CHARACTER SET utf8mb4 NOT NULL,
        `CreatedAt` datetime(6) NOT NULL,
        `UpdatedAt` datetime(6) NULL,
        CONSTRAINT `PK_StaffPermissions` PRIMARY KEY (`Id`),
        CONSTRAINT `FK_StaffPermissions_StaffProfiles_StaffProfileId` FOREIGN KEY (`StaffProfileId`) REFERENCES `StaffProfiles` (`Id`) ON DELETE CASCADE
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    CREATE INDEX `IX_Venues_CityId` ON `Venues` (`CityId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    CREATE INDEX `IX_Venues_CountryId` ON `Venues` (`CountryId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    CREATE INDEX `IX_Cities_CountryId` ON `Cities` (`CountryId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    CREATE UNIQUE INDEX `IX_Countries_Code` ON `Countries` (`Code`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    CREATE UNIQUE INDEX `IX_StaffPermissions_StaffProfileId_Permission` ON `StaffPermissions` (`StaffProfileId`, `Permission`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    CREATE INDEX `IX_StaffProfiles_CityId` ON `StaffProfiles` (`CityId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    CREATE INDEX `IX_StaffProfiles_CountryId` ON `StaffProfiles` (`CountryId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    CREATE UNIQUE INDEX `IX_StaffProfiles_UserId` ON `StaffProfiles` (`UserId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    INSERT INTO `Countries`
        (`NameAr`, `NameEn`, `Code`, `PhoneCode`, `CurrencyCode`,
         `IsActive`, `SortOrder`, `CreatedAt`)
    SELECT 'السعودية', 'Saudi Arabia', 'SA', '966', 'SAR', 1, 0, UTC_TIMESTAMP()
    FROM DUAL
    WHERE NOT EXISTS (SELECT 1 FROM `Countries` WHERE `Code` = 'SA');

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    UPDATE `Cities`
    SET `CountryId` = (SELECT `Id` FROM `Countries` WHERE `Code` = 'SA' LIMIT 1)
    WHERE `CountryId` = 0;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    UPDATE `Venues` v
    JOIN `Cities` c ON c.`NameAr` = TRIM(v.`City`) OR c.`NameEn` = TRIM(v.`City`)
    SET v.`CityId` = c.`Id`, v.`CountryId` = c.`CountryId`
    WHERE v.`CityId` IS NULL;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    UPDATE `Users` u
    JOIN `Cities` c ON c.`NameAr` = TRIM(u.`City`) OR c.`NameEn` = TRIM(u.`City`)
    SET u.`CityId` = c.`Id`
    WHERE u.`CityId` IS NULL AND u.`City` IS NOT NULL AND u.`City` <> '';

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    ALTER TABLE `Cities` ADD CONSTRAINT `FK_Cities_Countries_CountryId` FOREIGN KEY (`CountryId`) REFERENCES `Countries` (`Id`) ON DELETE RESTRICT;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    ALTER TABLE `Venues` ADD CONSTRAINT `FK_Venues_Cities_CityId` FOREIGN KEY (`CityId`) REFERENCES `Cities` (`Id`) ON DELETE SET NULL;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    ALTER TABLE `Venues` ADD CONSTRAINT `FK_Venues_Countries_CountryId` FOREIGN KEY (`CountryId`) REFERENCES `Countries` (`Id`) ON DELETE SET NULL;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802212804_AddStaffPermissionsAndCountries') THEN

    INSERT INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`)
    VALUES ('20260802212804_AddStaffPermissionsAndCountries', '9.0.15');

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802225326_AddDiscountsAndVenueSubscriptions') THEN

    UPDATE `Courts` SET `SportaCommissionPercent` = 5.00
    WHERE `SportaCommissionPercent` = 10.00;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802225326_AddDiscountsAndVenueSubscriptions') THEN

    UPDATE `Matches` SET `SportaCommissionPercent` = 5.00
    WHERE `SportaCommissionPercent` = 10.00
      AND `Status` IN (0, 1, 2);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802225326_AddDiscountsAndVenueSubscriptions') THEN

    ALTER TABLE `Courts` MODIFY COLUMN `SportaCommissionPercent` decimal(5,2) NOT NULL DEFAULT 5.0;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802225326_AddDiscountsAndVenueSubscriptions') THEN

    ALTER TABLE `CoachSessions` ADD `SportaCommissionPercent` decimal(5,2) NOT NULL DEFAULT 0.0;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802225326_AddDiscountsAndVenueSubscriptions') THEN

    CREATE TABLE `Discounts` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `NameAr` varchar(150) CHARACTER SET utf8mb4 NOT NULL,
        `DescriptionAr` longtext CHARACTER SET utf8mb4 NULL,
        `Target` int NOT NULL,
        `Percent` decimal(5,2) NOT NULL,
        `IsGeneral` tinyint(1) NOT NULL,
        `StartsAt` datetime(6) NULL,
        `EndsAt` datetime(6) NULL,
        `MaxBeneficiaries` int NULL,
        `GrantsLifetime` tinyint(1) NOT NULL,
        `IsActive` tinyint(1) NOT NULL,
        `CreatedAt` datetime(6) NOT NULL,
        `UpdatedAt` datetime(6) NULL,
        CONSTRAINT `PK_Discounts` PRIMARY KEY (`Id`)
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802225326_AddDiscountsAndVenueSubscriptions') THEN

    CREATE TABLE `VenueSubscriptionPricings` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `MonthlyOneCourt` decimal(10,2) NOT NULL,
        `MonthlyTwoCourts` decimal(10,2) NOT NULL,
        `MonthlyExtraCourt` decimal(10,2) NOT NULL,
        `YearlyOneCourt` decimal(10,2) NOT NULL,
        `YearlyTwoCourts` decimal(10,2) NOT NULL,
        `YearlyExtraCourt` decimal(10,2) NOT NULL,
        `IsActive` tinyint(1) NOT NULL,
        `CreatedAt` datetime(6) NOT NULL,
        `UpdatedAt` datetime(6) NULL,
        CONSTRAINT `PK_VenueSubscriptionPricings` PRIMARY KEY (`Id`)
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802225326_AddDiscountsAndVenueSubscriptions') THEN

    CREATE TABLE `VenueSubscriptions` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `OwnerId` int NOT NULL,
        `IsYearly` tinyint(1) NOT NULL,
        `CourtCount` int NOT NULL,
        `BasePrice` decimal(10,2) NOT NULL,
        `DiscountPercent` decimal(5,2) NOT NULL,
        `PaidAmount` decimal(10,2) NOT NULL,
        `StartsAt` datetime(6) NOT NULL,
        `EndsAt` datetime(6) NOT NULL,
        `CreatedAt` datetime(6) NOT NULL,
        `UpdatedAt` datetime(6) NULL,
        CONSTRAINT `PK_VenueSubscriptions` PRIMARY KEY (`Id`),
        CONSTRAINT `FK_VenueSubscriptions_Users_OwnerId` FOREIGN KEY (`OwnerId`) REFERENCES `Users` (`Id`) ON DELETE CASCADE
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802225326_AddDiscountsAndVenueSubscriptions') THEN

    CREATE TABLE `DiscountBeneficiaries` (
        `Id` int NOT NULL AUTO_INCREMENT,
        `DiscountId` int NOT NULL,
        `UserId` int NOT NULL,
        `AutoEnrolled` tinyint(1) NOT NULL,
        `CreatedAt` datetime(6) NOT NULL,
        `UpdatedAt` datetime(6) NULL,
        CONSTRAINT `PK_DiscountBeneficiaries` PRIMARY KEY (`Id`),
        CONSTRAINT `FK_DiscountBeneficiaries_Discounts_DiscountId` FOREIGN KEY (`DiscountId`) REFERENCES `Discounts` (`Id`) ON DELETE CASCADE,
        CONSTRAINT `FK_DiscountBeneficiaries_Users_UserId` FOREIGN KEY (`UserId`) REFERENCES `Users` (`Id`) ON DELETE CASCADE
    ) CHARACTER SET=utf8mb4;

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802225326_AddDiscountsAndVenueSubscriptions') THEN

    CREATE UNIQUE INDEX `IX_DiscountBeneficiaries_DiscountId_UserId` ON `DiscountBeneficiaries` (`DiscountId`, `UserId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802225326_AddDiscountsAndVenueSubscriptions') THEN

    CREATE INDEX `IX_DiscountBeneficiaries_UserId` ON `DiscountBeneficiaries` (`UserId`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802225326_AddDiscountsAndVenueSubscriptions') THEN

    CREATE INDEX `IX_Discounts_Target_IsActive` ON `Discounts` (`Target`, `IsActive`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802225326_AddDiscountsAndVenueSubscriptions') THEN

    CREATE INDEX `IX_VenueSubscriptions_OwnerId_EndsAt` ON `VenueSubscriptions` (`OwnerId`, `EndsAt`);

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

DROP PROCEDURE IF EXISTS MigrationsScript;
DELIMITER //
CREATE PROCEDURE MigrationsScript()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM `__EFMigrationsHistory` WHERE `MigrationId` = '20260802225326_AddDiscountsAndVenueSubscriptions') THEN

    INSERT INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`)
    VALUES ('20260802225326_AddDiscountsAndVenueSubscriptions', '9.0.15');

    END IF;
END //
DELIMITER ;
CALL MigrationsScript();
DROP PROCEDURE MigrationsScript;

COMMIT;

