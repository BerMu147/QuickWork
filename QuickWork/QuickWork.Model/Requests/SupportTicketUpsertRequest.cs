using System.ComponentModel.DataAnnotations;

namespace QuickWork.Model.Requests
{
    /// <summary>
    /// Payload used by a user to file a new support ticket.
    /// </summary>
    public class SupportTicketUpsertRequest
    {
        [Required]
        public int UserId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Subject { get; set; } = string.Empty;

        [Required]
        [MaxLength(2000)]
        public string Message { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string Category { get; set; } = "Question";

        [Required]
        [MaxLength(20)]
        public string Priority { get; set; } = "Medium";
    }
}
