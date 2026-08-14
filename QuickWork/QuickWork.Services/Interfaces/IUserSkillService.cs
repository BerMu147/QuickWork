using QuickWork.Model.Requests;
using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;
using System.Threading.Tasks;

namespace QuickWork.Services.Interfaces
{
    public interface IUserSkillService : IService<UserSkillResponse, UserSkillSearchObject>
    {
        Task<UserSkillResponse> CreateAsync(UserSkillUpsertRequest request, int userId);
        Task<UserSkillResponse?> UpdateAsync(int id, UserSkillUpsertRequest request);
        Task<bool> DeleteAsync(int id, int userId);
    }
}
