using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class GeneralizeSystemSettings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Value",
                table: "SystemSettings",
                newName: "ValueAr");

            migrationBuilder.AddColumn<string>(
                name: "ValueEn",
                table: "SystemSettings",
                type: "longtext",
                nullable: false,
                defaultValue: "")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<bool>(
                name: "IsSensitive",
                table: "SystemSettings",
                type: "tinyint(1)",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "NameAr",
                table: "SystemSettings",
                type: "longtext",
                nullable: false,
                defaultValue: "")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "NameEn",
                table: "SystemSettings",
                type: "longtext",
                nullable: false,
                defaultValue: "")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<int>(
                name: "Type",
                table: "SystemSettings",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsSensitive",
                table: "SystemSettings");

            migrationBuilder.DropColumn(
                name: "NameAr",
                table: "SystemSettings");

            migrationBuilder.DropColumn(
                name: "NameEn",
                table: "SystemSettings");

            migrationBuilder.DropColumn(
                name: "Type",
                table: "SystemSettings");

            migrationBuilder.DropColumn(
                name: "ValueEn",
                table: "SystemSettings");

            migrationBuilder.RenameColumn(
                name: "ValueAr",
                table: "SystemSettings",
                newName: "Value");
        }
    }
}
