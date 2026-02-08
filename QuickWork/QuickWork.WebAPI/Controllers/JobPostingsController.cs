using QuickWork.Model.Requests;
using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;
using QuickWork.Services.Interfaces;

namespace QuickWork.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class JobPostingsController : ControllerBase
    {
        private readonly IJobPostingService _jobPostingService;

        public JobPostingsController(IJobPostingService jobPostingService)
        {
            _jobPostingService = jobPostingService;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<JobPostingResponse>>> Get([FromQuery] JobPostingSearchObject? search = null)
        {
            return await _jobPostingService.GetAsync(search ?? new JobPostingSearchObject());
        }

        [HttpGet("{id}")]
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
