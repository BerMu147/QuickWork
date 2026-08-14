using QuickWork.Services.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;
using QuickWork.Model;
using QuickWork.Model.Requests;
using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;
using QuickWork.Services.Interfaces;
using MapsterMapper;

namespace QuickWork.Services.Services
{
    public class UserSkillService : BaseService<UserSkillResponse, UserSkillSearchObject, UserSkill>, IUserSkillService
    {
        public UserSkillService(QuickWorkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<PagedResult<UserSkillResponse>> GetAsync(UserSkillSearchObject search)
        {
            var query = _context.UserSkills.AsQueryable();

            if (search.UserId.HasValue)
            {
                query = query.Where(s => s.UserId == search.UserId.Value);
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(s => s.IsActive == search.IsActive.Value);
            }

            query = query.OrderBy(s => s.SkillName);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                {
                    query = query.Skip(search.Page.Value * search.PageSize.Value);
                }
                if (search.PageSize.HasValue)
                {
                    query = query.Take(search.PageSize.Value);
                }
            }

            var skills = await query.ToListAsync();
            return new PagedResult<UserSkillResponse>
            {
                Items = skills.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<UserSkillResponse?> GetByIdAsync(int id)
        {
            var skill = await _context.UserSkills.FindAsync(id);
            if (skill == null)
                return null;

            return MapToResponse(skill);
        }

        public async Task<UserSkillResponse> CreateAsync(UserSkillUpsertRequest request, int userId)
        {
            var skillName = (request.SkillName ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(skillName))
            {
                throw new UserException("Skill name cannot be empty.");
            }

            // Avoid storing duplicate skills for the same user.
            var exists = await _context.UserSkills
                .AnyAsync(s => s.UserId == userId && s.SkillName == skillName);
            if (exists)
            {
                throw new UserException("You have already added this skill.");
            }

            await EnsureUserExists(userId);

            var skill = new UserSkill
            {
                UserId = userId,
                SkillName = skillName,
                CreatedAt = DateTime.UtcNow,
                IsActive = request.IsActive
            };

            _context.UserSkills.Add(skill);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(skill.Id)
                ?? throw new InvalidOperationException("Failed to create skill.");
        }

        public async Task<UserSkillResponse?> UpdateAsync(int id, UserSkillUpsertRequest request)
        {
            var skill = await _context.UserSkills.FindAsync(id);
            if (skill == null)
                return null;

            var skillName = (request.SkillName ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(skillName))
            {
                throw new UserException("Skill name cannot be empty.");
            }

            skill.SkillName = skillName;
            skill.IsActive = request.IsActive;

            await _context.SaveChangesAsync();
            return await GetByIdAsync(skill.Id);
        }

        public async Task<bool> DeleteAsync(int id, int userId)
        {
            var skill = await _context.UserSkills.FindAsync(id);
            if (skill == null)
                return false;

            if (skill.UserId != userId)
            {
                throw new UserException("You can only delete your own skills.");
            }

            _context.UserSkills.Remove(skill);
            await _context.SaveChangesAsync();
            return true;
        }

        private async Task EnsureUserExists(int userId)
        {
            var exists = await _context.Users.AnyAsync(u => u.Id == userId);
            if (!exists)
            {
                throw new UserException("User not found.");
            }
        }

        protected override UserSkillResponse MapToResponse(UserSkill skill)
        {
            return new UserSkillResponse
            {
                Id = skill.Id,
                UserId = skill.UserId,
                SkillName = skill.SkillName,
                CreatedAt = skill.CreatedAt,
                IsActive = skill.IsActive
            };
        }
    }
}
