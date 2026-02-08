using System.ComponentModel.DataAnnotations;

namespace QuickWork.Model.Requests
{
    public class MessageUpsertRequest
    {
        [Required]
        public int JobPostingId { get; set; }

        [Required]
        public int ReceiverUserId { get; set; }

        [Required]
        [MaxLength(2000)]
        public string Content { get; set; } = string.Empty;
    }
}
