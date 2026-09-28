namespace LawFirmApi.DTOs;

// =========================================================
// LEGAL SERVICE
// =========================================================

public class LegalServiceDto
{
    public int Id { get; set; }

    public short PracticeAreaId { get; set; }

    public string PracticeAreaName { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;

    public string? Description { get; set; }

    public string? Detail { get; set; }

    public decimal? StartingPrice { get; set; }

    public string? IconKey { get; set; }

    public bool IsActive { get; set; }
}


// =========================================================
// CONSULTATION REQUEST
// =========================================================

public class ConsultationRequestDto
{
    public Guid Id { get; set; }

    public Guid ClientId { get; set; }

    public string ClientName { get; set; } = string.Empty;

    public string ClientEmail { get; set; } = string.Empty;

    public string? Phone { get; set; }

    public short? PracticeAreaId { get; set; }

    public string? PracticeAreaName { get; set; }

    public Guid? LawyerId { get; set; }

    public string? LawyerName { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public string Priority { get; set; } = "normal";

    public string Status { get; set; } = "new";

    public string? AttachmentUrl { get; set; }

    public Guid? CaseId { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }
}


// =========================================================
// CLIENT CREATE CONSULTATION REQUEST
// =========================================================

public class ConsultationRequestCreateRequest
{
    public string Title { get; set; } = string.Empty;

    public short? PracticeAreaId { get; set; }

    public string Description { get; set; } = string.Empty;

    public string Priority { get; set; } = "normal";

    public string? AttachmentUrl { get; set; }
}


// =========================================================
// ADMIN ASSIGN LAWYER
// =========================================================

public class ConsultationRequestAssignRequest
{
    public Guid? LawyerId { get; set; }

    public string? Status { get; set; }
}


// =========================================================
// ADMIN UPDATE CONSULTATION REQUEST
// =========================================================

public class ConsultationRequestUpdateRequest
{
    public string? Title { get; set; }

    public string? Description { get; set; }

    public short? PracticeAreaId { get; set; }

    public string? Priority { get; set; }

    public string? Status { get; set; }

    public Guid? LawyerId { get; set; }

    public string? AttachmentUrl { get; set; }
}


// =========================================================
// LAWYER UPDATE CONSULTATION REQUEST STATUS
// =========================================================

public class ConsultationRequestLawyerActionRequest
{
    public string Status { get; set; } = string.Empty;
}


// =========================================================
// USER ADMIN
// =========================================================

public class UserAdminDto
{
    public Guid Id { get; set; }

    public string FullName { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string? Phone { get; set; }

    public string Role { get; set; } = string.Empty;

    public bool IsActive { get; set; }

    public DateTime CreatedAt { get; set; }
}


// =========================================================
// USER STATUS
// =========================================================

public class UserStatusRequest
{
    public bool IsActive { get; set; }
}


// =========================================================
// DASHBOARD
// =========================================================

public class DashboardStatsDto
{
    public int TotalUsers { get; set; }

    public int TotalLawyers { get; set; }

    public int TotalClients { get; set; }

    public int TotalAppointments { get; set; }

    public int TotalCases { get; set; }

    public int TotalRequests { get; set; }

    public int PendingAppointments { get; set; }

    public int UnreadNotifications { get; set; }

    public List<DashboardPointDto> AppointmentsByDay { get; set; } = new();

    public List<DashboardPointDto> CasesByArea { get; set; } = new();
}


// =========================================================
// DASHBOARD POINT
// =========================================================

public class DashboardPointDto
{
    public string Label { get; set; } = string.Empty;

    public int Value { get; set; }
}