using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class AddCoachSessionStatus : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Default to Confirmed(1) so existing sessions stay confirmed.
            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "CoachSessions",
                type: "int",
                nullable: false,
                defaultValue: 1);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Status",
                table: "CoachSessions");
        }
    }
}
