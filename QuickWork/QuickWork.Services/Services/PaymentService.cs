using QuickWork.Services.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;
using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;
using QuickWork.Services.Interfaces;
using MapsterMapper;

namespace QuickWork.Services.Services
{
    public class PaymentService : BaseService<PaymentResponse, PaymentSearchObject, Payment>, IPaymentService
    {
        public PaymentService(QuickWorkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<PagedResult<PaymentResponse>> GetAsync(PaymentSearchObject search)
        {
            var query = _context.Payments.AsQueryable();

            if (search.JobPostingId.HasValue)
            {
                query = query.Where(p => p.JobPostingId == search.JobPostingId.Value);
            }

            if (search.PayerUserId.HasValue)
            {
                query = query.Where(p => p.PayerUserId == search.PayerUserId.Value);
            }

            if (search.ReceiverUserId.HasValue)
            {
                query = query.Where(p => p.ReceiverUserId == search.ReceiverUserId.Value);
            }

            if (!string.IsNullOrEmpty(search.Status))
            {
                query = query.Where(p => p.Status == search.Status);
            }

            if (!string.IsNullOrEmpty(search.StripePaymentIntentId))
            {
                query = query.Where(p => p.StripePaymentIntentId == search.StripePaymentIntentId);
            }

            query = query
                .Include(p => p.JobPosting)
                .Include(p => p.PayerUser)
                .Include(p => p.ReceiverUser)
                .OrderByDescending(p => p.CreatedAt);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                {
                    query = query.Skip(search.Page.Value * search.PageSize.Value);
                }
                if (search.PageSize.HasValue)
                {
                    query = query.Take(search.PageSize.Value);
                }
            }

            var payments = await query.ToListAsync();
            return new PagedResult<PaymentResponse>
            {
                Items = payments.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<PaymentResponse?> GetByIdAsync(int id)
        {
            var payment = await _context.Payments
                .Include(p => p.JobPosting)
                .Include(p => p.PayerUser)
                .Include(p => p.ReceiverUser)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (payment == null)
                return null;

            return MapToResponse(payment);
        }

        public async Task<PaymentResponse> CreatePaymentIntentAsync(int jobPostingId, int payerUserId, int receiverUserId, decimal amount)
        {
            // Generate a temporary Stripe Payment Intent ID (in real implementation, call Stripe API)
            var stripePaymentIntentId = $"pi_{Guid.NewGuid().ToString().Replace("-", "")}";

            var payment = new Payment
            {
                JobPostingId = jobPostingId,
                PayerUserId = payerUserId,
                ReceiverUserId = receiverUserId,
                Amount = amount,
                StripePaymentIntentId = stripePaymentIntentId,
                Status = "Pending",
                CreatedAt = DateTime.UtcNow
            };

            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(payment.Id) ?? throw new InvalidOperationException("Failed to create payment.");
        }

        public async Task<PaymentResponse?> UpdatePaymentStatusAsync(string stripePaymentIntentId, string status, string? chargeId = null, string? failureReason = null)
        {
            var payment = await _context.Payments
                .FirstOrDefaultAsync(p => p.StripePaymentIntentId == stripePaymentIntentId);

            if (payment == null)
                return null;

            payment.Status = status;
            payment.StripeChargeId = chargeId;
            payment.FailureReason = failureReason;

            if (status == "Completed")
            {
                payment.CompletedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            return await GetByIdAsync(payment.Id);
        }

        public async Task<PaymentResponse?> GetByStripePaymentIntentIdAsync(string stripePaymentIntentId)
        {
            var payment = await _context.Payments
                .Include(p => p.JobPosting)
                .Include(p => p.PayerUser)
                .Include(p => p.ReceiverUser)
                .FirstOrDefaultAsync(p => p.StripePaymentIntentId == stripePaymentIntentId);

            if (payment == null)
                return null;

            return MapToResponse(payment);
        }

        protected override PaymentResponse MapToResponse(Payment payment)
        {
            return new PaymentResponse
            {
                Id = payment.Id,
                JobPostingId = payment.JobPostingId,
                JobPostingTitle = payment.JobPosting?.Title ?? string.Empty,
                PayerUserId = payment.PayerUserId,
                PayerUserName = payment.PayerUser != null ? $"{payment.PayerUser.FirstName} {payment.PayerUser.LastName}" : string.Empty,
                ReceiverUserId = payment.ReceiverUserId,
                ReceiverUserName = payment.ReceiverUser != null ? $"{payment.ReceiverUser.FirstName} {payment.ReceiverUser.LastName}" : string.Empty,
                Amount = payment.Amount,
                StripePaymentIntentId = payment.StripePaymentIntentId,
                StripeChargeId = payment.StripeChargeId,
                Status = payment.Status,
                CreatedAt = payment.CreatedAt,
                CompletedAt = payment.CompletedAt,
                FailureReason = payment.FailureReason
            };
        }
    }
}
