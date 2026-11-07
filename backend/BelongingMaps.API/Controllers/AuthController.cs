using Microsoft.AspNetCore.Mvc;
using BelongingMaps.API.Data;
using BelongingMaps.API.Models;
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

    [HttpPost("login")]
    public IActionResult Login([FromBody] LoginRequest request)
    {
        var user = _context.Users
            .FirstOrDefault(u => u.Username == request.Username);

        if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            return Unauthorized();

        return Ok(new { role = user.Role });
    }

    public const int MinPasswordLength = 8;

    // P1-330: an admin changes their own password. The app has no tokens yet,
    // so the current password is what proves who is asking. Unknown user and
    // wrong password return the same 401 so the response doesn't leak which
    // usernames exist. Passwords are never logged or sent back.
    [HttpPost("change-password")]
    public IActionResult ChangePassword([FromBody] ChangePasswordRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Username) ||
            string.IsNullOrEmpty(request.CurrentPassword))
            return Unauthorized(new { message = "Current username or password is incorrect." });

        var user = _context.Users
            .FirstOrDefault(u => u.Username == request.Username);

        if (user == null || !BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash))
            return Unauthorized(new { message = "Current username or password is incorrect." });

        if (user.Role != "Admin")
            return StatusCode(StatusCodes.Status403Forbidden,
                new { message = "Only administrators can change their password here." });

        if (string.IsNullOrWhiteSpace(request.NewPassword) ||
            request.NewPassword.Length < MinPasswordLength)
            return BadRequest(new { message = $"New password must be at least {MinPasswordLength} characters." });

        if (request.NewPassword == request.CurrentPassword)
            return BadRequest(new { message = "New password must be different from the current password." });

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        _context.SaveChanges();

        return Ok(new { message = "Password changed." });
    }
}
