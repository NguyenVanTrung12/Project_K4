using LawFirmApi.Data;
using LawFirmApi.DTOs;
using LawFirmApi.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawFirmApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class LawyersController : ControllerBase
{
    private readonly AppDbContext _db;

    public LawyersController(AppDbContext db)
    {
        _db = db;
    }

    // =========================================================
    // GET ALL
    // GET /api/lawyers
    // =========================================================
    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<LawyerDto>>> GetAll(
    [FromQuery] short? practiceAreaId,
    [FromQuery] string? q)
    {
        var query = BuildLawyerQuery(practiceAreaId, q);

        var lawyers = await query
            .OrderByDescending(l => l.CreatedAt)
            .ToListAsync();

        return Ok(
            lawyers
                .Select(ToDto)
                .ToList());
    }

    // =========================================================
    // GET LATEST (có giới hạn số lượng)
    // GET /api/lawyers/latest?limit=8
    //
    // Mặc định 4 (mobile). Web truyền limit=8.
    // =========================================================
    [HttpGet("latest")]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<LawyerDto>>> GetLatest(
        [FromQuery] short? practiceAreaId,
        [FromQuery] string? q,
        [FromQuery] int limit = 4)
    {
        // Chặn giá trị bất thường (âm, 0, hoặc quá lớn)
        limit = Math.Clamp(limit, 1, 20);

        var query = BuildLawyerQuery(practiceAreaId, q);

        var lawyers = await query
            .OrderBy(l => l.User.FullName)
            .Take(limit) // Take chạy ở DB, không load cả bảng lên bộ nhớ
            .ToListAsync();

        return Ok(
            lawyers
                .Select(ToDto)
                .ToList());
    }

    // =========================================================
    // GET DETAIL
    // GET /api/lawyers/{id}
    // =========================================================
    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    public async Task<ActionResult<LawyerDto>> GetById(Guid id)
    {
        var lawyer = await _db.Lawyers
            .Include(l => l.User)
            .Include(l => l.LawyerPracticeAreas)
                .ThenInclude(lpa => lpa.PracticeArea)
            .FirstOrDefaultAsync(l => l.Id == id);

        if (lawyer == null)
        {
            return NotFound(new
            {
                message = "Không tìm thấy luật sư."
            });
        }

        return Ok(ToDto(lawyer));
    }

    // =========================================================
    // CREATE
    // POST /api/lawyers
    //
    // CHỈ ADMIN
    // Ảnh đại diện KHÔNG nhận ở đây, upload riêng qua
    // POST /api/users/{id}/avatar
    // =========================================================
    [HttpPost]
    [Authorize(Roles = "admin")]
    public async Task<ActionResult<LawyerDto>> Create(
        [FromBody] LawyerCreateRequest req)
    {
        // ---------------------------------------------------
        // VALIDATE
        // ---------------------------------------------------

        if (string.IsNullOrWhiteSpace(req.FullName))
        {
            return BadRequest(new { message = "Họ và tên không được để trống." });
        }

        if (string.IsNullOrWhiteSpace(req.Email))
        {
            return BadRequest(new { message = "Email không được để trống." });
        }

        if (string.IsNullOrWhiteSpace(req.Password))
        {
            return BadRequest(new { message = "Mật khẩu không được để trống." });
        }

        if (req.Password.Length < 6)
        {
            return BadRequest(new { message = "Mật khẩu phải có ít nhất 6 ký tự." });
        }

        if (string.IsNullOrWhiteSpace(req.Title))
        {
            return BadRequest(new { message = "Chức danh không được để trống." });
        }

        // ---------------------------------------------------
        // EMAIL
        // ---------------------------------------------------

        var email = req.Email.Trim();

        var emailExists = await _db.Users
            .AnyAsync(u => u.Email == email);

        if (emailExists)
        {
            return Conflict(new { message = "Email đã được sử dụng." });
        }

        // ---------------------------------------------------
        // PHONE
        // ---------------------------------------------------

        string? phone = null;

        if (!string.IsNullOrWhiteSpace(req.Phone))
        {
            phone = req.Phone.Trim();

            var phoneExists = await _db.Users
                .AnyAsync(u => u.Phone == phone);

            if (phoneExists)
            {
                return Conflict(new { message = "Số điện thoại đã được sử dụng." });
            }
        }

        // ---------------------------------------------------
        // PRACTICE AREAS
        // ---------------------------------------------------

        var practiceAreaIds =
            (req.PracticeAreaIds ?? new List<short>())
                .Distinct()
                .ToList();

        var invalidAreaIds = await FindInvalidPracticeAreaIds(practiceAreaIds);

        if (invalidAreaIds.Count > 0)
        {
            return BadRequest(new
            {
                message = "Một hoặc nhiều lĩnh vực hành nghề không tồn tại.",
                invalidPracticeAreaIds = invalidAreaIds
            });
        }

        // ---------------------------------------------------
        // USER
        // ---------------------------------------------------

        // Tạo Id trước để chắc chắn Lawyer.Id trùng User.Id,
        // không phụ thuộc vào việc Id do EF hay database sinh ra.
        var userId = Guid.NewGuid();

        var user = new User
        {
            Id = userId,

            FullName = req.FullName.Trim(),

            Email = email,

            Phone = phone,

            PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password),

            Role = "lawyer",

            Gender = NormalizeGender(req.Gender),

            // "Tạm khóa" thì không cho đăng nhập
            IsActive = req.IsAvailable,

            CreatedAt = DateTime.UtcNow,

            UpdatedAt = DateTime.UtcNow
        };

        // ---------------------------------------------------
        // LAWYER
        // ---------------------------------------------------

        var lawyer = new Lawyer
        {
            Id = userId,

            Title = req.Title.Trim(),

            BarLicenseNo = NullIfEmpty(req.BarLicenseNo),

            YearsExp = req.YearsExp,

            Bio = NullIfEmpty(req.Bio),

            Address = NullIfEmpty(req.Address),

            Education = NullIfEmpty(req.Education),

            Birthday = req.Birthday,

            IsAvailable = req.IsAvailable,

            RatingAvg = 0,

            CasesWon = 0,

            CreatedAt = DateTime.UtcNow
        };

        _db.Users.Add(user);
        _db.Lawyers.Add(lawyer);

        for (int i = 0; i < practiceAreaIds.Count; i++)
        {
            _db.LawyerPracticeAreas.Add(
                new LawyerPracticeArea
                {
                    LawyerId = lawyer.Id,
                    PracticeAreaId = practiceAreaIds[i],
                    IsPrimary = i == 0
                });
        }

        // Một lần SaveChanges = một transaction
        await _db.SaveChangesAsync();

        // ---------------------------------------------------
        // ĐỌC LẠI
        // ---------------------------------------------------

        var createdLawyer = await _db.Lawyers
            .Include(l => l.User)
            .Include(l => l.LawyerPracticeAreas)
                .ThenInclude(lpa => lpa.PracticeArea)
            .FirstOrDefaultAsync(l => l.Id == lawyer.Id);

        if (createdLawyer == null)
        {
            return StatusCode(500, new
            {
                message = "Đã tạo luật sư nhưng không thể đọc lại dữ liệu."
            });
        }

        return CreatedAtAction(
            nameof(GetById),
            new { id = createdLawyer.Id },
            ToDto(createdLawyer));
    }

    // =========================================================
    // UPDATE
    // PUT /api/lawyers/{id}
    //
    // CHỈ ADMIN
    // KHÔNG đụng tới avatar (avatar đổi qua endpoint riêng)
    // =========================================================
    [HttpPut("{id:guid}")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Update(
        Guid id,
        [FromBody] LawyerUpdateRequest req)
    {
        var lawyer = await _db.Lawyers
            .Include(l => l.LawyerPracticeAreas)
            .Include(l => l.User)
            .FirstOrDefaultAsync(l => l.Id == id);

        if (lawyer == null)
        {
            return NotFound(new { message = "Không tìm thấy luật sư." });
        }

        if (lawyer.User == null)
        {
            return BadRequest(new
            {
                message = "Tài khoản người dùng của luật sư không tồn tại."
            });
        }

        // ---------------------------------------------------
        // VALIDATE
        // ---------------------------------------------------

        if (string.IsNullOrWhiteSpace(req.FullName))
        {
            return BadRequest(new { message = "Họ và tên không được để trống." });
        }

        if (string.IsNullOrWhiteSpace(req.Email))
        {
            return BadRequest(new { message = "Email không được để trống." });
        }

        if (string.IsNullOrWhiteSpace(req.Title))
        {
            return BadRequest(new { message = "Chức danh không được để trống." });
        }

        var email = req.Email.Trim();

        var emailExists = await _db.Users
            .AnyAsync(u =>
                u.Id != lawyer.User.Id &&
                u.Email == email);

        if (emailExists)
        {
            return Conflict(new
            {
                message = "Email đã được sử dụng bởi tài khoản khác."
            });
        }

        string? phone = null;

        if (!string.IsNullOrWhiteSpace(req.Phone))
        {
            phone = req.Phone.Trim();

            var phoneExists = await _db.Users
                .AnyAsync(u =>
                    u.Id != lawyer.User.Id &&
                    u.Phone == phone);

            if (phoneExists)
            {
                return Conflict(new
                {
                    message = "Số điện thoại đã được sử dụng bởi tài khoản khác."
                });
            }
        }

        // ---------------------------------------------------
        // PRACTICE AREAS
        // ---------------------------------------------------

        var practiceAreaIds =
            (req.PracticeAreaIds ?? new List<short>())
                .Distinct()
                .ToList();

        var invalidAreaIds = await FindInvalidPracticeAreaIds(practiceAreaIds);

        if (invalidAreaIds.Count > 0)
        {
            return BadRequest(new
            {
                message = "Một hoặc nhiều lĩnh vực hành nghề không tồn tại.",
                invalidPracticeAreaIds = invalidAreaIds
            });
        }

        // ---------------------------------------------------
        // UPDATE USER
        // ---------------------------------------------------

        lawyer.User.FullName = req.FullName.Trim();
        lawyer.User.Email = email;
        lawyer.User.Phone = phone;
        lawyer.User.Gender = NormalizeGender(req.Gender);

        // "Tạm khóa" thì không cho đăng nhập
        lawyer.User.IsActive = req.IsAvailable;

        lawyer.User.UpdatedAt = DateTime.UtcNow;

        // ---------------------------------------------------
        // UPDATE LAWYER
        // ---------------------------------------------------

        lawyer.Title = req.Title.Trim();
        lawyer.BarLicenseNo = NullIfEmpty(req.BarLicenseNo);
        lawyer.YearsExp = req.YearsExp;
        lawyer.Bio = NullIfEmpty(req.Bio);
        lawyer.IsAvailable = req.IsAvailable;

        lawyer.Address = NullIfEmpty(req.Address);
        lawyer.Education = NullIfEmpty(req.Education);
        lawyer.Birthday = req.Birthday;

        // ---------------------------------------------------
        // PRACTICE AREAS: chỉ xóa cái bị bỏ, thêm cái mới
        // (currentAreas là List trong bộ nhớ nên Contains ở đây
        //  không bị dịch sang SQL)
        // ---------------------------------------------------

        var currentAreas = lawyer.LawyerPracticeAreas.ToList();

        var areasToRemove = currentAreas
            .Where(x => !practiceAreaIds.Contains(x.PracticeAreaId))
            .ToList();

        if (areasToRemove.Count > 0)
        {
            _db.LawyerPracticeAreas.RemoveRange(areasToRemove);
        }

        for (int i = 0; i < practiceAreaIds.Count; i++)
        {
            var areaId = practiceAreaIds[i];

            var existing = currentAreas
                .FirstOrDefault(x => x.PracticeAreaId == areaId);

            if (existing != null)
            {
                existing.IsPrimary = i == 0;
            }
            else
            {
                _db.LawyerPracticeAreas.Add(
                    new LawyerPracticeArea
                    {
                        LawyerId = lawyer.Id,
                        PracticeAreaId = areaId,
                        IsPrimary = i == 0
                    });
            }
        }

        await _db.SaveChangesAsync();

        return NoContent();
    }

    // =========================================================
    // DELETE
    // DELETE /api/lawyers/{id}
    //
    // CHỈ ADMIN
    // =========================================================
    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        await using var transaction = await _db.Database.BeginTransactionAsync();

        try
        {
            // =====================================================
            // 1. TÌM USER
            // =====================================================

            var user = await _db.Users
                .FirstOrDefaultAsync(u => u.Id == id);

            if (user == null)
            {
                return NotFound(new
                {
                    message = "Không tìm thấy tài khoản luật sư."
                });
            }

            // =====================================================
            // 2. KIỂM TRA ROLE
            // =====================================================

            if (!string.Equals(
                    user.Role,
                    "lawyer",
                    StringComparison.OrdinalIgnoreCase))
            {
                return BadRequest(new
                {
                    message = "Tài khoản này không phải luật sư."
                });
            }

            // =====================================================
            // 3. TÌM LAWYER
            // =====================================================

            var lawyer = await _db.Lawyers
                .FirstOrDefaultAsync(l => l.Id == id);

            // =====================================================
            // 4. XÓA LAWYER PRACTICE AREAS
            // =====================================================

            var lawyerPracticeAreas = await _db.LawyerPracticeAreas
                .Where(x => x.LawyerId == id)
                .ToListAsync();

            if (lawyerPracticeAreas.Count > 0)
            {
                _db.LawyerPracticeAreas.RemoveRange(
                    lawyerPracticeAreas);
            }

            // =====================================================
            // 5. XÓA LAWYER
            // =====================================================

            if (lawyer != null)
            {
                _db.Lawyers.Remove(lawyer);
            }

            // =====================================================
            // 6. XÓA USER
            // =====================================================

            _db.Users.Remove(user);

            // =====================================================
            // 7. SAVE
            // =====================================================

            await _db.SaveChangesAsync();

            await transaction.CommitAsync();

            return NoContent();
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();

            return StatusCode(500, new
            {
                message = "Không thể xóa luật sư.",
                detail = ex.InnerException?.Message ?? ex.Message
            });
        }
    }
    // =========================================================
    // LOCK LAWYER
    // PUT /api/lawyers/{id}/lock
    //
    // CHỈ ADMIN
    //
    // Không xóa dữ liệu.
    // Chỉ:
    // Users.IsActive = false
    // Lawyers.IsAvailable = false
    // =========================================================
    // =========================================================
    // LOCK LAWYER
    // PUT /api/lawyers/{id}/lock
    // CHỈ ADMIN
    // =========================================================
    [HttpPut("{id:guid}/lock")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Lock(Guid id)
    {
        var lawyer = await _db.Lawyers
            .Include(l => l.User)
            .FirstOrDefaultAsync(l => l.Id == id);

        if (lawyer == null)
        {
            return NotFound(new
            {
                message = "Không tìm thấy luật sư."
            });
        }

        if (lawyer.User == null)
        {
            return BadRequest(new
            {
                message = "Tài khoản người dùng của luật sư không tồn tại."
            });
        }

        if (!string.Equals(
                lawyer.User.Role,
                "lawyer",
                StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new
            {
                message = "Tài khoản này không phải luật sư."
            });
        }

        // KHÓA TÀI KHOẢN
        lawyer.User.IsActive = false;

        // NGỪNG HOẠT ĐỘNG LUẬT SƯ
        lawyer.IsAvailable = false;

        lawyer.User.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return Ok(new
        {
            message = "Đã khóa tài khoản luật sư thành công.",
            lawyerId = lawyer.Id,
            isActive = lawyer.User.IsActive,
            isAvailable = lawyer.IsAvailable
        });
    }
    // =========================================================
    // HELPERS
    // =========================================================

    // Query chung cho GetAll và GetLatest (lọc theo lĩnh vực + tìm theo tên)
    private IQueryable<Lawyer> BuildLawyerQuery(short? practiceAreaId, string? q)
    {
        var query = _db.Lawyers
            .Include(l => l.User)
            .Include(l => l.LawyerPracticeAreas)
                .ThenInclude(lpa => lpa.PracticeArea)
            .AsQueryable();

        // Lọc theo lĩnh vực
        if (practiceAreaId.HasValue)
        {
            var areaId = practiceAreaId.Value;

            query = query.Where(l =>
                l.LawyerPracticeAreas.Any(
                    lpa => lpa.PracticeAreaId == areaId));
        }

        // Tìm kiếm theo tên
        if (!string.IsNullOrWhiteSpace(q))
        {
            var keyword = q.Trim();

            query = query.Where(l =>
                l.User.FullName.Contains(keyword));
        }

        return query;
    }
    // =========================================================
    // UNLOCK LAWYER
    // PUT /api/lawyers/{id}/unlock
    //
    // CHỈ ADMIN
    //
    // Mở khóa tài khoản:
    // Users.IsActive = true
    // Lawyers.IsAvailable = true
    // =========================================================
    [HttpPut("{id:guid}/unlock")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Unlock(Guid id)
    {
        var lawyer = await _db.Lawyers
            .Include(l => l.User)
            .FirstOrDefaultAsync(l => l.Id == id);

        if (lawyer == null)
        {
            return NotFound(new
            {
                message = "Không tìm thấy luật sư."
            });
        }

        if (lawyer.User == null)
        {
            return BadRequest(new
            {
                message = "Tài khoản người dùng của luật sư không tồn tại."
            });
        }

        if (!string.Equals(
                lawyer.User.Role,
                "lawyer",
                StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new
            {
                message = "Tài khoản này không phải luật sư."
            });
        }

        // =====================================================
        // MỞ KHÓA TÀI KHOẢN
        // =====================================================

        lawyer.User.IsActive = true;

        // Cho phép luật sư hoạt động trở lại
        lawyer.IsAvailable = true;

        lawyer.User.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return Ok(new
        {
            message = "Đã mở khóa tài khoản luật sư thành công.",
            lawyerId = lawyer.Id,
            isActive = lawyer.User.IsActive,
            isAvailable = lawyer.IsAvailable
        });
    }
    // Kiểm tra các id lĩnh vực có tồn tại không.
    //
    // KHÔNG dùng `.Where(p => practiceAreaIds.Contains(p.Id))` vì EF Core
    // mới dịch nó thành OPENJSON ... WITH (...), gây lỗi
    // "Incorrect syntax near the keyword 'WITH'" trên database có
    // compatibility level < 130.
    //
    // Bảng PracticeAreas rất nhỏ nên lấy hết id rồi so sánh trong bộ nhớ.
    private async Task<List<short>> FindInvalidPracticeAreaIds(
        List<short> practiceAreaIds)
    {
        if (practiceAreaIds.Count == 0)
        {
            return new List<short>();
        }

        var existingIds = await _db.PracticeAreas
            .Select(p => p.Id)
            .ToListAsync();

        return practiceAreaIds
            .Except(existingIds)
            .ToList();
    }

    private static string? NullIfEmpty(string? value)
    {
        return string.IsNullOrWhiteSpace(value)
            ? null
            : value.Trim();
    }

    private static string? NormalizeGender(string? value)
    {
        var gender = NullIfEmpty(value);

        if (gender == null)
        {
            return null;
        }

        return gender is "Nam" or "Nữ" or "Khác"
            ? gender
            : null;
    }

    // =========================================================
    // LAWYER -> DTO
    // =========================================================

    private static LawyerDto ToDto(Lawyer l)
    {
        var areas = l.LawyerPracticeAreas?
            .Where(lpa => lpa.PracticeArea != null)
            .OrderByDescending(lpa => lpa.IsPrimary)
            .ToList()
            ?? new List<LawyerPracticeArea>();

        return new LawyerDto
        {
            Id = l.Id,

            // USER
            FullName = l.User?.FullName ?? string.Empty,
            Email = l.User?.Email ?? string.Empty,
            Phone = l.User?.Phone,
            AvatarUrl = l.User?.AvatarUrl,
            Gender = l.User?.Gender,

            // THÔNG TIN CÁ NHÂN
            Address = l.Address,
            Education = l.Education,
            Birthday = l.Birthday,

            // NGHỀ NGHIỆP
            Title = l.Title,
            BarLicenseNo = l.BarLicenseNo,
            YearsExp = l.YearsExp,
            Bio = l.Bio,

            // THỐNG KÊ
            RatingAvg = l.RatingAvg,
            CasesWon = l.CasesWon,
            IsAvailable = l.IsAvailable,

            // LĨNH VỰC
            PracticeAreas = areas
                .Select(lpa => lpa.PracticeArea!.Name)
                .ToList(),

            PracticeAreaIds = areas
                .Select(lpa => lpa.PracticeAreaId)
                .ToList()
        };
    }
}