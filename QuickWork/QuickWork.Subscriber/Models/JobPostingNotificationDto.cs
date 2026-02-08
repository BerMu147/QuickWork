using System.Collections.Generic;

namespace QuickWork.Subscriber.Models
{
    public class JobPostingNotificationDto
    {
        public string Title { get; set; } = null!;
        public string CategoryName { get; set; } = null!;
        public string CityName { get; set; } = null!;
        public string PostedByUserName { get; set; } = null!;
        public List<string> AdminEmails { get; set; } = new List<string>();
    }
}
