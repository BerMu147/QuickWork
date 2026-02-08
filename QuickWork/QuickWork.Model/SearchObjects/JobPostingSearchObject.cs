using System;

namespace QuickWork.Model.SearchObjects
{
    public class JobPostingSearchObject : BaseSearchObject
    {
        public string? Title { get; set; }
        public int? CategoryId { get; set; }
        public int? PostedByUserId { get; set; }
        public int? CityId { get; set; }
        public string? Status { get; set; }
        public DateTime? ScheduledDateFrom { get; set; }
        public DateTime? ScheduledDateTo { get; set; }
        public decimal? MinPaymentAmount { get; set; }
        public decimal? MaxPaymentAmount { get; set; }
        public bool? IsActive { get; set; }
    }
}
