using QuickWork.Model.Requests;
using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;
using System.Threading.Tasks;

namespace QuickWork.Services.Interfaces
{
    public interface IJobApplicationService : IService<JobApplicationResponse, JobApplicationSearchObject>
    {
        Task<JobApplicationResponse> CreateAsync(JobApplicationUpsertRequest request, int applicantUserId);
        Task<JobApplicationResponse?> UpdateAsync(int id, JobApplicationUpsertRequest request);
        Task<bool> DeleteAsync(int id);
    }
}
