using Microsoft.AspNetCore.Hosting;

namespace BelongingMaps.API.Tests;

public class SwaggerTests : IClassFixture<ApiFactory>
{
    private readonly ApiFactory _factory;

    public SwaggerTests(ApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task SwaggerDocument_ListsCurrentApiControllers()
    {
        using var developmentFactory = _factory.WithWebHostBuilder(builder =>
            builder.UseEnvironment("Development"));
        using var client = developmentFactory.CreateClient();

        var pageResponse = await client.GetAsync("/swagger/index.html");
        pageResponse.EnsureSuccessStatusCode();

        var documentResponse = await client.GetAsync("/swagger/v1/swagger.json");
        var document = await documentResponse.Content.ReadAsStringAsync();

        documentResponse.EnsureSuccessStatusCode();
        Assert.Contains("/api/auth/login", document, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("/api/maps", document, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("/api/surveys", document, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("/api/opportunities", document, StringComparison.OrdinalIgnoreCase);
        Assert.Contains(
            "/api/organizationresources",
            document,
            StringComparison.OrdinalIgnoreCase);
    }
}
