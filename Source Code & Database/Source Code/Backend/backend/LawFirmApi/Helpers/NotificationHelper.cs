using LawFirmApi.Data;
using LawFirmApi.Models;

namespace LawFirmApi.Helpers;

public static class NotificationHelper
{
    public static void Notify(AppDbContext db, Guid userId, string type, string title, string? body = null, Guid? refId = null)
    {
        db.Notifications.Add(new Notification
        {
            UserId = userId,
            Type = type,
            Title = title,
            Body = body,
            RefId = refId,
        });
    }
}
