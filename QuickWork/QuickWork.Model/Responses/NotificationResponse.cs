using System;

namespace QuickWork.Model.Responses
{
    public class NotificationResponse
    {
        public int Id { get; set; }
        
        public int UserId { get; set; }
        
        public string Type { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        
        public string? RelatedEntityType { get; set; }
        public int? RelatedEntityId { get; set; }
        
        public bool IsRead { get; set; }
        
        public DateTime CreatedAt { get; set; }
        public DateTime? ReadAt { get; set; }
    }
}
