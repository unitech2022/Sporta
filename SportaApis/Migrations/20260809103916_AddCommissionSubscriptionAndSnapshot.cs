using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class AddCommissionSubscriptionAndSnapshot : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "BookingDiscountPercent",
                table: "Subscriptions",
                type: "decimal(65,30)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "CommissionDiscountPercent",
                table: "Subscriptions",
                type: "decimal(65,30)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "CommissionPercent",
                table: "Subscriptions",
                type: "decimal(65,30)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<string>(
                name: "PackageName",
                table: "Subscriptions",
                type: "longtext",
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<int>(
                name: "Period",
                table: "Subscriptions",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<decimal>(
                name: "PointsMultiplier",
                table: "Subscriptions",
                type: "decimal(65,30)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "PricePaid",
                table: "Subscriptions",
                type: "decimal(65,30)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<int>(
                name: "WelcomePoints",
                table: "Subscriptions",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<decimal>(
                name: "CommissionPercent",
                table: "Packages",
                type: "decimal(65,30)",
                nullable: false,
                defaultValue: 0m);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "BookingDiscountPercent",
                table: "Subscriptions");

            migrationBuilder.DropColumn(
                name: "CommissionDiscountPercent",
                table: "Subscriptions");

            migrationBuilder.DropColumn(
                name: "CommissionPercent",
                table: "Subscriptions");

            migrationBuilder.DropColumn(
                name: "PackageName",
                table: "Subscriptions");

            migrationBuilder.DropColumn(
                name: "Period",
                table: "Subscriptions");

            migrationBuilder.DropColumn(
                name: "PointsMultiplier",
                table: "Subscriptions");

            migrationBuilder.DropColumn(
                name: "PricePaid",
                table: "Subscriptions");

            migrationBuilder.DropColumn(
                name: "WelcomePoints",
                table: "Subscriptions");

            migrationBuilder.DropColumn(
                name: "CommissionPercent",
                table: "Packages");
        }
    }
}
