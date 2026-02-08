using System;
using System.ComponentModel.DataAnnotations;

namespace QuickWork.Services.Database
{
    public class Review
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int JobPostingId { get; set; }

        [Required]
        public int ReviewerUserId { get; set; }

        [Required]
        public int ReviewedUserId { get; set; }

        [Required]
        [Range(1, 5)]
        public int Rating { get; set; }

        [MaxLength(1000)]
        public string? Comment { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public bool IsActive { get; set; } = true;

        // Navigation properties
        public JobPosting JobPosting { get; set; } = null!;
        public User ReviewerUser { get; set; } = null!;
        public User ReviewedUser { get; set; } = null!;
    }
}
