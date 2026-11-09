namespace BelongingMaps.API.Models
{
    public class OrganizationResource
    {
        public int Id { get; set; }
        public string Title { get; set; } = "";
        public string Category { get; set; } = "";
        public string Description { get; set; } = "";
        public string IconKey { get; set; } = "groups";
        public string OrgKey { get; set; } = "";

        // Optional photo uploaded through /api/images (P1-318).
        public int? ImageId { get; set; }
    }
}