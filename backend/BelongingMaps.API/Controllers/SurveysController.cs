using Microsoft.AspNetCore.Mvc;
using BelongingMaps.API.Data;
using BelongingMaps.API.Models;
using System.Linq;

namespace BelongingMaps.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SurveysController : ControllerBase
    {
        private readonly AppDbContext _context;

        public SurveysController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult GetSurveys()
        {
            return Ok(_context.Surveys.ToList());
        }

        [HttpPost]
        public IActionResult AddSurvey([FromBody] Survey survey)
        {
            _context.Surveys.Add(survey);
            _context.SaveChanges();
            return Ok(survey);
        }

        [HttpPut("{id}")]
        public IActionResult EditSurvey(int id, [FromBody] Survey updated)
        {
            var survey = _context.Surveys.FirstOrDefault(s => s.Id == id);
            if (survey == null)
                return NotFound();

            survey.Title = updated.Title;
            survey.Description = updated.Description;
            survey.Link = updated.Link;
            _context.SaveChanges();

            return Ok(survey);
        }

        [HttpDelete("{id}")]
        public IActionResult DeleteSurvey(int id)
        {
            var survey = _context.Surveys.FirstOrDefault(s => s.Id == id);
            if (survey == null)
                return NotFound();

            _context.Surveys.Remove(survey);
            _context.SaveChanges();

            return Ok();
        }
    }
}
