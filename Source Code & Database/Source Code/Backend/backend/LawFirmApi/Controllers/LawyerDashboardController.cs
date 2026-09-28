using LawFirmApi.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace ThemisTrustApi.Controllers
{
	[ApiController]
	[Route("api/lawyer-dashboard")]
	[Authorize(Roles = "lawyer")]
	public class LawyerDashboardController : ControllerBase
	{
		private readonly AppDbContext _context;

		public LawyerDashboardController(AppDbContext context)
		{
			_context = context;
		}

		// ============================================================
		// GET: /api/lawyer-dashboard
		// Lấy toàn bộ thông tin cho Lawyer Home
		// ============================================================
		[HttpGet]
		public async Task<IActionResult> GetDashboard()
		{
			try
			{
				var userId = GetCurrentUserId();

				if (userId == null)
				{
					return Unauthorized(new
					{
						message = "Không xác định được người dùng."
					});
				}

				// ====================================================
				// 1. LẤY THÔNG TIN LAWYER
				// ====================================================

				var lawyer = await _context.Lawyers
					.Include(l => l.User)
					.FirstOrDefaultAsync(l => l.Id == userId.Value);

				if (lawyer == null)
				{
					return NotFound(new
					{
						message = "Không tìm thấy thông tin luật sư."
					});
				}

				// ====================================================
				// 2. NGÀY HÔM NAY
				// ====================================================

				var today = DateTime.Today;
				var tomorrow = today.AddDays(1);

				// ====================================================
				// 3. LỊCH HẸN HÔM NAY
				// ====================================================

				var todayAppointments = await _context.Appointments
					.CountAsync(a =>
						a.LawyerId == userId.Value &&
						a.ScheduledAt >= today &&
						a.ScheduledAt < tomorrow &&
						a.Status != "cancelled"
					);

				// ====================================================
				// 4. YÊU CẦU TƯ VẤN MỚI
				// ====================================================

				var newConsultationRequests =
					await _context.ConsultationRequests
						.CountAsync(c =>
							c.LawyerId == userId.Value &&
							c.Status == "new"
						);

				// ====================================================
				// 5. ĐÁNH GIÁ TRUNG BÌNH
				// ====================================================

				var averageRating = await _context.Reviews
					.Where(r => r.LawyerId == userId.Value)
					.Select(r => (double?)r.Rating)
					.AverageAsync() ?? 0;

				// ====================================================
				// 6. TRẢ VỀ
				// ====================================================

				return Ok(new
				{
					lawyerId = lawyer.Id,

					fullName = lawyer.User.FullName,

					email = lawyer.User.Email,

					phone = lawyer.User.Phone,

					role = lawyer.User.Role,

					avatarUrl = lawyer.User.AvatarUrl,

					title = lawyer.Title,

					barLicenseNo = lawyer.BarLicenseNo,

					yearsExp = lawyer.YearsExp,

					bio = lawyer.Bio,

					address = lawyer.Address,

					education = lawyer.Education,

					birthday = lawyer.Birthday,

					isAvailable = lawyer.IsAvailable,

					// ============================
					// STATISTICS
					// ============================

					todayAppointments = todayAppointments,

					newConsultationRequests = newConsultationRequests,

					// Hiện tại chưa có bảng Follow/Favorite
					followingCustomers = 0,

					averageRating = Math.Round(averageRating, 1)
				});
			}
			catch (Exception ex)
			{
				return StatusCode(500, new
				{
					message = "Lỗi khi lấy dữ liệu dashboard luật sư.",
					error = ex.Message
				});
			}
		}

		// ============================================================
		// LẤY ID USER ĐANG ĐĂNG NHẬP
		// ============================================================

		private Guid? GetCurrentUserId()
		{
			var claim =
				User.FindFirst(ClaimTypes.NameIdentifier)
				?? User.FindFirst("sub");

			if (claim == null)
				return null;

			if (Guid.TryParse(claim.Value, out var userId))
				return userId;

			return null;
		}
	}
}