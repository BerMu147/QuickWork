namespace QuickWork.Model.SearchObjects
{
    public class PaymentSearchObject : BaseSearchObject
    {
        public int? JobPostingId { get; set; }
        public int? PayerUserId { get; set; }
        public int? ReceiverUserId { get; set; }
        public string? Status { get; set; }
        public string? StripePaymentIntentId { get; set; }
    }
}
