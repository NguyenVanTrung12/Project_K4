using LawFirmApi.Data; using LawFirmApi.DTOs; using LawFirmApi.Models; using Microsoft.AspNetCore.Authorization; using Microsoft.AspNetCore.Mvc; using Microsoft.EntityFrameworkCore;
namespace LawFirmApi.Controllers;
[ApiController][Route("api/services")]
public class ServicesController : ControllerBase
{
 private readonly AppDbContext _db; public ServicesController(AppDbContext db)=>_db=db;
 [HttpGet][AllowAnonymous] public async Task<ActionResult<IEnumerable<LegalServiceDto>>> GetAll([FromQuery] short? practiceAreaId){var q=_db.LegalServices.Include(x=>x.PracticeArea).Where(x=>x.IsActive); if(practiceAreaId.HasValue)q=q.Where(x=>x.PracticeAreaId==practiceAreaId); var a=await q.OrderBy(x=>x.SortOrder).ToListAsync(); return Ok(a.Select(ToDto));}
 [HttpGet("{id:int}")][AllowAnonymous] public async Task<ActionResult<LegalServiceDto>> GetById(int id){var x=await _db.LegalServices.Include(s=>s.PracticeArea).FirstOrDefaultAsync(s=>s.Id==id&&s.IsActive); return x is null?NotFound():Ok(ToDto(x));}
 [HttpPost][Authorize(Roles="admin,staff")] public async Task<ActionResult<LegalServiceDto>> Create(LegalService x){x.Id=0;_db.LegalServices.Add(x);await _db.SaveChangesAsync();await _db.Entry(x).Reference(s=>s.PracticeArea).LoadAsync();return Ok(ToDto(x));}
 [HttpPut("{id:int}")][Authorize(Roles="admin,staff")] public async Task<IActionResult> Update(int id,LegalService req){var x=await _db.LegalServices.FindAsync(id);if(x is null)return NotFound();x.Title=req.Title;x.Description=req.Description;x.Detail=req.Detail;x.StartingPrice=req.StartingPrice;x.IconKey=req.IconKey;x.PracticeAreaId=req.PracticeAreaId;x.IsActive=req.IsActive;await _db.SaveChangesAsync();return NoContent();}
 [HttpDelete("{id:int}")][Authorize(Roles="admin")] public async Task<IActionResult> Delete(int id){var x=await _db.LegalServices.FindAsync(id);if(x is null)return NotFound();x.IsActive=false;await _db.SaveChangesAsync();return NoContent();}
 static LegalServiceDto ToDto(LawFirmApi.Models.LegalService x)=>new(){Id=x.Id,PracticeAreaId=x.PracticeAreaId,PracticeAreaName=x.PracticeArea?.Name??"",Title=x.Title,Description=x.Description,Detail=x.Detail,StartingPrice=x.StartingPrice,IconKey=x.IconKey,IsActive=x.IsActive};
}
