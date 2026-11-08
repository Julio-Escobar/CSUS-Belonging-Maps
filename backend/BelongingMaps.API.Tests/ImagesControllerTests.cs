using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using BelongingMaps.API.Models;

namespace BelongingMaps.API.Tests;

public class ImagesControllerTests : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client;

    // Smallest valid PNG header plus a little data; enough for type detection.
    private static readonly byte[] PngBytes =
    {
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    };

    private static readonly byte[] JpegBytes = { 0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10 };

    public ImagesControllerTests(ApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    private async Task<HttpResponseMessage> UploadAsync(byte[] data, string claimedType = "image/jpeg")
    {
        using var content = new MultipartFormDataContent();
        var file = new ByteArrayContent(data);
        file.Headers.ContentType = new MediaTypeHeaderValue(claimedType);
        content.Add(file, "file", "photo.jpg");
        return await _client.PostAsync("/api/images", content);
    }

    private async Task<int> UploadImageIdAsync(byte[] data)
    {
        var response = await UploadAsync(data);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<Dictionary<string, int>>();
        return body!["id"];
    }

    [Fact]
    public async Task Upload_ThenGet_ReturnsSameBytesAndDetectedType()
    {
        var id = await UploadImageIdAsync(PngBytes);

        var response = await _client.GetAsync($"/api/images/{id}");

        response.EnsureSuccessStatusCode();
        // Type comes from the file's bytes, not the "image/jpeg" the client claimed.
        Assert.Equal("image/png", response.Content.Headers.ContentType!.MediaType);
        Assert.Equal(PngBytes, await response.Content.ReadAsByteArrayAsync());
    }

    [Fact]
    public async Task Upload_RejectsFilesThatAreNotImages()
    {
        var response = await UploadAsync("not an image"u8.ToArray());

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Upload_RejectsImagesOverTwoMegabytes()
    {
        var tooBig = new byte[2 * 1024 * 1024 + 1];
        JpegBytes.CopyTo(tooBig, 0);

        var response = await UploadAsync(tooBig);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Get_UnknownImage_Returns404()
    {
        var response = await _client.GetAsync("/api/images/999999");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task CommunityResource_SavesImageId_AndRejectsUnknownImage()
    {
        var imageId = await UploadImageIdAsync(JpegBytes);

        var created = await _client.PostAsJsonAsync("/api/communityresources", new CommunityResource
        {
            Title = "With photo",
            Category = "Food",
            ImageId = imageId,
        });
        created.EnsureSuccessStatusCode();
        var resource = await created.Content.ReadFromJsonAsync<CommunityResource>();
        Assert.Equal(imageId, resource!.ImageId);

        var bad = await _client.PostAsJsonAsync("/api/communityresources", new CommunityResource
        {
            Title = "Bad photo",
            ImageId = 999999,
        });
        Assert.Equal(HttpStatusCode.BadRequest, bad.StatusCode);
    }

    [Fact]
    public async Task ReplacingOrDeletingCommunityResourceImage_DeletesTheOldImage()
    {
        var firstImage = await UploadImageIdAsync(JpegBytes);
        var secondImage = await UploadImageIdAsync(PngBytes);

        var created = await _client.PostAsJsonAsync("/api/communityresources", new CommunityResource
        {
            Title = "Photo swap",
            ImageId = firstImage,
        });
        var resource = (await created.Content.ReadFromJsonAsync<CommunityResource>())!;

        // Replace the photo: the first image is cleaned up.
        resource.ImageId = secondImage;
        (await _client.PutAsJsonAsync($"/api/communityresources/{resource.Id}", resource))
            .EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.NotFound, (await _client.GetAsync($"/api/images/{firstImage}")).StatusCode);

        // Delete the resource: its current image is cleaned up too.
        (await _client.DeleteAsync($"/api/communityresources/{resource.Id}")).EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.NotFound, (await _client.GetAsync($"/api/images/{secondImage}")).StatusCode);
    }

    [Fact]
    public async Task OrganizationResource_SavesImageId_AndRemovingItDeletesImage()
    {
        var imageId = await UploadImageIdAsync(JpegBytes);

        var created = await _client.PostAsJsonAsync("/api/organizationresources", new OrganizationResource
        {
            Title = "Org post with photo",
            Category = "SOMOS",
            OrgKey = "somos",
            ImageId = imageId,
        });
        created.EnsureSuccessStatusCode();
        var resource = (await created.Content.ReadFromJsonAsync<OrganizationResource>())!;
        Assert.Equal(imageId, resource.ImageId);

        // Remove the photo from the post.
        resource.ImageId = null;
        (await _client.PutAsJsonAsync($"/api/organizationresources/{resource.Id}", resource))
            .EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.NotFound, (await _client.GetAsync($"/api/images/{imageId}")).StatusCode);
    }
}
