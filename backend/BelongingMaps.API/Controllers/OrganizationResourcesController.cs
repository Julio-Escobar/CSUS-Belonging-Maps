using BelongingMaps.API.Data;
using BelongingMaps.API.Models;
using Microsoft.AspNetCore.Mvc;

namespace BelongingMaps.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OrganizationResourcesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public OrganizationResourcesController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult GetOrganizationResources()
        {
            return Ok(_context.OrganizationResources.ToList());
        }

        [HttpGet("{id}")]
        public IActionResult GetOrganizationResource(int id)
        {
            var resource = _context.OrganizationResources.FirstOrDefault(r => r.Id == id);
            if (resource == null)
                return NotFound();

            return Ok(resource);
        }

        [HttpPost]
        public IActionResult AddOrganizationResource([FromBody] OrganizationResource resource)
        {
            resource.Id = 0;
            _context.OrganizationResources.Add(resource);
            _context.SaveChanges();
            return Ok(resource);
        }

        [HttpPut("{id}")]
        public IActionResult EditOrganizationResource(int id, [FromBody] OrganizationResource updated)
        {
            var resource = _context.OrganizationResources.FirstOrDefault(r => r.Id == id);
            if (resource == null)
                return NotFound();

            resource.Title = updated.Title;
            resource.Category = updated.Category;
            resource.Description = updated.Description;
            resource.IconKey = updated.IconKey;
            resource.OrgKey = updated.OrgKey;
            _context.SaveChanges();

            return Ok(resource);
        }

        [HttpDelete("{id}")]
        public IActionResult DeleteOrganizationResource(int id)
        {
            var resource = _context.OrganizationResources.FirstOrDefault(r => r.Id == id);
            if (resource == null)
                return NotFound();

            _context.OrganizationResources.Remove(resource);
            _context.SaveChanges();
            return Ok();
        }
    }
}