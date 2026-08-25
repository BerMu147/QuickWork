using QuickWork.Model.Requests;
using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;
using System.Threading.Tasks;

namespace QuickWork.Services.Interfaces
{
    public interface ISupportTicketService : IService<SupportTicketResponse, SupportTicketSearchObject>
    {
        /// <summary>Creates a new ticket filed by a user.</summary>
        Task<SupportTicketResponse> CreateAsync(SupportTicketUpsertRequest request);

        /// <summary>
        /// Applies an administrator's reply to a ticket and optionally advances
        /// its lifecycle status. Returns null if the ticket does not exist.
        /// </summary>
        Task<SupportTicketResponse?> ReplyAsync(int id, SupportTicketReplyRequest request);

        /// <summary>Updates only the lifecycle status of a ticket.</summary>
        Task<SupportTicketResponse?> UpdateStatusAsync(int id, string status);

        /// <summary>Soft-deletes (deactivates) a ticket. Returns false if not found.</summary>
        Task<bool> DeleteAsync(int id);
    }
}
