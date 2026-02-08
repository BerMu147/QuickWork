using QuickWork.Model.Requests;
using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;
using System.Threading.Tasks;

namespace QuickWork.Services.Interfaces
{
    public interface INotificationService : IService<NotificationResponse, NotificationSearchObject>
    {
        Task<NotificationResponse> CreateAsync(NotificationUpsertRequest request);
        Task<NotificationResponse?> MarkAsReadAsync(int id);
        Task<int> MarkAllAsReadForUserAsync(int userId);
        Task<bool> DeleteAsync(int id);
    }
}
