using System.Net;
using System.Net.Http.Json;
using BelongingMaps.API.Data;
using BelongingMaps.API.Models;
using Microsoft.Extensions.DependencyInjection;

namespace BelongingMaps.API.Tests;

// P1-332: change-password endpoint. Each test gets a fresh factory (and so a
// fresh in-memory database) because a successful change rewrites the hash.
public class ChangePasswordTests : IDisposable
{
    private const string Url = "/api/auth/change-password";
    private const string NewPassword = "brand-new-password";

    private readonly ApiFactory _factory = new();
    private readonly HttpClient _client;

    public ChangePasswordTests()
    {
        _client = _factory.CreateClient();
    }

    public void Dispose() => _factory.Dispose();

    private Task<HttpResponseMessage> Change(string username, string current, string next) =>
        _client.PostAsJsonAsync(Url, new
        {
            username,
            currentPassword = current,
            newPassword = next,
        });

    private Task<HttpResponseMessage> Login(string username, string password) =>
        _client.PostAsJsonAsync("/api/auth/login", new { username, password });

    private string StoredHash(string username)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        return db.Users.Single(u => u.Username == username).PasswordHash;
    }

    [Fact]
    public async Task ChangePassword_WithCorrectCurrentPassword_UpdatesHash()
    {
        var oldHash = StoredHash(ApiFactory.AdminUsername);

        var response = await Change(ApiFactory.AdminUsername, ApiFactory.AdminPassword, NewPassword);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var newHash = StoredHash(ApiFactory.AdminUsername);
        Assert.NotEqual(oldHash, newHash);
        Assert.NotEqual(NewPassword, newHash);
        Assert.True(BCrypt.Net.BCrypt.Verify(NewPassword, newHash));
    }

    [Fact]
    public async Task ChangePassword_ThenLogin_OnlyNewPasswordWorks()
    {
        await Change(ApiFactory.AdminUsername, ApiFactory.AdminPassword, NewPassword);

        var oldLogin = await Login(ApiFactory.AdminUsername, ApiFactory.AdminPassword);
        var newLogin = await Login(ApiFactory.AdminUsername, NewPassword);

        Assert.Equal(HttpStatusCode.Unauthorized, oldLogin.StatusCode);
        Assert.Equal(HttpStatusCode.OK, newLogin.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_WithWrongCurrentPassword_Returns401AndKeepsHash()
    {
        var oldHash = StoredHash(ApiFactory.AdminUsername);

        var response = await Change(ApiFactory.AdminUsername, "wrong-password", NewPassword);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        Assert.Equal(oldHash, StoredHash(ApiFactory.AdminUsername));
    }

    [Fact]
    public async Task ChangePassword_WithUnknownUser_Returns401()
    {
        var response = await Change("nobody", ApiFactory.AdminPassword, NewPassword);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_ForNonAdmin_Returns403()
    {
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Users.Add(new User
            {
                Username = "regular",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("regular-password"),
                Role = "User",
            });
            db.SaveChanges();
        }

        var response = await Change("regular", "regular-password", NewPassword);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Theory]
    [InlineData("short")]
    [InlineData("")]
    [InlineData(ApiFactory.AdminPassword)]
    public async Task ChangePassword_WithInvalidNewPassword_Returns400(string next)
    {
        var oldHash = StoredHash(ApiFactory.AdminUsername);

        var response = await Change(ApiFactory.AdminUsername, ApiFactory.AdminPassword, next);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal(oldHash, StoredHash(ApiFactory.AdminUsername));
    }

    [Fact]
    public async Task ChangePassword_ResponseNeverEchoesPasswords()
    {
        var response = await Change(ApiFactory.AdminUsername, ApiFactory.AdminPassword, NewPassword);
        var body = await response.Content.ReadAsStringAsync();

        Assert.DoesNotContain(ApiFactory.AdminPassword, body);
        Assert.DoesNotContain(NewPassword, body);
    }
}
