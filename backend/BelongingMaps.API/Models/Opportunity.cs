namespace BelongingMaps.API.Models
{
    public class Opportunity
    {
        public int Id { get; set; }
        public string Title { get; set; } = "";
        public string Description { get; set; } = "";
        public string Category { get; set; } = "";
        public string IconKey { get; set; } = "book";
        public List<OpportunityLink> Links { get; set; } = new();
    }

    public class OpportunityLink
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";
        public string Url { get; set; } = "";
        public int OpportunityId { get; set; }
    }
}
