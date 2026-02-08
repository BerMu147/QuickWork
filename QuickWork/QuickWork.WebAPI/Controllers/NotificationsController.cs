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
    public class NotificationsController : ControllerBase
    {
        private readonly INotificationService _notificationService;

        public NotificationsController(INotificationService notificationService)
        {
            _notificationService = notificationService;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<NotificationResponse>>> Get([FromQuery] NotificationSearchObject? search = null)
        {
            return await _notificationService.GetAsync(search ?? new NotificationSearchObject());
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<NotificationResponse>> GetById(int id)
        {
            var notification = await _notificationService.GetByIdAsync(id);

            if (notification == null)
                return NotFound();

            return notification;
        }

        [HttpPost]
        public async Task<ActionResult<NotificationResponse>> Create([FromBody] NotificationUpsertRequest request)
        {
            var createdNotification = await _notificationService.CreateAsync(request);
            return CreatedAtAction(nameof(GetById), new { id = createdNotification.Id }, createdNotification);
        }

        [HttpPatch("{id}/mark-as-read")]
        public async Task<ActionResult<NotificationResponse>> MarkAsRead(int id)
        {
            var updatedNotification = await _notificationService.MarkAsReadAsync(id);

            if (updatedNotification == null)
                return NotFound();

            return updatedNotification;
        }

        [HttpPatch("mark-all-as-read/{userId}")]
        public async Task<ActionResult<int>> MarkAllAsRead(int userId)
        {
            var count = await _notificationService.MarkAllAsReadForUserAsync(userId);
            return Ok(new { markedCount = count });
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            var deleted = await _notificationService.DeleteAsync(id);

            if (!deleted)
                return NotFound();

            return NoContent();
        }
    }
}
