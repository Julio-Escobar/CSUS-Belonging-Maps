using System.Net.Http.Json;
using BelongingMaps.API.Models;

namespace BelongingMaps.API.Tests;

public class CommunityResourcesControllerTests : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client;

    public CommunityResourcesControllerTests(ApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task CommunityResource_LinkIsOptional_AndCanBeSetAndCleared()
    {
        var createdResponse = await _client.PostAsJsonAsync("/api/communityresources", new CommunityResource
        {
            Title = "Link test",
            Category = "Education",
            Description = "Checks optional link persistence.",
            Link = "https://example.edu/help",
        });
        createdResponse.EnsureSuccessStatusCode();
        var created = (await createdResponse.Content.ReadFromJsonAsync<CommunityResource>())!;
        Assert.Equal("https://example.edu/help", created.Link);

        created.Link = null;
        var updatedResponse = await _client.PutAsJsonAsync(
            $"/api/communityresources/{created.Id}",
            created);
        updatedResponse.EnsureSuccessStatusCode();

        var fetched = (await _client.GetFromJsonAsync<CommunityResource>(
            $"/api/communityresources/{created.Id}"))!;
        Assert.Null(fetched.Link);
    }

    [Fact]
    public async Task CommunityResource_BlankLink_IsStoredAsNull()
    {
        var createdResponse = await _client.PostAsJsonAsync("/api/communityresources", new CommunityResource
        {
            Title = "Blank link test",
            Link = "   ",
        });
        createdResponse.EnsureSuccessStatusCode();

        var created = (await createdResponse.Content.ReadFromJsonAsync<CommunityResource>())!;
        Assert.Null(created.Link);
    }
}
