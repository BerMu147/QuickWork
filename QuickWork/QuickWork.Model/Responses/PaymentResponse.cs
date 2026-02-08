using System;

namespace QuickWork.Model.Responses
{
    public class PaymentResponse
    {
        public int Id { get; set; }
        
        public int JobPostingId { get; set; }
        public string JobPostingTitle { get; set; } = string.Empty;
        
        public int PayerUserId { get; set; }
        public string PayerUserName { get; set; } = string.Empty;
        
        public int ReceiverUserId { get; set; }
        public string ReceiverUserName { get; set; } = string.Empty;
        
        public decimal Amount { get; set; }
        public string StripePaymentIntentId { get; set; } = string.Empty;
        public string? StripeChargeId { get; set; }
        
        public string Status { get; set; } = string.Empty;
        
        public DateTime CreatedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
        public string? FailureReason { get; set; }
    }
}
