using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace BelongingMaps.API.Migrations
{
    /// <inheritdoc />
    public partial class AddSurveySeedData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Surveys",
                columns: new[] { "Id", "Description", "Link", "Title" },
                values: new object[,]
                {
                    { 1, "", "https://survey123.arcgis.com/share/56d94520eea24deaa5a1e57b3ab43e08", "SOMOS Sac State" },
                    { 2, "", "https://survey123.arcgis.com/share/ffa13b155b684041ab4b4335d4ccf029", "SOMOS Sac Community" },
                    { 3, "", "https://survey123.arcgis.com/share/9859d4081f2742449fcf4331ea9122f9", "UMMAH Sac State" },
                    { 4, "", "https://survey123.arcgis.com/share/2d1fe1696b794a239cbdecdae736f289", "UMMAH Sac Community" },
                    { 5, "", "https://storymaps.arcgis.com/stories/0533e5adea024e10a69568c547544c07", "Ubuntu Sac State" },
                    { 6, "", "https://survey123.arcgis.com/share/e4a218f5291f4fa9a31078cf8f067d84", "Ubuntu Sac Community" },
                    { 7, "", "https://survey123.arcgis.com/share/0b9123ed6c9f4cf6a0e1f3e076ffd5ae", "SOMOS Something Missing?" },
                    { 8, "", "https://survey123.arcgis.com/share/8688bd88b2e64da6bf369f4972161f2f", "UMMAH Something Missing?" },
                    { 9, "", "https://survey123.arcgis.com/share/b97c6c9ce15c4fa194d8aa4392d0e6c7", "UBUNTU Something Missing?" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Surveys",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Surveys",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Surveys",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Surveys",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Surveys",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Surveys",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "Surveys",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "Surveys",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "Surveys",
                keyColumn: "Id",
                keyValue: 9);
        }
    }
}
