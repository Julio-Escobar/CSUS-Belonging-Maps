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
        public DbSet<CommunityResource> CommunityResources { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Location>().HasData(
                new Location { Id = 1, Title = "Community Center", Latitude = 38.575, Longitude = -121.478 },
                new Location { Id = 2, Title = "School", Latitude = 38.576, Longitude = -121.480 }
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
        }
    }
}
