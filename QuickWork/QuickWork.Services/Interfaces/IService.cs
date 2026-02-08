using QuickWork.Services.Database;
using System.Collections.Generic;
using System.Threading.Tasks;
using QuickWork.Model.Responses;
using QuickWork.Model.Requests;
using QuickWork.Model.SearchObjects;

namespace QuickWork.Services.Interfaces
{
    public interface IService<T, TSearch> where T : class where TSearch : BaseSearchObject
    {
        Task<PagedResult<T>> GetAsync(TSearch search);
        Task<T?> GetByIdAsync(int id);
    }
}