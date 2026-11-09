using BelongingMaps.API.Data;
using BelongingMaps.API.Models;
using Microsoft.AspNetCore.Mvc;

namespace BelongingMaps.API.Controllers
{
    /// <summary>
    /// Upload and download images for organization and community resources
    /// (P1-318 / P1-319). Upload first, then send the returned id as the
    /// resource's imageId.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    public class ImagesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ImagesController(AppDbContext context)
        {
            _context = context;
        }

        [HttpPost]
        [Consumes("multipart/form-data")]
        [RequestSizeLimit(ImageStore.MaxBytes + 64 * 1024)]
        public async Task<IActionResult> UploadImage(IFormFile? file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("No image was uploaded.");

            if (file.Length > ImageStore.MaxBytes)
                return BadRequest("The image is too large (max 2 MB).");

            using var stream = new MemoryStream();
            await file.CopyToAsync(stream);
            var data = stream.ToArray();

            var contentType = ImageStore.DetectContentType(data);
            if (contentType == null)
                return BadRequest("Only JPEG, PNG or WebP images are allowed.");

            var image = new StoredImage { Data = data, ContentType = contentType };
            _context.Images.Add(image);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetImage), new { id = image.Id }, new { id = image.Id });
        }

        [HttpGet("{id}")]
        public IActionResult GetImage(int id)
        {
            var image = _context.Images.FirstOrDefault(i => i.Id == id);
            if (image == null)
                return NotFound();

            // An id always points at the same bytes (a new upload gets a new
            // id), so phones can cache images for a long time.
            Response.Headers.CacheControl = "public, max-age=604800, immutable";
            return File(image.Data, image.ContentType);
        }
    }
}
