using QuickWork.Model.Requests;
using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;
using System.Threading.Tasks;

namespace QuickWork.Services.Interfaces
{
    public interface IJobPostingService : IService<JobPostingResponse, JobPostingSearchObject>
    {
        Task<JobPostingResponse> CreateAsync(JobPostingUpsertRequest request, int postedByUserId);
        Task<JobPostingResponse?> UpdateAsync(int id, JobPostingUpsertRequest request);
        Task<bool> DeleteAsync(int id);
    }
}
