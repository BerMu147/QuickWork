using QuickWork.Services.Database;
using Microsoft.EntityFrameworkCore;
using QuickWork.Services.Database;

namespace QuickWork.Services.Database
{
    public class QuickWorkDbContext : DbContext
    {
        public QuickWorkDbContext(DbContextOptions<QuickWorkDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Role> Roles { get; set; }
        public DbSet<UserRole> UserRoles { get; set; }
        public DbSet<Gender> Genders { get; set; }
        public DbSet<City> Cities { get; set; }
        public DbSet<Category> Categories { get; set; }
        
        // New entities for Quick Work platform
        public DbSet<JobPosting> JobPostings { get; set; }
        public DbSet<JobApplication> JobApplications { get; set; }
        public DbSet<Message> Messages { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<Notification> Notifications { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure User entity
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            modelBuilder.Entity<User>()
                .HasIndex(u => u.Username)
                .IsUnique();
               

            // Configure Role entity
            modelBuilder.Entity<Role>()
                .HasIndex(r => r.Name)
                .IsUnique();

            // Configure UserRole join entity
            modelBuilder.Entity<UserRole>()
                .HasOne(ur => ur.User)
                .WithMany(u => u.UserRoles)
                .HasForeignKey(ur => ur.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<UserRole>()
                .HasOne(ur => ur.Role)
                .WithMany(r => r.UserRoles)
                .HasForeignKey(ur => ur.RoleId)
                .OnDelete(DeleteBehavior.Cascade);

            // Create a unique constraint on UserId and RoleId
            modelBuilder.Entity<UserRole>()
                .HasIndex(ur => new { ur.UserId, ur.RoleId })
                .IsUnique();

         

            // Configure Gender entity
            modelBuilder.Entity<Gender>()
                .HasIndex(g => g.Name)
                .IsUnique();

            // Configure City entity
            modelBuilder.Entity<City>()
                .HasIndex(c => c.Name)
                .IsUnique();

            // Configure Category entity
            modelBuilder.Entity<Category>()
                .HasIndex(c => c.Name)
                .IsUnique();

            modelBuilder.Entity<User>()
                .HasOne(u => u.Gender)
                .WithMany()
                .HasForeignKey(u => u.GenderId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<User>()
                .HasOne(u => u.City)
                .WithMany()
                .HasForeignKey(u => u.CityId)
                .OnDelete(DeleteBehavior.NoAction);

            // Configure JobPosting entity
            modelBuilder.Entity<JobPosting>()
                .HasIndex(jp => jp.PostedByUserId);

            modelBuilder.Entity<JobPosting>()
                .HasIndex(jp => jp.CategoryId);

            modelBuilder.Entity<JobPosting>()
                .HasIndex(jp => jp.CityId);

            modelBuilder.Entity<JobPosting>()
                .HasIndex(jp => jp.Status);

            modelBuilder.Entity<JobPosting>()
                .HasIndex(jp => jp.ScheduledDate);

            modelBuilder.Entity<JobPosting>()
                .HasOne(jp => jp.Category)
                .WithMany()
                .HasForeignKey(jp => jp.CategoryId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<JobPosting>()
                .HasOne(jp => jp.PostedByUser)
                .WithMany()
                .HasForeignKey(jp => jp.PostedByUserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<JobPosting>()
                .HasOne(jp => jp.City)
                .WithMany()
                .HasForeignKey(jp => jp.CityId)
                .OnDelete(DeleteBehavior.NoAction);

            // Configure JobApplication entity
            modelBuilder.Entity<JobApplication>()
                .HasIndex(ja => ja.JobPostingId);

            modelBuilder.Entity<JobApplication>()
                .HasIndex(ja => ja.ApplicantUserId);

            modelBuilder.Entity<JobApplication>()
                .HasIndex(ja => ja.Status);

            // Unique constraint: one application per user per job
            modelBuilder.Entity<JobApplication>()
                .HasIndex(ja => new { ja.JobPostingId, ja.ApplicantUserId })
                .IsUnique();

            modelBuilder.Entity<JobApplication>()
                .HasOne(ja => ja.JobPosting)
                .WithMany(jp => jp.JobApplications)
                .HasForeignKey(ja => ja.JobPostingId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<JobApplication>()
                .HasOne(ja => ja.ApplicantUser)
                .WithMany()
                .HasForeignKey(ja => ja.ApplicantUserId)
                .OnDelete(DeleteBehavior.NoAction);

            // Configure Message entity
            modelBuilder.Entity<Message>()
                .HasIndex(m => m.JobPostingId);

            modelBuilder.Entity<Message>()
                .HasIndex(m => m.SenderUserId);

            modelBuilder.Entity<Message>()
                .HasIndex(m => m.ReceiverUserId);

            modelBuilder.Entity<Message>()
                .HasIndex(m => m.SentAt);

            modelBuilder.Entity<Message>()
                .HasOne(m => m.JobPosting)
                .WithMany(jp => jp.Messages)
                .HasForeignKey(m => m.JobPostingId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Message>()
                .HasOne(m => m.SenderUser)
                .WithMany()
                .HasForeignKey(m => m.SenderUserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Message>()
                .HasOne(m => m.ReceiverUser)
                .WithMany()
                .HasForeignKey(m => m.ReceiverUserId)
                .OnDelete(DeleteBehavior.NoAction);

            // Configure Review entity
            modelBuilder.Entity<Review>()
                .HasIndex(r => r.JobPostingId);

            modelBuilder.Entity<Review>()
                .HasIndex(r => r.ReviewedUserId);

            // Unique constraint: one review per reviewer per job
            modelBuilder.Entity<Review>()
                .HasIndex(r => new { r.JobPostingId, r.ReviewerUserId })
                .IsUnique();

            modelBuilder.Entity<Review>()
                .HasOne(r => r.JobPosting)
                .WithMany(jp => jp.Reviews)
                .HasForeignKey(r => r.JobPostingId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Review>()
                .HasOne(r => r.ReviewerUser)
                .WithMany()
                .HasForeignKey(r => r.ReviewerUserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Review>()
                .HasOne(r => r.ReviewedUser)
                .WithMany()
                .HasForeignKey(r => r.ReviewedUserId)
                .OnDelete(DeleteBehavior.NoAction);

            // Configure Payment entity
            modelBuilder.Entity<Payment>()
                .HasIndex(p => p.JobPostingId);

            modelBuilder.Entity<Payment>()
                .HasIndex(p => p.StripePaymentIntentId)
                .IsUnique();

            modelBuilder.Entity<Payment>()
                .HasIndex(p => p.Status);

            modelBuilder.Entity<Payment>()
                .HasOne(p => p.JobPosting)
                .WithMany(jp => jp.Payments)
                .HasForeignKey(p => p.JobPostingId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Payment>()
                .HasOne(p => p.PayerUser)
                .WithMany()
                .HasForeignKey(p => p.PayerUserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Payment>()
                .HasOne(p => p.ReceiverUser)
                .WithMany()
                .HasForeignKey(p => p.ReceiverUserId)
                .OnDelete(DeleteBehavior.NoAction);

            // Configure Notification entity
            modelBuilder.Entity<Notification>()
                .HasIndex(n => n.UserId);

            modelBuilder.Entity<Notification>()
                .HasIndex(n => n.IsRead);

            modelBuilder.Entity<Notification>()
                .HasIndex(n => n.CreatedAt);

            modelBuilder.Entity<Notification>()
                .HasOne(n => n.User)
                .WithMany()
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // Seed initial data
            modelBuilder.SeedData();
        }
    }
} 