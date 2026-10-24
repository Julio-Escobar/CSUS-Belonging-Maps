using System.ComponentModel.DataAnnotations;

namespace BelongingMaps.API.Models
{
    public class CommunityResource
    {
        public int Id { get; set; }

        [Required]
        public string Title { get; set; } = "";

        public string Category { get; set; } = "";
        public string Description { get; set; } = "";

        // Matches the icon keys the Flutter app understands:
        // food, health, housing, education, financial, career, transportation, family.
        public string IconKey { get; set; } = "food";
    }
}
