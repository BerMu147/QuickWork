using QuickWork.Model.Requests;
using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;
using System.Threading.Tasks;

namespace QuickWork.Services.Interfaces
{
    public interface IReviewService : IService<ReviewResponse, ReviewSearchObject>
    {
        Task<ReviewResponse> CreateAsync(ReviewUpsertRequest request, int reviewerUserId);
        Task<ReviewResponse?> UpdateAsync(int id, ReviewUpsertRequest request);
        Task<bool> DeleteAsync(int id);
        Task<double> GetAverageRatingForUserAsync(int userId);
    }
}
