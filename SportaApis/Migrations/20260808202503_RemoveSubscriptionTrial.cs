using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class RemoveSubscriptionTrial : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TrialEndDate",
                table: "Subscriptions");

            migrationBuilder.DropColumn(
                name: "TrialUsed",
                table: "Subscriptions");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "TrialEndDate",
                table: "Subscriptions",
                type: "datetime(6)",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "TrialUsed",
                table: "Subscriptions",
                type: "tinyint(1)",
                nullable: false,
                defaultValue: false);
        }
    }
}
