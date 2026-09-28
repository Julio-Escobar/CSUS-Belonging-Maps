using Microsoft.EntityFrameworkCore;
using BelongingMaps.API.Data;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddControllers();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    try
    {
        DbSeeder.SeedAdmin(db);
    }
    catch (Exception ex)
    {
        app.Logger.LogWarning(ex, "Admin seeding skipped: database unavailable.");
    }
}

app.MapControllers();

app.Run();
