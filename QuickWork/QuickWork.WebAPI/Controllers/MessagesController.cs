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
    public class MessagesController : ControllerBase
    {
        private readonly IMessageService _messageService;

        public MessagesController(IMessageService messageService)
        {
            _messageService = messageService;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<MessageResponse>>> Get([FromQuery] MessageSearchObject? search = null)
        {
            return await _messageService.GetAsync(search ?? new MessageSearchObject());
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<MessageResponse>> GetById(int id)
        {
            var message = await _messageService.GetByIdAsync(id);

            if (message == null)
                return NotFound();

            return message;
        }

        [HttpPost]
        public async Task<ActionResult<MessageResponse>> Create([FromBody] MessageUpsertRequest request, [FromQuery] int senderUserId)
        {
            var createdMessage = await _messageService.CreateAsync(request, senderUserId);
            return CreatedAtAction(nameof(GetById), new { id = createdMessage.Id }, createdMessage);
        }

        [HttpPatch("{id}/mark-as-read")]
        public async Task<ActionResult<MessageResponse>> MarkAsRead(int id)
        {
            var updatedMessage = await _messageService.MarkAsReadAsync(id);

            if (updatedMessage == null)
                return NotFound();

            return updatedMessage;
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            var deleted = await _messageService.DeleteAsync(id);

            if (!deleted)
                return NotFound();

            return NoContent();
        }
    }
}
