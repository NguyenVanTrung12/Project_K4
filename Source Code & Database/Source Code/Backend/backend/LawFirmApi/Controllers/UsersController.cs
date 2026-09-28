using System.Security.Claims;
using LawFirmApi.Data;
using LawFirmApi.DTOs;
using LawFirmApi.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawFirmApi.Controllers;

[ApiController]
[Route("api/users")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly AppDbContext _db;

    // Gi?i h?n dung l??ng file ?nh
    private const long MaxAvatarSize = 5 * 1024 * 1024;

    // Gi?i h?n c? request (multipart có thêm ph?n overhead ngoài file)
    private const long MaxAvatarRequestSize = 6 * 1024 * 1024;

    private static readonly string[] AllowedAvatarExtensions =
    {
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    };

    public UsersController(AppDbContext db)
    {
        _db = db;
    }

    // =========================================================
    // GET ALL USERS
    // GET /api/users
    //
    // ?ang cho phép: admin, staff, lawyer
    // (N?u ch? mu?n admin + staff xem toàn b? danh sách thì b? "lawyer")
    // =========================================================

    [HttpGet]
    [Authorize(Roles = "admin,staff,lawyer")]
    public async Task<ActionResult<IEnumerable<UserAdminDto>>> GetAll(
        [FromQuery] string? q,
        [FromQuery] string? role)
    {
        var query = _db.Users.AsQueryable();

        if (!string.IsNullOrWhiteSpace(q))
        {
            q = q.Trim();

            query = query.Where(u =>
                u.FullName.Contains(q) ||
                u.Email.Contains(q) ||
                (u.Phone != null && u.Phone.Contains(q)));
        }

        if (!string.IsNullOrWhiteSpace(role))
        {
            query = query.Where(u => u.Role == role);
        }

        var users = await query
            .OrderByDescending(u => u.CreatedAt)
            .ToListAsync();

        return Ok(users.Select(user => ToDto(user)).ToList());
    }


    // =========================================================
    // GET USER
    // GET /api/users/{id}
    // =========================================================

    // =========================================================
    // GET USER
    // GET /api/users/{id}
    // =========================================================

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<UserAdminDto>> Get(Guid id)
    {
        var currentUserId = GetCurrentUserId();
        var role = GetCurrentRole();

        if (role != "admin" &&
            role != "staff" &&
            currentUserId != id)
        {
            return Forbid();
        }

        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
        {
            return NotFound(new
            {
                message = "Không tìm thấy tài khoản."
            });
        }

        // ⭐ THÊM: lấy thêm thông tin Client (Ngày sinh, Địa chỉ)
        var client = await _db.Clients
            .FirstOrDefaultAsync(c => c.Id == id);

        return Ok(ToDto(user, client));
    }


    // =========================================================
    // UPDATE PROFILE
    //
    // PATCH /api/users/{id}/profile
    //
    // Dùng ?? s?a:
    // - H? tên
    // - Email
    // - S? ?i?n tho?i
    // =========================================================

    // =========================================================
    // UPDATE PROFILE
    // PATCH /api/users/{id}/profile
    // =========================================================

    //[HttpPatch("{id:guid}/profile")]
    //public async Task<IActionResult> UpdateProfile(
    //    Guid id,
    //    [FromBody] UserProfileUpdateRequest req)
    //{
    //    var currentUserId = GetCurrentUserId();
    //    var role = GetCurrentRole();

    //    if (role != "admin" &&
    //        currentUserId != id)
    //    {
    //        return Forbid();
    //    }

    //    var user = await _db.Users
    //        .FirstOrDefaultAsync(u => u.Id == id);

    //    if (user == null)
    //    {
    //        return NotFound(new { message = "Không tìm thấy tài khoản." });
    //    }

    //    if (string.IsNullOrWhiteSpace(req.FullName))
    //    {
    //        return BadRequest(new { message = "Họ và tên không được để trống." });
    //    }

    //    if (string.IsNullOrWhiteSpace(req.Email))
    //    {
    //        return BadRequest(new { message = "Email không được để trống." });
    //    }

    //    var email = req.Email.Trim();

    //    var emailExists = await _db.Users
    //        .AnyAsync(u => u.Id != id && u.Email == email);

    //    if (emailExists)
    //    {
    //        return Conflict(new { message = "Email đã được sử dụng." });
    //    }

    //    if (!string.IsNullOrWhiteSpace(req.Phone))
    //    {
    //        var phone = req.Phone.Trim();

    //        var phoneExists = await _db.Users
    //            .AnyAsync(u => u.Id != id && u.Phone == phone);

    //        if (phoneExists)
    //        {
    //            return Conflict(new { message = "Số điện thoại đã được sử dụng." });
    //        }

    //        user.Phone = phone;
    //    }
    //    else
    //    {
    //        user.Phone = null;
    //    }

    //    user.FullName = req.FullName.Trim();
    //    user.Email = email;

    //    // ⭐ THÊM: cập nhật Giới tính (cột thuộc bảng Users)
    //    if (!string.IsNullOrWhiteSpace(req.Gender))
    //    {
    //        user.Gender = req.Gender.Trim();
    //    }

    //    user.UpdatedAt = DateTime.UtcNow;

    //    // ⭐ THÊM: cập nhật Ngày sinh / Địa chỉ (cột thuộc bảng Clients)
    //    var client = await _db.Clients
    //        .FirstOrDefaultAsync(c => c.Id == id);

    //    if (client != null)
    //    {
    //        if (req.DateOfBirth.HasValue)
    //        {
    //            client.DateOfBirth = req.DateOfBirth.Value;
    //        }

    //        if (req.Address != null)
    //        {
    //            client.Address = req.Address.Trim();
    //        }
    //    }

    //    await _db.SaveChangesAsync();

    //    return Ok(ToDto(user, client));
    //}
    // =========================================================
    // UPDATE PROFILE
    //
    // PATCH /api/users/{id}/profile
    //
    // Cập nhật:
    // - Họ tên
    // - Email
    // - Số điện thoại
    // - Giới tính
    // - Ngày sinh
    // - Địa chỉ
    // =========================================================

    [HttpPatch("{id:guid}/profile")]
    public async Task<IActionResult> UpdateProfile(
        Guid id,
        [FromBody] UserProfileUpdateRequest req)
    {
        var currentUserId = GetCurrentUserId();
        var role = GetCurrentRole();

        // =========================================================
        // PHÂN QUYỀN
        // Admin có thể sửa người khác.
        // User thường chỉ sửa chính mình.
        // =========================================================

        if (role != "admin" && currentUserId != id)
        {
            return Forbid();
        }

        // =========================================================
        // KIỂM TRA REQUEST
        // =========================================================

        if (req == null)
        {
            return BadRequest(new
            {
                message = "Dữ liệu cập nhật không hợp lệ."
            });
        }

        // =========================================================
        // LẤY USER
        // =========================================================

        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
        {
            return NotFound(new
            {
                message = "Không tìm thấy tài khoản."
            });
        }

        // =========================================================
        // HỌ TÊN
        // =========================================================

        if (string.IsNullOrWhiteSpace(req.FullName))
        {
            return BadRequest(new
            {
                message = "Họ và tên không được để trống."
            });
        }

        // =========================================================
        // EMAIL
        // =========================================================

        if (string.IsNullOrWhiteSpace(req.Email))
        {
            return BadRequest(new
            {
                message = "Email không được để trống."
            });
        }

        var email = req.Email.Trim();

        var emailExists = await _db.Users
            .AnyAsync(u =>
                u.Id != id &&
                u.Email == email);

        if (emailExists)
        {
            return Conflict(new
            {
                message = "Email đã được sử dụng."
            });
        }

        // =========================================================
        // PHONE
        // =========================================================

        if (!string.IsNullOrWhiteSpace(req.Phone))
        {
            var phone = req.Phone.Trim();

            var phoneExists = await _db.Users
                .AnyAsync(u =>
                    u.Id != id &&
                    u.Phone == phone);

            if (phoneExists)
            {
                return Conflict(new
                {
                    message = "Số điện thoại đã được sử dụng."
                });
            }

            user.Phone = phone;
        }
        else
        {
            user.Phone = null;
        }

        // =========================================================
        // GENDER
        //
        // DB chỉ cho phép:
        // - Nam
        // - Nữ
        // - Khác
        // - NULL
        // =========================================================

        if (string.IsNullOrWhiteSpace(req.Gender))
        {
            user.Gender = null;
        }
        else
        {
            var gender = req.Gender.Trim();

            if (gender != "Nam" &&
                gender != "Nữ" &&
                gender != "Khác")
            {
                return BadRequest(new
                {
                    message = "Giới tính không hợp lệ.",
                    allowedValues = new[]
                    {
                    "Nam",
                    "Nữ",
                    "Khác"
                }
                });
            }

            user.Gender = gender;
        }

        // =========================================================
        // USER
        // =========================================================

        user.FullName = req.FullName.Trim();

        user.Email = email;

        user.UpdatedAt = DateTime.UtcNow;

        // =========================================================
        // CLIENT
        //
        // Ngày sinh / Địa chỉ nằm trong bảng Clients
        // =========================================================

        var client = await _db.Clients
            .FirstOrDefaultAsync(c => c.Id == id);

        if (client != null)
        {
            if (req.DateOfBirth.HasValue)
            {
                client.DateOfBirth = req.DateOfBirth.Value;
            }

            if (req.Address != null)
            {
                client.Address = req.Address.Trim();
            }
        }

        // =========================================================
        // SAVE
        // =========================================================

        await _db.SaveChangesAsync();

        // =========================================================
        // TRẢ VỀ
        // =========================================================

        return Ok(ToDto(user, client));
    }

    // =========================================================
    // UPLOAD AVATAR
    //
    // POST /api/users/{id}/avatar
    //
    // Content-Type: multipart/form-data
    // Form field:   file
    // =========================================================

    [HttpPost("{id:guid}/avatar")]
    [RequestSizeLimit(MaxAvatarRequestSize)]
    public async Task<IActionResult> UploadAvatar(
        Guid id,
        IFormFile file)
    {
        var currentUserId = GetCurrentUserId();
        var role = GetCurrentRole();

        // Ng??i dùng ch? ???c s?a avatar c?a chính mình.
        // Admin có th? s?a avatar c?a ng??i khác.
        if (role != "admin" &&
            currentUserId != id)
        {
            return Forbid();
        }

        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
        {
            return NotFound(new
            {
                message = "Không tìm th?y tài kho?n."
            });
        }

        // ---------------------------------------------------
        // KI?M TRA FILE
        // ---------------------------------------------------

        if (file == null || file.Length == 0)
        {
            return BadRequest(new
            {
                message = "Vui lòng ch?n ?nh."
            });
        }

        if (file.Length > MaxAvatarSize)
        {
            return BadRequest(new
            {
                message = "?nh không ???c v??t quá 5MB."
            });
        }

        var extension =
            Path.GetExtension(file.FileName)
                .ToLowerInvariant();

        if (!AllowedAvatarExtensions.Contains(extension))
        {
            return BadRequest(new
            {
                message = "Ch? ch?p nh?n ?nh JPG, JPEG, PNG ho?c WEBP."
            });
        }

        // ---------------------------------------------------
        // T?O TH? M?C
        // ---------------------------------------------------

        var uploadsFolder = GetAvatarFolder();

        Directory.CreateDirectory(uploadsFolder);

        // ---------------------------------------------------
        // XÓA AVATAR C?
        // ---------------------------------------------------

        DeleteAvatarFile(user.AvatarUrl);

        // ---------------------------------------------------
        // L?U FILE M?I
        // ---------------------------------------------------

        var fileName = $"{Guid.NewGuid()}{extension}";

        var filePath = Path.Combine(uploadsFolder, fileName);

        await using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        var avatarUrl = $"/uploads/avatars/{fileName}";

        user.AvatarUrl = avatarUrl;

        user.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return Ok(new
        {
            message = "C?p nh?t ?nh ??i di?n thành công.",
            avatarUrl = avatarUrl
        });
    }


    // =========================================================
    // DELETE AVATAR
    //
    // DELETE /api/users/{id}/avatar
    // =========================================================

    [HttpDelete("{id:guid}/avatar")]
    public async Task<IActionResult> DeleteAvatar(Guid id)
    {
        var currentUserId = GetCurrentUserId();
        var role = GetCurrentRole();

        if (role != "admin" &&
            currentUserId != id)
        {
            return Forbid();
        }

        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
        {
            return NotFound(new
            {
                message = "Không tìm th?y tài kho?n."
            });
        }

        DeleteAvatarFile(user.AvatarUrl);

        user.AvatarUrl = null;

        user.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return Ok(new
        {
            message = "?ã xóa ?nh ??i di?n."
        });
    }


    // =========================================================
    // UPDATE STATUS
    //
    // CH? ADMIN
    // =========================================================

    [HttpPatch("{id:guid}/status")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Status(
        Guid id,
        [FromBody] UserStatusRequest req)
    {
        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
        {
            return NotFound(new
            {
                message = "Không tìm th?y tài kho?n."
            });
        }

        user.IsActive = req.IsActive;

        user.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return NoContent();
    }


    // =========================================================
    // DELETE USER
    //
    // CH? ADMIN
    // =========================================================

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var currentUserId = GetCurrentUserId();

        if (currentUserId == id)
        {
            return BadRequest(new
            {
                message = "Không th? t? xóa tài kho?n qu?n tr? ?ang ??ng nh?p."
            });
        }

        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
        {
            return NotFound(new
            {
                message = "Không tìm th?y tài kho?n."
            });
        }

        DeleteAvatarFile(user.AvatarUrl);

        _db.Users.Remove(user);

        await _db.SaveChangesAsync();

        return NoContent();
    }


    // =========================================================
    // HELPERS
    // =========================================================

    private static string GetAvatarFolder()
    {
        return Path.Combine(
            Directory.GetCurrentDirectory(),
            "wwwroot",
            "uploads",
            "avatars");
    }

    // Ch? xóa file n?m trong wwwroot/uploads/avatars
    private static void DeleteAvatarFile(string? avatarUrl)
    {
        if (string.IsNullOrWhiteSpace(avatarUrl))
        {
            return;
        }

        try
        {
            var fileName = Path.GetFileName(avatarUrl);

            if (string.IsNullOrWhiteSpace(fileName))
            {
                return;
            }

            var physicalPath = Path.Combine(GetAvatarFolder(), fileName);

            if (System.IO.File.Exists(physicalPath))
            {
                System.IO.File.Delete(physicalPath);
            }
        }
        catch
        {
            // Không làm API th?t b?i n?u xóa file c? g?p l?i.
        }
    }

    private Guid GetCurrentUserId()
    {
        var value = User.FindFirstValue(ClaimTypes.NameIdentifier);

        return Guid.TryParse(value, out var id)
            ? id
            : Guid.Empty;
    }

    private string GetCurrentRole()
    {
        return User
            .FindFirstValue(ClaimTypes.Role)?
            .Trim()
            .ToLower()
            ?? string.Empty;
    }

    private static UserAdminDto ToDto(User x, Models.Client? client = null)
    {
        return new UserAdminDto
        {
            Id = x.Id,
            FullName = x.FullName,
            Email = x.Email,
            Phone = x.Phone,
            Role = x.Role,
            IsActive = x.IsActive,
            CreatedAt = x.CreatedAt,
            AvatarUrl = x.AvatarUrl,

            // ⭐ THÊM
            Gender = x.Gender,
            DateOfBirth = client?.DateOfBirth,
            Address = client?.Address
        };
    }
}


// =============================================================
// REQUEST DTO
// =============================================================

public class UserProfileUpdateRequest
{
    public string FullName { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string? Phone { get; set; }

    public string? Gender { get; set; }
    public DateTime? DateOfBirth { get; set; }
    public string? Address { get; set; }
    public string? Occupation { get; set; }
}