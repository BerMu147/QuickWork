using System;
using System.ComponentModel.DataAnnotations;

namespace QuickWork.Services.Database
{
    public class Notification
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        [MaxLength(50)]
        public string Type { get; set; } = string.Empty; // NewApplication, MessageReceived, JobAccepted, PaymentReceived, etc.

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [MaxLength(500)]
        public string Message { get; set; } = string.Empty;

        [MaxLength(50)]
        public string? RelatedEntityType { get; set; } // JobPosting, Message, Payment, etc.

        public int? RelatedEntityId { get; set; }

        public bool IsRead { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? ReadAt { get; set; }

        // Navigation properties
        public User User { get; set; } = null!;
    }
}
