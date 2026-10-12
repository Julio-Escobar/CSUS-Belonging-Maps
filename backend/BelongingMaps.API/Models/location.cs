namespace BelongingMaps.API.Models
{
    public class Location
    {
        public int Id { get; set; }
        public string Title { get; set; } = "";
        public double Latitude { get; set; }
        public double Longitude { get; set; }
    }
}