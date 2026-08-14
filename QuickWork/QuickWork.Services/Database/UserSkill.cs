using System;
using System.ComponentModel.DataAnnotations;

namespace QuickWork.Services.Database
{
    /// <summary>
    /// A custom skill that a user adds to their profile so publishers can
    /// gauge whether the worker is relevant for a particular job.
    /// </summary>
    public class UserSkill
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        [MaxLength(100)]
        public string SkillName { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public bool IsActive { get; set; } = true;

        // Navigation property
        public User User { get; set; } = null!;
    }
}
