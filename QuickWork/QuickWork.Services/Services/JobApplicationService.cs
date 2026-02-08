using QuickWork.Services.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;
using QuickWork.Model.Requests;
using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;
using QuickWork.Services.Interfaces;
using MapsterMapper;

namespace QuickWork.Services.Services
{
    public class JobApplicationService : BaseService<JobApplicationResponse, JobApplicationSearchObject, JobApplication>, IJobApplicationService
    {
        public JobApplicationService(QuickWorkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<PagedResult<JobApplicationResponse>> GetAsync(JobApplicationSearchObject search)
        {
            var query = _context.JobApplications.AsQueryable();

            if (search.JobPostingId.HasValue)
            {
                query = query.Where(ja => ja.JobPostingId == search.JobPostingId.Value);
            }

            if (search.ApplicantUserId.HasValue)
            {
                query = query.Where(ja => ja.ApplicantUserId == search.ApplicantUserId.Value);
            }

            if (!string.IsNullOrEmpty(search.Status))
            {
                query = query.Where(ja => ja.Status == search.Status);
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(ja => ja.IsActive == search.IsActive.Value);
            }

            query = query
                .Include(ja => ja.JobPosting)
                .Include(ja => ja.ApplicantUser);

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

            var applications = await query.ToListAsync();
            return new PagedResult<JobApplicationResponse>
            {
                Items = applications.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<JobApplicationResponse?> GetByIdAsync(int id)
        {
            var application = await _context.JobApplications
                .Include(ja => ja.JobPosting)
                .Include(ja => ja.ApplicantUser)
                .FirstOrDefaultAsync(ja => ja.Id == id);

            if (application == null)
                return null;

            return MapToResponse(application);
        }

        public async Task<JobApplicationResponse> CreateAsync(JobApplicationUpsertRequest request, int applicantUserId)
        {
            // Check if user already applied to this job
            var existingApplication = await _context.JobApplications
                .FirstOrDefaultAsync(ja => ja.JobPostingId == request.JobPostingId && ja.ApplicantUserId == applicantUserId);

            if (existingApplication != null)
            {
                throw new InvalidOperationException("You have already applied to this job.");
            }

            var application = new JobApplication
            {
                JobPostingId = request.JobPostingId,
                ApplicantUserId = applicantUserId,
                Message = request.Message,
                Status = request.Status,
                IsActive = request.IsActive,
                AppliedAt = DateTime.UtcNow
            };

            _context.JobApplications.Add(application);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(application.Id) ?? throw new InvalidOperationException("Failed to create application.");
        }

        public async Task<JobApplicationResponse?> UpdateAsync(int id, JobApplicationUpsertRequest request)
        {
            var application = await _context.JobApplications.FindAsync(id);
            if (application == null)
                return null;

            application.Message = request.Message;
            application.Status = request.Status;
            application.IsActive = request.IsActive;

            if (request.Status == "Accepted" || request.Status == "Rejected")
            {
                application.RespondedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            return await GetByIdAsync(application.Id);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var application = await _context.JobApplications.FindAsync(id);
            if (application == null)
                return false;

            _context.JobApplications.Remove(application);
            await _context.SaveChangesAsync();
            return true;
        }

        protected override JobApplicationResponse MapToResponse(JobApplication application)
        {
            return new JobApplicationResponse
            {
                Id = application.Id,
                JobPostingId = application.JobPostingId,
                JobPostingTitle = application.JobPosting?.Title ?? string.Empty,
                ApplicantUserId = application.ApplicantUserId,
                ApplicantUserName = application.ApplicantUser != null ? $"{application.ApplicantUser.FirstName} {application.ApplicantUser.LastName}" : string.Empty,
                ApplicantUserEmail = application.ApplicantUser?.Email ?? string.Empty,
                Message = application.Message,
                Status = application.Status,
                AppliedAt = application.AppliedAt,
                RespondedAt = application.RespondedAt,
                IsActive = application.IsActive
            };
        }
    }
}
