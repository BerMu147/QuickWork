namespace QuickWork.Model.SearchObjects
{
    public class JobApplicationSearchObject : BaseSearchObject
    {
        public int? JobPostingId { get; set; }
        public int? ApplicantUserId { get; set; }
        public string? Status { get; set; }
        public bool? IsActive { get; set; }
    }
}
