using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace BelongingMaps.API.Migrations
{
    /// <inheritdoc />
    public partial class AddCommunityResources : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "CommunityResources",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Category = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IconKey = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CommunityResources", x => x.Id);
                });

            migrationBuilder.InsertData(
                table: "CommunityResources",
                columns: new[] { "Id", "Category", "Description", "IconKey", "Title" },
                values: new object[,]
                {
                    { 1, "Food", "Free food resources available for students and community members.", "food", "Food Pantry" },
                    { 2, "Health", "Counseling and mental health support for students.", "health", "Mental Health Services" },
                    { 3, "Housing", "Resources and support for students experiencing housing insecurity.", "housing", "Housing Assistance" },
                    { 4, "Education", "Free academic tutoring and support services on campus.", "education", "Tutoring Center" },
                    { 5, "Financial", "Help with scholarships, grants, and financial assistance.", "financial", "Financial Aid Office" },
                    { 6, "Career", "Job placement, resume help, and career counseling services.", "career", "Career Center" },
                    { 7, "Transportation", "Bus passes and transportation assistance for students.", "transportation", "Transportation Services" },
                    { 8, "Family", "Affordable childcare options available for student parents.", "family", "Childcare Services" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "CommunityResources");
        }
    }
}
