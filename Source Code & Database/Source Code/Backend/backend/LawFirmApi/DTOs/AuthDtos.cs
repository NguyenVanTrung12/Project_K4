using System.ComponentModel.DataAnnotations;

namespace LawFirmApi.DTOs;

public class RegisterRequest
{
    [Required] public string FullName { get; set; } = string.Empty;
    [Required, EmailAddress] public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    [Required, MinLength(6)] public string Password { get; set; } = string.Empty;
    // "client" hoặc "lawyer" — role quản trị (staff/admin) chỉ được tạo bởi admin
    public string Role { get; set; } = "client";
}

public class LoginRequest
{
    [Required, EmailAddress] public string Email { get; set; } = string.Empty;
    [Required] public string Password { get; set; } = string.Empty;
}

public class AuthResponse
{
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public UserDto User { get; set; } = null!;
}

public class UserDto
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string Role { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
}
