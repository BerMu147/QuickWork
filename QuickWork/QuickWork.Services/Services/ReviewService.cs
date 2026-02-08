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
    public class ReviewService : BaseService<ReviewResponse, ReviewSearchObject, Review>, IReviewService
    {
        public ReviewService(QuickWorkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<PagedResult<ReviewResponse>> GetAsync(ReviewSearchObject search)
        {
            var query = _context.Reviews.AsQueryable();

            if (search.JobPostingId.HasValue)
            {
                query = query.Where(r => r.JobPostingId == search.JobPostingId.Value);
            }

            if (search.ReviewerUserId.HasValue)
            {
                query = query.Where(r => r.ReviewerUserId == search.ReviewerUserId.Value);
            }

            if (search.ReviewedUserId.HasValue)
            {
                query = query.Where(r => r.ReviewedUserId == search.ReviewedUserId.Value);
            }

            if (search.MinRating.HasValue)
            {
                query = query.Where(r => r.Rating >= search.MinRating.Value);
            }

            if (search.MaxRating.HasValue)
            {
                query = query.Where(r => r.Rating <= search.MaxRating.Value);
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(r => r.IsActive == search.IsActive.Value);
            }

            query = query
                .Include(r => r.JobPosting)
                .Include(r => r.ReviewerUser)
                .Include(r => r.ReviewedUser)
                .OrderByDescending(r => r.CreatedAt);

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

            var reviews = await query.ToListAsync();
            return new PagedResult<ReviewResponse>
            {
                Items = reviews.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<ReviewResponse?> GetByIdAsync(int id)
        {
            var review = await _context.Reviews
                .Include(r => r.JobPosting)
                .Include(r => r.ReviewerUser)
                .Include(r => r.ReviewedUser)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (review == null)
                return null;

            return MapToResponse(review);
        }

        public async Task<ReviewResponse> CreateAsync(ReviewUpsertRequest request, int reviewerUserId)
        {
            // Check if user already reviewed this job
            var existingReview = await _context.Reviews
                .FirstOrDefaultAsync(r => r.JobPostingId == request.JobPostingId && r.ReviewerUserId == reviewerUserId);

            if (existingReview != null)
            {
                throw new InvalidOperationException("You have already reviewed this job.");
            }

            var review = new Review
            {
                JobPostingId = request.JobPostingId,
                ReviewerUserId = reviewerUserId,
                ReviewedUserId = request.ReviewedUserId,
                Rating = request.Rating,
                Comment = request.Comment,
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };

            _context.Reviews.Add(review);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(review.Id) ?? throw new InvalidOperationException("Failed to create review.");
        }

        public async Task<ReviewResponse?> UpdateAsync(int id, ReviewUpsertRequest request)
        {
            var review = await _context.Reviews.FindAsync(id);
            if (review == null)
                return null;

            review.Rating = request.Rating;
            review.Comment = request.Comment;
            review.IsActive = request.IsActive;

            await _context.SaveChangesAsync();
            return await GetByIdAsync(review.Id);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var review = await _context.Reviews.FindAsync(id);
            if (review == null)
                return false;

            _context.Reviews.Remove(review);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<double> GetAverageRatingForUserAsync(int userId)
        {
            var reviews = await _context.Reviews
                .Where(r => r.ReviewedUserId == userId && r.IsActive)
                .ToListAsync();

            if (!reviews.Any())
                return 0;

            return reviews.Average(r => r.Rating);
        }

        protected override ReviewResponse MapToResponse(Review review)
        {
            return new ReviewResponse
            {
                Id = review.Id,
                JobPostingId = review.JobPostingId,
                JobPostingTitle = review.JobPosting?.Title ?? string.Empty,
                ReviewerUserId = review.ReviewerUserId,
                ReviewerUserName = review.ReviewerUser != null ? $"{review.ReviewerUser.FirstName} {review.ReviewerUser.LastName}" : string.Empty,
                ReviewedUserId = review.ReviewedUserId,
                ReviewedUserName = review.ReviewedUser != null ? $"{review.ReviewedUser.FirstName} {review.ReviewedUser.LastName}" : string.Empty,
                Rating = review.Rating,
                Comment = review.Comment,
                CreatedAt = review.CreatedAt,
                IsActive = review.IsActive
            };
        }
    }
}
