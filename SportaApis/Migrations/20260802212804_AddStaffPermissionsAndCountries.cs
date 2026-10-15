using System;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class AddStaffPermissionsAndCountries : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CityId",
                table: "Venues",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CountryId",
                table: "Venues",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CountryId",
                table: "Cities",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "Countries",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    NameAr = table.Column<string>(type: "varchar(120)", maxLength: 120, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    NameEn = table.Column<string>(type: "varchar(120)", maxLength: 120, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Code = table.Column<string>(type: "varchar(2)", maxLength: 2, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    PhoneCode = table.Column<string>(type: "varchar(6)", maxLength: 6, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    CurrencyCode = table.Column<string>(type: "varchar(3)", maxLength: 3, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    IsActive = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Countries", x => x.Id);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "StaffProfiles",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    CountryId = table.Column<int>(type: "int", nullable: false),
                    CityId = table.Column<int>(type: "int", nullable: true),
                    JobTitle = table.Column<string>(type: "varchar(120)", maxLength: 120, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    CreatedByUserId = table.Column<int>(type: "int", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StaffProfiles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StaffProfiles_Cities_CityId",
                        column: x => x.CityId,
                        principalTable: "Cities",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_StaffProfiles_Countries_CountryId",
                        column: x => x.CountryId,
                        principalTable: "Countries",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_StaffProfiles_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "StaffPermissions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    StaffProfileId = table.Column<int>(type: "int", nullable: false),
                    Permission = table.Column<string>(type: "varchar(80)", maxLength: 80, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StaffPermissions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StaffPermissions_StaffProfiles_StaffProfileId",
                        column: x => x.StaffProfileId,
                        principalTable: "StaffProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_Venues_CityId",
                table: "Venues",
                column: "CityId");

            migrationBuilder.CreateIndex(
                name: "IX_Venues_CountryId",
                table: "Venues",
                column: "CountryId");

            migrationBuilder.CreateIndex(
                name: "IX_Cities_CountryId",
                table: "Cities",
                column: "CountryId");

            migrationBuilder.CreateIndex(
                name: "IX_Countries_Code",
                table: "Countries",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_StaffPermissions_StaffProfileId_Permission",
                table: "StaffPermissions",
                columns: new[] { "StaffProfileId", "Permission" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_StaffProfiles_CityId",
                table: "StaffProfiles",
                column: "CityId");

            migrationBuilder.CreateIndex(
                name: "IX_StaffProfiles_CountryId",
                table: "StaffProfiles",
                column: "CountryId");

            migrationBuilder.CreateIndex(
                name: "IX_StaffProfiles_UserId",
                table: "StaffProfiles",
                column: "UserId",
                unique: true);

            // المدن الموجودة أُضيف لها CountryId = 0، وهو ما يكسر المفتاح الأجنبي
            // أدناه. نُنشئ الدولة الافتراضية (السعودية) وننسب لها كل مدينة غير
            // مرتبطة قبل تفعيل القيد. (idempotent: INSERT مشروط بعدم وجود الرمز.)
            migrationBuilder.Sql("""
                INSERT INTO `Countries`
                    (`NameAr`, `NameEn`, `Code`, `PhoneCode`, `CurrencyCode`,
                     `IsActive`, `SortOrder`, `CreatedAt`)
                SELECT 'السعودية', 'Saudi Arabia', 'SA', '966', 'SAR', 1, 0, UTC_TIMESTAMP()
                FROM DUAL
                WHERE NOT EXISTS (SELECT 1 FROM `Countries` WHERE `Code` = 'SA');
                """);
            migrationBuilder.Sql("""
                UPDATE `Cities`
                SET `CountryId` = (SELECT `Id` FROM `Countries` WHERE `Code` = 'SA' LIMIT 1)
                WHERE `CountryId` = 0;
                """);

            // ربط الأندية القديمة بالمدينة عبر مطابقة الاسم النصي، حتى تخضع
            // لنطاق الموظفين مباشرة بعد الترقية.
            migrationBuilder.Sql("""
                UPDATE `Venues` v
                JOIN `Cities` c ON c.`NameAr` = TRIM(v.`City`) OR c.`NameEn` = TRIM(v.`City`)
                SET v.`CityId` = c.`Id`, v.`CountryId` = c.`CountryId`
                WHERE v.`CityId` IS NULL;
                """);

            // نفس المعالجة للمستخدمين القدامى الذين لم يختاروا مدينة من القائمة.
            migrationBuilder.Sql("""
                UPDATE `Users` u
                JOIN `Cities` c ON c.`NameAr` = TRIM(u.`City`) OR c.`NameEn` = TRIM(u.`City`)
                SET u.`CityId` = c.`Id`
                WHERE u.`CityId` IS NULL AND u.`City` IS NOT NULL AND u.`City` <> '';
                """);

            migrationBuilder.AddForeignKey(
                name: "FK_Cities_Countries_CountryId",
                table: "Cities",
                column: "CountryId",
                principalTable: "Countries",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Venues_Cities_CityId",
                table: "Venues",
                column: "CityId",
                principalTable: "Cities",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Venues_Countries_CountryId",
                table: "Venues",
                column: "CountryId",
                principalTable: "Countries",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Cities_Countries_CountryId",
                table: "Cities");

            migrationBuilder.DropForeignKey(
                name: "FK_Venues_Cities_CityId",
                table: "Venues");

            migrationBuilder.DropForeignKey(
                name: "FK_Venues_Countries_CountryId",
                table: "Venues");

            migrationBuilder.DropTable(
                name: "StaffPermissions");

            migrationBuilder.DropTable(
                name: "StaffProfiles");

            migrationBuilder.DropTable(
                name: "Countries");

            migrationBuilder.DropIndex(
                name: "IX_Venues_CityId",
                table: "Venues");

            migrationBuilder.DropIndex(
                name: "IX_Venues_CountryId",
                table: "Venues");

            migrationBuilder.DropIndex(
                name: "IX_Cities_CountryId",
                table: "Cities");

            migrationBuilder.DropColumn(
                name: "CityId",
                table: "Venues");

            migrationBuilder.DropColumn(
                name: "CountryId",
                table: "Venues");

            migrationBuilder.DropColumn(
                name: "CountryId",
                table: "Cities");
        }
    }
}
