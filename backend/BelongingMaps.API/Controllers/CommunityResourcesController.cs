using Microsoft.AspNetCore.Mvc;
using BelongingMaps.API.Data;
using BelongingMaps.API.Models;
using System.Linq;

namespace BelongingMaps.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CommunityResourcesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CommunityResourcesController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult GetCommunityResources()
        {
            return Ok(_context.CommunityResources.OrderBy(r => r.Id).ToList());
        }

        [HttpGet("{id}")]
        public IActionResult GetCommunityResource(int id)
        {
            var resource = _context.CommunityResources.FirstOrDefault(r => r.Id == id);
            if (resource == null)
                return NotFound();

            return Ok(resource);
        }

        [HttpPost]
        public IActionResult AddCommunityResource([FromBody] CommunityResource resource)
        {
            resource.Id = 0;
            _context.CommunityResources.Add(resource);
            _context.SaveChanges();
            return CreatedAtAction(nameof(GetCommunityResource), new { id = resource.Id }, resource);
        }

        [HttpPut("{id}")]
        public IActionResult EditCommunityResource(int id, [FromBody] CommunityResource updated)
        {
            var resource = _context.CommunityResources.FirstOrDefault(r => r.Id == id);
            if (resource == null)
                return NotFound();

            resource.Title = updated.Title;
            resource.Category = updated.Category;
            resource.Description = updated.Description;
            resource.IconKey = updated.IconKey;
            _context.SaveChanges();

            return Ok(resource);
        }

        [HttpDelete("{id}")]
        public IActionResult DeleteCommunityResource(int id)
        {
            var resource = _context.CommunityResources.FirstOrDefault(r => r.Id == id);
            if (resource == null)
                return NotFound();

            _context.CommunityResources.Remove(resource);
            _context.SaveChanges();

            return NoContent();
        }
    }
}
