namespace BelongingMaps.API.Models
{
    public class Location
    {
        public int Id { get; set; }
        public string Title { get; set; } = "";
        public string Address { get; set; } = "";
        public string Category { get; set; } = "";
        public string Type { get; set; } = "";
        public string Website { get; set; } = "";
        public string Phone { get; set; } = "";
        public string Email { get; set; } = "";
        public string Description { get; set; } = "";
        public string ImageUrl { get; set; } = "";
        public string Instagram { get; set; } = "";
        public string Facebook { get; set; } = "";
        public string TwitterX { get; set; } = "";
        public string TikTok { get; set; } = "";
        public string LinkedIn { get; set; } = "";
        public string OrgLogo { get; set; } = "";
        public double Latitude { get; set; }
        public double Longitude { get; set; }
    }
}
