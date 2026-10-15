using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class AddCoachSessionPlayerRating : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "PlayerRating",
                table: "CoachSessions",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PlayerReview",
                table: "CoachSessions",
                type: "longtext",
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PlayerRating",
                table: "CoachSessions");

            migrationBuilder.DropColumn(
                name: "PlayerReview",
                table: "CoachSessions");
        }
    }
}
