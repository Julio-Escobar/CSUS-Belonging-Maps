using BelongingMaps.API.Models;

namespace BelongingMaps.API.Data
{
    public static class DbSeeder
    {
        // Creates or resets the admin user from the SEED_ADMIN_PASSWORD
        // environment variable. Does nothing when the variable is not set,
        // so normal runs never touch existing accounts.
        public static void SeedAdmin(AppDbContext context)
        {
            var password = Environment.GetEnvironmentVariable("SEED_ADMIN_PASSWORD");
            if (string.IsNullOrEmpty(password)) return;

            var hash = BCrypt.Net.BCrypt.HashPassword(password);
            var admin = context.Users.FirstOrDefault(u => u.Username == "admin");

            if (admin == null)
            {
                context.Users.Add(new User
                {
                    Username = "admin",
                    PasswordHash = hash,
                    Role = "Admin",
                });
            }
            else
            {
                admin.PasswordHash = hash;
            }

            context.SaveChanges();
        }
    }
}
