using System.Security.Claims;
using LawFirmApi.Data;
using LawFirmApi.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawFirmApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "admin,staff,lawyer,client")]
public class NotificationsController : ControllerBase
{
    private readonly AppDbContext _db;

    public NotificationsController(AppDbContext db)
    {
        _db = db;
    }

    // =========================================================
    // L?Y USER ID HI?N T?I
    // =========================================================

    private Guid? GetCurrentUserId()
    {
        var userId =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? User.FindFirstValue("userId");

        if (Guid.TryParse(userId, out var id))
        {
            return id;
        }

        return null;
    }

    // =========================================================
    // L?Y ROLE
    // =========================================================

    private string GetCurrentRole()
    {
        var role =
            User.FindFirstValue(ClaimTypes.Role)
            ?? User.FindFirstValue("role")
            ?? User.FindFirstValue("Role");

        return role?
            .Trim()
            .ToLowerInvariant()
            ?? "";
    }

    // =========================================================
    // GET: api/notifications
    //
    // ADMIN:
    //   - M?c ??nh: xem t?t c?
    //   - Có lawyerId: ch? xem notification c?a lawyer ?ó
    //
    // LAWYER:
    //   - Luôn ch? xem notification c?a chính mình
    //
    // STAFF:
    //   - Ch? xem notification c?a chính mình
    // =========================================================

    [HttpGet]
    public async Task<ActionResult<IEnumerable<NotificationDto>>> GetMine(
        [FromQuery] bool? unreadOnly = null,
        [FromQuery] Guid? lawyerId = null)
    {
        var currentUserId = GetCurrentUserId();
        var role = GetCurrentRole();

        if (currentUserId == null)
        {
            return Unauthorized(new
            {
                message = "Không xác ??nh ???c ng??i dùng hi?n t?i."
            });
        }

        IQueryable<Models.Notification> query =
            _db.Notifications.AsNoTracking();

        // =====================================================
        // ADMIN
        // =====================================================

        if (role == "admin")
        {
            // Không truy?n lawyerId
            // ? Admin xem t?t c?

            if (lawyerId.HasValue)
            {
                // Có lawyerId
                // ? Admin ch? xem notification c?a lawyer ?ó

                query = query.Where(n =>
                    n.UserId == lawyerId.Value
                );
            }
        }
        else
        {
            // =================================================
            // LAWYER / STAFF
            //
            // KHÔNG ???C PHÉP truy?n lawyerId ?? xem ng??i khác
            // =================================================

            query = query.Where(n =>
                n.UserId == currentUserId.Value
            );
        }

        // =====================================================
        // L?C CH?A ??C
        // =====================================================

        if (unreadOnly == true)
        {
            query = query.Where(n => !n.IsRead);
        }

        // =====================================================
        // L?Y D? LI?U
        // =====================================================

        var items = await query
            .OrderByDescending(n => n.CreatedAt)
            .Take(100)
            .ToListAsync();

        var result = items.Select(n => new NotificationDto
        {
            Id = n.Id,

            // QUAN TR?NG
            UserId = n.UserId,

            Type = n.Type,

            Title = n.Title,

            Body = n.Body,

            RefId = n.RefId,

            IsRead = n.IsRead,

            CreatedAt = n.CreatedAt
        });

        return Ok(result);
    }

    // =========================================================
    // GET: api/notifications/unread-count
    //
    // ADMIN:
    //   - Không lawyerId ? t?t c?
    //   - Có lawyerId ? unread c?a lawyer ?ó
    //
    // LAWYER:
    //   - Ch? unread c?a mình
    // =========================================================

    [HttpGet("unread-count")]
    public async Task<ActionResult<int>> GetUnreadCount(
        [FromQuery] Guid? lawyerId = null)
    {
        var currentUserId = GetCurrentUserId();
        var role = GetCurrentRole();

        if (currentUserId == null)
        {
            return Unauthorized(new
            {
                message = "Không xác ??nh ???c ng??i dùng hi?n t?i."
            });
        }

        IQueryable<Models.Notification> query =
            _db.Notifications.AsNoTracking();

        // =====================================================
        // ADMIN
        // =====================================================

        if (role == "admin")
        {
            if (lawyerId.HasValue)
            {
                query = query.Where(n =>
                    n.UserId == lawyerId.Value
                );
            }
        }
        else
        {
            // =================================================
            // LAWYER / STAFF
            // =================================================

            query = query.Where(n =>
                n.UserId == currentUserId.Value
            );
        }

        var count = await query.CountAsync(n => !n.IsRead);

        return Ok(count);
    }

    // =========================================================
    // PATCH: api/notifications/{id}/read
    //
    // ADMIN:
    //   ? Có th? ??c b?t k? notification
    //
    // LAWYER:
    //   ? Ch? ??c notification c?a mình
    // =========================================================

    [HttpPatch("{id:guid}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        var currentUserId = GetCurrentUserId();
        var role = GetCurrentRole();

        if (currentUserId == null)
        {
            return Unauthorized();
        }

        IQueryable<Models.Notification> query =
            _db.Notifications;

        if (role != "admin")
        {
            query = query.Where(n =>
                n.UserId == currentUserId.Value
            );
        }

        var notification = await query
            .FirstOrDefaultAsync(n => n.Id == id);

        if (notification == null)
        {
            return NotFound(new
            {
                message = "Không tìm th?y thông báo."
            });
        }

        if (!notification.IsRead)
        {
            notification.IsRead = true;

            await _db.SaveChangesAsync();
        }

        return NoContent();
    }

    // =========================================================
    // PATCH: api/notifications/read-all
    //
    // ADMIN:
    //   ? T?t c?
    //
    // LAWYER:
    //   ? Ch? c?a mình
    // =========================================================

    [HttpPatch("read-all")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var currentUserId = GetCurrentUserId();
        var role = GetCurrentRole();

        if (currentUserId == null)
        {
            return Unauthorized();
        }

        var query = _db.Notifications
            .Where(n => !n.IsRead);

        if (role != "admin")
        {
            query = query.Where(n =>
                n.UserId == currentUserId.Value
            );
        }

        await query.ExecuteUpdateAsync(setters =>
            setters.SetProperty(
                n => n.IsRead,
                true
            )
        );

        return NoContent();
    }
}