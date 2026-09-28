using System.ComponentModel.DataAnnotations;

namespace LawFirmApi.DTOs;

public class ClientDto
{
    public Guid Id { get; set; }

    public string FullName { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string? Phone { get; set; }

    public string? AvatarUrl { get; set; }

    public string? IdNumber { get; set; }

    public string? Address { get; set; }
}


// =========================================================
// CASE EVENT DTO
// =========================================================

public class CaseEventDto
{
    public Guid Id { get; set; }

    public string Title { get; set; } = string.Empty;

    public DateTime EventDate { get; set; }

    public string? Note { get; set; }

    public bool IsDone { get; set; }

    public short SortOrder { get; set; }

    // B? SUNG
    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }
}


// =========================================================
// CASE DOCUMENT DTO
// =========================================================

public class CaseDocumentDto
{
    public Guid Id { get; set; }

    public string FileName { get; set; } = string.Empty;

    public string FileUrl { get; set; } = string.Empty;

    public string? FileType { get; set; }

    public long? FileSizeBytes { get; set; }

    public DateTime UploadedAt { get; set; }

    // B? SUNG
    public Guid? UploadedBy { get; set; }

    public string? UploadedByName { get; set; }
}


// =========================================================
// CREATE CASE EVENT
// =========================================================

public class CaseEventCreateRequest
{
    [Required]
    public string Title { get; set; } = string.Empty;

    [Required]
    public DateTime EventDate { get; set; }

    public string? Note { get; set; }

    public bool IsDone { get; set; }

    public short SortOrder { get; set; }
}


// =========================================================
// UPDATE CASE EVENT
// =========================================================

public class CaseEventUpdateRequest
{
    [Required]
    public string Title { get; set; } = string.Empty;

    [Required]
    public DateTime EventDate { get; set; }

    public string? Note { get; set; }

    public bool IsDone { get; set; }

    public short SortOrder { get; set; }
}


// =========================================================
// CASE DTO
// =========================================================

public class CaseDto
{
    public Guid Id { get; set; }

    public string DocketNo { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;

    public Guid ClientId { get; set; }

    public string ClientName { get; set; } = string.Empty;

    public Guid LawyerId { get; set; }

    public string LawyerName { get; set; } = string.Empty;

    // B? SUNG
    public short? PracticeAreaId { get; set; }

    public string? PracticeAreaName { get; set; }

    public string Status { get; set; } = string.Empty;

    public string? NextStep { get; set; }

    public string? CourtName { get; set; }

    public DateTime OpenedAt { get; set; }

    public DateTime? ClosedAt { get; set; }

    public List<CaseEventDto> Events { get; set; } = new();

    public List<CaseDocumentDto> Documents { get; set; } = new();

    // B? SUNG
    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }
}


// =========================================================
// CREATE CASE
// =========================================================

public class CaseCreateRequest
{
    [Required]
    public string DocketNo { get; set; } = string.Empty;

    [Required]
    public string Title { get; set; } = string.Empty;

    [Required]
    public Guid ClientId { get; set; }

    [Required]
    public Guid LawyerId { get; set; }

    public short? PracticeAreaId { get; set; }

    public string? CourtName { get; set; }

    public DateTime? OpenedAt { get; set; }

    // B? SUNG
    public string? Status { get; set; }

    public string? NextStep { get; set; }
}


// =========================================================
// UPDATE CASE
// =========================================================

public class CaseUpdateRequest
{
    [Required]
    public string Title { get; set; } = string.Empty;

    [Required]
    public string Status { get; set; } = string.Empty;
    // filed | in_review | hearing | resolved

    public string? NextStep { get; set; }

    public string? CourtName { get; set; }

    public DateTime? ClosedAt { get; set; }

    // =====================================================
    // GI? / B? SUNG FIELD CONTROLLER ?ANG DÙNG
    // =====================================================

    public Guid? ClientId { get; set; }

    public short? PracticeAreaId { get; set; }

    public DateTime? OpenedAt { get; set; }

    // =====================================================
    // ADMIN:
    // ??i lu?t s? ph? trách
    // =====================================================

    public Guid? LawyerId { get; set; }
}


// =========================================================
// PHÂN CÔNG LU?T S?
// =========================================================

public class CaseAssignLawyerRequest
{
    [Required]
    public Guid LawyerId { get; set; }
}


// =========================================================
// THÔNG TIN PHÂN CÔNG
// =========================================================

public class CaseAssignmentDto
{
    public Guid CaseId { get; set; }

    public string DocketNo { get; set; } = string.Empty;

    public Guid LawyerId { get; set; }

    public string LawyerName { get; set; } = string.Empty;

    public DateTime AssignedAt { get; set; }
}


// =========================================================
// C?P NH?T TR?NG THÁI
// =========================================================

public class CaseStatusUpdateRequest
{
    [Required]
    public string Status { get; set; } = string.Empty;

    public string? NextStep { get; set; }

    public DateTime? ClosedAt { get; set; }
}


// =========================================================
// XÓA TÀI LI?U
// =========================================================

public class CaseDocumentDeleteRequest
{
    [Required]
    public Guid DocumentId { get; set; }
}