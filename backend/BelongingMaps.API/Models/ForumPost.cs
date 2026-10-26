namespace BelongingMaps.API.Models
{
    public class ForumPost
    {
        public int Id { get; set; }
        public string Title { get; set; } = "";
        public string Author { get; set; } = "";
        public string Body { get; set; } = "";
        public DateTimeOffset PostedAt { get; set; }
        public List<ForumReply> Replies { get; set; } = new();
    }
}