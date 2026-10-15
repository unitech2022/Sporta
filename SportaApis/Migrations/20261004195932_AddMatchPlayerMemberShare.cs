using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class AddMatchPlayerMemberShare : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "MemberDiscountMinutes",
                table: "MatchPlayers",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "MembershipId",
                table: "MatchPlayers",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "PaidAmount",
                table: "MatchPlayers",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_MatchPlayers_MembershipId",
                table: "MatchPlayers",
                column: "MembershipId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_MatchPlayers_MembershipId",
                table: "MatchPlayers");

            migrationBuilder.DropColumn(
                name: "MemberDiscountMinutes",
                table: "MatchPlayers");

            migrationBuilder.DropColumn(
                name: "MembershipId",
                table: "MatchPlayers");

            migrationBuilder.DropColumn(
                name: "PaidAmount",
                table: "MatchPlayers");
        }
    }
}
