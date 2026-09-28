using System.Security.Claims;
using LawFirmApi.Data;
using LawFirmApi.DTOs;
using LawFirmApi.Helpers;
using LawFirmApi.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawFirmApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CasesController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IWebHostEnvironment _environment;

    public CasesController(
        AppDbContext db,
        IWebHostEnvironment environment)
    {
        _db = db;
        _environment = environment;
    }

    // =========================================================
    // CONSTANTS
    // =========================================================

    private static readonly string[] ValidStatuses =
    {
        "filed",
        "in_review",
        "hearing",
        "resolved"
    };

    private static readonly string[] AllowedExtensions =
    {
        ".pdf",
        ".doc",
        ".docx",
        ".jpg",
        ".jpeg",
        ".png"
    };

    private const long MaxFileSizeBytes = 10 * 1024 * 1024;


    // =========================================================
    // GET ALL CASES
    //
    // ADMIN / STAFF
    //     -> Xem toàn bộ hồ sơ
    //
    // LAWYER
    //     -> Chỉ xem hồ sơ được phân công cho mình
    //
    // GET /api/cases
    // =========================================================

    [HttpGet]
    [Authorize(Roles = "admin,staff,lawyer")]
    public async Task<ActionResult<IEnumerable<CaseDto>>> GetAll(
        [FromQuery] string? status,
        [FromQuery] Guid? clientId,
        [FromQuery] Guid? lawyerId)
    {
        var role = GetRole();

        var query = _db.Cases
            .AsNoTracking()
            .Include(c => c.Client)
                .ThenInclude(cl => cl.User)
            .Include(c => c.Lawyer)
                .ThenInclude(l => l.User)
            .Include(c => c.PracticeArea)
            .Include(c => c.Events
                .OrderBy(e => e.SortOrder))
            .Include(c => c.Documents
                .OrderByDescending(d => d.UploadedAt))
            .AsQueryable();

        // =====================================================
        // LAWYER
        // =====================================================

        if (role == "lawyer")
        {
            var currentUserId = GetUserId();

            if (currentUserId == Guid.Empty)
            {
                return Unauthorized(new
                {
                    message =
                        "Token không hợp lệ hoặc không có UserId."
                });
            }

            var lawyerExists = await _db.Lawyers
                .AsNoTracking()
                .AnyAsync(l => l.Id == currentUserId);

            if (!lawyerExists)
            {
                return BadRequest(new
                {
                    message =
                        "Tài khoản Lawyer chưa có hồ sơ luật sư."
                });
            }

            // Lawyer chỉ xem case của chính mình.
            query = query.Where(
                c => c.LawyerId == currentUserId);
        }

        // =====================================================
        // STATUS FILTER
        // =====================================================

        if (!string.IsNullOrWhiteSpace(status))
        {
            var normalizedStatus =
                status.Trim().ToLowerInvariant();

            if (!ValidStatuses.Contains(normalizedStatus))
            {
                return BadRequest(new
                {
                    message =
                        "Trạng thái không hợp lệ."
                });
            }

            query = query.Where(
                c => c.Status == normalizedStatus);
        }

        // =====================================================
        // CLIENT FILTER
        // =====================================================

        if (clientId.HasValue)
        {
            query = query.Where(
                c => c.ClientId == clientId.Value);
        }

        // =====================================================
        // LAWYER FILTER
        //
        // Admin / Staff được lọc lawyer.
        //
        // Lawyer không được dùng lawyerId
        // để xem hồ sơ của lawyer khác.
        // =====================================================

        if (lawyerId.HasValue && role != "lawyer")
        {
            query = query.Where(
                c => c.LawyerId == lawyerId.Value);
        }

        var cases = await query
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync();

        return Ok(
            cases.Select(ToDto).ToList());
    }


    // =========================================================
    // GET CASE DETAIL
    //
    // GET /api/cases/{id}
    // =========================================================

    [HttpGet("{id:guid}")]
    [Authorize(Roles = "admin,staff,lawyer")]
    public async Task<ActionResult<CaseDto>> GetById(Guid id)
    {
        var entity = await LoadCase(id);

        if (entity == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy hồ sơ vụ án."
            });
        }

        if (!await CanAccessCase(entity))
        {
            return Forbid();
        }

        return Ok(ToDto(entity));
    }


    // =========================================================
    // CREATE CASE
    //
    // POST /api/cases
    //
    // ADMIN / STAFF / LAWYER
    //
    // Lawyer chỉ được tạo case với chính mình
    // là lawyer phụ trách.
    // =========================================================

    [HttpPost]
    [Authorize(Roles = "admin,staff,lawyer")]
    public async Task<ActionResult<CaseDto>> Create(
        [FromBody] CaseCreateRequest req)
    {
        var role = GetRole();

        // =====================================================
        // LAWYER PERMISSION
        // =====================================================

        if (role == "lawyer")
        {
            var currentLawyerId =
                await GetCurrentLawyerId();

            if (!currentLawyerId.HasValue)
            {
                return Forbid();
            }

            if (req.LawyerId != currentLawyerId.Value)
            {
                return Forbid();
            }
        }

        // =====================================================
        // DOCKET
        // =====================================================

        if (string.IsNullOrWhiteSpace(req.DocketNo))
        {
            return BadRequest(new
            {
                message =
                    "Số hồ sơ không được để trống."
            });
        }

        var docketNo =
            req.DocketNo.Trim();

        // =====================================================
        // TITLE
        // =====================================================

        if (string.IsNullOrWhiteSpace(req.Title))
        {
            return BadRequest(new
            {
                message =
                    "Tên vụ án không được để trống."
            });
        }

        var title =
            req.Title.Trim();

        // =====================================================
        // DUPLICATE DOCKET
        // =====================================================

        var duplicate =
            await _db.Cases
                .AnyAsync(
                    c => c.DocketNo == docketNo);

        if (duplicate)
        {
            return Conflict(new
            {
                message =
                    "Số hồ sơ đã tồn tại."
            });
        }

        // =====================================================
        // CLIENT
        // =====================================================

        var clientExists =
            await _db.Clients
                .AnyAsync(
                    c => c.Id == req.ClientId);

        if (!clientExists)
        {
            return BadRequest(new
            {
                message =
                    "Khách hàng không tồn tại."
            });
        }

        // =====================================================
        // LAWYER
        // =====================================================

        var lawyerExists =
            await _db.Lawyers
                .AnyAsync(
                    l => l.Id == req.LawyerId);

        if (!lawyerExists)
        {
            return BadRequest(new
            {
                message =
                    "Luật sư không tồn tại."
            });
        }

        // =====================================================
        // PRACTICE AREA
        // =====================================================

        if (req.PracticeAreaId.HasValue)
        {
            var practiceAreaExists =
                await _db.PracticeAreas
                    .AnyAsync(
                        p =>
                            p.Id ==
                            req.PracticeAreaId.Value);

            if (!practiceAreaExists)
            {
                return BadRequest(new
                {
                    message =
                        "Lĩnh vực pháp lý không tồn tại."
                });
            }
        }

        // =====================================================
        // CREATE
        // =====================================================

        var entity = new Case
        {
            DocketNo = docketNo,

            Title = title,

            ClientId =
                req.ClientId,

            LawyerId =
                req.LawyerId,

            PracticeAreaId =
                req.PracticeAreaId,

            CourtName =
                string.IsNullOrWhiteSpace(
                    req.CourtName)
                    ? null
                    : req.CourtName.Trim(),

            OpenedAt =
                req.OpenedAt ??
                DateTime.UtcNow.Date,

            Status = "filed",

            NextStep =
                "Tiếp nhận hồ sơ",

            CreatedAt =
                DateTime.UtcNow,

            UpdatedAt =
                DateTime.UtcNow
        };

        _db.Cases.Add(entity);

        await _db.SaveChangesAsync();

        // =====================================================
        // LOAD SAVED CASE
        // =====================================================

        var saved =
            await LoadCase(entity.Id);

        if (saved == null)
        {
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                new
                {
                    message =
                        "Đã tạo hồ sơ nhưng không thể tải lại hồ sơ."
                });
        }

        // =====================================================
        // NOTIFY CLIENT
        // =====================================================

        NotificationHelper.Notify(
            _db,

            entity.ClientId,

            "case_update",

            "Đã tạo hồ sơ vụ án",

            $"Hồ sơ {entity.DocketNo} đã được tạo.",

            entity.Id);

        await _db.SaveChangesAsync();

        // =====================================================
        // RESPONSE
        // =====================================================

        return CreatedAtAction(
            nameof(GetById),

            new
            {
                id = entity.Id
            },

            ToDto(saved));
    }


    // =========================================================
    // CREATE CASE FROM APPOINTMENT
    //
    // POST:
    // /api/cases/from-appointment/{appointmentId}
    //
    // Dùng cho nút:
    //
    // "Tạo hồ sơ vụ án"
    //
    // trên màn hình chi tiết lịch hẹn của Lawyer.
    //
    // Luồng:
    //
    // Appointment
    //      ↓
    // ClientId
    // LawyerId
    //      ↓
    // Case
    //      ↓
    // Appointment.CaseId
    //      ↓
    // ConsultationRequest.CaseId
    //
    // =========================================================

    [HttpPost("from-appointment/{appointmentId:guid}")]
    [Authorize(Roles = "admin,staff,lawyer")]
    public async Task<ActionResult<CaseDto>> CreateFromAppointment(
        Guid appointmentId)
    {
        // =====================================================
        // ROLE
        // =====================================================

        var role = GetRole();

        // =====================================================
        // TÌM APPOINTMENT
        // =====================================================

        var appointment =
            await _db.Appointments
                .FirstOrDefaultAsync(
                    a => a.Id == appointmentId);

        if (appointment == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy lịch hẹn."
            });
        }

        // =====================================================
        // LAWYER
        //
        // Lawyer chỉ được tạo hồ sơ từ lịch
        // thuộc về chính mình.
        // =====================================================

        if (role == "lawyer")
        {
            var currentLawyerId =
                await GetCurrentLawyerId();

            if (!currentLawyerId.HasValue)
            {
                return Forbid();
            }

            if (appointment.LawyerId !=
                currentLawyerId.Value)
            {
                return Forbid();
            }
        }

        // =====================================================
        // NẾU APPOINTMENT ĐÃ CÓ CASE
        // =====================================================

        if (appointment.CaseId.HasValue)
        {
            var existingCase =
                await LoadCase(
                    appointment.CaseId.Value);

            if (existingCase != null)
            {
                return Conflict(new
                {
                    message =
                        "Lịch hẹn này đã được tạo hồ sơ vụ án.",

                    caseId =
                        existingCase.Id
                });
            }

            // Trường hợp CaseId có giá trị
            // nhưng case không còn tồn tại.
            //
            // Cho phép tạo lại.
            appointment.CaseId = null;
        }

        // =====================================================
        // CLIENT
        // =====================================================

        var client =
            await _db.Clients
                .Include(c => c.User)
                .FirstOrDefaultAsync(
                    c =>
                        c.Id ==
                        appointment.ClientId);

        if (client == null)
        {
            return BadRequest(new
            {
                message =
                    "Không tìm thấy khách hàng của lịch hẹn."
            });
        }

        // =====================================================
        // LAWYER
        // =====================================================

        var lawyer =
            await _db.Lawyers
                .Include(l => l.User)
                .FirstOrDefaultAsync(
                    l =>
                        l.Id ==
                        appointment.LawyerId);

        if (lawyer == null)
        {
            return BadRequest(new
            {
                message =
                    "Không tìm thấy luật sư của lịch hẹn."
            });
        }

        // =====================================================
        // TẠO DOCKET NUMBER
        //
        // Ví dụ:
        //
        // HS-20260928-123456
        // =====================================================

        string docketNo;

        do
        {
            docketNo =
                $"HS-{DateTime.UtcNow:yyyyMMdd}-{Random.Shared.Next(100000, 999999)}";
        }
        while (
            await _db.Cases.AnyAsync(
                c => c.DocketNo == docketNo));

        // =====================================================
        // CLIENT NAME
        // =====================================================

        var clientName =
            client.User?.FullName;

        if (string.IsNullOrWhiteSpace(clientName))
        {
            clientName = "Khách hàng";
        }

        // =====================================================
        // TITLE
        // =====================================================

        var description =
            appointment.Description?.Trim();

        string title;

        if (string.IsNullOrWhiteSpace(description))
        {
            title =
                $"Vụ việc tư vấn của {clientName}";
        }
        else
        {
            title =
                description.Length > 200
                    ? description[..200]
                    : description;
        }

        // =====================================================
        // TÌM CONSULTATION REQUEST
        //
        // Appointment hiện tại chưa có
        // ConsultationRequestId.
        //
        // Vì vậy tìm request bằng:
        //
        // ClientId
        // +
        // LawyerId
        // +
        // CaseId == null
        //
        // Lấy request mới nhất.
        // =====================================================

        var consultationRequest =
            await _db.ConsultationRequests
                .Where(r =>
                    r.ClientId ==
                        appointment.ClientId &&

                    r.LawyerId ==
                        appointment.LawyerId &&

                    r.CaseId == null)
                .OrderByDescending(
                    r => r.CreatedAt)
                .FirstOrDefaultAsync();

        // =====================================================
        // CREATE CASE
        // =====================================================

        var entity = new Case
        {
            DocketNo =
                docketNo,

            Title =
                title,

            ClientId =
                appointment.ClientId,

            LawyerId =
                appointment.LawyerId,

            PracticeAreaId =
                null,

            CourtName =
                null,

            OpenedAt =
                appointment.ScheduledAt.Date,

            Status =
                "filed",

            NextStep =
                "Tiếp nhận hồ sơ",

            CreatedAt =
                DateTime.UtcNow,

            UpdatedAt =
                DateTime.UtcNow
        };

        _db.Cases.Add(entity);

        // =====================================================
        // SAVE CASE
        // =====================================================

        await _db.SaveChangesAsync();

        // =====================================================
        // GÁN CASE CHO APPOINTMENT
        // =====================================================

        appointment.CaseId =
            entity.Id;

        // =====================================================
        // GÁN CASE CHO CONSULTATION REQUEST
        //
        // Nếu tìm được request tương ứng.
        // =====================================================

        if (consultationRequest != null)
        {
            consultationRequest.CaseId =
                entity.Id;

            consultationRequest.UpdatedAt =
                DateTime.UtcNow;
        }

        await _db.SaveChangesAsync();

        // =====================================================
        // LOAD CASE ĐẦY ĐỦ
        // =====================================================

        var saved =
            await LoadCase(entity.Id);

        if (saved == null)
        {
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                new
                {
                    message =
                        "Đã tạo hồ sơ nhưng không thể tải lại hồ sơ."
                });
        }

        // =====================================================
        // NOTIFY CLIENT
        // =====================================================

        NotificationHelper.Notify(
            _db,

            entity.ClientId,

            "case_update",

            "Đã tạo hồ sơ vụ án",

            $"Hồ sơ {entity.DocketNo} đã được tạo từ lịch tư vấn.",

            entity.Id);

        await _db.SaveChangesAsync();

        // =====================================================
        // RESPONSE
        // =====================================================

        return CreatedAtAction(
            nameof(GetById),

            new
            {
                id = entity.Id
            },

            ToDto(saved));
    }


    // =========================================================
    // UPDATE CASE
    //
    // PUT /api/cases/{id}
    //
    // ADMIN / STAFF
    //     -> Có thể sửa tất cả
    //
    // LAWYER
    //     -> Chỉ sửa case được giao cho mình
    // =========================================================

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "admin,staff,lawyer")]
    public async Task<IActionResult> Update(
        Guid id,
        [FromBody] CaseUpdateRequest req)
    {
        // =====================================================
        // STATUS
        // =====================================================

        var status =
            req.Status?
                .Trim()
                .ToLowerInvariant();

        if (string.IsNullOrWhiteSpace(status) ||
            !ValidStatuses.Contains(status))
        {
            return BadRequest(new
            {
                message =
                    "Trạng thái không hợp lệ."
            });
        }

        // =====================================================
        // LOAD
        // =====================================================

        var entity =
            await _db.Cases
                .FirstOrDefaultAsync(
                    c => c.Id == id);

        if (entity == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy hồ sơ vụ án."
            });
        }

        // =====================================================
        // PERMISSION
        // =====================================================

        if (!await CanAccessCase(entity))
        {
            return Forbid();
        }

        // =====================================================
        // TITLE
        // =====================================================

        if (!string.IsNullOrWhiteSpace(req.Title))
        {
            entity.Title =
                req.Title.Trim();
        }

        // =====================================================
        // STATUS
        // =====================================================

        entity.Status =
            status;

        // =====================================================
        // NEXT STEP
        // =====================================================

        entity.NextStep =
            string.IsNullOrWhiteSpace(req.NextStep)
                ? null
                : req.NextStep.Trim();

        // =====================================================
        // COURT
        // =====================================================

        entity.CourtName =
            string.IsNullOrWhiteSpace(req.CourtName)
                ? null
                : req.CourtName.Trim();

        // =====================================================
        // CLOSED AT
        // =====================================================

        if (status == "resolved")
        {
            entity.ClosedAt ??=
                DateTime.UtcNow;
        }
        else
        {
            entity.ClosedAt =
                req.ClosedAt;
        }

        entity.UpdatedAt =
            DateTime.UtcNow;

        await _db.SaveChangesAsync();

        // =====================================================
        // NOTIFY CLIENT
        // =====================================================

        NotificationHelper.Notify(
            _db,

            entity.ClientId,

            "case_update",

            $"Hồ sơ {entity.DocketNo} cập nhật",

            $"Trạng thái mới: {GetStatusLabel(entity.Status)}.",

            entity.Id);

        await _db.SaveChangesAsync();

        return NoContent();
    }


    // =========================================================
    // DELETE CASE
    //
    // CHỈ ADMIN
    //
    // DELETE /api/cases/{id}
    // =========================================================

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Delete(
        Guid id)
    {
        var entity =
            await _db.Cases
                .FirstOrDefaultAsync(
                    c => c.Id == id);

        if (entity == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy hồ sơ vụ án."
            });
        }

        _db.Cases.Remove(entity);

        await _db.SaveChangesAsync();

        // =====================================================
        // DELETE PHYSICAL FILES
        // =====================================================

        var webRoot =
            GetWebRoot();

        var directory =
            Path.Combine(
                webRoot,
                "uploads",
                "cases",
                id.ToString());

        if (Directory.Exists(directory))
        {
            Directory.Delete(
                directory,
                true);
        }

        return NoContent();
    }


    // =========================================================
    // ADD CASE EVENT
    //
    // POST /api/cases/{id}/events
    // =========================================================

    [HttpPost("{id:guid}/events")]
    [Authorize(Roles = "admin,staff,lawyer")]
    public async Task<ActionResult<CaseEventDto>> AddEvent(
        Guid id,
        [FromBody] CaseEventCreateRequest req)
    {
        var caseEntity =
            await _db.Cases
                .FirstOrDefaultAsync(
                    c => c.Id == id);

        if (caseEntity == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy hồ sơ vụ án."
            });
        }

        if (!await CanAccessCase(caseEntity))
        {
            return Forbid();
        }

        if (string.IsNullOrWhiteSpace(req.Title))
        {
            return BadRequest(new
            {
                message =
                    "Tên sự kiện không được để trống."
            });
        }

        var evt = new CaseEvent
        {
            CaseId =
                id,

            Title =
                req.Title.Trim(),

            EventDate =
                req.EventDate,

            Note =
                string.IsNullOrWhiteSpace(req.Note)
                    ? null
                    : req.Note.Trim(),

            IsDone =
                req.IsDone,

            SortOrder =
                req.SortOrder,

            CreatedAt =
                DateTime.UtcNow
        };

        _db.CaseEvents.Add(evt);

        caseEntity.UpdatedAt =
            DateTime.UtcNow;

        await _db.SaveChangesAsync();

        // =====================================================
        // NOTIFY CLIENT
        // =====================================================

        NotificationHelper.Notify(
            _db,

            caseEntity.ClientId,

            "case_update",

            $"Hồ sơ {caseEntity.DocketNo} có cập nhật",

            $"Sự kiện mới: {evt.Title}",

            caseEntity.Id);

        await _db.SaveChangesAsync();

        return Ok(
            ToEventDto(evt));
    }


    // =========================================================
    // UPDATE EVENT
    //
    // PUT /api/cases/events/{eventId}
    // =========================================================

    [HttpPut("events/{eventId:guid}")]
    [Authorize(Roles = "admin,staff,lawyer")]
    public async Task<IActionResult> UpdateEvent(
        Guid eventId,
        [FromBody] CaseEventUpdateRequest req)
    {
        var evt =
            await _db.CaseEvents
                .Include(e => e.Case)
                .FirstOrDefaultAsync(
                    e => e.Id == eventId);

        if (evt == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy sự kiện."
            });
        }

        if (!await CanAccessCase(evt.Case))
        {
            return Forbid();
        }

        if (string.IsNullOrWhiteSpace(req.Title))
        {
            return BadRequest(new
            {
                message =
                    "Tên sự kiện không được để trống."
            });
        }

        evt.Title =
            req.Title.Trim();

        evt.EventDate =
            req.EventDate;

        evt.Note =
            string.IsNullOrWhiteSpace(req.Note)
                ? null
                : req.Note.Trim();

        evt.IsDone =
            req.IsDone;

        evt.SortOrder =
            req.SortOrder;

        evt.Case.UpdatedAt =
            DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return NoContent();
    }


    // =========================================================
    // DELETE EVENT
    //
    // DELETE /api/cases/events/{eventId}
    // =========================================================

    [HttpDelete("events/{eventId:guid}")]
    [Authorize(Roles = "admin,staff,lawyer")]
    public async Task<IActionResult> DeleteEvent(
        Guid eventId)
    {
        var evt =
            await _db.CaseEvents
                .Include(e => e.Case)
                .FirstOrDefaultAsync(
                    e => e.Id == eventId);

        if (evt == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy sự kiện."
            });
        }

        if (!await CanAccessCase(evt.Case))
        {
            return Forbid();
        }

        evt.Case.UpdatedAt =
            DateTime.UtcNow;

        _db.CaseEvents.Remove(evt);

        await _db.SaveChangesAsync();

        return NoContent();
    }


    // =========================================================
    // TOGGLE EVENT DONE
    //
    // PATCH /api/cases/events/{eventId}/toggle-done
    // =========================================================

    [HttpPatch("events/{eventId:guid}/toggle-done")]
    [Authorize(Roles = "admin,staff,lawyer")]
    public async Task<IActionResult> ToggleEventDone(
        Guid eventId)
    {
        var evt =
            await _db.CaseEvents
                .Include(e => e.Case)
                .FirstOrDefaultAsync(
                    e => e.Id == eventId);

        if (evt == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy sự kiện."
            });
        }

        if (!await CanAccessCase(evt.Case))
        {
            return Forbid();
        }

        evt.IsDone =
            !evt.IsDone;

        evt.Case.UpdatedAt =
            DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return NoContent();
    }


    // =========================================================
    // UPLOAD DOCUMENT
    //
    // POST /api/cases/{id}/documents
    // =========================================================

    [HttpPost("{id:guid}/documents")]
    [Authorize(Roles = "admin,staff,lawyer")]
    [RequestSizeLimit(MaxFileSizeBytes)]
    public async Task<ActionResult<CaseDocumentDto>> UploadDocument(
        Guid id,
        IFormFile? file)
    {
        var caseEntity =
            await _db.Cases
                .FirstOrDefaultAsync(
                    c => c.Id == id);

        if (caseEntity == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy hồ sơ vụ án."
            });
        }

        if (!await CanAccessCase(caseEntity))
        {
            return Forbid();
        }

        // =====================================================
        // FILE
        // =====================================================

        if (file == null ||
            file.Length == 0)
        {
            return BadRequest(new
            {
                message =
                    "Chưa chọn file."
            });
        }

        if (file.Length >
            MaxFileSizeBytes)
        {
            return BadRequest(new
            {
                message =
                    "File tối đa 10MB."
            });
        }

        var extension =
            Path.GetExtension(
                file.FileName)
                .ToLowerInvariant();

        if (!AllowedExtensions.Contains(
                extension))
        {
            return BadRequest(new
            {
                message =
                    "Chỉ chấp nhận PDF, Word hoặc ảnh JPG/JPEG/PNG."
            });
        }

        // =====================================================
        // UPLOAD DIRECTORY
        // =====================================================

        var webRoot =
            GetWebRoot();

        var uploadsDir =
            Path.Combine(
                webRoot,
                "uploads",
                "cases",
                id.ToString());

        Directory.CreateDirectory(
            uploadsDir);

        // =====================================================
        // SAFE FILE NAME
        // =====================================================

        var storedFileName =
            $"{Guid.NewGuid():N}{extension}";

        var fullPath =
            Path.Combine(
                uploadsDir,
                storedFileName);

        await using (
            var stream =
                new FileStream(
                    fullPath,
                    FileMode.Create))
        {
            await file.CopyToAsync(
                stream);
        }

        // =====================================================
        // URL
        // =====================================================

        var relativeUrl =
            $"/uploads/cases/{id}/{storedFileName}";

        var absoluteUrl =
            $"{Request.Scheme}://{Request.Host}{relativeUrl}";

        // =====================================================
        // CURRENT USER
        // =====================================================

        var userId =
            GetUserId();

        if (userId == Guid.Empty)
        {
            System.IO.File.Delete(
                fullPath);

            return Unauthorized();
        }

        // =====================================================
        // CREATE DOCUMENT
        // =====================================================

        var doc = new CaseDocument
        {
            CaseId =
                id,

            UploadedBy =
                userId,

            FileName =
                Path.GetFileName(
                    file.FileName),

            FileUrl =
                absoluteUrl,

            FileType =
                extension.TrimStart('.'),

            FileSizeBytes =
                file.Length,

            UploadedAt =
                DateTime.UtcNow
        };

        _db.CaseDocuments.Add(doc);

        caseEntity.UpdatedAt =
            DateTime.UtcNow;

        await _db.SaveChangesAsync();

        // =====================================================
        // NOTIFY CLIENT
        // =====================================================

        NotificationHelper.Notify(
            _db,

            caseEntity.ClientId,

            "case_update",

            $"Hồ sơ {caseEntity.DocketNo} có tài liệu mới",

            $"Tài liệu: {doc.FileName}",

            caseEntity.Id);

        await _db.SaveChangesAsync();

        return Ok(
            ToDocumentDto(doc));
    }


    // =========================================================
    // DELETE DOCUMENT
    //
    // DELETE /api/cases/documents/{documentId}
    // =========================================================

    [HttpDelete("documents/{documentId:guid}")]
    [Authorize(Roles = "admin,staff,lawyer")]
    public async Task<IActionResult> DeleteDocument(
        Guid documentId)
    {
        var doc =
            await _db.CaseDocuments
                .Include(d => d.Case)
                .FirstOrDefaultAsync(
                    d => d.Id == documentId);

        if (doc == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy tài liệu."
            });
        }

        if (!await CanAccessCase(doc.Case))
        {
            return Forbid();
        }

        // =====================================================
        // DELETE PHYSICAL FILE
        // =====================================================

        var webRoot =
            GetWebRoot();

        var physicalPath =
            GetPhysicalFilePath(
                doc.FileUrl,
                webRoot);

        if (physicalPath != null &&
            System.IO.File.Exists(
                physicalPath))
        {
            System.IO.File.Delete(
                physicalPath);
        }

        doc.Case.UpdatedAt =
            DateTime.UtcNow;

        _db.CaseDocuments.Remove(doc);

        await _db.SaveChangesAsync();

        return NoContent();
    }


    // =========================================================
    // LOAD CASE
    // =========================================================

    private async Task<Case?> LoadCase(
        Guid id)
    {
        return await _db.Cases

            .Include(c => c.Client)
                .ThenInclude(cl => cl.User)

            .Include(c => c.Lawyer)
                .ThenInclude(l => l.User)

            .Include(c => c.PracticeArea)

            .Include(c => c.Events
                .OrderBy(e => e.SortOrder))

            .Include(c => c.Documents
                .OrderByDescending(
                    d => d.UploadedAt))

            .FirstOrDefaultAsync(
                c => c.Id == id);
    }


    // =========================================================
    // GET USER ID FROM JWT
    // =========================================================

    private Guid GetUserId()
    {
        var value =
            User.FindFirstValue(
                ClaimTypes.NameIdentifier);

        return Guid.TryParse(
            value,
            out var id)
            ? id
            : Guid.Empty;
    }


    // =========================================================
    // GET ROLE FROM JWT
    // =========================================================

    private string GetRole()
    {
        return User.FindFirstValue(
                   ClaimTypes.Role)?
                   .Trim()
                   .ToLowerInvariant()
               ?? string.Empty;
    }


    // =========================================================
    // GET CURRENT LAWYER ID
    // =========================================================

    private async Task<Guid?> GetCurrentLawyerId()
    {
        var userId =
            GetUserId();

        if (userId == Guid.Empty)
        {
            return null;
        }

        var lawyerId =
            await _db.Lawyers
                .AsNoTracking()
                .Where(
                    l => l.Id == userId)
                .Select(
                    l => (Guid?)l.Id)
                .FirstOrDefaultAsync();

        return lawyerId;
    }


    // =========================================================
    // CHECK CASE ACCESS
    //
    // ADMIN
    //     -> ALL
    //
    // STAFF
    //     -> ALL
    //
    // LAWYER
    //     -> ONLY ASSIGNED CASE
    //
    // CLIENT
    //     -> DENY
    // =========================================================

    private async Task<bool> CanAccessCase(
        Case entity)
    {
        var role =
            GetRole();

        // =====================================================
        // ADMIN
        // =====================================================

        if (role == "admin")
        {
            return true;
        }

        // =====================================================
        // STAFF
        // =====================================================

        if (role == "staff")
        {
            return true;
        }

        // =====================================================
        // LAWYER
        // =====================================================

        if (role == "lawyer")
        {
            var lawyerId =
                await GetCurrentLawyerId();

            if (!lawyerId.HasValue)
            {
                return false;
            }

            return entity.LawyerId ==
                   lawyerId.Value;
        }

        // =====================================================
        // CLIENT
        // =====================================================

        return false;
    }


    // =========================================================
    // WEB ROOT
    // =========================================================

    private string GetWebRoot()
    {
        if (!string.IsNullOrWhiteSpace(
                _environment.WebRootPath))
        {
            return _environment.WebRootPath;
        }

        return Path.Combine(
            Directory.GetCurrentDirectory(),
            "wwwroot");
    }


    // =========================================================
    // GET PHYSICAL FILE PATH
    // =========================================================

    private string? GetPhysicalFilePath(
        string? fileUrl,
        string webRoot)
    {
        if (string.IsNullOrWhiteSpace(
                fileUrl))
        {
            return null;
        }

        var relativeUrl =
            fileUrl;

        // =====================================================
        // ABSOLUTE URL
        //
        // http://localhost:5000/uploads/...
        // =====================================================

        if (Uri.TryCreate(
                fileUrl,
                UriKind.Absolute,
                out var uri))
        {
            relativeUrl =
                uri.AbsolutePath;
        }

        // =====================================================
        // NORMALIZE
        // =====================================================

        relativeUrl =
            relativeUrl
                .Split('?')[0]
                .TrimStart('/');

        if (string.IsNullOrWhiteSpace(
                relativeUrl))
        {
            return null;
        }

        // =====================================================
        // CHỈ CHO PHÉP UPLOADS
        // =====================================================

        if (!relativeUrl.StartsWith(
                "uploads/",
                StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var physicalPath =
            Path.Combine(
                webRoot,
                relativeUrl.Replace(
                    '/',
                    Path.DirectorySeparatorChar));

        var fullWebRoot =
            Path.GetFullPath(
                webRoot);

        var fullPhysicalPath =
            Path.GetFullPath(
                physicalPath);

        if (!fullPhysicalPath.StartsWith(
                fullWebRoot,
                StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        return fullPhysicalPath;
    }


    // =========================================================
    // STATUS LABEL
    // =========================================================

    private static string GetStatusLabel(
        string status)
    {
        return status switch
        {
            "filed" =>
                "Đã nộp",

            "in_review" =>
                "Đang thụ lý",

            "hearing" =>
                "Đang xét xử",

            "resolved" =>
                "Đã giải quyết",

            _ =>
                "Không xác định"
        };
    }


    // =========================================================
    // CASE DTO
    // =========================================================

    private static CaseDto ToDto(
        Case c)
    {
        return new CaseDto
        {
            Id =
                c.Id,

            DocketNo =
                c.DocketNo,

            Title =
                c.Title,

            ClientId =
                c.ClientId,

            ClientName =
                c.Client?.User?.FullName
                ?? string.Empty,

            LawyerId =
                c.LawyerId,

            LawyerName =
                c.Lawyer?.User?.FullName
                ?? string.Empty,

            PracticeAreaName =
                c.PracticeArea?.Name,

            Status =
                c.Status,

            NextStep =
                c.NextStep,

            CourtName =
                c.CourtName,

            OpenedAt =
                c.OpenedAt,

            ClosedAt =
                c.ClosedAt,

            Events =
                c.Events?
                    .Select(ToEventDto)
                    .ToList()
                ?? new List<CaseEventDto>(),

            Documents =
                c.Documents?
                    .Select(ToDocumentDto)
                    .ToList()
                ?? new List<CaseDocumentDto>()
        };
    }


    // =========================================================
    // EVENT DTO
    // =========================================================

    private static CaseEventDto ToEventDto(
        CaseEvent e)
    {
        return new CaseEventDto
        {
            Id =
                e.Id,

            Title =
                e.Title,

            EventDate =
                e.EventDate,

            Note =
                e.Note,

            IsDone =
                e.IsDone,

            SortOrder =
                e.SortOrder
        };
    }


    // =========================================================
    // DOCUMENT DTO
    // =========================================================

    private static CaseDocumentDto ToDocumentDto(
        CaseDocument d)
    {
        return new CaseDocumentDto
        {
            Id =
                d.Id,

            FileName =
                d.FileName,

            FileUrl =
                d.FileUrl,

            FileType =
                d.FileType,

            FileSizeBytes =
                d.FileSizeBytes,

            UploadedAt =
                d.UploadedAt
        };
    }
}