using System.Security.Claims;
using LawFirmApi.Data;
using LawFirmApi.DTOs;
using LawFirmApi.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawFirmApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ReviewsController : ControllerBase
{
    private readonly AppDbContext _db;

    public ReviewsController(AppDbContext db)
    {
        _db = db;
    }

    // =========================================================
    // GET REVIEWS BY LAWYER
    // GET /api/reviews/lawyer/{lawyerId}
    // =========================================================

    [HttpGet("lawyer/{lawyerId:guid}")]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<ReviewDto>>> GetByLawyer(
        Guid lawyerId)
    {
        var reviews = await _db.Reviews
            .AsNoTracking()
            .Include(r => r.Client)
                .ThenInclude(c => c.User)
            .Where(r => r.LawyerId == lawyerId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        var result = reviews.Select(r => new ReviewDto
        {
            Id = r.Id,

            LawyerId = r.LawyerId,

            ClientId = r.ClientId,

            ClientName =
                r.Client?.User?.FullName
                ?? "Khách hàng",

            Rating = r.Rating,

            Comment = r.Comment,

            CreatedAt = r.CreatedAt
        });

        return Ok(result);
    }


    // =========================================================
    // GET LATEST REVIEWS
    // GET /api/reviews/latest?take=3
    // =========================================================

    [HttpGet("latest")]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<object>>> GetLatest(
        [FromQuery] int take = 3)
    {
        // Không cho frontend truyền take quá lớn
        take = Math.Clamp(take, 1, 20);

        var reviews = await _db.Reviews
            .AsNoTracking()
            .Include(r => r.Client)
                .ThenInclude(c => c.User)
            .Include(r => r.Lawyer)
                .ThenInclude(l => l.User)
            .Where(r =>
                r.Comment != null &&
                r.Comment != "")
            .OrderByDescending(r => r.CreatedAt)
            .Take(take)
            .ToListAsync();

        var result = reviews.Select(r => new
        {
            id = r.Id,

            clientName =
                r.Client?.User?.FullName
                ?? "Khách hàng",

            lawyerName =
                r.Lawyer?.User?.FullName
                ?? "Luật sư",

            rating = (int)r.Rating,

            comment = r.Comment,

            createdAt = r.CreatedAt
        });

        return Ok(result);
    }


    // =========================================================
    // CREATE REVIEW
    // POST /api/reviews
    // =========================================================

    [HttpPost]
    [Authorize(Roles = "client")]
    public async Task<ActionResult<ReviewDto>> Create(
        [FromBody] ReviewCreateRequest req)
    {
        var userId =
            User.FindFirstValue(
                ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userId, out var clientId))
        {
            return Unauthorized(new
            {
                message = "Token không hợp lệ."
            });
        }

        // Kiểm tra luật sư
        var lawyerExists =
            await _db.Lawyers.AnyAsync(
                l => l.Id == req.LawyerId);

        if (!lawyerExists)
        {
            return BadRequest(new
            {
                message = "Luật sư không tồn tại."
            });
        }

        // Kiểm tra rating
        if (req.Rating < 1 || req.Rating > 5)
        {
            return BadRequest(new
            {
                message = "Đánh giá phải từ 1 đến 5 sao."
            });
        }

        // Nếu đánh giá theo Case
        if (req.CaseId.HasValue)
        {
            var alreadyReviewed =
                await _db.Reviews.AnyAsync(
                    r =>
                        r.ClientId == clientId &&
                        r.CaseId == req.CaseId);

            if (alreadyReviewed)
            {
                return Conflict(new
                {
                    message =
                        "Bạn đã đánh giá vụ án này rồi."
                });
            }
        }

        var review = new Review
        {
            LawyerId = req.LawyerId,

            ClientId = clientId,

            CaseId = req.CaseId,

            Rating = (byte)req.Rating,

            Comment = req.Comment,

            CreatedAt = DateTime.UtcNow
        };

        _db.Reviews.Add(review);

        await _db.SaveChangesAsync();


        // =====================================================
        // UPDATE LAWYER RATING
        // =====================================================

        var lawyer =
            await _db.Lawyers
                .FirstOrDefaultAsync(
                    l => l.Id == req.LawyerId);

        if (lawyer != null)
        {
            var average =
                await _db.Reviews
                    .Where(
                        r =>
                            r.LawyerId ==
                            req.LawyerId)
                    .AverageAsync(
                        r => (double)r.Rating);

            lawyer.RatingAvg =
                Math.Round(
                    (decimal)average,
                    1);

            await _db.SaveChangesAsync();
        }


        // =====================================================
        // RESPONSE
        // =====================================================

        var client =
            await _db.Clients
                .Include(c => c.User)
                .FirstOrDefaultAsync(
                    c => c.Id == clientId);

        return Ok(new ReviewDto
        {
            Id = review.Id,

            LawyerId = review.LawyerId,

            ClientId = review.ClientId,

            ClientName =
                client?.User?.FullName
                ?? "Khách hàng",

            Rating = review.Rating,

            Comment = review.Comment,

            CreatedAt = review.CreatedAt
        });
    }
}