using QuickWork.Model.Requests;
using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;

namespace QuickWork.Services.Interfaces
{
    public interface ICategoryService : ICRUDService<CategoryResponse, CategorySearchObject, CategoryUpsertRequest, CategoryUpsertRequest>
    {
    }
}
