using QuickWork.Services.Database;
using System.Collections.Generic;
using System.Threading.Tasks;
using QuickWork.Model.Responses;
using QuickWork.Model.Requests;
using QuickWork.Model.SearchObjects;

namespace QuickWork.Services.Interfaces
{
    public interface ICRUDService<T, TSearch, TInsert, TUpdate> : IService<T, TSearch> where T : class where TSearch : BaseSearchObject where TInsert : class where TUpdate : class
    {
        Task<T> CreateAsync(TInsert request);
        Task<T?> UpdateAsync(int id, TUpdate request);
        Task<bool> DeleteAsync(int id);
    }
}