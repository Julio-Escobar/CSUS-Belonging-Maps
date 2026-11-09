using System.Net;
using System.Net.Http.Json;
using BelongingMaps.API.Data;
using BelongingMaps.API.Models;
using Microsoft.Extensions.DependencyInjection;

namespace BelongingMaps.API.Tests;

public class MapControllerTests : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client;
    private readonly ApiFactory _factory;

    public MapControllerTests(ApiFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetMaps_ReturnsSeededLocations()
    {
        var response = await _client.GetAsync("/api/maps");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var locations = await response.Content.ReadFromJsonAsync<List<Location>>();
        Assert.NotNull(locations);
        Assert.Contains(locations, l => l.Title == "Community Center");
        Assert.Contains(locations, l => l.Title == "School");
    }

    [Fact]
    public async Task GetMaps_ReturnsEveryLocationInfoCardField()
    {
        var location = new Location
        {
            Title = "Student Health Center",
            Address = "6000 J Street",
            Category = "Health",
            Type = "Campus service",
            Website = "https://www.csus.edu/student-life/health-counseling/",
            Phone = "916-278-6461",
            Email = "health@csus.edu",
            Description = "Health services for students.",
            ImageUrl = "https://example.com/health-center.jpg",
            Instagram = "https://instagram.com/csus",
            Facebook = "https://facebook.com/csus",
            TwitterX = "https://x.com/csus",
            TikTok = "https://tiktok.com/@csus",
            LinkedIn = "https://linkedin.com/school/csus",
            OrgLogo = "assets/images/csus_logo.png",
            Latitude = 38.56091,
            Longitude = -121.42405,
        };

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Locations.Add(location);
            await db.SaveChangesAsync();
        }

        var locations = await _client.GetFromJsonAsync<List<Location>>("/api/maps");
        var returned = Assert.Single(locations!, item => item.Title == location.Title);

        Assert.Equal(location.Address, returned.Address);
        Assert.Equal(location.Category, returned.Category);
        Assert.Equal(location.Type, returned.Type);
        Assert.Equal(location.Website, returned.Website);
        Assert.Equal(location.Phone, returned.Phone);
        Assert.Equal(location.Email, returned.Email);
        Assert.Equal(location.Description, returned.Description);
        Assert.Equal(location.ImageUrl, returned.ImageUrl);
        Assert.Equal(location.Instagram, returned.Instagram);
        Assert.Equal(location.Facebook, returned.Facebook);
        Assert.Equal(location.TwitterX, returned.TwitterX);
        Assert.Equal(location.TikTok, returned.TikTok);
        Assert.Equal(location.LinkedIn, returned.LinkedIn);
        Assert.Equal(location.OrgLogo, returned.OrgLogo);
        Assert.Equal(location.Latitude, returned.Latitude);
        Assert.Equal(location.Longitude, returned.Longitude);
    }
}
