using System.Net;
using System.Net.Http.Json;
using BelongingMaps.API.Models;

namespace BelongingMaps.API.Tests;

public class SurveysControllerTests : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client;

    public SurveysControllerTests(ApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    private async Task<Survey> CreateSurveyAsync(string title)
    {
        var response = await _client.PostAsJsonAsync("/api/surveys", new Survey
        {
            Title = title,
            Description = "A test survey",
            Link = "https://example.com/survey",
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<Survey>())!;
    }

    [Fact]
    public async Task PostSurvey_SavesItAndGetReturnsIt()
    {
        var created = await CreateSurveyAsync("Post test");

        Assert.True(created.Id > 0);
        var surveys = await _client.GetFromJsonAsync<List<Survey>>("/api/surveys");
        Assert.Contains(surveys!, s => s.Id == created.Id && s.Title == "Post test");
    }

    [Fact]
    public async Task PostSurvey_IgnoresIdFromClient()
    {
        var response = await _client.PostAsJsonAsync("/api/surveys", new Survey
        {
            Id = 12345,
            Title = "Id test",
            Link = "https://example.com",
        });

        response.EnsureSuccessStatusCode();
        var created = await response.Content.ReadFromJsonAsync<Survey>();
        Assert.NotEqual(12345, created!.Id);
    }

    [Fact]
    public async Task PutSurvey_UpdatesFields()
    {
        var created = await CreateSurveyAsync("Before edit");

        var response = await _client.PutAsJsonAsync($"/api/surveys/{created.Id}", new Survey
        {
            Title = "After edit",
            Description = "Updated",
            Link = "https://example.com/updated",
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var surveys = await _client.GetFromJsonAsync<List<Survey>>("/api/surveys");
        var saved = Assert.Single(surveys!, s => s.Id == created.Id);
        Assert.Equal("After edit", saved.Title);
        Assert.Equal("Updated", saved.Description);
        Assert.Equal("https://example.com/updated", saved.Link);
    }

    [Fact]
    public async Task PutSurvey_UnknownId_Returns404()
    {
        var response = await _client.PutAsJsonAsync("/api/surveys/99999", new Survey
        {
            Title = "Nope",
        });

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task DeleteSurvey_RemovesIt()
    {
        var created = await CreateSurveyAsync("Delete me");

        var response = await _client.DeleteAsync($"/api/surveys/{created.Id}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var surveys = await _client.GetFromJsonAsync<List<Survey>>("/api/surveys");
        Assert.DoesNotContain(surveys!, s => s.Id == created.Id);
    }

    [Fact]
    public async Task DeleteSurvey_UnknownId_Returns404()
    {
        var response = await _client.DeleteAsync("/api/surveys/99999");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
