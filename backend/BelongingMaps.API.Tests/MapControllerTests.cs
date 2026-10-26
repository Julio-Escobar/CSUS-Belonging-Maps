using System.Net;
using System.Net.Http.Json;
using BelongingMaps.API.Models;

namespace BelongingMaps.API.Tests;

public class MapControllerTests : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client;

    public MapControllerTests(ApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetMaps_ReturnsSeededLocations()
    {
        var response = await _client.GetAsync("/api/maps");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var locations = await response.Content.ReadFromJsonAsync<List<Location>>();
        Assert.NotNull(locations);
        Assert.Equal(2, locations.Count);
        Assert.Contains(locations, l => l.Title == "Community Center");
        Assert.Contains(locations, l => l.Title == "School");
    }
}
