using System;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class AddMatchGender : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Gender",
                table: "Matches",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "IdDocumentUrl",
                table: "CoachProfiles",
                type: "longtext",
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<int>(
                name: "SportId",
                table: "CoachProfiles",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "EndDate",
                table: "AmericanoMatches",
                type: "datetime(6)",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsTournament",
                table: "AmericanoMatches",
                type: "tinyint(1)",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "SportSettings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    SportId = table.Column<int>(type: "int", nullable: false),
                    Title = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    ItemsText = table.Column<string>(type: "longtext", nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SportSettings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SportSettings_Sports_SportId",
                        column: x => x.SportId,
                        principalTable: "Sports",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_CoachProfiles_SportId",
                table: "CoachProfiles",
                column: "SportId");

            migrationBuilder.CreateIndex(
                name: "IX_SportSettings_SportId",
                table: "SportSettings",
                column: "SportId");

            migrationBuilder.AddForeignKey(
                name: "FK_CoachProfiles_Sports_SportId",
                table: "CoachProfiles",
                column: "SportId",
                principalTable: "Sports",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CoachProfiles_Sports_SportId",
                table: "CoachProfiles");

            migrationBuilder.DropTable(
                name: "SportSettings");

            migrationBuilder.DropIndex(
                name: "IX_CoachProfiles_SportId",
                table: "CoachProfiles");

            migrationBuilder.DropColumn(
                name: "Gender",
                table: "Matches");

            migrationBuilder.DropColumn(
                name: "IdDocumentUrl",
                table: "CoachProfiles");

            migrationBuilder.DropColumn(
                name: "SportId",
                table: "CoachProfiles");

            migrationBuilder.DropColumn(
                name: "EndDate",
                table: "AmericanoMatches");

            migrationBuilder.DropColumn(
                name: "IsTournament",
                table: "AmericanoMatches");
        }
    }
}
