using System.ComponentModel.DataAnnotations;

namespace LawFirmApi.DTOs;

// ---- Appointment ----
public class AppointmentDto
{
    public Guid Id { get; set; }
    public Guid ClientId { get; set; }
    public string ClientName { get; set; } = string.Empty;
    public Guid LawyerId { get; set; }
    public string LawyerName { get; set; } = string.Empty;
    public Guid? CaseId { get; set; }
    public DateTime ScheduledAt { get; set; }
    public short DurationMin { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ClientPhone { get; set; }
    public string? ClientEmail { get; set; }
    public string? ClientAvatarUrl { get; set; }
}

public class AppointmentCreateRequest
{
    [Required] public Guid ClientId { get; set; }
    [Required] public Guid LawyerId { get; set; }
    public Guid? CaseId { get; set; }
    [Required] public DateTime ScheduledAt { get; set; }
    public short DurationMin { get; set; } = 30;
    public string? Description { get; set; }
}

// Đặt lịch công khai từ website marketing — người gửi CHƯA CẦN có tài khoản.
// Hệ thống tự tìm hoặc tạo mới một Client theo email, không yêu cầu mật khẩu ngay lúc này.
public class PublicAppointmentRequest
{
    [Required] public string FullName { get; set; } = string.Empty;
    [Required, EmailAddress] public string Email { get; set; } = string.Empty;
    [Required] public string Phone { get; set; } = string.Empty;
    public Guid? LawyerId { get; set; } // để trống thì hệ thống tự chọn 1 luật sư đang nhận ca
    [Required] public DateTime ScheduledAt { get; set; }
    public string? Description { get; set; }
}

public class AppointmentStatusUpdateRequest
{
    [Required] public string Status { get; set; } = string.Empty; // pending | confirmed | completed | cancelled
}

// ---- Message / Conversation ----
public class ConversationDto
{
    public Guid Id { get; set; }
    public Guid ClientId { get; set; }
    public string ClientName { get; set; } = string.Empty;
    public Guid LawyerId { get; set; }
    public string LawyerName { get; set; } = string.Empty;
    public DateTime? LastMessageAt { get; set; }
    public string? LastMessagePreview { get; set; }
}



public class StartConversationRequest
{
    public Guid? ClientId { get; set; }

    public Guid? LawyerId { get; set; }

    public Guid? CaseId { get; set; }
}

public class MessageDto
{
    public Guid Id { get; set; }
    public Guid ConversationId { get; set; }
    public Guid SenderId { get; set; }
    public string? Content { get; set; }
    public string? AttachmentUrl { get; set; }
    public DateTime SentAt { get; set; }
    public DateTime? ReadAt { get; set; }
}

public class MessageCreateRequest
{
    [Required] public Guid ConversationId { get; set; }
    public string? Content { get; set; }
    public string? AttachmentUrl { get; set; }
}

// ---- Review ----
public class ReviewDto
{
    public Guid Id { get; set; }
    public Guid LawyerId { get; set; }
    public Guid ClientId { get; set; }
    public string ClientName { get; set; } = string.Empty;
    public short Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class ReviewCreateRequest
{
    [Required] public Guid LawyerId { get; set; }
    public Guid? CaseId { get; set; }
    [Required, Range(1, 5)] public short Rating { get; set; }
    public string? Comment { get; set; }
}
