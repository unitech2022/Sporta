using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class AddOtpPurposeAndVerificationToken : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Attempts",
                table: "OtpCodes",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "Channel",
                table: "OtpCodes",
                type: "varchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<int>(
                name: "Purpose",
                table: "OtpCodes",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<bool>(
                name: "TokenConsumed",
                table: "OtpCodes",
                type: "tinyint(1)",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "TokenExpiresAt",
                table: "OtpCodes",
                type: "datetime(6)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "VerificationToken",
                table: "OtpCodes",
                type: "varchar(64)",
                maxLength: 64,
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<DateTime>(
                name: "VerifiedAt",
                table: "OtpCodes",
                type: "datetime(6)",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_OtpCodes_PhoneNumber_Purpose_CreatedAt",
                table: "OtpCodes",
                columns: new[] { "PhoneNumber", "Purpose", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_OtpCodes_VerificationToken",
                table: "OtpCodes",
                column: "VerificationToken");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_OtpCodes_PhoneNumber_Purpose_CreatedAt",
                table: "OtpCodes");

            migrationBuilder.DropIndex(
                name: "IX_OtpCodes_VerificationToken",
                table: "OtpCodes");

            migrationBuilder.DropColumn(
                name: "Attempts",
                table: "OtpCodes");

            migrationBuilder.DropColumn(
                name: "Channel",
                table: "OtpCodes");

            migrationBuilder.DropColumn(
                name: "Purpose",
                table: "OtpCodes");

            migrationBuilder.DropColumn(
                name: "TokenConsumed",
                table: "OtpCodes");

            migrationBuilder.DropColumn(
                name: "TokenExpiresAt",
                table: "OtpCodes");

            migrationBuilder.DropColumn(
                name: "VerificationToken",
                table: "OtpCodes");

            migrationBuilder.DropColumn(
                name: "VerifiedAt",
                table: "OtpCodes");
        }
    }
}
