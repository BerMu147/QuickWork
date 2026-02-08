using System.Threading.Tasks;

namespace QuickWork.Subscriber.Interfaces
{
    public interface IEmailSenderService
    {
        Task SendEmailAsync(string email, string subject, string message);
    }
}
