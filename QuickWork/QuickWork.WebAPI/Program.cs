using Mapster;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Reflection;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using QuickWork.Services.Interfaces;
using QuickWork.Services.Services;
using QuickWork.Services.Database;
using QuickWork.WebAPI.Filters;
using QuickWork.WebAPI.Helpers;
using Microsoft.AspNetCore.Mvc.Authorization;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddTransient<IUserService, UserService>();
builder.Services.AddTransient<IRoleService, RoleService>();
builder.Services.AddTransient<IGenderService, GenderService>();
builder.Services.AddTransient<ICityService, CityService>();
builder.Services.AddTransient<ICategoryService, CategoryService>();

// Quick Work platform services
builder.Services.AddTransient<IJobPostingService, JobPostingService>();
builder.Services.AddTransient<JobRecommendationService>();
builder.Services.AddTransient<IJobApplicationService, JobApplicationService>();
builder.Services.AddTransient<IMessageService, MessageService>();
builder.Services.AddTransient<IReviewService, ReviewService>();
builder.Services.AddTransient<IPaymentService, PaymentService>();
builder.Services.AddTransient<INotificationService, NotificationService>();

// JWT Token Helper
builder.Services.AddSingleton<JwtTokenHelper>();

// Configure database
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? "Data Source=.;Database=MoSmartParkDb;User Id=sa;Password=QWEasd123!;TrustServerCertificate=True;Trusted_Connection=True;";
builder.Services.AddDatabaseServices(connectionString);

// Add configuration
builder.Services.AddSingleton<IConfiguration>(builder.Configuration);

builder.Services.AddMapster();

// Configure JWT authentication
var jwtKey = builder.Configuration["Jwt:Key"] ?? "QuickWork_Default_Secret_Key_For_Development_Only_1234567890";
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "QuickWork";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "QuickWorkClients";
builder.Services.AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtIssuer,
            ValidAudience = jwtAudience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.ASCII.GetBytes(jwtKey))
        };
    })
    .AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>("BasicAuthentication", null);

builder.Services.AddControllers(x =>
    {
        x.Filters.Add<ExceptionFilter>();
        // Require authentication on ALL endpoints by default.
        // Endpoints marked [AllowAnonymous] remain public.
        x.Filters.Add(new AuthorizeFilter());
    }
);

builder.Services.AddAuthorization();

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();

// Za dodavanje opisnog teksta pored swagger call-a
var xmlFilename = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";

builder.Services.AddSwaggerGen(c =>
{
    c.IncludeXmlComments(Path.Combine(AppContext.BaseDirectory, xmlFilename));

    c.AddSecurityDefinition("BasicAuthentication", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "basic",
        In = ParameterLocation.Header,
        Description = "Basic Authorization header using the Bearer scheme."
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "BasicAuthentication" } },
            new string[] { }
        }
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "JWT Authorization header using the Bearer scheme."
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" } },
            new string[] { }
        }
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
//if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

using (var scope = app.Services.CreateScope())
{
    //var dataContext = scope.ServiceProvider.GetRequiredService<ManiFestDbContext>();


    //var pendingMigrations = dataContext.Database.GetPendingMigrations().Any();

    //if (pendingMigrations)
    //{

    //    dataContext.Database.Migrate();


    //}
    


    // Run dynamic data seeder
    //await DynamicDataSeeder.SeedAsync(dataContext);
    
    // Train the recommender model in background after startup
    //_ = Task.Run(async () =>  // The underscore tells the compiler we're intentionally ignoring the result
    //{
    //    // Wait a bit for the app to fully start
    //    await Task.Delay(2000);
    //    using (var trainingScope = app.Services.CreateScope())
    //    {
    //        ParkingSpotService.TrainRecommenderAtStartup(trainingScope.ServiceProvider);
    //    }
    //});
}

app.Run();

