using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BelongingMaps.API.Migrations
{
    /// <inheritdoc />
    public partial class AddCommunityResourceLink : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Link",
                table: "CommunityResources",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "CommunityResources",
                keyColumn: "Id",
                keyValue: 1,
                column: "Link",
                value: null);

            migrationBuilder.UpdateData(
                table: "CommunityResources",
                keyColumn: "Id",
                keyValue: 2,
                column: "Link",
                value: null);

            migrationBuilder.UpdateData(
                table: "CommunityResources",
                keyColumn: "Id",
                keyValue: 3,
                column: "Link",
                value: null);

            migrationBuilder.UpdateData(
                table: "CommunityResources",
                keyColumn: "Id",
                keyValue: 4,
                column: "Link",
                value: null);

            migrationBuilder.UpdateData(
                table: "CommunityResources",
                keyColumn: "Id",
                keyValue: 5,
                column: "Link",
                value: null);

            migrationBuilder.UpdateData(
                table: "CommunityResources",
                keyColumn: "Id",
                keyValue: 6,
                column: "Link",
                value: null);

            migrationBuilder.UpdateData(
                table: "CommunityResources",
                keyColumn: "Id",
                keyValue: 7,
                column: "Link",
                value: null);

            migrationBuilder.UpdateData(
                table: "CommunityResources",
                keyColumn: "Id",
                keyValue: 8,
                column: "Link",
                value: null);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Link",
                table: "CommunityResources");
        }
    }
}
