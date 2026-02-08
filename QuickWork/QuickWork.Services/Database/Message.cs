using System;
using System.ComponentModel.DataAnnotations;

namespace QuickWork.Services.Database
{
    public class Message
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int JobPostingId { get; set; }

        [Required]
        public int SenderUserId { get; set; }

        [Required]
        public int ReceiverUserId { get; set; }

        [Required]
        [MaxLength(2000)]
        public string Content { get; set; } = string.Empty;

        public DateTime SentAt { get; set; } = DateTime.UtcNow;

        public bool IsRead { get; set; } = false;

        public DateTime? ReadAt { get; set; }

        // Navigation properties
        public JobPosting JobPosting { get; set; } = null!;
        public User SenderUser { get; set; } = null!;
        public User ReceiverUser { get; set; } = null!;
    }
}
