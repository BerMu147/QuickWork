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
    public class ReviewsController : ControllerBase
    {
        private readonly IReviewService _reviewService;

        public ReviewsController(IReviewService reviewService)
        {
            _reviewService = reviewService;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<ReviewResponse>>> Get([FromQuery] ReviewSearchObject? search = null)
        {
            return await _reviewService.GetAsync(search ?? new ReviewSearchObject());
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ReviewResponse>> GetById(int id)
        {
            var review = await _reviewService.GetByIdAsync(id);

            if (review == null)
                return NotFound();

            return review;
        }

        [HttpPost]
        public async Task<ActionResult<ReviewResponse>> Create([FromBody] ReviewUpsertRequest request, [FromQuery] int reviewerUserId)
        {
            var createdReview = await _reviewService.CreateAsync(request, reviewerUserId);
            return CreatedAtAction(nameof(GetById), new { id = createdReview.Id }, createdReview);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<ReviewResponse>> Update(int id, [FromBody] ReviewUpsertRequest request)
        {
            var updatedReview = await _reviewService.UpdateAsync(id, request);

            if (updatedReview == null)
                return NotFound();

            return updatedReview;
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            var deleted = await _reviewService.DeleteAsync(id);

            if (!deleted)
                return NotFound();

            return NoContent();
        }

        [HttpGet("average-rating/{userId}")]
        public async Task<ActionResult<double>> GetAverageRating(int userId)
        {
            var averageRating = await _reviewService.GetAverageRatingForUserAsync(userId);
            return Ok(averageRating);
        }
    }
}
