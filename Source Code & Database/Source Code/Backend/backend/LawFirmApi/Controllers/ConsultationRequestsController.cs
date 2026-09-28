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
[Route("api/consultation-requests")]
[Authorize]
public class ConsultationRequestsController : ControllerBase
{
    private readonly AppDbContext _db;

    public ConsultationRequestsController(
        AppDbContext db)
    {
        _db = db;
    }


    // =========================================================
    // HELPERS
    // =========================================================

    private string GetRole()
    {
        return User.FindFirstValue(
                   ClaimTypes.Role)?
                   .Trim()
                   .ToLowerInvariant()
               ?? "";
    }


    private bool TryGetUserId(
        out Guid userId)
    {
        userId =
            Guid.Empty;

        var value =
            User.FindFirstValue(
                ClaimTypes.NameIdentifier);

        return Guid.TryParse(
            value,
            out userId);
    }


    // =========================================================
    // GET CURRENT LAWYER ID
    //
    // Model:
    //
    // User.Id == Lawyer.Id
    // =========================================================

    private async Task<Guid?> GetLawyerIdFromCurrentUser()
    {
        if (!TryGetUserId(
                out var userId))
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
    // LOAD REQUEST
    // =========================================================

    private async Task<ConsultationRequest?> Load(
        Guid id)
    {
        return await _db.ConsultationRequests

            .Include(x => x.Client)
                .ThenInclude(c => c.User)

            .Include(x => x.PracticeArea)

            .Include(x => x.Lawyer)
                .ThenInclude(l => l!.User)

            .Include(x => x.Case)

            .FirstOrDefaultAsync(
                x => x.Id == id);
    }


    // =========================================================
    // DTO
    // =========================================================

    private static ConsultationRequestDto ToDto(
        ConsultationRequest x)
    {
        return new ConsultationRequestDto
        {
            Id =
                x.Id,

            ClientId =
                x.ClientId,

            ClientName =
                x.Client?.User?.FullName
                ?? "Khách hàng",

            ClientEmail =
                x.Client?.User?.Email
                ?? "",

            Phone =
                x.Client?.User?.Phone,

            PracticeAreaId =
                x.PracticeAreaId,

            PracticeAreaName =
                x.PracticeArea?.Name,

            LawyerId =
                x.LawyerId,

            LawyerName =
                x.Lawyer?.User?.FullName,

            Title =
                x.Title,

            Description =
                x.Description,

            Priority =
                x.Priority,

            Status =
                x.Status,

            AttachmentUrl =
                x.AttachmentUrl,

            CaseId =
                x.CaseId,

            CreatedAt =
                x.CreatedAt
        };
    }


    // =========================================================
    // GET ALL
    //
    // ADMIN / STAFF:
    //     Tất cả
    //
    // LAWYER:
    //     Chỉ yêu cầu được phân công cho mình
    //
    // CLIENT:
    //     Chỉ yêu cầu của mình
    // =========================================================

    [HttpGet]
    [Authorize(
        Roles = "admin,staff,lawyer,client")]
    public async Task<
        ActionResult<IEnumerable<ConsultationRequestDto>>>
        GetAll()
    {
        if (!TryGetUserId(
                out var userId))
        {
            return Unauthorized(new
            {
                message =
                    "Token không hợp lệ."
            });
        }


        var role =
            GetRole();


        var query =
            _db.ConsultationRequests
                .AsNoTracking()

                .Include(x => x.Client)
                    .ThenInclude(c => c.User)

                .Include(x => x.PracticeArea)

                .Include(x => x.Lawyer)
                    .ThenInclude(l => l!.User)

                .AsQueryable();


        // =====================================================
        // CLIENT
        // =====================================================

        if (role == "client")
        {
            query =
                query.Where(
                    x =>
                        x.ClientId ==
                        userId);
        }


        // =====================================================
        // LAWYER
        //
        // CHỈ LẤY REQUEST ĐƯỢC PHÂN CÔNG CHO LAWYER HIỆN TẠI
        // =====================================================

        else if (role == "lawyer")
        {
            var lawyerId =
                await GetLawyerIdFromCurrentUser();


            if (!lawyerId.HasValue)
            {
                return BadRequest(new
                {
                    message =
                        "Tài khoản Lawyer chưa có hồ sơ luật sư."
                });
            }


            query =
                query.Where(
                    x =>
                        x.LawyerId ==
                        lawyerId.Value);
        }


        // =====================================================
        // ADMIN / STAFF
        //
        // Không filter.
        // =====================================================

        else if (role != "admin" &&
                 role != "staff")
        {
            return Forbid();
        }


        var requests =
            await query
                .OrderByDescending(
                    x => x.CreatedAt)
                .ToListAsync();


        return Ok(
            requests
                .Select(ToDto)
                .ToList());
    }


    // =========================================================
    // GET DETAIL
    //
    // GET /api/consultation-requests/{id}
    // =========================================================

    [HttpGet("{id:guid}")]
    [Authorize]
    public async Task<
        ActionResult<ConsultationRequestDto>>
        GetById(Guid id)
    {
        if (!TryGetUserId(
                out var userId))
        {
            return Unauthorized();
        }


        var request =
            await Load(id);


        if (request == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy yêu cầu tư vấn."
            });
        }


