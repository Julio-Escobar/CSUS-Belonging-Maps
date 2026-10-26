using Microsoft.EntityFrameworkCore;
using BelongingMaps.API.Models;

namespace BelongingMaps.API.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Location> Locations { get; set; }
        public DbSet<Survey> Surveys { get; set; }
        public DbSet<Opportunity> Opportunities { get; set; }
        public DbSet<OpportunityLink> OpportunityLinks { get; set; }
        public DbSet<OrganizationResource> OrganizationResources { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Location>().HasData(
                new Location { Id = 1, Title = "Community Center", Latitude = 38.575, Longitude = -121.478 },
                new Location { Id = 2, Title = "School", Latitude = 38.576, Longitude = -121.480 }
            );

            modelBuilder.Entity<OrganizationResource>().HasData(
                new OrganizationResource { Id = 1, Title = "SOMOS Student Organization", Category = "SOMOS", Description = "Resources and support for SOMOS community members.", IconKey = "groups", OrgKey = "somos" },
                new OrganizationResource { Id = 2, Title = "SOMOS Meeting Times", Category = "SOMOS", Description = "TODO: replace with real meeting schedule, e.g. \"Weekly meetings every Thursday at 5:00 PM in the Multicultural Center.\"", IconKey = "event", OrgKey = "somos" },
                new OrganizationResource { Id = 3, Title = "SOMOS Contact Info", Category = "SOMOS", Description = "TODO: replace with real contact details, e.g. an email address or social media handle for the SOMOS Student Organization.", IconKey = "mail", OrgKey = "somos" },
                new OrganizationResource { Id = 4, Title = "Ummah Student Organization", Category = "Ummah", Description = "Resources and support for the Ummah community.", IconKey = "groups", OrgKey = "ummah" },
                new OrganizationResource { Id = 5, Title = "Ummah Meeting Times", Category = "Ummah", Description = "TODO: replace with real meeting schedule, e.g. \"Jummah gathering every Friday at 1:00 PM, followed by a general meeting.\"", IconKey = "event", OrgKey = "ummah" },
                new OrganizationResource { Id = 6, Title = "Ummah Contact Info", Category = "Ummah", Description = "TODO: replace with real contact details, e.g. an email address or social media handle for the Ummah Student Organization.", IconKey = "mail", OrgKey = "ummah" },
                new OrganizationResource { Id = 7, Title = "Ubuntu Student Organization", Category = "Ubuntu", Description = "Resources and support for the Ubuntu community.", IconKey = "groups", OrgKey = "ubuntu" },
                new OrganizationResource { Id = 8, Title = "Ubuntu Meeting Times", Category = "Ubuntu", Description = "TODO: replace with real meeting schedule, e.g. \"Meetings held biweekly on Wednesdays at 4:00 PM.\"", IconKey = "event", OrgKey = "ubuntu" },
                new OrganizationResource { Id = 9, Title = "Ubuntu Contact Info", Category = "Ubuntu", Description = "TODO: replace with real contact details, e.g. an email address or social media handle for the Ubuntu Student Organization.", IconKey = "mail", OrgKey = "ubuntu" }
            );
        }
    }
}
