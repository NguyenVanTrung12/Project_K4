public class UserAdminDto
{
    public Guid Id { get; set; }

    public string FullName { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string? Phone { get; set; }

    public string Role { get; set; } = string.Empty;

    public string? AvatarUrl { get; set; }

    public bool IsActive { get; set; }

    public DateTime CreatedAt { get; set; }
    public string? Gender { get; set; }

    public DateTime? DateOfBirth { get; set; }

    public string? Address { get; set; }
}