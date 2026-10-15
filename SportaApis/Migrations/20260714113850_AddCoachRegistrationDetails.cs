using System;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class AddCoachRegistrationDetails : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AvailableDays",
                table: "CoachProfiles",
                type: "longtext",
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "Certifications",
                table: "CoachProfiles",
                type: "longtext",
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<int>(
                name: "ExperienceLevel",
                table: "CoachProfiles",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "NationalIdBackUrl",
                table: "CoachProfiles",
                type: "longtext",
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "NationalIdFrontUrl",
                table: "CoachProfiles",
                type: "longtext",
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<decimal>(
                name: "PackagePrice",
                table: "CoachProfiles",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "PreferredVenueId",
                table: "CoachProfiles",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Residency",
                table: "CoachProfiles",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "TargetGender",
                table: "CoachProfiles",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "CoachSpecializations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    NameAr = table.Column<string>(type: "longtext", nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    NameEn = table.Column<string>(type: "longtext", nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    IsActive = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CoachSpecializations", x => x.Id);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "CoachProfileSpecializations",
                columns: table => new
                {
                    CoachProfileId = table.Column<int>(type: "int", nullable: false),
                    SpecializationId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CoachProfileSpecializations", x => new { x.CoachProfileId, x.SpecializationId });
                    table.ForeignKey(
                        name: "FK_CoachProfileSpecializations_CoachProfiles_CoachProfileId",
                        column: x => x.CoachProfileId,
                        principalTable: "CoachProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CoachProfileSpecializations_CoachSpecializations_Specializat~",
                        column: x => x.SpecializationId,
                        principalTable: "CoachSpecializations",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_CoachProfiles_PreferredVenueId",
                table: "CoachProfiles",
                column: "PreferredVenueId");

            migrationBuilder.CreateIndex(
                name: "IX_CoachProfileSpecializations_SpecializationId",
                table: "CoachProfileSpecializations",
                column: "SpecializationId");

            migrationBuilder.AddForeignKey(
                name: "FK_CoachProfiles_Venues_PreferredVenueId",
                table: "CoachProfiles",
                column: "PreferredVenueId",
                principalTable: "Venues",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CoachProfiles_Venues_PreferredVenueId",
                table: "CoachProfiles");

            migrationBuilder.DropTable(
                name: "CoachProfileSpecializations");

            migrationBuilder.DropTable(
                name: "CoachSpecializations");

            migrationBuilder.DropIndex(
                name: "IX_CoachProfiles_PreferredVenueId",
                table: "CoachProfiles");

            migrationBuilder.DropColumn(
                name: "AvailableDays",
                table: "CoachProfiles");

            migrationBuilder.DropColumn(
                name: "Certifications",
                table: "CoachProfiles");

            migrationBuilder.DropColumn(
                name: "ExperienceLevel",
                table: "CoachProfiles");

            migrationBuilder.DropColumn(
                name: "NationalIdBackUrl",
                table: "CoachProfiles");

            migrationBuilder.DropColumn(
                name: "NationalIdFrontUrl",
                table: "CoachProfiles");

            migrationBuilder.DropColumn(
                name: "PackagePrice",
                table: "CoachProfiles");

            migrationBuilder.DropColumn(
                name: "PreferredVenueId",
                table: "CoachProfiles");

            migrationBuilder.DropColumn(
                name: "Residency",
                table: "CoachProfiles");

            migrationBuilder.DropColumn(
                name: "TargetGender",
                table: "CoachProfiles");
        }
    }
}
