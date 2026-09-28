using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LawFirmApi.Models;

public class User
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string PasswordHash { get; set; } = string.Empty;
    public string Role { get; set; } = "client"; // client | lawyer | staff | admin

    // ?nh ??i di?n: ngu?n duy nh?t cho m?i lo?i tài kho?n
    public string? AvatarUrl { get; set; }

    // Gi?i tính: "Nam" | "N?" | "Khác"
    public string? Gender { get; set; }

    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Client? Client { get; set; }
    public Lawyer? Lawyer { get; set; }
}

public class Client
{
    [Key, ForeignKey(nameof(User))]
    public Guid Id { get; set; }
    public string? IdNumber { get; set; }
    public string? Address { get; set; }
    public DateTime? DateOfBirth { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
    public ICollection<Case> Cases { get; set; } = new List<Case>();
    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
}

public class Lawyer
{
    [Key, ForeignKey(nameof(User))]
    public Guid Id { get; set; }

    // ============================
    // THÔNG TIN LU?T S?
    // ============================

    public string Title { get; set; } = string.Empty;

    public string? BarLicenseNo { get; set; }

    public short YearsExp { get; set; }

    public string? Bio { get; set; }

    // ============================
    // THÔNG TIN CÁ NHÂN
    // (?nh ??i di?n và gi?i tính n?m ? User)
    // ============================

    // ??a ch?
    public string? Address { get; set; }

    // H?c v?n
    public string? Education { get; set; }

    // Ngày sinh
    public DateTime? Birthday { get; set; }

    // ============================
    // TH?NG KÊ
    // ============================

    public decimal RatingAvg { get; set; } = 0;

    public int CasesWon { get; set; } = 0;

    public bool IsAvailable { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // ============================
    // NAVIGATION
    // ============================

    public User User { get; set; } = null!;

    public ICollection<Case> Cases { get; set; } =
        new List<Case>();

    public ICollection<LawyerPracticeArea> LawyerPracticeAreas { get; set; } =
        new List<LawyerPracticeArea>();
}

public class PracticeArea
{
    [Key]
    public short Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? IconKey { get; set; }
    public short SortOrder { get; set; }

    public ICollection<LawyerPracticeArea> LawyerPracticeAreas { get; set; } = new List<LawyerPracticeArea>();
}

public class LawyerPracticeArea
{
    public Guid LawyerId { get; set; }
    public short PracticeAreaId { get; set; }
    public bool IsPrimary { get; set; }

    public Lawyer Lawyer { get; set; } = null!;
    public PracticeArea PracticeArea { get; set; } = null!;
}

public class Case
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();
    public string DocketNo { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public Guid ClientId { get; set; }
    public Guid LawyerId { get; set; }
    public short? PracticeAreaId { get; set; }
    public string Status { get; set; } = "filed"; // filed | in_review | hearing | resolved
    public string? NextStep { get; set; }
    public string? CourtName { get; set; }
    public DateTime OpenedAt { get; set; } = DateTime.UtcNow.Date;
    public DateTime? ClosedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Client Client { get; set; } = null!;
    public Lawyer Lawyer { get; set; } = null!;
    public PracticeArea? PracticeArea { get; set; }
    public ICollection<CaseEvent> Events { get; set; } = new List<CaseEvent>();
    public ICollection<CaseDocument> Documents { get; set; } = new List<CaseDocument>();
}

public class CaseEvent
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CaseId { get; set; }
    public string Title { get; set; } = string.Empty;
    public DateTime EventDate { get; set; }
    public string? Note { get; set; }
    public bool IsDone { get; set; }
    public short SortOrder { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Case Case { get; set; } = null!;
}

public class CaseDocument
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CaseId { get; set; }
    public Guid UploadedBy { get; set; }
    public string FileName { get; set; } = string.Empty;
    public string FileUrl { get; set; } = string.Empty;
    public string? FileType { get; set; }
    public long? FileSizeBytes { get; set; }
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

    public Case Case { get; set; } = null!;
}

public class Appointment
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ClientId { get; set; }
    public Guid LawyerId { get; set; }
    public Guid? CaseId { get; set; }
    public DateTime ScheduledAt { get; set; }
    public short DurationMin { get; set; } = 30;
    public string Status { get; set; } = "pending"; // pending | confirmed | completed | cancelled
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Client Client { get; set; } = null!;
    public Lawyer Lawyer { get; set; } = null!;
    public Case? Case { get; set; }
}

public class Conversation
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ClientId { get; set; }
    public Guid LawyerId { get; set; }
    public Guid? CaseId { get; set; }
    public DateTime? LastMessageAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Client Client { get; set; } = null!;
    public Lawyer Lawyer { get; set; } = null!;
    public ICollection<Message> Messages { get; set; } = new List<Message>();
}

public class Message
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ConversationId { get; set; }
    public Guid SenderId { get; set; }
    public string? Content { get; set; }
    public string? AttachmentUrl { get; set; }
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
    public DateTime? ReadAt { get; set; }

    public Conversation Conversation { get; set; } = null!;
}

public class Review
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid LawyerId { get; set; }

    public Guid ClientId { get; set; }

    public Guid? CaseId { get; set; }

    // SQL Server tinyint -> C# byte
    public byte Rating { get; set; }

    public string? Comment { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Lawyer Lawyer { get; set; } = null!;

    public Client Client { get; set; } = null!;
}

public class Notification
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string Type { get; set; } = "system"; // case_update | appointment | message | system
    public string Title { get; set; } = string.Empty;
    public string? Body { get; set; }
    public Guid? RefId { get; set; }
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
}

public class LegalService
{
    [Key]
    public int Id { get; set; }
    public short PracticeAreaId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Detail { get; set; }
    public decimal? StartingPrice { get; set; }
    public string? IconKey { get; set; }
    public short SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public PracticeArea PracticeArea { get; set; } = null!;
}

public class ConsultationRequest
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    // Ng??i g?i yêu c?u
    public Guid ClientId { get; set; }

    // L?nh v?c pháp lu?t
    public short? PracticeAreaId { get; set; }

    // Lu?t s? ???c phân công
    public Guid? LawyerId { get; set; }

    // Thông tin yêu c?u
    public string Title { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    // low | normal | high | urgent
    public string Priority { get; set; } = "normal";

    // new | processing | completed | cancelled
    public string Status { get; set; } = "new";

    // File ?ính kèm
    public string? AttachmentUrl { get; set; }

    // V? vi?c ???c t?o t? yêu c?u t? v?n
    public Guid? CaseId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // =========================
    // Navigation
    // =========================

    public Client Client { get; set; } = null!;

    public PracticeArea? PracticeArea { get; set; }

    public Lawyer? Lawyer { get; set; }

    public Case? Case { get; set; }
}

public class FavoriteLawyer
{
    public Guid ClientId { get; set; }
    public Guid LawyerId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public Client Client { get; set; } = null!;
    public Lawyer Lawyer { get; set; } = null!;
}