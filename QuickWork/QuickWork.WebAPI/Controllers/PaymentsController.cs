using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;
using QuickWork.Services.Interfaces;

namespace QuickWork.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class PaymentsController : ControllerBase
    {
        private readonly IPaymentService _paymentService;

        public PaymentsController(IPaymentService paymentService)
        {
            _paymentService = paymentService;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<PaymentResponse>>> Get([FromQuery] PaymentSearchObject? search = null)
        {
            return await _paymentService.GetAsync(search ?? new PaymentSearchObject());
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<PaymentResponse>> GetById(int id)
        {
            var payment = await _paymentService.GetByIdAsync(id);

            if (payment == null)
                return NotFound();

            return payment;
        }

        [HttpPost("create-payment-intent")]
        public async Task<ActionResult<PaymentResponse>> CreatePaymentIntent(
            [FromQuery] int jobPostingId,
            [FromQuery] int payerUserId,
            [FromQuery] int receiverUserId,
            [FromQuery] decimal amount)
        {
            var payment = await _paymentService.CreatePaymentIntentAsync(jobPostingId, payerUserId, receiverUserId, amount);
            return CreatedAtAction(nameof(GetById), new { id = payment.Id }, payment);
        }

        [HttpPatch("update-status")]
        public async Task<ActionResult<PaymentResponse>> UpdatePaymentStatus(
            [FromQuery] string stripePaymentIntentId,
            [FromQuery] string status,
            [FromQuery] string? chargeId = null,
            [FromQuery] string? failureReason = null)
        {
            var updatedPayment = await _paymentService.UpdatePaymentStatusAsync(stripePaymentIntentId, status, chargeId, failureReason);

            if (updatedPayment == null)
                return NotFound();

            return updatedPayment;
        }

        [HttpGet("by-stripe-intent/{stripePaymentIntentId}")]
        public async Task<ActionResult<PaymentResponse>> GetByStripePaymentIntentId(string stripePaymentIntentId)
        {
            var payment = await _paymentService.GetByStripePaymentIntentIdAsync(stripePaymentIntentId);

            if (payment == null)
                return NotFound();

            return payment;
        }
    }
}
