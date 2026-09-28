using LawFirmApi.Data;
using LawFirmApi.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawFirmApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "admin,staff,lawyer")]
public class ClientsController : ControllerBase
{
    private readonly AppDbContext _db;

    public ClientsController(AppDbContext db)
    {
        _db = db;
    }


    // =========================================================
    // GET ALL CLIENTS
    // =========================================================

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ClientDto>>> GetAll(
        [FromQuery] string? q)
    {
        var query = _db.Clients
            .Include(c => c.User)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(q))
        {
            q = q.Trim();

            query = query.Where(c =>
                c.User.FullName.Contains(q) ||
                c.User.Email.Contains(q));
        }

        var clients = await query
            .OrderBy(c => c.User.FullName)
            .ToListAsync();

        return Ok(
            clients
                .Select(ToDto)
                .ToList());
    }


    // =========================================================
    // GET CLIENT
    // =========================================================

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ClientDto>> GetById(Guid id)
    {
        var client = await _db.Clients
            .Include(c => c.User)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (client == null)
        {
            return NotFound(new
            {
                message = "Không tìm th?y khách hàng."
            });
        }

        return Ok(ToDto(client));
    }


    // =========================================================
    // DELETE
    //
    // CH? ADMIN
    // =========================================================

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var user = await _db.Users
            .FindAsync(id);

        if (user == null)
        {
            return NotFound(new
            {
                message = "Không tìm th?y tài kho?n."
            });
        }

        _db.Users.Remove(user);

        await _db.SaveChangesAsync();

        return NoContent();
    }


    // =========================================================
    // DTO
    // =========================================================

    private static ClientDto ToDto(
        Models.Client c)
    {
        return new ClientDto
        {
            Id = c.Id,

            FullName =
                c.User.FullName,

            Email =
                c.User.Email,

            Phone =
                c.User.Phone,

            // QUAN TR?NG
            AvatarUrl =
                c.User.AvatarUrl,

            IdNumber =
                c.IdNumber,

            Address =
                c.Address
        };
    }
}