using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BelongingMaps.API.Migrations
{
    /// <inheritdoc />
    public partial class AddOpportunityLinkDeadlines : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateOnly>(
                name: "Deadline",
                table: "OpportunityLinks",
                type: "date",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Deadline",
                table: "OpportunityLinks");
        }
    }
}
