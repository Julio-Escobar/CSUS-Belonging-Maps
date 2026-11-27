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
        public DbSet<CommunityResource> CommunityResources { get; set; }
        public DbSet<StoredImage> Images { get; set; }

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

            // Starting resources, moved from the old hardcoded list in
            // community_resources_screen.dart (P1-220).
            modelBuilder.Entity<CommunityResource>().HasData(
                new CommunityResource { Id = 1, Title = "Food Pantry", Category = "Food", IconKey = "food",
                    Description = "Free food resources available for students and community members." },
                new CommunityResource { Id = 2, Title = "Mental Health Services", Category = "Health", IconKey = "health",
                    Description = "Counseling and mental health support for students." },
                new CommunityResource { Id = 3, Title = "Housing Assistance", Category = "Housing", IconKey = "housing",
                    Description = "Resources and support for students experiencing housing insecurity." },
                new CommunityResource { Id = 4, Title = "Tutoring Center", Category = "Education", IconKey = "education",
                    Description = "Free academic tutoring and support services on campus." },
                new CommunityResource { Id = 5, Title = "Financial Aid Office", Category = "Financial", IconKey = "financial",
                    Description = "Help with scholarships, grants, and financial assistance." },
                new CommunityResource { Id = 6, Title = "Career Center", Category = "Career", IconKey = "career",
                    Description = "Job placement, resume help, and career counseling services." },
                new CommunityResource { Id = 7, Title = "Transportation Services", Category = "Transportation", IconKey = "transportation",
                    Description = "Bus passes and transportation assistance for students." },
                new CommunityResource { Id = 8, Title = "Childcare Services", Category = "Family", IconKey = "family",
                    Description = "Affordable childcare options available for student parents." }
            );

            // Starting surveys, moved from the hardcoded list in
            // surveys_screen.dart so admins can edit and delete them.
            modelBuilder.Entity<Survey>().HasData(
                new Survey { Id = 1, Title = "SOMOS Sac State", Description = "",
                    Link = "https://survey123.arcgis.com/share/56d94520eea24deaa5a1e57b3ab43e08" },
                new Survey { Id = 2, Title = "SOMOS Sac Community", Description = "",
                    Link = "https://survey123.arcgis.com/share/ffa13b155b684041ab4b4335d4ccf029" },
                new Survey { Id = 3, Title = "UMMAH Sac State", Description = "",
                    Link = "https://survey123.arcgis.com/share/9859d4081f2742449fcf4331ea9122f9" },
                new Survey { Id = 4, Title = "UMMAH Sac Community", Description = "",
                    Link = "https://survey123.arcgis.com/share/2d1fe1696b794a239cbdecdae736f289" },
                new Survey { Id = 5, Title = "Ubuntu Sac State", Description = "",
                    Link = "https://storymaps.arcgis.com/stories/0533e5adea024e10a69568c547544c07" },
                new Survey { Id = 6, Title = "Ubuntu Sac Community", Description = "",
                    Link = "https://survey123.arcgis.com/share/e4a218f5291f4fa9a31078cf8f067d84" },
                new Survey { Id = 7, Title = "SOMOS Something Missing?", Description = "",
                    Link = "https://survey123.arcgis.com/share/0b9123ed6c9f4cf6a0e1f3e076ffd5ae" },
                new Survey { Id = 8, Title = "UMMAH Something Missing?", Description = "",
                    Link = "https://survey123.arcgis.com/share/8688bd88b2e64da6bf369f4972161f2f" },
                new Survey { Id = 9, Title = "UBUNTU Something Missing?", Description = "",
                    Link = "https://survey123.arcgis.com/share/b97c6c9ce15c4fa194d8aa4392d0e6c7" }
            );
        }
    }
}
