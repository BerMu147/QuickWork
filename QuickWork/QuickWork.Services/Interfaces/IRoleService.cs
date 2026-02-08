using QuickWork.Model.Requests;
using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;

namespace QuickWork.Services.Interfaces
{
    public interface IRoleService : ICRUDService<RoleResponse, RoleSearchObject, RoleUpsertRequest, RoleUpsertRequest>
    {
    }
}