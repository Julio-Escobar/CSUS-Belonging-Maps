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

        /// <summary>Returns every organization resource.</summary>
        [HttpGet]
        public IActionResult GetOrganizationResources()
        {
            return Ok(_context.OrganizationResources.ToList());
        }

        /// <summary>Returns one organization resource.</summary>
        [HttpGet("{id}")]
        public IActionResult GetOrganizationResource(int id)
        {
            var resource = _context.OrganizationResources.FirstOrDefault(r => r.Id == id);
            if (resource == null)
                return NotFound();

            return Ok(resource);
        }

        /// <summary>Creates an organization resource.</summary>
        [HttpPost]
        public IActionResult AddOrganizationResource([FromBody] OrganizationResource resource)
        {
            resource.Id = 0;
            if (!ImageStore.IsValidReference(_context, resource.ImageId))
                return BadRequest("imageId does not match an uploaded image.");

            _context.OrganizationResources.Add(resource);
            _context.SaveChanges();
            return Ok(resource);
        }

        /// <summary>Updates an organization resource.</summary>
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
            if (!ImageStore.IsValidReference(_context, updated.ImageId))
                return BadRequest("imageId does not match an uploaded image.");

            // The old image is no longer used once it's replaced or removed.
            if (resource.ImageId != updated.ImageId)
                ImageStore.Remove(_context, resource.ImageId);

            resource.OrgKey = updated.OrgKey;
            resource.ImageId = updated.ImageId;
            _context.SaveChanges();

            return Ok(resource);
        }

        /// <summary>Deletes an organization resource.</summary>
        [HttpDelete("{id}")]
        public IActionResult DeleteOrganizationResource(int id)
        {
            var resource = _context.OrganizationResources.FirstOrDefault(r => r.Id == id);
            if (resource == null)
                return NotFound();

            ImageStore.Remove(_context, resource.ImageId);
            _context.OrganizationResources.Remove(resource);
            _context.SaveChanges();
            return Ok();
        }
    }
}
