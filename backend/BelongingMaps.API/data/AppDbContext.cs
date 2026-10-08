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

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Location>().HasData(
                new Location { Id = 1, Title = "Community Center", Latitude = 38.575, Longitude = -121.478 },
                new Location { Id = 2, Title = "School", Latitude = 38.576, Longitude = -121.480 }
            );
        }
    }
}
