using Microsoft.AspNetCore.Mvc;
using BelongingMaps.API.Models;

namespace BelongingMaps.API.Controllers
{
    [ApiController]
    [Route("api/maps")]
    public class MapController : ControllerBase
    {
        [HttpGet]
        public IActionResult GetLocations()
        {
            var locations = new List<Location>
            {
                new Location
                {
                    Title = "Community Center",
                    Latitude = 38.575,
                    Longitude = -121.478
                },
                new Location
                {
                    Title = "School",
                    Latitude = 38.576,
                    Longitude = -121.480
                }
            };

            return Ok(locations);
        }
    }
}