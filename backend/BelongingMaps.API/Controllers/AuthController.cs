using Microsoft.AspNetCore.Mvc;
using BelongingMaps.API.Data;
using System.Linq;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;

    public AuthController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet("login")]
    public IActionResult Login(string username, string password)
    {
        var user = _context.Users
            .FirstOrDefault(u => u.Username == username && u.PasswordHash == password);

        if (user == null)
            return Unauthorized();

        return Ok(new { role = user.Role });
    }
}
