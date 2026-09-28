using LawFirmApi.Data;
using LawFirmApi.DTOs;
using LawFirmApi.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawFirmApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PracticeAreasController : ControllerBase
{
    private readonly AppDbContext _db;
    public PracticeAreasController(AppDbContext db) => _db = db;

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<PracticeAreaDto>>> GetAll()
    {
        var areas = await _db.PracticeAreas.OrderBy(a => a.SortOrder).ToListAsync();
        return Ok(areas.Select(a => new PracticeAreaDto
        {
            Id = a.Id,
            Name = a.Name,
            IconKey = a.IconKey,
            SortOrder = a.SortOrder,
        }));
    }

    [HttpPost]
    [Authorize(Roles = "admin")]
    public async Task<ActionResult<PracticeAreaDto>> Create(PracticeAreaDto dto)
    {
        var area = new PracticeArea { Name = dto.Name, IconKey = dto.IconKey, SortOrder = dto.SortOrder };
        _db.PracticeAreas.Add(area);
        await _db.SaveChangesAsync();
        dto.Id = area.Id;
        return Ok(dto);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Delete(short id)
    {
        var area = await _db.PracticeAreas.FindAsync(id);
        if (area is null) return NotFound();
        _db.PracticeAreas.Remove(area);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
