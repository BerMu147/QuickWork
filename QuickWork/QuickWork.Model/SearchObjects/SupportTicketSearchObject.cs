namespace QuickWork.Model.SearchObjects
{
    /// <summary>
    /// Filtering / paging options for listing support tickets.
    /// </summary>
    public class SupportTicketSearchObject : BaseSearchObject
    {
        /// <summary>Limit to tickets filed by a given user.</summary>
        public int? UserId { get; set; }

        /// <summary>Open, InProgress, Resolved or Closed.</summary>
        public string? Status { get; set; }

        /// <summary>Low, Medium, High or Critical.</summary>
        public string? Priority { get; set; }

        /// <summary>Bug, Question, Report, Suggestion, ...</summary>
        public string? Category { get; set; }

        /// <summary>Whether to include soft-deleted (inactive) tickets too.</summary>
        public bool? IsActive { get; set; }
    }
}
