using QuickWork.Model.Requests;
using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;
using QuickWork.Services.Interfaces;
using QuickWork.Services.Services;

namespace QuickWork.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class JobPostingsController : ControllerBase
    {
        private readonly IJobPostingService _jobPostingService;
        private readonly JobRecommendationService _recommendationService;

        public JobPostingsController(IJobPostingService jobPostingService, JobRecommendationService recommendationService)
        {
            _jobPostingService = jobPostingService;
            _recommendationService = recommendationService;
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<ActionResult<PagedResult<JobPostingResponse>>> Get([FromQuery] JobPostingSearchObject? search = null)
        {
            return await _jobPostingService.GetAsync(search ?? new JobPostingSearchObject());
        }

        [HttpGet("recommended")]
        [AllowAnonymous]
        public async Task<ActionResult<List<JobPostingResponse>>> GetRecommended([FromQuery] int userId, [FromQuery] int? count = null)
        {
            var recommended = await _recommendationService.GetRecommendedAsync(userId, count ?? 10);
            return Ok(recommended);
        }


        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<ActionResult<JobPostingResponse>> GetById(int id)
        {
            var jobPosting = await _jobPostingService.GetByIdAsync(id);

            if (jobPosting == null)
                return NotFound();

            return jobPosting;
        }

        [HttpPost]
        public async Task<ActionResult<JobPostingResponse>> Create([FromBody] JobPostingUpsertRequest request, [FromQuery] int postedByUserId)
        {
            var createdJobPosting = await _jobPostingService.CreateAsync(request, postedByUserId);
            return CreatedAtAction(nameof(GetById), new { id = createdJobPosting.Id }, createdJobPosting);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<JobPostingResponse>> Update(int id, [FromBody] JobPostingUpsertRequest request)
        {
            var updatedJobPosting = await _jobPostingService.UpdateAsync(id, request);

            if (updatedJobPosting == null)
                return NotFound();

                        return updatedJobPosting;
        }

        /// <summary>
        /// Transitions a job to a new status (Open -> InProgress -> Completed).
        /// Only the job's owner may change its status.
        /// </summary>
        [HttpPut("{id}/status")]
        public async Task<ActionResult<JobPostingResponse>> ChangeStatus(
            int id,
            [FromQuery] int postedByUserId,
            [FromQuery] string status)
        {
            var updatedJobPosting =
                await _jobPostingService.ChangeStatusAsync(id, postedByUserId, status);

            if (updatedJobPosting == null)
                return NotFound();

            return updatedJobPosting;
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            var deleted = await _jobPostingService.DeleteAsync(id);

            if (!deleted)
                return NotFound();

            return NoContent();
        }
    }
}


