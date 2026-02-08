using System;

namespace QuickWork.Model.Responses
{
    public class ReviewResponse
    {
        public int Id { get; set; }
        
        public int JobPostingId { get; set; }
        public string JobPostingTitle { get; set; } = string.Empty;
        
        public int ReviewerUserId { get; set; }
        public string ReviewerUserName { get; set; } = string.Empty;
        
        public int ReviewedUserId { get; set; }
        public string ReviewedUserName { get; set; } = string.Empty;
        
        public int Rating { get; set; }
        public string? Comment { get; set; }
        
        public DateTime CreatedAt { get; set; }
        public bool IsActive { get; set; }
    }
}
