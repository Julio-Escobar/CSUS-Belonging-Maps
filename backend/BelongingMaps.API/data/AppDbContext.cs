using Microsoft.EntityFrameworkCore;
using BelongingMaps.API.Models;

namespace BelongingMaps.API.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options) { }

        public DbSet<User> Users { get; set; }
    }
}
