using System.ComponentModel.DataAnnotations;

namespace QuickWork.Model.Requests
{
    public class ReviewUpsertRequest
    {
        [Required]
        public int JobPostingId { get; set; }

        [Required]
        public int ReviewedUserId { get; set; }

        [Required]
        [Range(1, 5)]
        public int Rating { get; set; }

        [MaxLength(1000)]
        public string? Comment { get; set; }

        public bool IsActive { get; set; } = true;
    }
}
