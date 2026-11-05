using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace BelongingMaps.API.Migrations
{
    /// <inheritdoc />
    public partial class AddOrganizationResources : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "OrganizationResources",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Category = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IconKey = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    OrgKey = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OrganizationResources", x => x.Id);
                });

            migrationBuilder.InsertData(
                table: "OrganizationResources",
                columns: new[] { "Id", "Category", "Description", "IconKey", "OrgKey", "Title" },
                values: new object[,]
                {
                    { 1, "SOMOS", "Resources and support for SOMOS community members.", "groups", "somos", "SOMOS Student Organization" },
                    { 2, "SOMOS", "TODO: replace with real meeting schedule, e.g. \"Weekly meetings every Thursday at 5:00 PM in the Multicultural Center.\"", "event", "somos", "SOMOS Meeting Times" },
                    { 3, "SOMOS", "TODO: replace with real contact details, e.g. an email address or social media handle for the SOMOS Student Organization.", "mail", "somos", "SOMOS Contact Info" },
                    { 4, "Ummah", "Resources and support for the Ummah community.", "groups", "ummah", "Ummah Student Organization" },
                    { 5, "Ummah", "TODO: replace with real meeting schedule, e.g. \"Jummah gathering every Friday at 1:00 PM, followed by a general meeting.\"", "event", "ummah", "Ummah Meeting Times" },
                    { 6, "Ummah", "TODO: replace with real contact details, e.g. an email address or social media handle for the Ummah Student Organization.", "mail", "ummah", "Ummah Contact Info" },
                    { 7, "Ubuntu", "Resources and support for the Ubuntu community.", "groups", "ubuntu", "Ubuntu Student Organization" },
                    { 8, "Ubuntu", "TODO: replace with real meeting schedule, e.g. \"Meetings held biweekly on Wednesdays at 4:00 PM.\"", "event", "ubuntu", "Ubuntu Meeting Times" },
                    { 9, "Ubuntu", "TODO: replace with real contact details, e.g. an email address or social media handle for the Ubuntu Student Organization.", "mail", "ubuntu", "Ubuntu Contact Info" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "OrganizationResources");
        }
    }
}
