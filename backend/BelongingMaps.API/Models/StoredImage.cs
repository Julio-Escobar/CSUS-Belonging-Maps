namespace BelongingMaps.API.Models
{
    /// <summary>
    /// An image uploaded by an admin (P1-318 / P1-319). Kept in its own table
    /// so resource lists never load image bytes; resources point at it by
    /// ImageId and the app downloads it from GET /api/images/{id}.
    /// </summary>
    public class StoredImage
    {
        public int Id { get; set; }
        public byte[] Data { get; set; } = Array.Empty<byte>();
        public string ContentType { get; set; } = "image/jpeg";
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
