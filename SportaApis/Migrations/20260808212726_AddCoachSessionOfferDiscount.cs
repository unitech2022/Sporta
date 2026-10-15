using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class AddCoachSessionOfferDiscount : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "BasePrice",
                table: "CoachSessions",
                type: "decimal(65,30)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "OfferDiscountPercent",
                table: "CoachSessions",
                type: "decimal(65,30)",
                nullable: false,
                defaultValue: 0m);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "BasePrice",
                table: "CoachSessions");

            migrationBuilder.DropColumn(
                name: "OfferDiscountPercent",
                table: "CoachSessions");
        }
    }
}
