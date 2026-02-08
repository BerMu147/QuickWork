using QuickWork.Services.Database;
using System.Collections.Generic;
using System.Threading.Tasks;
using QuickWork.Model.Responses;
using QuickWork.Model.Requests;
using QuickWork.Model.SearchObjects;
using QuickWork.Services.Services;

namespace QuickWork.Services.Interfaces
{
    public interface IUserService : IService<UserResponse, UserSearchObject>
    {
        Task<UserResponse?> AuthenticateAsync(UserLoginRequest request);
        Task<UserResponse> CreateAsync(UserUpsertRequest request);
        Task<UserResponse?> UpdateAsync(int id, UserUpsertRequest request);
        Task<bool> DeleteAsync(int id);
    }
}