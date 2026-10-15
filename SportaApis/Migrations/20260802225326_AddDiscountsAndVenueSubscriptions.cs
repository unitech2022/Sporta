using System;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class AddDiscountsAndVenueSubscriptions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // معنى النسبة تغيّر: كانت تُضاف فوق سعر المالك، وصارت تُقتطع منه.
            // الملاعب التي بقيت على الافتراضي القديم (١٠) تُنقل إلى ٥ حتى لا
            // يتضاعف اقتطاع سبورتا من مستحقات المالك بعد الترقية. الملاعب ذات
            // النسب المخصّصة تبقى كما هي — الأدمن اختارها عمداً ويراجعها.
            migrationBuilder.Sql("""
                UPDATE `Courts` SET `SportaCommissionPercent` = 5.00
                WHERE `SportaCommissionPercent` = 10.00;
                """);

            // نفس المعالجة للقطة النسبة على المباريات التي لم تُغلَق بعد.
            migrationBuilder.Sql("""
                UPDATE `Matches` SET `SportaCommissionPercent` = 5.00
                WHERE `SportaCommissionPercent` = 10.00
                  AND `Status` IN (0, 1, 2);
                """);

            migrationBuilder.AlterColumn<decimal>(
                name: "SportaCommissionPercent",
                table: "Courts",
                type: "decimal(5,2)",
                precision: 5,
                scale: 2,
                nullable: false,
                defaultValue: 5m,
                oldClrType: typeof(decimal),
                oldType: "decimal(5,2)",
                oldPrecision: 5,
                oldScale: 2,
                oldDefaultValue: 10m);

            migrationBuilder.AddColumn<decimal>(
                name: "SportaCommissionPercent",
                table: "CoachSessions",
                type: "decimal(5,2)",
                precision: 5,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.CreateTable(
                name: "Discounts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    NameAr = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    DescriptionAr = table.Column<string>(type: "longtext", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Target = table.Column<int>(type: "int", nullable: false),
                    Percent = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    IsGeneral = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    StartsAt = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    EndsAt = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    MaxBeneficiaries = table.Column<int>(type: "int", nullable: true),
                    GrantsLifetime = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    IsActive = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Discounts", x => x.Id);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "VenueSubscriptionPricings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    MonthlyOneCourt = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    MonthlyTwoCourts = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    MonthlyExtraCourt = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    YearlyOneCourt = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    YearlyTwoCourts = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    YearlyExtraCourt = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    IsActive = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VenueSubscriptionPricings", x => x.Id);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "VenueSubscriptions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    OwnerId = table.Column<int>(type: "int", nullable: false),
                    IsYearly = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    CourtCount = table.Column<int>(type: "int", nullable: false),
                    BasePrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    DiscountPercent = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    PaidAmount = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    StartsAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    EndsAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VenueSubscriptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_VenueSubscriptions_Users_OwnerId",
                        column: x => x.OwnerId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "DiscountBeneficiaries",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    DiscountId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    AutoEnrolled = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DiscountBeneficiaries", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DiscountBeneficiaries_Discounts_DiscountId",
                        column: x => x.DiscountId,
                        principalTable: "Discounts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_DiscountBeneficiaries_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_DiscountBeneficiaries_DiscountId_UserId",
                table: "DiscountBeneficiaries",
                columns: new[] { "DiscountId", "UserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DiscountBeneficiaries_UserId",
                table: "DiscountBeneficiaries",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Discounts_Target_IsActive",
                table: "Discounts",
                columns: new[] { "Target", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_VenueSubscriptions_OwnerId_EndsAt",
                table: "VenueSubscriptions",
                columns: new[] { "OwnerId", "EndsAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DiscountBeneficiaries");

            migrationBuilder.DropTable(
                name: "VenueSubscriptionPricings");

            migrationBuilder.DropTable(
                name: "VenueSubscriptions");

            migrationBuilder.DropTable(
                name: "Discounts");

            migrationBuilder.DropColumn(
                name: "SportaCommissionPercent",
                table: "CoachSessions");

            migrationBuilder.AlterColumn<decimal>(
                name: "SportaCommissionPercent",
                table: "Courts",
                type: "decimal(5,2)",
                precision: 5,
                scale: 2,
                nullable: false,
                defaultValue: 10m,
                oldClrType: typeof(decimal),
                oldType: "decimal(5,2)",
                oldPrecision: 5,
                oldScale: 2,
                oldDefaultValue: 5m);
        }
    }
}
