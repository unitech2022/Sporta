using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class RenameSessionRatingToCoachRating : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "PlayerReview",
                table: "CoachSessions",
                newName: "CoachReview");

            migrationBuilder.RenameColumn(
                name: "PlayerRating",
                table: "CoachSessions",
                newName: "CoachRating");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "CoachReview",
                table: "CoachSessions",
                newName: "PlayerReview");

            migrationBuilder.RenameColumn(
                name: "CoachRating",
                table: "CoachSessions",
                newName: "PlayerRating");
        }
    }
}
