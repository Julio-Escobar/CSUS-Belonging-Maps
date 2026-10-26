using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BelongingMaps.API.Data;
using BelongingMaps.API.Models;

namespace BelongingMaps.API.Controllers
{
    public record ReplyDto(int Id, string Author, string Body, DateTimeOffset PostedAt);
    public record PostDto(int Id, string Title, string Author, string Body,
                          DateTimeOffset PostedAt, List<ReplyDto> Replies);
    public record CreatePostRequest(string Title, string Author, string Body);
    public record CreateReplyRequest(string? Author, string Body);

    [ApiController]
    [Route("api/forums")]
    public class ForumsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ForumsController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetPosts()
        {
            var posts = await _context.ForumPosts
                .OrderByDescending(p => p.PostedAt)
                .Select(p => new PostDto(
                    p.Id, p.Title, p.Author, p.Body, p.PostedAt,
                    p.Replies
                        .OrderBy(r => r.PostedAt)
                        .Select(r => new ReplyDto(r.Id, r.Author, r.Body, r.PostedAt))
                        .ToList()))
                .ToListAsync();

            return Ok(posts);
        }

        // POST api/forums
        [HttpPost]
        public async Task<IActionResult> CreatePost(CreatePostRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Title) ||
                string.IsNullOrWhiteSpace(request.Author) ||
                string.IsNullOrWhiteSpace(request.Body))
            {
                return BadRequest("Title, author and body are required.");
            }

            var post = new ForumPost
            {
                Title = request.Title.Trim(),
                Author = request.Author.Trim(),
                Body = request.Body.Trim(),
                PostedAt = DateTimeOffset.UtcNow
            };

            _context.ForumPosts.Add(post);
            await _context.SaveChangesAsync();

            return Ok(new PostDto(post.Id, post.Title, post.Author, post.Body,
                                  post.PostedAt, new List<ReplyDto>()));
        }

        [HttpPost("{postId:int}/replies")]
        public async Task<IActionResult> AddReply(int postId, CreateReplyRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Body))
                return BadRequest("Reply body is required.");

            if (!await _context.ForumPosts.AnyAsync(p => p.Id == postId))
                return NotFound();

            var reply = new ForumReply
            {
                ForumPostId = postId,
                Author = string.IsNullOrWhiteSpace(request.Author)
                    ? "Anonymous"
                    : request.Author.Trim(),
                Body = request.Body.Trim(),
                PostedAt = DateTimeOffset.UtcNow
            };

            _context.ForumReplies.Add(reply);
            await _context.SaveChangesAsync();

            return Ok(new ReplyDto(reply.Id, reply.Author, reply.Body, reply.PostedAt));
        }

        [HttpDelete("{postId:int}")]
        public async Task<IActionResult> DeletePost(int postId)
        {
            var post = await _context.ForumPosts.FindAsync(postId);
            if (post == null) return NotFound();

            _context.ForumPosts.Remove(post);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}