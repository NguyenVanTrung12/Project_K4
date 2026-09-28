using LawFirmApi.Data;
using LawFirmApi.DTOs;
using LawFirmApi.Models;
using LawFirmApi.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
namespace LawFirmApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ITokenService _tokenService;

    public AuthController(AppDbContext db, ITokenService tokenService)
    {
        _db = db;
        _tokenService = tokenService;
    }

    [HttpPost("register")]
    public async Task<ActionResult<AuthResponse>> Register(RegisterRequest req)
    {
        if (await _db.Users.AnyAsync(u => u.Email == req.Email))
            return Conflict(new { message = "Email đã được sử dụng." });

        if (req.Role is not ("client" or "lawyer"))
            return BadRequest(new { message = "Vai trò đăng ký chỉ có thể là 'client' hoặc 'lawyer'." });

        var user = new User
        {
            FullName = req.FullName,
            Email = req.Email,
            Phone = req.Phone,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password),
            Role = req.Role,
        };
        _db.Users.Add(user);

        if (req.Role == "client")
            _db.Clients.Add(new Client { Id = user.Id });
        else
            _db.Lawyers.Add(new Lawyer { Id = user.Id, Title = "Luật sư" });

        await _db.SaveChangesAsync();

        var (token, expiresAt) = _tokenService.GenerateToken(user);
        return Ok(new AuthResponse
        {
            Token = token,
            ExpiresAt = expiresAt,
            User = ToDto(user),
        });
    }

    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(LoginRequest req)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == req.Email);
        if (user is null || !BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash))
            return Unauthorized(new { message = "Email hoặc mật khẩu không đúng." });

        if (!user.IsActive)
            return Unauthorized(new { message = "Tài khoản đã bị khoá." });

        var (token, expiresAt) = _tokenService.GenerateToken(user);
        return Ok(new AuthResponse
        {
            Token = token,
            ExpiresAt = expiresAt,
            User = ToDto(user),
        });
    }

    // Cấp lại token mới trước khi token hiện tại hết hạn, giữ nguyên phiên đăng nhập
    // mà không cần người dùng nhập lại mật khẩu. Client (mobile/web) tự gọi định kỳ.
    [HttpPost("refresh")]
    [Authorize]
    public async Task<ActionResult<AuthResponse>> Refresh()
    {
        var userId = Guid.Parse(User.FindFirstValue(System.Security.Claims.ClaimTypes.NameIdentifier)!);
        var user = await _db.Users.FindAsync(userId);
        if (user is null || !user.IsActive) return Unauthorized();

        var (token, expiresAt) = _tokenService.GenerateToken(user);
        return Ok(new AuthResponse
        {
            Token = token,
            ExpiresAt = expiresAt,
            User = ToDto(user),
        });
    }

    private static UserDto ToDto(User u) => new()
    {
        Id = u.Id,
        FullName = u.FullName,
        Email = u.Email,
        Phone = u.Phone,
        Role = u.Role,
        AvatarUrl = u.AvatarUrl,
    };
}
