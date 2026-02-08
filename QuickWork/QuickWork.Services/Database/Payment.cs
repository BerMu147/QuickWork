using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuickWork.Services.Database
{
    public class Payment
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int JobPostingId { get; set; }

        [Required]
        public int PayerUserId { get; set; }

        [Required]
        public int ReceiverUserId { get; set; }

        [Required]
        [Column(TypeName = "decimal(10,2)")]
        public decimal Amount { get; set; }

        [Required]
        [MaxLength(255)]
        public string StripePaymentIntentId { get; set; } = string.Empty;

        [MaxLength(255)]
        public string? StripeChargeId { get; set; }

        [Required]
        [MaxLength(50)]
        public string Status { get; set; } = "Pending"; // Pending, Completed, Failed, Refunded

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? CompletedAt { get; set; }

        [MaxLength(500)]
        public string? FailureReason { get; set; }

        // Navigation properties
        public JobPosting JobPosting { get; set; } = null!;
        public User PayerUser { get; set; } = null!;
        public User ReceiverUser { get; set; } = null!;
    }
}
