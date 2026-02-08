using System;

namespace QuickWork.Model.Responses
{
    public class MessageResponse
    {
        public int Id { get; set; }
        
        public int JobPostingId { get; set; }
        public string JobPostingTitle { get; set; } = string.Empty;
        
        public int SenderUserId { get; set; }
        public string SenderUserName { get; set; } = string.Empty;
        
        public int ReceiverUserId { get; set; }
        public string ReceiverUserName { get; set; } = string.Empty;
        
        public string Content { get; set; } = string.Empty;
        
        public DateTime SentAt { get; set; }
        public bool IsRead { get; set; }
        public DateTime? ReadAt { get; set; }
    }
}
