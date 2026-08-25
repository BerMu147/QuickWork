using System.ComponentModel.DataAnnotations;

namespace QuickWork.Model.Requests
{
    /// <summary>
    /// Payload used by an administrator to resolve / update a support ticket.
    /// </summary>
    public class SupportTicketReplyRequest
    {
        /// <summary>The resolution note from the administrator.</summary>
        [Required]
        [MaxLength(2000)]
        public string AdminReply { get; set; } = string.Empty;

        /// <summary>
        /// Optional new status to apply (Open, InProgress, Resolved, Closed).
        /// When omitted the ticket keeps its current status; if the ticket is
        /// open it is advanced to Resolved.
        /// </summary>
        [MaxLength(20)]
        public string? Status { get; set; }
    }
}
