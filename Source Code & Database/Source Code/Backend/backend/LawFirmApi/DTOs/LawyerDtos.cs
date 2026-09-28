using System.ComponentModel.DataAnnotations;

namespace LawFirmApi.DTOs;

public class LawyerDto
{
    public Guid Id { get; set; }

    // ============================
    // THÔNG TIN USER
    // ============================

    public string FullName { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string? Phone { get; set; }

    // ?nh ??i di?n (l?y t? User.AvatarUrl)
    public string? AvatarUrl { get; set; }

    // Gi?i tính (l?y t? User.Gender)
    public string? Gender { get; set; }

    // ============================
    // THÔNG TIN CÁ NHÂN LU?T S?
    // ============================

    // ??a ch?
    public string? Address { get; set; }

    // H?c v?n
    public string? Education { get; set; }

    // Ngày sinh
    public DateTime? Birthday { get; set; }

    // ============================
    // THÔNG TIN NGH? NGHI?P
    // ============================

    public string Title { get; set; } = string.Empty;

    public string? BarLicenseNo { get; set; }

    public short YearsExp { get; set; }

    public string? Bio { get; set; }

    // ============================
    // TH?NG KÊ
    // ============================

    public decimal RatingAvg { get; set; }

    public int CasesWon { get; set; }

    public bool IsAvailable { get; set; }

    // ============================
    // L?NH V?C PHÁP LÝ
    // ============================

    public List<string> PracticeAreas { get; set; } = new();

    // Frontend dùng danh sách id này ?? hi?n th? và l?u l?i l?nh v?c
    public List<short> PracticeAreaIds { get; set; } = new();
}


// ============================================================
// CREATE LAWYER
// ============================================================

public class LawyerCreateRequest
{
    // ============================
    // USER
    // ============================

    [Required]
    public string FullName { get; set; } = string.Empty;

    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;

    public string? Phone { get; set; }

    [Required, MinLength(6)]
    public string Password { get; set; } = string.Empty;

    public string? Gender { get; set; }

    // ============================
    // THÔNG TIN CÁ NHÂN
    // (?nh ??i di?n upload riêng qua POST /api/users/{id}/avatar)
    // ============================

    public string? Address { get; set; }

    public string? Education { get; set; }

    public DateTime? Birthday { get; set; }

    // ============================
    // THÔNG TIN NGH? NGHI?P
    // ============================

    [Required]
    public string Title { get; set; } = string.Empty;

    public string? BarLicenseNo { get; set; }

    public short YearsExp { get; set; }

    public string? Bio { get; set; }

    public bool IsAvailable { get; set; } = true;

    // ============================
    // L?NH V?C PHÁP LÝ
    // ============================

    public List<short> PracticeAreaIds { get; set; } = new();
}


// ============================================================
// UPDATE LAWYER
// ============================================================

public class LawyerUpdateRequest
{
    // ============================
    // USER
    // ============================

    public string FullName { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string? Phone { get; set; }

    public string? Gender { get; set; }

    // ============================
    // THÔNG TIN CÁ NHÂN
    // (?nh ??i di?n upload riêng qua POST /api/users/{id}/avatar)
    // ============================

    public string? Address { get; set; }

    public string? Education { get; set; }

    public DateTime? Birthday { get; set; }

    // ============================
    // THÔNG TIN NGH? NGHI?P
    // ============================

    public string Title { get; set; } = string.Empty;

    public string? BarLicenseNo { get; set; }

    public short YearsExp { get; set; }

    public string? Bio { get; set; }

    public bool IsAvailable { get; set; }

    // ============================
    // L?NH V?C PHÁP LÝ
    // ============================

    public List<short>? PracticeAreaIds { get; set; }
}


// ============================================================
// PRACTICE AREA
// ============================================================

public class PracticeAreaDto
{
    public short Id { get; set; }

    public string Name { get; set; } = string.Empty;

    public string? IconKey { get; set; }

    public short SortOrder { get; set; }
}