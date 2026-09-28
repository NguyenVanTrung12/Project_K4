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
public class AppointmentsController : ControllerBase
{
    private readonly AppDbContext _db;

    public AppointmentsController(AppDbContext db)
    {
        _db = db;
    }

    // =========================================================
    // CÁC TRẠNG THÁI CỦA APPOINTMENT
    // =========================================================

    private static readonly string[] ValidStatuses =
    {
        "pending",
        "confirmed",
        "completed",
        "cancelled"
    };

    // =========================================================
    // GET: /api/appointments
    // =========================================================

    [HttpGet]
    public async Task<ActionResult<IEnumerable<AppointmentDto>>> GetAll(
        [FromQuery] DateTime? date)
    {
        var query = _db.Appointments
            .Include(a => a.Client)
                .ThenInclude(c => c.User)
            .Include(a => a.Lawyer)
                .ThenInclude(l => l.User)
            .AsQueryable();

        var role = User.FindFirstValue(ClaimTypes.Role);
        var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdValue, out var userId))
        {
            return Unauthorized(new
            {
                message = "Token không hợp lệ."
            });
        }

        // =====================================================
        // CLIENT
        // =====================================================

        if (role == "client")
        {
            query = query.Where(a => a.ClientId == userId);
        }

        // =====================================================
        // LAWYER
        // Lawyer chỉ xem lịch của chính mình
        // =====================================================

        else if (role == "lawyer")
        {
            query = query.Where(a => a.LawyerId == userId);
        }

        // =====================================================
        // ADMIN / STAFF
        // Xem toàn bộ
        // =====================================================

        if (date.HasValue)
        {
            query = query.Where(a =>
                a.ScheduledAt.Date == date.Value.Date);
        }

        var items = await query
            .OrderBy(a => a.ScheduledAt)
            .ToListAsync();

        return Ok(items.Select(ToDto));
    }

    // =========================================================
    // GET: /api/appointments/availability
    // =========================================================

    [HttpGet("availability")]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<string>>> GetAvailability(
        Guid lawyerId,
        DateTime date)
    {
        var booked = await _db.Appointments
            .Where(a =>
                a.LawyerId == lawyerId &&
                a.ScheduledAt.Date == date.Date &&
                a.Status != "cancelled")
            .Select(a => a.ScheduledAt.ToString("HH:mm"))
            .ToListAsync();

        var allSlots = new[]
        {
            "08:30",
            "10:00",
            "13:30",
            "15:00",
            "16:30"
        };

        return Ok(allSlots.Except(booked));
    }

    // =========================================================
    // POST: /api/appointments
    //
    // Khách hàng đặt lịch
    //
    // Tạo:
    // 1. Appointment
    // 2. ConsultationRequest
    //
    // Không tạo Case
    // =========================================================

    [HttpPost]
    public async Task<ActionResult<AppointmentDto>> Create(
        AppointmentCreateRequest req)
    {
        // =====================================================
        // KIỂM TRA CLIENT
        // =====================================================

        var clientExists = await _db.Clients
            .AnyAsync(c => c.Id == req.ClientId);

        if (!clientExists)
        {
            return BadRequest(new
            {
                message = "Khách hàng không tồn tại."
            });
        }

        // =====================================================
        // KIỂM TRA LAWYER
        // =====================================================

        var lawyerExists = await _db.Lawyers
            .AnyAsync(l => l.Id == req.LawyerId);

        if (!lawyerExists)
        {
            return BadRequest(new
            {
                message = "Luật sư không tồn tại."
            });
        }

        // =====================================================
        // KIỂM TRA TRÙNG LỊCH
        // =====================================================

        var conflict = await _db.Appointments.AnyAsync(a =>
            a.LawyerId == req.LawyerId &&
            a.ScheduledAt == req.ScheduledAt &&
            a.Status != "cancelled");

        if (conflict)
        {
            return Conflict(new
            {
                message = "Khung giờ này đã có người đặt."
            });
        }

        // =====================================================
        // TẠO APPOINTMENT
        // =====================================================

        var appointment = new Appointment
        {
            ClientId = req.ClientId,
            LawyerId = req.LawyerId,

            CaseId = req.CaseId,

            ScheduledAt = req.ScheduledAt,

            DurationMin = req.DurationMin,

            Description = req.Description,

            // Đảm bảo trạng thái ban đầu
            Status = "pending"
        };

        _db.Appointments.Add(appointment);

        // =====================================================
        // TẠO CONSULTATION REQUEST
        // =====================================================

        var consultationRequest = new ConsultationRequest
        {
            ClientId = req.ClientId,

            LawyerId = req.LawyerId,

            PracticeAreaId = null,

            Title = string.IsNullOrWhiteSpace(req.Description)
                ? "Yêu cầu tư vấn pháp lý"
                : req.Description.Length > 200
                    ? req.Description[..200]
                    : req.Description,

            Description = string.IsNullOrWhiteSpace(req.Description)
                ? "Khách hàng đăng ký lịch tư vấn."
                : req.Description,

            Priority = "normal",

            // Giá trị hiện tại của hệ thống
            Status = "new",

            AttachmentUrl = null,

            CaseId = null,

            CreatedAt = DateTime.UtcNow,

            UpdatedAt = DateTime.UtcNow
        };

        _db.ConsultationRequests.Add(consultationRequest);

        // =====================================================
        // SAVE
        // =====================================================

        await _db.SaveChangesAsync();

        // =====================================================
        // THÔNG BÁO LUẬT SƯ
        // =====================================================

        NotificationHelper.Notify(
            _db,
            req.LawyerId,
            "consultation",
            "Có yêu cầu tư vấn mới",
            $"Khách hàng đã đặt lịch tư vấn ngày {req.ScheduledAt:dd/MM/yyyy HH:mm}.",
            consultationRequest.Id
        );

        await _db.SaveChangesAsync();

        // =====================================================
        // LẤY APPOINTMENT ĐẦY ĐỦ
        // =====================================================

        var saved = await _db.Appointments
            .Include(a => a.Client)
                .ThenInclude(c => c.User)
            .Include(a => a.Lawyer)
                .ThenInclude(l => l.User)
            .FirstAsync(a => a.Id == appointment.Id);

        return Ok(ToDto(saved));
    }

    // =========================================================
    // POST: /api/appointments/public
    //
    // Đặt lịch từ website
    // BẮT BUỘC CLIENT ĐĂNG NHẬP
    // =========================================================

    [HttpPost("public")]
    [Authorize(Roles = "client")]
    public async Task<ActionResult<AppointmentDto>> CreatePublic(
        PublicAppointmentRequest req)
    {
        // =====================================================
        // LẤY USER ID TỪ TOKEN
        // =====================================================

        var userIdValue =
            User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdValue, out var userId))
        {
            return Unauthorized(new
            {
                message = "Token không hợp lệ hoặc đã hết hạn."
            });
        }

        // =====================================================
        // KIỂM TRA CLIENT
        // =====================================================

        var client = await _db.Clients
            .Include(c => c.User)
            .FirstOrDefaultAsync(c => c.Id == userId);

        if (client is null)
        {
            return Forbid();
        }

        // =====================================================
        // KIỂM TRA LAWYER
        // =====================================================

        if (req.LawyerId is null)
        {
            return BadRequest(new
            {
                message = "Vui lòng chọn luật sư trước khi đặt lịch."
            });
        }

        var lawyer = await _db.Lawyers
            .FirstOrDefaultAsync(l =>
                l.Id == req.LawyerId.Value &&
                l.IsAvailable);

        if (lawyer is null)
        {
            return BadRequest(new
            {
                message = "Luật sư không tồn tại hoặc hiện không nhận lịch."
            });
        }

        // =====================================================
        // KIỂM TRA TRÙNG LỊCH
        // =====================================================

        var conflict = await _db.Appointments.AnyAsync(a =>
            a.LawyerId == req.LawyerId.Value &&
            a.ScheduledAt == req.ScheduledAt &&
            a.Status != "cancelled");

        if (conflict)
        {
            return Conflict(new
            {
                message = "Khung giờ này đã có người đặt."
            });
        }

        // =====================================================
        // TẠO APPOINTMENT
        // =====================================================

        var appointment = new Appointment
        {
            ClientId = client.Id,
            LawyerId = req.LawyerId.Value,
            ScheduledAt = req.ScheduledAt,
            Description = req.Description,
            Status = "pending"
        };

        _db.Appointments.Add(appointment);

        // =====================================================
        // TẠO CONSULTATION REQUEST
        // =====================================================

        var consultationRequest = new ConsultationRequest
        {
            ClientId = client.Id,
            LawyerId = req.LawyerId.Value,
            PracticeAreaId = null,

            Title = string.IsNullOrWhiteSpace(req.Description)
                ? "Yêu cầu tư vấn pháp lý"
                : req.Description.Length > 200
                    ? req.Description[..200]
                    : req.Description,

            Description = string.IsNullOrWhiteSpace(req.Description)
                ? "Khách hàng đăng ký lịch tư vấn từ website."
                : req.Description,

            Priority = "normal",
            Status = "new",
            AttachmentUrl = null,
            CaseId = null,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _db.ConsultationRequests.Add(consultationRequest);

        // =====================================================
        // SAVE
        // =====================================================

        await _db.SaveChangesAsync();

        // =====================================================
        // THÔNG BÁO LAWYER
        // =====================================================

        var clientName = client.User?.FullName;

        NotificationHelper.Notify(
            _db,
            req.LawyerId.Value,
            "appointment",
            "Có yêu cầu đặt lịch mới từ website",
            $"{(string.IsNullOrWhiteSpace(clientName) ? "Khách hàng" : clientName)} — {req.ScheduledAt:dd/MM/yyyy HH:mm}",
            appointment.Id
        );

        await _db.SaveChangesAsync();

        // =====================================================
        // LẤY APPOINTMENT
        // =====================================================

        var saved = await _db.Appointments
            .Include(a => a.Client)
                .ThenInclude(c => c.User)
            .Include(a => a.Lawyer)
                .ThenInclude(l => l.User)
            .FirstAsync(a => a.Id == appointment.Id);

        return Ok(ToDto(saved));
    }

    // =========================================================
    // PATCH: /api/appointments/{id}/status
    //
    // ADMIN / STAFF / LAWYER
    //
    // Đây là phần ĐÃ SỬA
    // =========================================================

    [HttpPatch("{id:guid}/status")]
    [Authorize(Roles = "admin,staff,lawyer,client")]
    public async Task<IActionResult> UpdateStatus(
        Guid id,
        AppointmentStatusUpdateRequest req)
    {
        // =====================================================
        // KIỂM TRA STATUS
        // =====================================================

        var newStatus = req.Status?
            .Trim()
            .ToLower();

        if (string.IsNullOrWhiteSpace(newStatus))
        {
            return BadRequest(new
            {
                message = "Trạng thái không được để trống."
            });
        }

        if (!ValidStatuses.Contains(newStatus))
        {
            return BadRequest(new
            {
                message = "Trạng thái không hợp lệ.",
                allowedStatuses = ValidStatuses
            });
        }

        // =====================================================
        // TÌM APPOINTMENT
        // =====================================================

        var entity =
            await _db.Appointments
                .FirstOrDefaultAsync(a => a.Id == id);

        if (entity is null)
        {
            return NotFound(new
            {
                message = "Không tìm thấy lịch hẹn."
            });
        }

        // =====================================================
        // LẤY ROLE
        // =====================================================

        var role =
            User.FindFirstValue(ClaimTypes.Role);
        if (role == "client")
        {
            var currentUserIdValue =
                User.FindFirstValue(
                    ClaimTypes.NameIdentifier);

            if (!Guid.TryParse(
                    currentUserIdValue,
                    out var currentUserId))
            {
                return Unauthorized(new
                {
                    message = "Token không hợp lệ."
                });
            }

            // Client chỉ được thao tác trên lịch của chính mình
            if (entity.ClientId != currentUserId)
            {
                return Forbid();
            }

            // Client chỉ được hủy lịch đang chờ xác nhận
            if (entity.Status != "pending")
            {
                return BadRequest(new
                {
                    message =
                        "Chỉ có thể hủy lịch đang chờ xác nhận."
                });
            }

            // Client chỉ được chuyển sang cancelled
            if (newStatus != "cancelled")
            {
                return BadRequest(new
                {
                    message =
                        "Bạn chỉ có thể hủy lịch tư vấn."
                });
            }
        }
        // =====================================================
        // LAWYER
        //
        // Chỉ được cập nhật lịch của chính mình
        // =====================================================

        if (role == "lawyer")
        {
            var currentUserIdValue =
                User.FindFirstValue(
                    ClaimTypes.NameIdentifier);

            if (!Guid.TryParse(
                    currentUserIdValue,
                    out var currentUserId))
            {
                return Unauthorized(new
                {
                    message = "Token không hợp lệ."
                });
            }

            if (entity.LawyerId != currentUserId)
            {
                return Forbid();
            }
        }

        // =====================================================
        // LƯU TRẠNG THÁI CŨ
        // =====================================================

        var oldStatus = entity.Status;

        // =====================================================
        // CẬP NHẬT APPOINTMENT
        // =====================================================

        entity.Status = newStatus;

        // =====================================================
        // QUAN TRỌNG
        //
        // KHÔNG cập nhật ConsultationRequest.Status ở đây.
        //
        // Lý do:
        // ConsultationRequest có CHECK constraint riêng.
        // Appointment và ConsultationRequest là 2 nghiệp vụ
        // khác nhau.
        //
        // Việc cập nhật:
        //
        // confirmed -> in_progress
        //
        // trước đây làm SQL Server báo:
        //
        // CK_ConsultationRequests_Status
        //
        // =====================================================

        await _db.SaveChangesAsync();

        // =====================================================
        // THÔNG BÁO CLIENT
        // =====================================================

        var statusLabel = newStatus switch
        {
            "pending" =>
                "đang chờ xác nhận",

            "confirmed" =>
                "đã được xác nhận",

            "completed" =>
                "đã hoàn tất",

            "cancelled" =>
                "đã bị huỷ",

            _ =>
                "đã được cập nhật"
        };

        NotificationHelper.Notify(
            _db,

            entity.ClientId,

            "appointment",

            "Cập nhật lịch tư vấn",

            $"Lịch hẹn ngày {entity.ScheduledAt:dd/MM/yyyy HH:mm} {statusLabel}.",

            entity.Id
        );

        await _db.SaveChangesAsync();

        // =====================================================
        // TRẢ KẾT QUẢ
        // =====================================================

        return Ok(new
        {
            message = "Cập nhật trạng thái lịch hẹn thành công.",

            appointmentId = entity.Id,

            oldStatus = oldStatus,

            status = entity.Status
        });
    }

    // =========================================================
    // DTO
    // =========================================================


    // =========================================================
    // GET: /api/lawyers/{lawyerId}/clients
    //
    // ADMIN:
    //   Có thể xem khách hàng của bất kỳ Lawyer nào.
    //
    // LAWYER:
    //   Chỉ được xem khách hàng của chính mình.
    //
    // Quan hệ:
    //   Lawyer -> Appointment -> Client
    // =========================================================

    [HttpGet("~/api/lawyers/{lawyerId:guid}/clients")]
    [Authorize(Roles = "admin,lawyer")]
    public async Task<IActionResult> GetClientsByLawyer(Guid lawyerId)
    {
        // =====================================================
        // LẤY ROLE + USER ID TỪ TOKEN
        // =====================================================

        var role = User.FindFirstValue(ClaimTypes.Role);

        var currentUserIdValue =
            User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(
                currentUserIdValue,
                out var currentUserId))
        {
            return Unauthorized(new
            {
                message = "Token không hợp lệ."
            });
        }

        // =====================================================
        // LAWYER
        //
        // Lawyer chỉ được xem khách hàng của chính mình.
        // =====================================================

        if (role == "lawyer" &&
            lawyerId != currentUserId)
        {
            return Forbid();
        }

        // =====================================================
        // KIỂM TRA LAWYER CÓ TỒN TẠI
        // =====================================================

        var lawyerExists = await _db.Lawyers
            .AnyAsync(l => l.Id == lawyerId);

        if (!lawyerExists)
        {
            return NotFound(new
            {
                message = "Không tìm thấy luật sư."
            });
        }

        // =====================================================
        // LẤY CLIENT
        //
        // Không dùng:
        //
        // clientIds.Contains(c.Id)
        //
        // vì EF Core có thể sinh OPENJSON ... WITH (...)
        // và gây lỗi:
        //
        // Incorrect syntax near the keyword 'WITH'
        //
        // Thay vào đó dùng EXISTS / Any().
        // =====================================================

        var clients = await _db.Clients
            .Where(c =>
                _db.Appointments.Any(a =>
                    a.LawyerId == lawyerId &&
                    a.ClientId == c.Id &&
                    a.Status != "cancelled"))
            .Select(c => new
            {
                id = c.Id,

                fullName =
                    c.User != null
                        ? c.User.FullName
                        : "Khách hàng",

                email =
                    c.User != null
                        ? c.User.Email
                        : null,

                phone =
                    c.User != null
                        ? c.User.Phone
                        : null,

                avatarUrl =
                    c.User != null
                        ? c.User.AvatarUrl
                        : null,

                // =================================================
                // ĐẾM SỐ HỒ SƠ VỤ ÁN CỦA CLIENT VỚI LAWYER NÀY
                //
                // Chỉ tính CaseId khác null
                // Không tính appointment đã cancelled
                // Không đếm trùng CaseId
                // =================================================

                caseCount = _db.Appointments
                    .Where(a =>
                        a.LawyerId == lawyerId &&
                        a.ClientId == c.Id &&
                        a.CaseId != null &&
                        a.Status != "cancelled")
                    .Select(a => a.CaseId)
                    .Distinct()
                    .Count()
            })
            .OrderBy(c => c.fullName)
            .ToListAsync();

        // =====================================================
        // TRẢ KẾT QUẢ
        // =====================================================

        return Ok(clients);
    }

    private static AppointmentDto ToDto(Appointment a)
    {
        return new AppointmentDto
        {
            Id = a.Id,

            // =====================================================
            // CLIENT
            // =====================================================

            ClientId = a.ClientId,

            ClientName =
                a.Client?.User?.FullName
                ?? "Khách hàng",

            ClientPhone =
                a.Client?.User?.Phone,

            ClientEmail =
                a.Client?.User?.Email,

            ClientAvatarUrl =
                a.Client?.User?.AvatarUrl,

            // =====================================================
            // LAWYER
            // =====================================================

            LawyerId = a.LawyerId,

            LawyerName =
                a.Lawyer?.User?.FullName
                ?? "Luật sư",

            // =====================================================
            // APPOINTMENT
            // =====================================================

            CaseId = a.CaseId,

            ScheduledAt = a.ScheduledAt,

            DurationMin = a.DurationMin,

            Status = a.Status,

            Description = a.Description
        };
    }
}