        var role =
            GetRole();


        // =====================================================
        // CLIENT
        // =====================================================

        if (role == "client")
        {
            if (request.ClientId != userId)
            {
                return Forbid();
            }
        }


        // =====================================================
        // LAWYER
        // =====================================================

        else if (role == "lawyer")
        {
            var lawyerId =
                await GetLawyerIdFromCurrentUser();


            if (!lawyerId.HasValue)
            {
                return Forbid();
            }


            if (request.LawyerId !=
                lawyerId.Value)
            {
                return Forbid();
            }
        }


        // =====================================================
        // ADMIN / STAFF
        // =====================================================

        else if (role != "admin" &&
                 role != "staff")
        {
            return Forbid();
        }


        return Ok(
            ToDto(request));
    }


    // =========================================================
    // CREATE REQUEST
    //
    // CLIENT ONLY
    // =========================================================

    [HttpPost]
    [Authorize(Roles = "client")]
    public async Task<
        ActionResult<ConsultationRequestDto>>
        Create(
            [FromBody]
            ConsultationRequestCreateRequest req)
    {
        if (!TryGetUserId(
                out var clientId))
        {
            return Unauthorized();
        }


        if (string.IsNullOrWhiteSpace(req.Title) ||
            string.IsNullOrWhiteSpace(req.Description))
        {
            return BadRequest(new
            {
                message =
                    "Vui lòng nhập tiêu đề và nội dung vấn đề."
            });
        }


        if (req.Priority is not
            ("low" or
             "normal" or
             "high" or
             "urgent"))
        {
            return BadRequest(new
            {
                message =
                    "Mức độ khẩn cấp không hợp lệ."
            });
        }


        var clientExists =
            await _db.Clients.AnyAsync(
                x => x.Id == clientId);


        if (!clientExists)
        {
            return BadRequest(new
            {
                message =
                    "Tài khoản chưa có hồ sơ khách hàng."
            });
        }


        // =====================================================
        // CHECK PRACTICE AREA
        // =====================================================

        if (req.PracticeAreaId.HasValue)
        {
            var practiceAreaExists =
                await _db.PracticeAreas.AnyAsync(
                    x =>
                        x.Id ==
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


        var request =
            new ConsultationRequest
            {
                ClientId =
                    clientId,

                PracticeAreaId =
                    req.PracticeAreaId,

                Title =
                    req.Title.Trim(),

                Description =
                    req.Description.Trim(),

                Priority =
                    req.Priority,

                Status =
                    "new",

                AttachmentUrl =
                    req.AttachmentUrl,

                CreatedAt =
                    DateTime.UtcNow,

                UpdatedAt =
                    DateTime.UtcNow
            };


        _db.ConsultationRequests.Add(
            request);


        await _db.SaveChangesAsync();


        // =====================================================
        // NOTIFICATION ADMIN / STAFF
        // =====================================================

        var staffIds =
            await _db.Users
                .Where(
                    u =>
                        u.Role == "admin" ||
                        u.Role == "staff")
                .Select(
                    u => u.Id)
                .ToListAsync();


        foreach (var staffId in staffIds)
        {
            NotificationHelper.Notify(
                _db,
                staffId,
                "system",
                "Có yêu cầu tư vấn mới",
                request.Title,
                request.Id);
        }


        await _db.SaveChangesAsync();


        var saved =
            await Load(request.Id);


        return CreatedAtAction(
            nameof(GetById),
            new
            {
                id = request.Id
            },
            ToDto(saved!));
    }


    // =========================================================
    // CREATE REQUEST WITH FILE
    //
    // CLIENT ONLY
    // =========================================================

    [HttpPost("with-file")]
    [Authorize(Roles = "client")]
    public async Task<
        ActionResult<ConsultationRequestDto>>
        CreateWithFile(
            [FromForm] string title,
            [FromForm] short? practiceAreaId,
            [FromForm] string description,
            [FromForm] string priority = "normal",
            IFormFile? file = null)
    {
        if (!TryGetUserId(
                out var clientId))
        {
            return Unauthorized();
        }


        if (string.IsNullOrWhiteSpace(title) ||
            string.IsNullOrWhiteSpace(description))
        {
            return BadRequest(new
            {
                message =
                    "Thiếu tiêu đề hoặc nội dung."
            });
        }


        if (priority is not
            ("low" or
             "normal" or
             "high" or
             "urgent"))
        {
            return BadRequest(new
            {
                message =
                    "Mức độ khẩn cấp không hợp lệ."
            });
        }


        var clientExists =
            await _db.Clients.AnyAsync(
                x => x.Id == clientId);


        if (!clientExists)
        {
            return BadRequest(new
            {
                message =
                    "Tài khoản chưa có hồ sơ khách hàng."
            });
        }


        // =====================================================
        // CHECK PRACTICE AREA
        // =====================================================

        if (practiceAreaId.HasValue)
        {
            var practiceAreaExists =
                await _db.PracticeAreas.AnyAsync(
                    x =>
                        x.Id ==
                        practiceAreaId.Value);


            if (!practiceAreaExists)
            {
                return BadRequest(new
                {
                    message =
                        "Lĩnh vực pháp lý không tồn tại."
                });
            }
        }


        string? url = null;


        // =====================================================
        // FILE
        // =====================================================

        if (file is not null &&
            file.Length > 0)
        {
            const long maxSize =
                10 * 1024 * 1024;


            if (file.Length > maxSize)
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


            var allowed =
                new[]
                {
                    ".pdf",
                    ".doc",
                    ".docx",
                    ".jpg",
                    ".jpeg",
                    ".png"
                };


            if (!allowed.Contains(extension))
            {
                return BadRequest(new
                {
                    message =
                        "Chỉ chấp nhận PDF, Word hoặc ảnh JPG/JPEG/PNG."
                });
            }


            var fileName =
                $"{Guid.NewGuid():N}{extension}";


            var directory =
                Path.Combine(
                    Directory.GetCurrentDirectory(),
                    "wwwroot",
                    "uploads",
                    "consultations");


            Directory.CreateDirectory(
                directory);


            var path =
                Path.Combine(
                    directory,
                    fileName);


            await using (
                var stream =
                    System.IO.File.Create(path))
            {
                await file.CopyToAsync(stream);
            }


            url =
                $"/uploads/consultations/{fileName}";
        }


        // =====================================================
        // CREATE REQUEST
        // =====================================================

        var request =
            new ConsultationRequest
            {
                ClientId =
                    clientId,

                PracticeAreaId =
                    practiceAreaId,

                Title =
                    title.Trim(),

                Description =
                    description.Trim(),

                Priority =
                    priority,

                Status =
                    "new",

                AttachmentUrl =
                    url,

                CreatedAt =
                    DateTime.UtcNow,

                UpdatedAt =
                    DateTime.UtcNow
            };


        _db.ConsultationRequests.Add(
            request);


        await _db.SaveChangesAsync();


        // =====================================================
        // NOTIFICATION
        // =====================================================

        var staffIds =
            await _db.Users
                .Where(
                    u =>
                        u.Role == "admin" ||
                        u.Role == "staff")
                .Select(
                    u => u.Id)
                .ToListAsync();


        foreach (var staffId in staffIds)
        {
            NotificationHelper.Notify(
                _db,
                staffId,
                "system",
                "Có yêu cầu tư vấn mới",
                request.Title,
                request.Id);
        }


        await _db.SaveChangesAsync();


        var saved =
            await Load(request.Id);


        return CreatedAtAction(
            nameof(GetById),
            new
            {
                id = request.Id
            },
            ToDto(saved!));
    }


    // =========================================================
    // UPDATE / ASSIGN REQUEST
    //
    // ADMIN / STAFF:
    //     Có thể phân công Lawyer
    //     Có thể đổi Status
    //
    // LAWYER:
    //     Chỉ đổi Status request của mình
    // =========================================================

    [HttpPatch("{id:guid}")]
    [Authorize(
        Roles = "admin,staff,lawyer")]
    public async Task<IActionResult> Update(
        Guid id,
        [FromBody]
        ConsultationRequestAssignRequest req)
    {
        if (!TryGetUserId(
                out var userId))
        {
            return Unauthorized();
        }


        var request =
            await _db.ConsultationRequests
                .FirstOrDefaultAsync(
                    x => x.Id == id);


        if (request == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy yêu cầu tư vấn."
            });
        }


        var role =
            GetRole();


        // =====================================================
        // LAWYER
        // =====================================================

        if (role == "lawyer")
        {
            var currentLawyerId =
                await GetLawyerIdFromCurrentUser();


            if (!currentLawyerId.HasValue)
            {
                return Forbid();
            }


            // Không cho Lawyer tự phân công
            // sang Lawyer khác.
            if (req.LawyerId.HasValue)
            {
                return Forbid();
            }


            // Chỉ thao tác request của mình.
            if (request.LawyerId !=
                currentLawyerId.Value)
            {
                return Forbid();
            }


            if (!string.IsNullOrWhiteSpace(
                    req.Status))
            {
                var status =
                    req.Status
                        .Trim()
                        .ToLowerInvariant();


                if (status is not
                    ("new" or
                     "processing" or
                     "completed" or
                     "cancelled"))
                {
                    return BadRequest(new
                    {
                        message =
                            "Trạng thái không hợp lệ."
                    });
                }


                request.Status =
                    status;
            }
        }


        // =====================================================
        // ADMIN / STAFF
        // =====================================================

        else if (role == "admin" ||
                 role == "staff")
        {
            // =================================================
            // ASSIGN LAWYER
            // =================================================

            if (req.LawyerId.HasValue)
            {
                var lawyer =
                    await _db.Lawyers
                        .FirstOrDefaultAsync(
                            l =>
                                l.Id ==
                                req.LawyerId.Value);


                if (lawyer == null)
                {
                    return BadRequest(new
                    {
                        message =
                            "Luật sư không tồn tại."
                    });
                }


                request.LawyerId =
                    lawyer.Id;


                // Nếu request đang new
                // thì chuyển processing.
                if (request.Status == "new")
                {
                    request.Status =
                        "processing";
                }


                // =================================================
                // THÔNG BÁO LAWYER
                // =================================================

                NotificationHelper.Notify(
                    _db,
                    lawyer.Id,
                    "system",
                    "Bạn được phân công yêu cầu tư vấn",
                    request.Title,
                    request.Id);
            }


            // =================================================
            // STATUS
            // =================================================

            if (!string.IsNullOrWhiteSpace(
                    req.Status))
            {
                var status =
                    req.Status
                        .Trim()
                        .ToLowerInvariant();


                if (status is not
                    ("new" or
                     "processing" or
                     "completed" or
                     "cancelled"))
                {
                    return BadRequest(new
                    {
                        message =
                            "Trạng thái không hợp lệ."
                    });
                }


                request.Status =
                    status;
            }
        }


        else
        {
            return Forbid();
        }


        request.UpdatedAt =
            DateTime.UtcNow;


        await _db.SaveChangesAsync();


        // =====================================================
        // NOTIFICATION CLIENT
        // =====================================================

        NotificationHelper.Notify(
            _db,
            request.ClientId,
            "case_update",
            "Yêu cầu tư vấn được cập nhật",
            $"Trạng thái: {GetRequestStatusLabel(request.Status)}",
            request.Id);


        await _db.SaveChangesAsync();


        return NoContent();
    }


    // =========================================================
    // CREATE CASE FROM CONSULTATION REQUEST
    //
    // ADMIN / STAFF:
    //     Có thể tạo
    //
    // LAWYER:
    //     Chỉ tạo nếu request được phân công cho mình
    //
    // POST:
    // /api/consultation-requests/{id}/create-case
    // =========================================================

    [HttpPost("{id:guid}/create-case")]
    [Authorize(
        Roles = "admin,staff,lawyer")]
    public async Task<IActionResult> CreateCase(
        Guid id)
    {
        if (!TryGetUserId(
                out var userId))
        {
            return Unauthorized();
        }


        var request =
            await _db.ConsultationRequests
                .FirstOrDefaultAsync(
                    x => x.Id == id);


        if (request == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy yêu cầu tư vấn."
            });
        }


        var role =
            GetRole();


        // =====================================================
        // LAWYER
        // =====================================================

        if (role == "lawyer")
        {
            var lawyerId =
                await GetLawyerIdFromCurrentUser();


            if (!lawyerId.HasValue)
            {
                return Forbid();
            }


            // =================================================
            // REQUEST PHẢI ĐƯỢC PHÂN CÔNG CHO CHÍNH LAWYER
            // =================================================

            if (request.LawyerId !=
                lawyerId.Value)
            {
                return Forbid();
            }
        }


        // =====================================================
        // ADMIN / STAFF / LAWYER
        // =====================================================

        if (role != "admin" &&
            role != "staff" &&
            role != "lawyer")
        {
            return Forbid();
        }


        // =====================================================
        // PHẢI CÓ LAWYER
        // =====================================================

        if (!request.LawyerId.HasValue)
        {
            return BadRequest(new
            {
                message =
                    "Vui lòng phân công luật sư trước khi tạo hồ sơ vụ án."
            });
        }


        // =====================================================
        // NẾU ĐÃ CÓ CASE
        // =====================================================

        if (request.CaseId.HasValue)
        {
            return Ok(new
            {
                caseId =
                    request.CaseId.Value
            });
        }


        // =====================================================
        // KIỂM TRA CLIENT
        // =====================================================

        var clientExists =
            await _db.Clients.AnyAsync(
                c =>
                    c.Id ==
                    request.ClientId);


        if (!clientExists)
        {
            return BadRequest(new
            {
                message =
                    "Khách hàng của yêu cầu không tồn tại."
            });
        }


        // =====================================================
        // KIỂM TRA LAWYER
        // =====================================================

        var lawyerExists =
            await _db.Lawyers.AnyAsync(
                l =>
                    l.Id ==
                    request.LawyerId.Value);


        if (!lawyerExists)
        {
            return BadRequest(new
            {
                message =
                    "Luật sư được phân công không tồn tại."
            });
        }


        // =====================================================
        // TẠO SỐ HỒ SƠ
        // =====================================================

        var docket =
            await GenerateDocketNo();


        // =====================================================
        // CREATE CASE
        // =====================================================

        var caseEntity =
            new Case
            {
                DocketNo =
                    docket,

                Title =
                    request.Title,

                ClientId =
                    request.ClientId,

                LawyerId =
                    request.LawyerId.Value,

                PracticeAreaId =
                    request.PracticeAreaId,

                Status =
                    "filed",

                NextStep =
                    "Tiếp nhận hồ sơ",

                OpenedAt =
                    DateTime.UtcNow.Date,

                CreatedAt =
                    DateTime.UtcNow,

                UpdatedAt =
                    DateTime.UtcNow
            };


        _db.Cases.Add(caseEntity);


        // =====================================================
        // LINK REQUEST -> CASE
        // =====================================================

        request.CaseId =
            caseEntity.Id;


        request.Status =
            "completed";


        request.UpdatedAt =
            DateTime.UtcNow;


        await _db.SaveChangesAsync();


        // =====================================================
        // NOTIFY CLIENT
        // =====================================================

        NotificationHelper.Notify(
            _db,
            request.ClientId,
            "case_update",
            "Đã tạo hồ sơ vụ án",
            $"Hồ sơ {docket} đã được tạo từ yêu cầu tư vấn.",
            caseEntity.Id);


        // =====================================================
        // NOTIFY LAWYER
        // =====================================================

        NotificationHelper.Notify(
            _db,
            request.LawyerId.Value,
            "case_update",
            "Bạn được giao hồ sơ vụ án mới",
            $"Hồ sơ {docket}: {request.Title}",
            caseEntity.Id);


        await _db.SaveChangesAsync();


        return Ok(new
        {
            caseId =
                caseEntity.Id,

            docketNo =
                docket
        });
    }


    // =========================================================
    // GENERATE DOCKET NUMBER
    // =========================================================

    private async Task<string> GenerateDocketNo()
    {
        for (var i = 0; i < 10; i++)
        {
            var docket =
                $"HS-{DateTime.UtcNow:yyyyMMddHHmmss}-{Random.Shared.Next(100, 999)}";


            var exists =
                await _db.Cases.AnyAsync(
                    c =>
                        c.DocketNo ==
                        docket);


            if (!exists)
            {
                return docket;
            }


            await Task.Delay(5);
        }


        // Fallback cực hiếm
        return
            $"HS-{DateTime.UtcNow:yyyyMMddHHmmssfff}-{Guid.NewGuid():N[..6]}";
    }


    // =========================================================
    // REQUEST STATUS LABEL
    // =========================================================

    private static string GetRequestStatusLabel(
        string status)
    {
        return status switch
        {
            "new" =>
                "Mới",

            "processing" =>
                "Đang xử lý",

            "completed" =>
                "Hoàn thành",

            "cancelled" =>
                "Đã hủy",

            _ =>
                "Không xác định"
        };
    }
}