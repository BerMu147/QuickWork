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
    public class UserSkillsController : ControllerBase
    {
        private readonly IUserSkillService _userSkillService;

        public UserSkillsController(IUserSkillService userSkillService)
        {
            _userSkillService = userSkillService;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<UserSkillResponse>>> Get(
            [FromQuery] UserSkillSearchObject? search = null)
        {
            return await _userSkillService.GetAsync(search ?? new UserSkillSearchObject());
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<UserSkillResponse>> GetById(int id)
        {
            var skill = await _userSkillService.GetByIdAsync(id);
            if (skill == null)
                return NotFound();

            return skill;
        }

        [HttpPost]
        public async Task<ActionResult<UserSkillResponse>> Create(
            [FromBody] UserSkillUpsertRequest request,
            [FromQuery] int userId)
        {
            var createdSkill = await _userSkillService.CreateAsync(request, userId);
            return CreatedAtAction(nameof(GetById), new { id = createdSkill.Id }, createdSkill);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<UserSkillResponse>> Update(
            int id,
            [FromBody] UserSkillUpsertRequest request,
            [FromQuery] int userId)
        {
            var updatedSkill = await _userSkillService.UpdateAsync(id, request);
            if (updatedSkill == null)
                return NotFound();

            return updatedSkill;
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id, [FromQuery] int userId)
        {
            var deleted = await _userSkillService.DeleteAsync(id, userId);

            if (!deleted)
                return NotFound();

            return NoContent();
        }
    }
}
