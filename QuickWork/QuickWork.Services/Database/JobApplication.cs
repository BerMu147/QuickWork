using System;
using System.ComponentModel.DataAnnotations;

namespace QuickWork.Services.Database
{
    public class JobApplication
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int JobPostingId { get; set; }

        [Required]
        public int ApplicantUserId { get; set; }

        [MaxLength(1000)]
        public string? Message { get; set; }

        [Required]
        [MaxLength(50)]
        public string Status { get; set; } = "Pending"; // Pending, Accepted, Rejected, Withdrawn

        public DateTime AppliedAt { get; set; } = DateTime.UtcNow;

        public DateTime? RespondedAt { get; set; }

        public bool IsActive { get; set; } = true;

        // Navigation properties
        public JobPosting JobPosting { get; set; } = null!;
        public User ApplicantUser { get; set; } = null!;
    }
}
