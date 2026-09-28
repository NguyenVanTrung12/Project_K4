using System.Security.Claims;
using LawFirmApi.Data;
using LawFirmApi.DTOs;
using LawFirmApi.Helpers;
using LawFirmApi.Hubs;
using LawFirmApi.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace LawFirmApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class MessagesController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IHubContext<ChatHub> _hub;

    public MessagesController(
        AppDbContext db,
        IHubContext<ChatHub> hub)
    {
        _db = db;
        _hub = hub;
    }

    // =========================================================
    // CURRENT USER ID
    // =========================================================

    private Guid CurrentUserId
    {
        get
        {
            var value =
                User.FindFirstValue(
                    ClaimTypes.NameIdentifier);

            return Guid.TryParse(
                value,
                out var id)
                ? id
                : Guid.Empty;
        }
    }

    // =========================================================
    // CURRENT ROLE
    // =========================================================

    private string CurrentRole
    {
        get
        {
            return User.FindFirstValue(
                       ClaimTypes.Role)?
                       .Trim()
                       .ToLowerInvariant()
                   ?? string.Empty;
        }
    }

    // =========================================================
    // CHECK CONVERSATION ACCESS
    //
    // ADMIN / STAFF
    //     -> Xem mọi hội thoại
    //
    // LAWYER
    //     -> Chỉ hội thoại của mình
    //
    // CLIENT
    //     -> Chỉ hội thoại của mình
    // =========================================================

    private bool CanAccessConversation(
        Conversation conv)
    {
        if (CurrentRole is "admin" or "staff")
        {
            return true;
        }

        if (CurrentRole == "client")
        {
            return conv.ClientId ==
                   CurrentUserId;
        }

        if (CurrentRole == "lawyer")
        {
            return conv.LawyerId ==
                   CurrentUserId;
        }

        return false;
    }

    // =========================================================
    // GET CONVERSATIONS
    //
    // GET /api/messages/conversations
    // =========================================================

    [HttpGet("conversations")]
    public async Task<
        ActionResult<IEnumerable<ConversationDto>>>
        GetConversations()
    {
        if (CurrentUserId ==
            Guid.Empty)
        {
            return Unauthorized(new
            {
                message =
                    "Token không hợp lệ."
            });
        }

        var query =
            _db.Conversations
                .AsNoTracking()

                .Include(c =>
                    c.Client)
                    .ThenInclude(cl =>
                        cl.User)

                .Include(c =>
                    c.Lawyer)
                    .ThenInclude(l =>
                        l.User)

                .Include(c =>
                    c.Messages
                        .OrderByDescending(
                            m => m.SentAt)
                        .Take(1))

                .AsQueryable();

        // =====================================================
        // LAWYER
        // =====================================================

        if (CurrentRole ==
            "lawyer")
        {
            query = query.Where(
                c =>
                    c.LawyerId ==
                    CurrentUserId);
        }

        // =====================================================
        // CLIENT
        // =====================================================

        else if (CurrentRole ==
                 "client")
        {
            query = query.Where(
                c =>
                    c.ClientId ==
                    CurrentUserId);
        }

        // =====================================================
        // ADMIN / STAFF
        //
        // Không filter
        // =====================================================

        var conversations =
            await query
                .OrderByDescending(
                    c =>
                        c.LastMessageAt)
                .ThenByDescending(
                    c =>
                        c.CreatedAt)
                .ToListAsync();

        var result =
            conversations
                .Select(c =>
                    new ConversationDto
                    {
                        Id = c.Id,

                        ClientId =
                            c.ClientId,

                        ClientName =
                            c.Client?.User
                                ?.FullName
                            ?? "Khách hàng",

                        LawyerId =
                            c.LawyerId,

                        LawyerName =
                            c.Lawyer?.User
                                ?.FullName
                            ?? "Luật sư",

                        LastMessageAt =
                            c.LastMessageAt,

                        LastMessagePreview =
                            c.Messages
                                .FirstOrDefault()
                                ?.Content
                    })
                .ToList();

        return Ok(result);
    }

    // =========================================================
    // CREATE / START CONVERSATION
    //
    // POST /api/messages/conversations
    //
    // LAWYER
    // {
    //     "clientId": "CLIENT_GUID"
    // }
    //
    // CLIENT
    // {
    //     "lawyerId": "LAWYER_GUID"
    // }
    //
    // ADMIN / STAFF
    // {
    //     "clientId": "...",
    //     "lawyerId": "..."
    // }
    // =========================================================

    [HttpPost("conversations")]
    [Authorize(
        Roles =
            "admin,staff,lawyer,client")]
    public async Task<
        ActionResult<ConversationDto>>
        StartConversation(
            [FromBody]
            StartConversationRequest req)
    {
        // =====================================================
        // TOKEN
        // =====================================================

        if (CurrentUserId ==
            Guid.Empty)
        {
            return Unauthorized(new
            {
                message =
                    "Token không hợp lệ hoặc không có UserId."
            });
        }

        // =====================================================
        // REQUEST NULL
        // =====================================================

        if (req == null)
        {
            return BadRequest(new
            {
                message =
                    "Dữ liệu tạo cuộc hội thoại không hợp lệ."
            });
        }

        Guid clientId;
        Guid lawyerId;

        // =====================================================
        // LAWYER
        //
        // Lawyer chỉ được chat với Client
        // đã từng đặt lịch với chính Lawyer.
        // =====================================================

        if (CurrentRole ==
            "lawyer")
        {
            // -------------------------------------------------
            // Kiểm tra hồ sơ Lawyer
            // -------------------------------------------------

            var lawyerExists =
                await _db.Lawyers
                    .AsNoTracking()
                    .AnyAsync(
                        l =>
                            l.Id ==
                            CurrentUserId);

            if (!lawyerExists)
            {
                return BadRequest(new
                {
                    message =
                        "Tài khoản Lawyer chưa có hồ sơ luật sư."
                });
            }

            // -------------------------------------------------
            // ClientId bắt buộc
            // -------------------------------------------------

            if (!req.ClientId.HasValue ||
                req.ClientId.Value ==
                Guid.Empty)
            {
                return BadRequest(new
                {
                    message =
                        "ClientId là bắt buộc khi Lawyer tạo cuộc trò chuyện."
                });
            }

            clientId =
                req.ClientId.Value;

            lawyerId =
                CurrentUserId;

            // -------------------------------------------------
            // QUAN TRỌNG
            //
            // Lawyer chỉ được chat với Client
            // đã đặt lịch với chính Lawyer đó.
            // -------------------------------------------------

            var hasAppointment =
                await _db.Appointments
                    .AsNoTracking()
                    .AnyAsync(a =>
                        a.ClientId ==
                            clientId &&
                        a.LawyerId ==
                            lawyerId &&
                        a.Status !=
                            "cancelled");

            if (!hasAppointment)
            {
                return Forbid();
            }
        }

        // =====================================================
        // CLIENT
        //
        // Client chỉ được chat với Lawyer
        // mà mình đã từng đặt lịch.
        // =====================================================

        else if (CurrentRole ==
                 "client")
        {
            // -------------------------------------------------
            // Kiểm tra hồ sơ Client
            // -------------------------------------------------

            var clientExists =
                await _db.Clients
                    .AsNoTracking()
                    .AnyAsync(
                        c =>
                            c.Id ==
                            CurrentUserId);

            if (!clientExists)
            {
                return BadRequest(new
                {
                    message =
                        "Tài khoản Client chưa có hồ sơ khách hàng."
                });
            }

            // -------------------------------------------------
            // LawyerId bắt buộc
            // -------------------------------------------------

            if (!req.LawyerId.HasValue ||
                req.LawyerId.Value ==
                Guid.Empty)
            {
                return BadRequest(new
                {
                    message =
                        "LawyerId là bắt buộc khi Client tạo cuộc trò chuyện."
                });
            }

            clientId =
                CurrentUserId;

            lawyerId =
                req.LawyerId.Value;

            // -------------------------------------------------
            // Client chỉ được chat với Lawyer
            // đã từng đặt lịch.
            // -------------------------------------------------

            var hasAppointment =
                await _db.Appointments
                    .AsNoTracking()
                    .AnyAsync(a =>
                        a.ClientId ==
                            clientId &&
                        a.LawyerId ==
                            lawyerId &&
                        a.Status !=
                            "cancelled");

            if (!hasAppointment)
            {
                return Forbid();
            }
        }

        // =====================================================
        // ADMIN / STAFF
        //
        // Có thể tạo conversation giữa Client + Lawyer.
        // =====================================================

        else if (
            CurrentRole is
                "admin" or
                "staff")
        {
            if (!req.ClientId.HasValue ||
                req.ClientId.Value ==
                Guid.Empty)
            {
                return BadRequest(new
                {
                    message =
                        "ClientId là bắt buộc."
                });
            }

            if (!req.LawyerId.HasValue ||
                req.LawyerId.Value ==
                Guid.Empty)
            {
                return BadRequest(new
                {
                    message =
                        "LawyerId là bắt buộc."
                });
            }

            clientId =
                req.ClientId.Value;

            lawyerId =
                req.LawyerId.Value;
        }

        // =====================================================
        // ROLE KHÔNG HỢP LỆ
        // =====================================================

        else
        {
            return Forbid();
        }

        // =====================================================
        // KHÔNG CHO TỰ CHAT VỚI CHÍNH MÌNH
        // =====================================================

        if (clientId ==
            lawyerId)
        {
            return BadRequest(new
            {
                message =
                    "Client và Lawyer không thể là cùng một tài khoản."
            });
        }

        // =====================================================
        // KIỂM TRA CLIENT
        // =====================================================

        var client =
            await _db.Clients
                .Include(c =>
                    c.User)
                .FirstOrDefaultAsync(
                    c =>
                        c.Id ==
                        clientId);

        if (client == null)
        {
            return BadRequest(new
            {
                message =
                    "Khách hàng không tồn tại."
            });
        }

        // =====================================================
        // KIỂM TRA LAWYER
        // =====================================================

        var lawyer =
            await _db.Lawyers
                .Include(l =>
                    l.User)
                .FirstOrDefaultAsync(
                    l =>
                        l.Id ==
                        lawyerId);

        if (lawyer == null)
        {
            return BadRequest(new
            {
                message =
                    "Luật sư không tồn tại."
            });
        }

        // =====================================================
        // KIỂM TRA CONVERSATION ĐÃ TỒN TẠI
        // =====================================================

        var existing =
            await _db.Conversations
                .FirstOrDefaultAsync(
                    c =>
                        c.ClientId ==
                            clientId &&
                        c.LawyerId ==
                            lawyerId &&
                        c.CaseId ==
                            req.CaseId);

        if (existing != null)
        {
            var existingDto =
                new ConversationDto
                {
                    Id =
                        existing.Id,

                    ClientId =
                        existing.ClientId,

                    ClientName =
                        client.User
                            ?.FullName
                        ?? "Khách hàng",

                    LawyerId =
                        existing.LawyerId,

                    LawyerName =
                        lawyer.User
                            ?.FullName
                        ?? "Luật sư",

                    LastMessageAt =
                        existing.LastMessageAt,

                    LastMessagePreview =
                        await _db.Messages
                            .Where(
                                m =>
                                    m.ConversationId ==
                                    existing.Id)
                            .OrderByDescending(
                                m =>
                                    m.SentAt)
                            .Select(
                                m =>
                                    m.Content)
                            .FirstOrDefaultAsync()
                };

            return Ok(
                existingDto);
        }

        // =====================================================
        // TẠO CONVERSATION
        // =====================================================

        var conv =
            new Conversation
            {
                ClientId =
                    clientId,

                LawyerId =
                    lawyerId,

                CaseId =
                    req.CaseId
            };

        _db.Conversations.Add(
            conv);

        await _db.SaveChangesAsync();

        // =====================================================
        // DTO
        // =====================================================

        var result =
            new ConversationDto
            {
                Id =
                    conv.Id,

                ClientId =
                    conv.ClientId,

                ClientName =
                    client.User
                        ?.FullName
                    ?? "Khách hàng",

                LawyerId =
                    conv.LawyerId,

                LawyerName =
                    lawyer.User
                        ?.FullName
                    ?? "Luật sư",

                LastMessageAt =
                    conv.LastMessageAt,

                LastMessagePreview =
                    null
            };

        // =====================================================
        // SIGNALR
        // =====================================================

        await _hub.Clients
            .Group(
                ChatHub.UserGroup(
                    clientId.ToString()))
            .SendAsync(
                "ConversationCreated",
                new
                {
                    conversationId =
                        conv.Id
                });

        await _hub.Clients
            .Group(
                ChatHub.UserGroup(
                    lawyerId.ToString()))
            .SendAsync(
                "ConversationCreated",
                new
                {
                    conversationId =
                        conv.Id
                });

        return Ok(result);
    }

    // =========================================================
    // GET MESSAGES
    //
    // GET /api/messages/conversations/{id}
    // =========================================================

    [HttpGet(
        "conversations/{conversationId:guid}")]
    public async Task<
        ActionResult<IEnumerable<MessageDto>>>
        GetMessages(
            Guid conversationId)
    {
        if (CurrentUserId ==
            Guid.Empty)
        {
            return Unauthorized();
        }

        var conv =
            await _db.Conversations
                .FirstOrDefaultAsync(
                    c =>
                        c.Id ==
                        conversationId);

        if (conv == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy cuộc trò chuyện."
            });
        }

        if (!CanAccessConversation(
                conv))
        {
            return Forbid();
        }

        var messages =
            await _db.Messages
                .Where(
                    m =>
                        m.ConversationId ==
                        conversationId)
                .OrderBy(
                    m =>
                        m.SentAt)
                .ToListAsync();

        var result =
            messages
                .Select(
                    m =>
                        new MessageDto
                        {
                            Id =
                                m.Id,

                            ConversationId =
                                m.ConversationId,

                            SenderId =
                                m.SenderId,

                            Content =
                                m.Content,

                            AttachmentUrl =
                                m.AttachmentUrl,

                            SentAt =
                                m.SentAt,

                            ReadAt =
                                m.ReadAt
                        })
                .ToList();

        return Ok(result);
    }

    // =========================================================
    // SEND MESSAGE
    //
    // POST /api/messages
    // =========================================================

    [HttpPost]
    public async Task<
        ActionResult<MessageDto>>
        Send(
            [FromBody]
            MessageCreateRequest req)
    {
        if (CurrentUserId ==
            Guid.Empty)
        {
            return Unauthorized();
        }

        if (req == null)
        {
            return BadRequest(new
            {
                message =
                    "Dữ liệu tin nhắn không hợp lệ."
            });
        }

        var conv =
            await _db.Conversations
                .FirstOrDefaultAsync(
                    c =>
                        c.Id ==
                        req.ConversationId);

        if (conv == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy cuộc trò chuyện."
            });
        }

        // =====================================================
        // KIỂM TRA QUYỀN
        // =====================================================

        if (!CanAccessConversation(
                conv))
        {
            return Forbid();
        }

        // =====================================================
        // CONTENT
        // =====================================================

        if (
            string.IsNullOrWhiteSpace(
                req.Content) &&
            string.IsNullOrWhiteSpace(
                req.AttachmentUrl))
        {
            return BadRequest(new
            {
                message =
                    "Tin nhắn không được để trống."
            });
        }

        // =====================================================
        // CREATE MESSAGE
        // =====================================================

        var msg =
            new Message
            {
                ConversationId =
                    req.ConversationId,

                SenderId =
                    CurrentUserId,

                Content =
                    req.Content,

                AttachmentUrl =
                    req.AttachmentUrl
            };

        _db.Messages.Add(msg);

        conv.LastMessageAt =
            msg.SentAt;

        await _db.SaveChangesAsync();

        // =====================================================
        // RECIPIENT
        // =====================================================

        Guid? recipientId = null;

        if (CurrentUserId ==
            conv.ClientId)
        {
            recipientId =
                conv.LawyerId;
        }
        else if (
            CurrentUserId ==
            conv.LawyerId)
        {
            recipientId =
                conv.ClientId;
        }

        // =====================================================
        // SENDER NAME
        // =====================================================

        var senderName =
            User.FindFirstValue(
                ClaimTypes.Name)
            ?? "Người dùng";

        var content =
            req.Content ?? "";

        var preview =
            content.Length > 60
                ? $"{senderName}: {content.Substring(0, 60)}..."
                : $"{senderName}: {content}";

        // =====================================================
        // NOTIFICATION
        // =====================================================

        if (
            CurrentRole is
                "admin" or
                "staff")
        {
            NotificationHelper.Notify(
                _db,
                conv.ClientId,
                "message",
                "Tin nhắn mới",
                preview,
                conv.Id);

            NotificationHelper.Notify(
                _db,
                conv.LawyerId,
                "message",
                "Tin nhắn mới",
                preview,
                conv.Id);
        }
        else if (
            recipientId.HasValue)
        {
            NotificationHelper.Notify(
                _db,
                recipientId.Value,
                "message",
                "Tin nhắn mới",
                preview,
                conv.Id);
        }

        await _db.SaveChangesAsync();

        // =====================================================
        // DTO
        // =====================================================

        var messageDto =
            new MessageDto
            {
                Id =
                    msg.Id,

                ConversationId =
                    msg.ConversationId,

                SenderId =
                    msg.SenderId,

                Content =
                    msg.Content,

                AttachmentUrl =
                    msg.AttachmentUrl,

                SentAt =
                    msg.SentAt,

                ReadAt =
                    msg.ReadAt
            };

        // =====================================================
        // SIGNALR
        //
        // Conversation
        // =====================================================

        await _hub.Clients
            .Group(
                ChatHub.ConversationGroup(
                    conv.Id.ToString()))
            .SendAsync(
                "ReceiveMessage",
                messageDto);

        // =====================================================
        // SIGNALR
        //
        // Client
        // =====================================================

        await _hub.Clients
            .Group(
                ChatHub.UserGroup(
                    conv.ClientId.ToString()))
            .SendAsync(
                "ConversationUpdated",
                new
                {
                    conversationId =
                        conv.Id
                });

        // =====================================================
        // SIGNALR
        //
        // Lawyer
        // =====================================================

        await _hub.Clients
            .Group(
                ChatHub.UserGroup(
                    conv.LawyerId.ToString()))
            .SendAsync(
                "ConversationUpdated",
                new
                {
                    conversationId =
                        conv.Id
                });

        return Ok(
            messageDto);
    }
}