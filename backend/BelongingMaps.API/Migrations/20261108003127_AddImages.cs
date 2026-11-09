using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BelongingMaps.API.Migrations
{
    /// <inheritdoc />
    public partial class AddImages : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "ImageId",
                table: "OrganizationResources",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ImageId",
                table: "CommunityResources",
                type: "int",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Images",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Data = table.Column<byte[]>(type: "varbinary(max)", nullable: false),
                    ContentType = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Images", x => x.Id);
                });

            migrationBuilder.UpdateData(
                table: "CommunityResources",
                keyColumn: "Id",
                keyValue: 1,
                column: "ImageId",
                value: null);

            migrationBuilder.UpdateData(
                table: "CommunityResources",
                keyColumn: "Id",
                keyValue: 2,
                column: "ImageId",
                value: null);

            migrationBuilder.UpdateData(
                table: "CommunityResources",
                keyColumn: "Id",
                keyValue: 3,
                column: "ImageId",
                value: null);

            migrationBuilder.UpdateData(
                table: "CommunityResources",
                keyColumn: "Id",
                keyValue: 4,
                column: "ImageId",
                value: null);

            migrationBuilder.UpdateData(
                table: "CommunityResources",
                keyColumn: "Id",
                keyValue: 5,
                column: "ImageId",
                value: null);

            migrationBuilder.UpdateData(
                table: "CommunityResources",
                keyColumn: "Id",
                keyValue: 6,
                column: "ImageId",
                value: null);

            migrationBuilder.UpdateData(
                table: "CommunityResources",
                keyColumn: "Id",
                keyValue: 7,
                column: "ImageId",
                value: null);

            migrationBuilder.UpdateData(
                table: "CommunityResources",
                keyColumn: "Id",
                keyValue: 8,
                column: "ImageId",
                value: null);

            migrationBuilder.UpdateData(
                table: "OrganizationResources",
                keyColumn: "Id",
                keyValue: 1,
                column: "ImageId",
                value: null);

            migrationBuilder.UpdateData(
                table: "OrganizationResources",
                keyColumn: "Id",
                keyValue: 2,
                column: "ImageId",
                value: null);

            migrationBuilder.UpdateData(
                table: "OrganizationResources",
                keyColumn: "Id",
                keyValue: 3,
                column: "ImageId",
                value: null);

            migrationBuilder.UpdateData(
                table: "OrganizationResources",
                keyColumn: "Id",
                keyValue: 4,
                column: "ImageId",
                value: null);

            migrationBuilder.UpdateData(
                table: "OrganizationResources",
                keyColumn: "Id",
                keyValue: 5,
                column: "ImageId",
                value: null);

            migrationBuilder.UpdateData(
                table: "OrganizationResources",
                keyColumn: "Id",
                keyValue: 6,
                column: "ImageId",
                value: null);

            migrationBuilder.UpdateData(
                table: "OrganizationResources",
                keyColumn: "Id",
                keyValue: 7,
                column: "ImageId",
                value: null);

            migrationBuilder.UpdateData(
                table: "OrganizationResources",
                keyColumn: "Id",
                keyValue: 8,
                column: "ImageId",
                value: null);

            migrationBuilder.UpdateData(
                table: "OrganizationResources",
                keyColumn: "Id",
                keyValue: 9,
                column: "ImageId",
                value: null);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Images");

            migrationBuilder.DropColumn(
                name: "ImageId",
                table: "OrganizationResources");

            migrationBuilder.DropColumn(
                name: "ImageId",
                table: "CommunityResources");
        }
    }
}
