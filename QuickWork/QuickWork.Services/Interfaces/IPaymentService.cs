using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;
using System.Threading.Tasks;

namespace QuickWork.Services.Interfaces
{
    public interface IPaymentService : IService<PaymentResponse, PaymentSearchObject>
    {
        Task<PaymentResponse> CreatePaymentIntentAsync(int jobPostingId, int payerUserId, int receiverUserId, decimal amount);
        Task<PaymentResponse?> UpdatePaymentStatusAsync(string stripePaymentIntentId, string status, string? chargeId = null, string? failureReason = null);
        Task<PaymentResponse?> GetByStripePaymentIntentIdAsync(string stripePaymentIntentId);
    }
}
