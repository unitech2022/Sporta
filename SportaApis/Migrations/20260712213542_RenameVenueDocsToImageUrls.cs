using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class RenameVenueDocsToImageUrls : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "NationalAddress",
                table: "Venues",
                newName: "NationalAddressImageUrl");

            migrationBuilder.RenameColumn(
                name: "CommercialRegistration",
                table: "Venues",
                newName: "CommercialRegistrationImageUrl");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "NationalAddressImageUrl",
                table: "Venues",
                newName: "NationalAddress");

            migrationBuilder.RenameColumn(
                name: "CommercialRegistrationImageUrl",
                table: "Venues",
                newName: "CommercialRegistration");
        }
    }
}
