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

        /// <summary>
        /// Transitions a job to a new status (e.g. Open -> InProgress -> Completed).
        /// Only the job's owner may change its status. Throws <see cref="UserException"/>
        /// for invalid transitions or unauthorized callers.
        /// </summary>
        Task<JobPostingResponse> ChangeStatusAsync(int id, int postedByUserId, string status);
    }
}

