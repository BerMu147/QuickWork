using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace QuickWork.Services.Database
{
    public static class DatabaseConfiguration
    {
        public static void AddDatabaseServices(this IServiceCollection services, string connectionString)
        {
            services.AddDbContext<QuickWorkDbContext>(options =>
                options.UseSqlServer(connectionString));
        }

        public static void AddDatabaseManiFest(this IServiceCollection services, string connectionString)
        {
            services.AddDbContext<QuickWorkDbContext>(options =>
                options.UseSqlServer(connectionString));
        }
    }
}