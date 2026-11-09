namespace BelongingMaps.API.Models
{
    public class LoginRequest
    {
        public string Username { get; set; } = "";
        public string Password { get; set; } = "";
    }

    // P1-330: body for POST /api/auth/change-password.
    public class ChangePasswordRequest
    {
        public string Username { get; set; } = "";
        public string CurrentPassword { get; set; } = "";
        public string NewPassword { get; set; } = "";
    }
}
