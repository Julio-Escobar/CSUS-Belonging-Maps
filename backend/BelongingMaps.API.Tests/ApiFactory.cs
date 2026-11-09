using BelongingMaps.API.Data;
using BelongingMaps.API.Models;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace BelongingMaps.API.Tests;

/// <summary>
/// Starts the real API in memory, but swaps Azure SQL for the EF Core
/// in-memory provider so tests never touch the shared database.
/// </summary>
public class ApiFactory : WebApplicationFactory<Program>
{
    public const string AdminUsername = "testadmin";
    public const string AdminPassword = "test-password";

    // Each factory gets its own database so test classes don't share rows.
    private readonly string _databaseName = $"BelongingMapsTests-{Guid.NewGuid()}";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        builder.ConfigureTestServices(services =>
        {
            // Drop the SQL Server registration from Program.cs.
            services.RemoveAll<DbContextOptions<AppDbContext>>();
            services.RemoveAll<IDbContextOptionsConfiguration<AppDbContext>>();

            services.AddDbContext<AppDbContext>(options =>
                options.UseInMemoryDatabase(_databaseName));
        });
    }

    protected override void ConfigureClient(HttpClient client)
    {
        base.ConfigureClient(client);
        SeedDatabase();
    }

    private void SeedDatabase()
    {
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // EnsureCreated applies the HasData seed (the two map locations).
        db.Database.EnsureCreated();

        if (!db.Users.Any(u => u.Username == AdminUsername))
        {
            db.Users.Add(new User
            {
                Username = AdminUsername,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(AdminPassword),
                Role = "Admin",
            });
            db.SaveChanges();
        }
    }
}
