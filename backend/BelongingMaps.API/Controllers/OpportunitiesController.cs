using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BelongingMaps.API.Data;
using BelongingMaps.API.Models;
using System.Linq;

namespace BelongingMaps.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OpportunitiesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public OpportunitiesController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult GetOpportunities()
        {
            return Ok(_context.Opportunities.Include(o => o.Links).ToList());
        }

        [HttpGet("{id}")]
        public IActionResult GetOpportunity(int id)
        {
            var opportunity = _context.Opportunities
                .Include(o => o.Links)
                .FirstOrDefault(o => o.Id == id);
            if (opportunity == null)
                return NotFound();

            return Ok(opportunity);
        }

        [HttpPost]
        public IActionResult AddOpportunity([FromBody] Opportunity opportunity)
        {
            opportunity.Id = 0;
            foreach (var link in opportunity.Links)
                link.Id = 0;

            _context.Opportunities.Add(opportunity);
            _context.SaveChanges();
            return Ok(opportunity);
        }

        [HttpPut("{id}")]
        public IActionResult EditOpportunity(int id, [FromBody] Opportunity updated)
        {
            var opportunity = _context.Opportunities
                .Include(o => o.Links)
                .FirstOrDefault(o => o.Id == id);
            if (opportunity == null)
                return NotFound();

            opportunity.Title = updated.Title;
            opportunity.Description = updated.Description;
            opportunity.Category = updated.Category;
            opportunity.IconKey = updated.IconKey;

            // Replace the whole link list with the one sent by the client.
            _context.OpportunityLinks.RemoveRange(opportunity.Links);
            opportunity.Links = updated.Links
                .Select(l => new OpportunityLink { Name = l.Name, Url = l.Url })
                .ToList();
            _context.SaveChanges();

            return Ok(opportunity);
        }

        [HttpDelete("{id}")]
        public IActionResult DeleteOpportunity(int id)
        {
            var opportunity = _context.Opportunities.FirstOrDefault(o => o.Id == id);
            if (opportunity == null)
                return NotFound();

            _context.Opportunities.Remove(opportunity);
            _context.SaveChanges();

            return Ok();
        }
    }
}
