using Microsoft.AspNetCore.Mvc;
using BelongingMaps.API.Data;
using System.Linq;

namespace BelongingMaps.API.Controllers
{
    [ApiController]
    [Route("api/maps")]
    public class MapController : ControllerBase
    {
        private readonly AppDbContext _context;

        public MapController(AppDbContext context)
        {
            _context = context;
        }

        /// <summary>Returns saved map locations.</summary>
        [HttpGet]
        public IActionResult GetLocations()
        {
            var locations = _context.Locations.ToList();
            return Ok(locations);
        }
    }
}
