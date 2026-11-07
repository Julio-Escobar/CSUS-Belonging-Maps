using BelongingMaps.API.Data;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BelongingMaps.API.Migrations
{
    [DbContext(typeof(AppDbContext))]
    [Migration("20261028000300_AddLocationInfoCardFields")]
    public partial class AddLocationInfoCardFields : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(name: "Address", table: "Locations", type: "nvarchar(max)", nullable: false, defaultValue: "");
            migrationBuilder.AddColumn<string>(name: "Category", table: "Locations", type: "nvarchar(max)", nullable: false, defaultValue: "");
            migrationBuilder.AddColumn<string>(name: "Description", table: "Locations", type: "nvarchar(max)", nullable: false, defaultValue: "");
            migrationBuilder.AddColumn<string>(name: "Email", table: "Locations", type: "nvarchar(max)", nullable: false, defaultValue: "");
            migrationBuilder.AddColumn<string>(name: "Facebook", table: "Locations", type: "nvarchar(max)", nullable: false, defaultValue: "");
            migrationBuilder.AddColumn<string>(name: "ImageUrl", table: "Locations", type: "nvarchar(max)", nullable: false, defaultValue: "");
            migrationBuilder.AddColumn<string>(name: "Instagram", table: "Locations", type: "nvarchar(max)", nullable: false, defaultValue: "");
            migrationBuilder.AddColumn<string>(name: "LinkedIn", table: "Locations", type: "nvarchar(max)", nullable: false, defaultValue: "");
            migrationBuilder.AddColumn<string>(name: "OrgLogo", table: "Locations", type: "nvarchar(max)", nullable: false, defaultValue: "");
            migrationBuilder.AddColumn<string>(name: "Phone", table: "Locations", type: "nvarchar(max)", nullable: false, defaultValue: "");
            migrationBuilder.AddColumn<string>(name: "TikTok", table: "Locations", type: "nvarchar(max)", nullable: false, defaultValue: "");
            migrationBuilder.AddColumn<string>(name: "TwitterX", table: "Locations", type: "nvarchar(max)", nullable: false, defaultValue: "");
            migrationBuilder.AddColumn<string>(name: "Type", table: "Locations", type: "nvarchar(max)", nullable: false, defaultValue: "");
            migrationBuilder.AddColumn<string>(name: "Website", table: "Locations", type: "nvarchar(max)", nullable: false, defaultValue: "");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(name: "Address", table: "Locations");
            migrationBuilder.DropColumn(name: "Category", table: "Locations");
            migrationBuilder.DropColumn(name: "Description", table: "Locations");
            migrationBuilder.DropColumn(name: "Email", table: "Locations");
            migrationBuilder.DropColumn(name: "Facebook", table: "Locations");
            migrationBuilder.DropColumn(name: "ImageUrl", table: "Locations");
            migrationBuilder.DropColumn(name: "Instagram", table: "Locations");
            migrationBuilder.DropColumn(name: "LinkedIn", table: "Locations");
            migrationBuilder.DropColumn(name: "OrgLogo", table: "Locations");
            migrationBuilder.DropColumn(name: "Phone", table: "Locations");
            migrationBuilder.DropColumn(name: "TikTok", table: "Locations");
            migrationBuilder.DropColumn(name: "TwitterX", table: "Locations");
            migrationBuilder.DropColumn(name: "Type", table: "Locations");
            migrationBuilder.DropColumn(name: "Website", table: "Locations");
        }
    }
}
