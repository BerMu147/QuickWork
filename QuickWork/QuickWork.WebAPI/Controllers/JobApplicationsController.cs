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
    public class JobApplicationsController : ControllerBase
    {
        private readonly IJobApplicationService _jobApplicationService;

        public JobApplicationsController(IJobApplicationService jobApplicationService)
        {
            _jobApplicationService = jobApplicationService;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<JobApplicationResponse>>> Get([FromQuery] JobApplicationSearchObject? search = null)
        {
            return await _jobApplicationService.GetAsync(search ?? new JobApplicationSearchObject());
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<JobApplicationResponse>> GetById(int id)
        {
            var application = await _jobApplicationService.GetByIdAsync(id);

            if (application == null)
                return NotFound();

            return application;
        }

        [HttpPost]
        public async Task<ActionResult<JobApplicationResponse>> Create([FromBody] JobApplicationUpsertRequest request, [FromQuery] int applicantUserId)
        {
            var createdApplication = await _jobApplicationService.CreateAsync(request, applicantUserId);
            return CreatedAtAction(nameof(GetById), new { id = createdApplication.Id }, createdApplication);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<JobApplicationResponse>> Update(int id, [FromBody] JobApplicationUpsertRequest request)
        {
            var updatedApplication = await _jobApplicationService.UpdateAsync(id, request);

            if (updatedApplication == null)
                return NotFound();

            return updatedApplication;
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            var deleted = await _jobApplicationService.DeleteAsync(id);

            if (!deleted)
                return NotFound();

            return NoContent();
        }
    }
}
