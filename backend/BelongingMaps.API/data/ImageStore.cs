using BelongingMaps.API.Models;

namespace BelongingMaps.API.Data
{
    /// <summary>
    /// Helpers shared by the controllers whose records can have an image.
    /// </summary>
    public static class ImageStore
    {
        /// <summary>Largest image the API accepts (the app shrinks photos well below this).</summary>
        public const int MaxBytes = 2 * 1024 * 1024;

        /// <summary>
        /// Works out the image type from the file's first bytes, so we never
        /// trust the type the client claims. Returns null if it isn't a
        /// JPEG, PNG or WebP.
        /// </summary>
        public static string? DetectContentType(byte[] data)
        {
            if (data.Length >= 3 && data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF)
                return "image/jpeg";

            if (data.Length >= 8 && data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E &&
                data[3] == 0x47 && data[4] == 0x0D && data[5] == 0x0A && data[6] == 0x1A && data[7] == 0x0A)
                return "image/png";

            if (data.Length >= 12 && data[0] == 'R' && data[1] == 'I' && data[2] == 'F' && data[3] == 'F' &&
                data[8] == 'W' && data[9] == 'E' && data[10] == 'B' && data[11] == 'P')
                return "image/webp";

            return null;
        }

        /// <summary>True when imageId is null (no image) or points at a stored image.</summary>
        public static bool IsValidReference(AppDbContext context, int? imageId)
        {
            return imageId == null || context.Images.Any(i => i.Id == imageId);
        }

        /// <summary>
        /// Deletes an image that a record no longer uses (it was replaced,
        /// removed, or its record was deleted). Call before SaveChanges.
        /// </summary>
        public static void Remove(AppDbContext context, int? imageId)
        {
            if (imageId == null) return;
            var image = context.Images.FirstOrDefault(i => i.Id == imageId);
            if (image != null) context.Images.Remove(image);
        }
    }
}
