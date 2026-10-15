using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class AddScoreProposals : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "ProposedAt",
                table: "TournamentFixtures",
                type: "datetime(6)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ProposedById",
                table: "TournamentFixtures",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ProposedTeam1Score",
                table: "TournamentFixtures",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ProposedTeam2Score",
                table: "TournamentFixtures",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ProposedAt",
                table: "Matches",
                type: "datetime(6)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ProposedById",
                table: "Matches",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ProposedTeam1Score",
                table: "Matches",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ProposedTeam2Score",
                table: "Matches",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ProposedAt",
                table: "AmericanoRounds",
                type: "datetime(6)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ProposedById",
                table: "AmericanoRounds",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ProposedTeam1Score",
                table: "AmericanoRounds",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ProposedTeam2Score",
                table: "AmericanoRounds",
                type: "int",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ProposedAt",
                table: "TournamentFixtures");

            migrationBuilder.DropColumn(
                name: "ProposedById",
                table: "TournamentFixtures");

            migrationBuilder.DropColumn(
                name: "ProposedTeam1Score",
                table: "TournamentFixtures");

            migrationBuilder.DropColumn(
                name: "ProposedTeam2Score",
                table: "TournamentFixtures");

            migrationBuilder.DropColumn(
                name: "ProposedAt",
                table: "Matches");

            migrationBuilder.DropColumn(
                name: "ProposedById",
                table: "Matches");

            migrationBuilder.DropColumn(
                name: "ProposedTeam1Score",
                table: "Matches");

            migrationBuilder.DropColumn(
                name: "ProposedTeam2Score",
                table: "Matches");

            migrationBuilder.DropColumn(
                name: "ProposedAt",
                table: "AmericanoRounds");

            migrationBuilder.DropColumn(
                name: "ProposedById",
                table: "AmericanoRounds");

            migrationBuilder.DropColumn(
                name: "ProposedTeam1Score",
                table: "AmericanoRounds");

            migrationBuilder.DropColumn(
                name: "ProposedTeam2Score",
                table: "AmericanoRounds");
        }
    }
}
