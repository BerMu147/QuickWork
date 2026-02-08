using QuickWork.Model.Requests;
using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;
using System.Threading.Tasks;

namespace QuickWork.Services.Interfaces
{
    public interface IMessageService : IService<MessageResponse, MessageSearchObject>
    {
        Task<MessageResponse> CreateAsync(MessageUpsertRequest request, int senderUserId);
        Task<MessageResponse?> MarkAsReadAsync(int id);
        Task<bool> DeleteAsync(int id);
    }
}
