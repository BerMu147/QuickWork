using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using QuickWork.Services.Database;
using QuickWork.Model.Responses;

namespace QuickWork.Services.Services
{
    public class JobRecommendationService
    {
        private readonly QuickWorkDbContext _context;

        public JobRecommendationService(QuickWorkDbContext context)
        {
            _context = context;
        }

        public async Task<List<JobPostingResponse>> GetRecommendedAsync(int userId, int count = 10)
        {
            // 1. Categories the user previously applied to or posted jobs in.
            var userAppliesCategoryIds = await _context.JobApplications
                .Where(ja => ja.ApplicantUserId == userId && ja.IsActive)
                .Select(ja => ja.JobPosting.CategoryId)
                .Distinct()
                .ToListAsync();

            var userPostsCategoryIds = await _context.JobPostings
                .Where(jp => jp.PostedByUserId == userId && jp.IsActive)
                .Select(jp => jp.CategoryId)
                .Distinct()
                .ToListAsync();

            var preferredCategoryIds = userAppliesCategoryIds
                .Union(userPostsCategoryIds)
                .Distinct()
                .ToList();

            // 2. Cities the user operates in.
            var userCityIds = await _context.JobApplications
                .Where(ja => ja.ApplicantUserId == userId)
                .Select(ja => ja.JobPosting.CityId)
                .Union(
                    _context.JobPostings
                        .Where(jp => jp.PostedByUserId == userId)
                        .Select(jp => jp.CityId)
                )
                .Distinct()
                .ToListAsync();

            // 3. Keyword profile from the user's applied/posted job texts.
            var userHistoryTexts = await _context.JobApplications
                .Where(ja => ja.ApplicantUserId == userId && ja.IsActive)
                .Select(ja => ja.JobPosting.Title + " " + ja.JobPosting.Description)
                .Union(
                    _context.JobPostings
                        .Where(jp => jp.PostedByUserId == userId && jp.IsActive)
                        .Select(jp => jp.Title + " " + jp.Description)
                )
                .ToListAsync();

            var keywordProfile = BuildKeywordProfile(userHistoryTexts);

            // 4. Candidate set: active, open jobs the user did not post.
            var candidates = await _context.JobPostings
                .Where(jp => jp.IsActive && jp.Status == "Open" && jp.PostedByUserId != userId)
                .Include(jp => jp.Category)
                .Include(jp => jp.PostedByUser)
                .Include(jp => jp.City)
                .Include(jp => jp.JobApplications)
                .Include(jp => jp.Messages)
                .ToListAsync();

            if (candidates.Count == 0)
                return new List<JobPostingResponse>();

            // 5. Score and rank candidates.
            var scored = candidates
                .Select(candidate =>
                {
                    double score = 0.0;

                    if (preferredCategoryIds.Contains(candidate.CategoryId))
                        score += 3.0;

                    if (userCityIds.Contains(candidate.CityId))
                        score += 2.0;

                    score += ComputeKeywordOverlap(candidate, keywordProfile) * 1.5;

                    var ageDays = (DateTime.UtcNow - candidate.CreatedAt).TotalDays;
                    if (ageDays <= 7)
                        score += 0.5;

                    return new { Job = candidate, Score = score };
                })
                .OrderByDescending(x => x.Score)
                .ThenByDescending(x => x.Job.CreatedAt)
                .Take(count)
                .ToList();

            return scored.Select(x => MapToResponse(x.Job)).ToList();
        }

        private static Dictionary<string, int> BuildKeywordProfile(List<string> texts)
        {
            var profile = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            var stopWords = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "the", "a", "an", "i", "you", "for", "and", "with",
                "za", "na", "u", "i", "je", "se", "sa", "od", "do",
                "potreban", "potrebna", "potrebno", "trazim"
            };

            foreach (var text in texts)
            {
                if (string.IsNullOrWhiteSpace(text)) continue;

                foreach (var rawWord in text.Split(
                    new[] { ' ', '.', ',', ';', ':', '!', '?', '\t', '\n', '\r', '-', '(', ')' },
                    StringSplitOptions.RemoveEmptyEntries))
                {
                    var word = rawWord.ToLowerInvariant();
                    if (word.Length < 3 || stopWords.Contains(word)) continue;

                    if (profile.ContainsKey(word)) profile[word]++;
                    else profile[word] = 1;
                }
            }
            return profile;
        }

        private static double ComputeKeywordOverlap(JobPosting jobPosting, Dictionary<string, int> keywordProfile)
        {
            if (keywordProfile.Count == 0)
                return 0.0;

            var jobText = $"{jobPosting.Title} {jobPosting.Description}".ToLowerInvariant();
            var uniqueJobWords = new HashSet<string>(jobText.Split(
                new[] { ' ', '.', ',', ';', ':', '!', '?', '\t', '\n', '\r', '-', '(', ')' },
                StringSplitOptions.RemoveEmptyEntries));

            double matchWeight = 0.0;
            foreach (var word in uniqueJobWords)
            {
                if (keywordProfile.TryGetValue(word, out int weight))
                    matchWeight += weight;
            }
            return matchWeight / keywordProfile.Count;
        }

        private static JobPostingResponse MapToResponse(JobPosting jobPosting)
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
