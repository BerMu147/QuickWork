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
    public class JobPostingService : BaseService<JobPostingResponse, JobPostingSearchObject, JobPosting>, IJobPostingService
    {
        public JobPostingService(QuickWorkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<PagedResult<JobPostingResponse>> GetAsync(JobPostingSearchObject search)
        {
            var query = _context.JobPostings.AsQueryable();

            if (!string.IsNullOrEmpty(search.Title))
            {
                query = query.Where(jp => jp.Title.Contains(search.Title));
            }

            if (search.CategoryId.HasValue)
            {
                query = query.Where(jp => jp.CategoryId == search.CategoryId.Value);
            }

            if (search.PostedByUserId.HasValue)
            {
                query = query.Where(jp => jp.PostedByUserId == search.PostedByUserId.Value);
            }

            if (search.CityId.HasValue)
            {
                query = query.Where(jp => jp.CityId == search.CityId.Value);
            }

            if (!string.IsNullOrEmpty(search.Status))
            {
                query = query.Where(jp => jp.Status == search.Status);
            }

            if (search.ScheduledDateFrom.HasValue)
            {
                query = query.Where(jp => jp.ScheduledDate >= search.ScheduledDateFrom.Value);
            }

            if (search.ScheduledDateTo.HasValue)
            {
                query = query.Where(jp => jp.ScheduledDate <= search.ScheduledDateTo.Value);
            }

            if (search.MinPaymentAmount.HasValue)
            {
                query = query.Where(jp => jp.PaymentAmount >= search.MinPaymentAmount.Value);
            }

            if (search.MaxPaymentAmount.HasValue)
            {
                query = query.Where(jp => jp.PaymentAmount <= search.MaxPaymentAmount.Value);
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(jp => jp.IsActive == search.IsActive.Value);
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(jp =>
                    jp.Title.Contains(search.FTS) ||
                    jp.Description.Contains(search.FTS));
            }

            query = query
                .Include(jp => jp.Category)
                .Include(jp => jp.PostedByUser)
                .Include(jp => jp.City)
                .Include(jp => jp.JobApplications)
                .Include(jp => jp.Messages);

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

            var jobPostings = await query.ToListAsync();
            return new PagedResult<JobPostingResponse>
            {
                Items = jobPostings.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<JobPostingResponse?> GetByIdAsync(int id)
        {
            var jobPosting = await _context.JobPostings
                .Include(jp => jp.Category)
                .Include(jp => jp.PostedByUser)
                .Include(jp => jp.City)
                .Include(jp => jp.JobApplications)
                .Include(jp => jp.Messages)
                .FirstOrDefaultAsync(jp => jp.Id == id);

            if (jobPosting == null)
                return null;

            return MapToResponse(jobPosting);
        }

        public async Task<JobPostingResponse> CreateAsync(JobPostingUpsertRequest request, int postedByUserId)
        {
            var jobPosting = new JobPosting
            {
                Title = request.Title,
                Description = request.Description,
                CategoryId = request.CategoryId,
                PostedByUserId = postedByUserId,
                CityId = request.CityId,
                Address = request.Address,
                PaymentAmount = request.PaymentAmount,
                EstimatedDurationHours = request.EstimatedDurationHours,
                ScheduledDate = request.ScheduledDate,
                ScheduledTimeStart = request.ScheduledTimeStart,
                ScheduledTimeEnd = request.ScheduledTimeEnd,
                Status = request.Status,
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };

            _context.JobPostings.Add(jobPosting);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(jobPosting.Id) ?? throw new InvalidOperationException("Failed to create job posting.");
        }

        public async Task<JobPostingResponse?> UpdateAsync(int id, JobPostingUpsertRequest request)
        {
            var jobPosting = await _context.JobPostings.FindAsync(id);
            if (jobPosting == null)
                return null;

            jobPosting.Title = request.Title;
            jobPosting.Description = request.Description;
            jobPosting.CategoryId = request.CategoryId;
            jobPosting.CityId = request.CityId;
            jobPosting.Address = request.Address;
            jobPosting.PaymentAmount = request.PaymentAmount;
            jobPosting.EstimatedDurationHours = request.EstimatedDurationHours;
            jobPosting.ScheduledDate = request.ScheduledDate;
            jobPosting.ScheduledTimeStart = request.ScheduledTimeStart;
            jobPosting.ScheduledTimeEnd = request.ScheduledTimeEnd;
            jobPosting.Status = request.Status;
            jobPosting.IsActive = request.IsActive;
            jobPosting.UpdatedAt = DateTime.UtcNow;

            if (request.Status == "Completed")
            {
                jobPosting.CompletedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            return await GetByIdAsync(jobPosting.Id);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var jobPosting = await _context.JobPostings.FindAsync(id);
            if (jobPosting == null)
                return false;

            _context.JobPostings.Remove(jobPosting);
            await _context.SaveChangesAsync();
            return true;
        }

        protected override JobPostingResponse MapToResponse(JobPosting jobPosting)
        {
            return new JobPostingResponse
            {
                Id = jobPosting.Id,
                Title = jobPosting.Title,
                Description = jobPosting.Description,
                CategoryId = jobPosting.CategoryId,
                CategoryName = jobPosting.Category?.Name ?? string.Empty,
                PostedByUserId = jobPosting.PostedByUserId,
                PostedByUserName = jobPosting.PostedByUser != null ? $"{jobPosting.PostedByUser.FirstName} {jobPosting.PostedByUser.LastName}" : string.Empty,
                PostedByUserEmail = jobPosting.PostedByUser?.Email ?? string.Empty,
                CityId = jobPosting.CityId,
                CityName = jobPosting.City?.Name ?? string.Empty,
                Address = jobPosting.Address,
                PaymentAmount = jobPosting.PaymentAmount,
                EstimatedDurationHours = jobPosting.EstimatedDurationHours,
                ScheduledDate = jobPosting.ScheduledDate,
                ScheduledTimeStart = jobPosting.ScheduledTimeStart,
                ScheduledTimeEnd = jobPosting.ScheduledTimeEnd,
                Status = jobPosting.Status,
                IsActive = jobPosting.IsActive,
                CreatedAt = jobPosting.CreatedAt,
                UpdatedAt = jobPosting.UpdatedAt,
                CompletedAt = jobPosting.CompletedAt,
                ApplicationCount = jobPosting.JobApplications?.Count ?? 0,
                MessageCount = jobPosting.Messages?.Count ?? 0
            };
        }
    }
}
