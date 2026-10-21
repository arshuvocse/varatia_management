using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface INotificationService
{
    Task<IReadOnlyList<NotificationListItemDto>> GetAllAsync(
        CancellationToken cancellationToken = default);

    Task<SendUserNotificationResponse> SendToUserAsync(
        SendUserNotificationRequest request,
        CancellationToken cancellationToken = default);

    Task<MarkNotificationReadResponse> MarkAsReadAsync(
        int notificationId,
        CancellationToken cancellationToken = default);

    Task<SendRentNoticeResponse> SendRentNoticeAsync(
        SendRentNoticeRequest request,
        CancellationToken cancellationToken = default);
}
