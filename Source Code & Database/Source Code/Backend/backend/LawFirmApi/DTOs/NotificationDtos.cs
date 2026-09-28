namespace LawFirmApi.DTOs;

public class NotificationDto
{
    public Guid Id { get; set; }

    // Ng??i s? h?u thông báo
    public Guid UserId { get; set; }

    public string? Type { get; set; }

    public string? Title { get; set; }

    public string? Body { get; set; }

    public Guid? RefId { get; set; }

    public bool IsRead { get; set; }

    public DateTime CreatedAt { get; set; }
}