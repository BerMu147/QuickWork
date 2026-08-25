using System;
using System.ComponentModel.DataAnnotations;

namespace QuickWork.Services.Database
{
    /// <summary>
    /// A support / help-desk ticket raised by a user and handled by an
    /// administrator. Covers bug reports, questions, reports about other users
    /// and feature suggestions.
    ///
    /// The ticket lifecycle is driven by <see cref="Status"/>:
    /// Open -> InProgress -> Resolved -> Closed. An administrator resolves it
    /// by posting <see cref="AdminReply"/> (and optionally advancing the
    /// status).
    /// </summary>
    public class SupportTicket
    {
        [Key]
        public int Id { get; set; }

        /// <summary>The user who raised the ticket.</summary>
        [Required]
        public int UserId { get; set; }

        /// <summary>Short one-line summary of the issue.</summary>
        [Required]
        [MaxLength(200)]
        public string Subject { get; set; } = string.Empty;

        /// <summary>Full description of the issue raised by the user.</summary>
        [Required]
        [MaxLength(2000)]
        public string Message { get; set; } = string.Empty;

        /// <summary>Category / type of ticket (Bug, Question, Report, ...).</summary>
        [Required]
        [MaxLength(50)]
        public string Category { get; set; } = string.Empty;

        /// <summary>Priority of the ticket (Low, Medium, High, Critical).</summary>
        [Required]
        [MaxLength(20)]
        public string Priority { get; set; } = "Medium";

        /// <summary>Lifecycle status (Open, InProgress, Resolved, Closed).</summary>
        [Required]
        [MaxLength(20)]
        public string Status { get; set; } = "Open";

        /// <summary>Resolution note written by an administrator.</summary>
        [MaxLength(2000)]
        public string? AdminReply { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        /// <summary>Soft-delete flag so history can be retained.</summary>
        public bool IsActive { get; set; } = true;

        // Navigation properties
        public User User { get; set; } = null!;
    }
}
