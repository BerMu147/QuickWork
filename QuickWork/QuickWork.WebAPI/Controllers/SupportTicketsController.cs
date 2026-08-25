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
    public class SupportTicketsController : ControllerBase
    {
        private readonly ISupportTicketService _supportTicketService;

        public SupportTicketsController(ISupportTicketService supportTicketService)
        {
            _supportTicketService = supportTicketService;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<SupportTicketResponse>>> Get([FromQuery] SupportTicketSearchObject? search = null)
        {
            return await _supportTicketService.GetAsync(search ?? new SupportTicketSearchObject());
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<SupportTicketResponse>> GetById(int id)
        {
            var ticket = await _supportTicketService.GetByIdAsync(id);

            if (ticket == null)
                return NotFound();

            return ticket;
        }

        [HttpPost]
        public async Task<ActionResult<SupportTicketResponse>> Create([FromBody] SupportTicketUpsertRequest request)
        {
            var createdTicket = await _supportTicketService.CreateAsync(request);
            return CreatedAtAction(nameof(GetById), new { id = createdTicket.Id }, createdTicket);
        }

        [HttpPatch("{id}/reply")]
        public async Task<ActionResult<SupportTicketResponse>> Reply(int id, [FromBody] SupportTicketReplyRequest request)
        {
            var updatedTicket = await _supportTicketService.ReplyAsync(id, request);

            if (updatedTicket == null)
                return NotFound();

            return updatedTicket;
        }

        [HttpPatch("{id}/status")]
        public async Task<ActionResult<SupportTicketResponse>> UpdateStatus(int id, [FromBody] UpdateStatusRequest request)
        {
            var updatedTicket = await _supportTicketService.UpdateStatusAsync(id, request.Status);

            if (updatedTicket == null)
                return NotFound();

            return updatedTicket;
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            var deleted = await _supportTicketService.DeleteAsync(id);

            if (!deleted)
                return NotFound();

            return NoContent();
        }

        /// <summary>Small inline DTO for the status-only update endpoint.</summary>
        public class UpdateStatusRequest
        {
            public string Status { get; set; } = string.Empty;
        }
    }
}
