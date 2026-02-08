using System;
using System.ComponentModel.DataAnnotations;

namespace QuickWork.Model.Requests
{
    public class JobPostingUpsertRequest
    {
        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [MaxLength(2000)]
        public string Description { get; set; } = string.Empty;

        [Required]
        public int CategoryId { get; set; }

        [Required]
        public int CityId { get; set; }

        [MaxLength(300)]
        public string? Address { get; set; }

        [Required]
        [Range(0.01, 999999.99)]
        public decimal PaymentAmount { get; set; }

        [Range(0.01, 99.99)]
        public decimal? EstimatedDurationHours { get; set; }

        [Required]
        public DateTime ScheduledDate { get; set; }

        public TimeSpan? ScheduledTimeStart { get; set; }

        public TimeSpan? ScheduledTimeEnd { get; set; }

        [MaxLength(50)]
        public string Status { get; set; } = "Open"; // Open, InProgress, Completed, Cancelled

        public bool IsActive { get; set; } = true;
    }
}
