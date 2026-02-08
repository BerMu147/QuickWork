using System;

namespace QuickWork.Model.Responses
{
    public class JobApplicationResponse
    {
        public int Id { get; set; }
        
        public int JobPostingId { get; set; }
        public string JobPostingTitle { get; set; } = string.Empty;
        
        public int ApplicantUserId { get; set; }
        public string ApplicantUserName { get; set; } = string.Empty;
        public string ApplicantUserEmail { get; set; } = string.Empty;
        
        public string? Message { get; set; }
        public string Status { get; set; } = string.Empty;
        
        public DateTime AppliedAt { get; set; }
        public DateTime? RespondedAt { get; set; }
        
        public bool IsActive { get; set; }
    }
}
