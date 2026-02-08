using System;

namespace QuickWork.Model.Responses
{
    public class JobPostingResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        
        public int CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        
        public int PostedByUserId { get; set; }
        public string PostedByUserName { get; set; } = string.Empty;
        public string PostedByUserEmail { get; set; } = string.Empty;
        
        public int CityId { get; set; }
        public string CityName { get; set; } = string.Empty;
        
        public string? Address { get; set; }
        public decimal PaymentAmount { get; set; }
        public decimal? EstimatedDurationHours { get; set; }
        
        public DateTime ScheduledDate { get; set; }
        public TimeSpan? ScheduledTimeStart { get; set; }
        public TimeSpan? ScheduledTimeEnd { get; set; }
        
        public string Status { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
        
        // Counts for related entities
        public int ApplicationCount { get; set; }
        public int MessageCount { get; set; }
    }
}
