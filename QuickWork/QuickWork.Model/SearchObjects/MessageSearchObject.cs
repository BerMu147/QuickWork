namespace QuickWork.Model.SearchObjects
{
    public class MessageSearchObject : BaseSearchObject
    {
        public int? JobPostingId { get; set; }
        public int? SenderUserId { get; set; }
        public int? ReceiverUserId { get; set; }
        public bool? IsRead { get; set; }
    }
}
