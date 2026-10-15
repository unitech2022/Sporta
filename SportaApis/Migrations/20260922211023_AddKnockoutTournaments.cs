using System;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class AddKnockoutTournaments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "DrawnAt",
                table: "AmericanoMatches",
                type: "datetime(6)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Format",
                table: "AmericanoMatches",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "IncompleteNoticeSentAt",
                table: "AmericanoMatches",
                type: "datetime(6)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MatchMinutes",
                table: "AmericanoMatches",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "Name",
                table: "AmericanoMatches",
                type: "varchar(80)",
                maxLength: 80,
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "TournamentCourts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    AmericanoMatchId = table.Column<int>(type: "int", nullable: false),
                    CourtId = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TournamentCourts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TournamentCourts_AmericanoMatches_AmericanoMatchId",
                        column: x => x.AmericanoMatchId,
                        principalTable: "AmericanoMatches",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TournamentCourts_Courts_CourtId",
                        column: x => x.CourtId,
                        principalTable: "Courts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "TournamentFixtures",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    AmericanoMatchId = table.Column<int>(type: "int", nullable: false),
                    Stage = table.Column<int>(type: "int", nullable: false),
                    GroupIndex = table.Column<int>(type: "int", nullable: true),
                    Round = table.Column<int>(type: "int", nullable: false),
                    Index = table.Column<int>(type: "int", nullable: false),
                    Team1 = table.Column<int>(type: "int", nullable: true),
                    Team2 = table.Column<int>(type: "int", nullable: true),
                    Team1Score = table.Column<int>(type: "int", nullable: true),
                    Team2Score = table.Column<int>(type: "int", nullable: true),
                    IsCompleted = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    IsBye = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    WinnerTeam = table.Column<int>(type: "int", nullable: true),
                    CourtId = table.Column<int>(type: "int", nullable: true),
                    ScheduledAt = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TournamentFixtures", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TournamentFixtures_AmericanoMatches_AmericanoMatchId",
                        column: x => x.AmericanoMatchId,
                        principalTable: "AmericanoMatches",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TournamentFixtures_Courts_CourtId",
                        column: x => x.CourtId,
                        principalTable: "Courts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_TournamentCourts_AmericanoMatchId_CourtId",
                table: "TournamentCourts",
                columns: new[] { "AmericanoMatchId", "CourtId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TournamentCourts_CourtId",
                table: "TournamentCourts",
                column: "CourtId");

            migrationBuilder.CreateIndex(
                name: "IX_TournamentFixtures_AmericanoMatchId_Stage_Round_Index",
                table: "TournamentFixtures",
                columns: new[] { "AmericanoMatchId", "Stage", "Round", "Index" });

            migrationBuilder.CreateIndex(
                name: "IX_TournamentFixtures_CourtId",
                table: "TournamentFixtures",
                column: "CourtId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "TournamentCourts");

            migrationBuilder.DropTable(
                name: "TournamentFixtures");

            migrationBuilder.DropColumn(
                name: "DrawnAt",
                table: "AmericanoMatches");

            migrationBuilder.DropColumn(
                name: "Format",
                table: "AmericanoMatches");

            migrationBuilder.DropColumn(
                name: "IncompleteNoticeSentAt",
                table: "AmericanoMatches");

            migrationBuilder.DropColumn(
                name: "MatchMinutes",
                table: "AmericanoMatches");

            migrationBuilder.DropColumn(
                name: "Name",
                table: "AmericanoMatches");
        }
    }
}
