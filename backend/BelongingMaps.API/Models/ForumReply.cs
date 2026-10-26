namespace BelongingMaps.API.Models
{
    public class ForumReply
    {
        public int Id { get; set; }
        public int ForumPostId { get; set; }
        public ForumPost? ForumPost { get; set; }
        public string Author { get; set; } = "Anonymous";
        public string Body { get; set; } = "";
        public DateTimeOffset PostedAt { get; set; }
    }
}