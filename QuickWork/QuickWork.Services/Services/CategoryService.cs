using QuickWork.Model.Requests;
using QuickWork.Model.Responses;
using QuickWork.Model.SearchObjects;
using QuickWork.Services.Database;
using QuickWork.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace QuickWork.Services.Services
{
    public class CategoryService : BaseCRUDService<CategoryResponse, CategorySearchObject, Category, CategoryUpsertRequest, CategoryUpsertRequest>, ICategoryService
    {
        public CategoryService(QuickWorkDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Category> ApplyFilter(IQueryable<Category> query, CategorySearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(c => c.Name.Contains(search.Name));
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(c => c.Name.Contains(search.FTS));
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(c => c.IsActive == search.IsActive.Value);
            }

            return query;
        }

        protected override async Task BeforeInsert(Category entity, CategoryUpsertRequest request)
        {
            if (await _context.Categories.AnyAsync(c => c.Name == request.Name))
            {
                throw new InvalidOperationException("A category with this name already exists.");
            }
        }

        protected override async Task BeforeUpdate(Category entity, CategoryUpsertRequest request)
        {
            if (await _context.Categories.AnyAsync(c => c.Name == request.Name && c.Id != entity.Id))
            {
                throw new InvalidOperationException("A category with this name already exists.");
            }
        }
    }
}
