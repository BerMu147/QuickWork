using System;

namespace QuickWork.Model.Responses
{
    /// <summary>
    /// The serialized shape of a support ticket returned to clients.
    /// Resembles the other *Response DTOs (Id, navigation-inlined user name).
    /// </summary>
    public class SupportTicketResponse
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public string UserName { get; set; } = string.Empty;

        public string UserEmail { get; set; } = string.Empty;

        public string Subject { get; set; } = string.Empty;

        public string Message { get; set; } = string.Empty;

        public string Category { get; set; } = string.Empty;

        public string Priority { get; set; } = string.Empty;

        public string Status { get; set; } = string.Empty;

        public string? AdminReply { get; set; }

        public DateTime CreatedAt { get; set; }

        public DateTime? UpdatedAt { get; set; }

        public bool IsActive { get; set; }
    }
}
