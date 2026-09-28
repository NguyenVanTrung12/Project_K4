using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace LawFirmApi.Hubs;

/// <summary>
/// Hub SignalR cho tin nhắn thời gian thực. Mỗi kết nối tự động được thêm vào group
/// riêng theo UserId (để nhận "ConversationUpdated" — cập nhật preview danh sách hội thoại
/// dù đang không mở đúng hội thoại đó), và có thể chủ động join/leave group theo từng
/// hội thoại cụ thể (để nhận "ReceiveMessage" — tin nhắn mới ngay khi đang xem đúng cửa sổ chat đó).
/// </summary>
[Authorize]
public class ChatHub : Hub
{
    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId != null)
            await Groups.AddToGroupAsync(Context.ConnectionId, UserGroup(userId));
        await base.OnConnectedAsync();
    }

    public Task JoinConversation(string conversationId) =>
        Groups.AddToGroupAsync(Context.ConnectionId, ConversationGroup(conversationId));

    public Task LeaveConversation(string conversationId) =>
        Groups.RemoveFromGroupAsync(Context.ConnectionId, ConversationGroup(conversationId));

    public static string ConversationGroup(string conversationId) => $"conversation-{conversationId}";
    public static string UserGroup(string userId) => $"user-{userId}";
}
