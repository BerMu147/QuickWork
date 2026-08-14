using System.ComponentModel.DataAnnotations;

namespace QuickWork.Model.Requests
{
    public class UserSkillUpsertRequest
    {
        [Required]
        [MaxLength(100)]
        public string SkillName { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;
    }
}
