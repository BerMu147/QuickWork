namespace QuickWork.Model.SearchObjects
{
    public class ReviewSearchObject : BaseSearchObject
    {
        public int? JobPostingId { get; set; }
        public int? ReviewerUserId { get; set; }
        public int? ReviewedUserId { get; set; }
        public int? MinRating { get; set; }
        public int? MaxRating { get; set; }
        public bool? IsActive { get; set; }
    }
}
