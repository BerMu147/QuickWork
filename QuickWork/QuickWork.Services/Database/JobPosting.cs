using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuickWork.Services.Database
{
    public class JobPosting
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [MaxLength(2000)]
        public string Description { get; set; } = string.Empty;

        [Required]
        public int CategoryId { get; set; }

        [Required]
        public int PostedByUserId { get; set; }

        [Required]
        public int CityId { get; set; }

        [MaxLength(300)]
        public string? Address { get; set; }

        [Required]
        [Column(TypeName = "decimal(10,2)")]
        public decimal PaymentAmount { get; set; }

        [Column(TypeName = "decimal(4,2)")]
        public decimal? EstimatedDurationHours { get; set; }

        [Required]
        public DateTime ScheduledDate { get; set; }

        public TimeSpan? ScheduledTimeStart { get; set; }

        public TimeSpan? ScheduledTimeEnd { get; set; }

        [Required]
        [MaxLength(50)]
        public string Status { get; set; } = "Open"; // Open, InProgress, Completed, Cancelled

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public DateTime? CompletedAt { get; set; }

        // Navigation properties
        public Category Category { get; set; } = null!;
        public User PostedByUser { get; set; } = null!;
        public City City { get; set; } = null!;

        // Collections
        public ICollection<JobApplication> JobApplications { get; set; } = new List<JobApplication>();
        public ICollection<Message> Messages { get; set; } = new List<Message>();
        public ICollection<Review> Reviews { get; set; } = new List<Review>();
        public ICollection<Payment> Payments { get; set; } = new List<Payment>();
    }
}
