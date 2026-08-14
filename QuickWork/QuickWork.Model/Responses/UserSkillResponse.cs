using System;

namespace QuickWork.Model.Responses
{
    public class UserSkillResponse
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public string SkillName { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; }

        public bool IsActive { get; set; }
    }
}
