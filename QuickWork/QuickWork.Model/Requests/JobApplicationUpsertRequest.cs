using System.ComponentModel.DataAnnotations;

namespace QuickWork.Model.Requests
{
    public class JobApplicationUpsertRequest
    {
        [Required]
        public int JobPostingId { get; set; }

        [MaxLength(1000)]
        public string? Message { get; set; }

        [MaxLength(50)]
        public string Status { get; set; } = "Pending"; // Pending, Accepted, Rejected, Withdrawn

        public bool IsActive { get; set; } = true;
    }
}
