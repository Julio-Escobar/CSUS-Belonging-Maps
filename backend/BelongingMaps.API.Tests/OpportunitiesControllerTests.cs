using System.Net.Http.Json;
using BelongingMaps.API.Models;

namespace BelongingMaps.API.Tests;

public class OpportunitiesControllerTests : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client;

    public OpportunitiesControllerTests(ApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task OpportunityLinks_SaveAndClearAnOptionalDeadline()
    {
        var createdResponse = await _client.PostAsJsonAsync("/api/opportunities", new Opportunity
        {
            Title = "Deadline test",
            Description = "Verifies date-only persistence.",
            Links =
            {
                new OpportunityLink
                {
                    Name = "Apply",
                    Url = "https://example.com/apply",
                    Deadline = new DateOnly(2026, 11, 15),
                },
            },
        });
        createdResponse.EnsureSuccessStatusCode();
        var created = (await createdResponse.Content.ReadFromJsonAsync<Opportunity>())!;
        Assert.Equal(new DateOnly(2026, 11, 15), created.Links.Single().Deadline);

        created.Links.Single().Deadline = null;
        var updatedResponse = await _client.PutAsJsonAsync(
            $"/api/opportunities/{created.Id}",
            created);
        updatedResponse.EnsureSuccessStatusCode();

        var fetched = (await _client.GetFromJsonAsync<Opportunity>(
            $"/api/opportunities/{created.Id}"))!;
        Assert.Null(fetched.Links.Single().Deadline);
    }
}
