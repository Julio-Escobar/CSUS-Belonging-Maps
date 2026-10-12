using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace BelongingMaps.API.Migrations
{
    /// <inheritdoc />
    public partial class SeedSampleLocations : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Locations",
                columns: new[] { "Id", "Latitude", "Longitude", "Title" },
                values: new object[,]
                {
                    { 1, 38.575000000000003, -121.47799999999999, "Community Center" },
                    { 2, 38.576000000000001, -121.48, "School" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Locations",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Locations",
                keyColumn: "Id",
                keyValue: 2);
        }
    }
}
