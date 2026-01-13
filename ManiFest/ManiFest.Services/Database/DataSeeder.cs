using eRent.Services.Helpers;
using ManiFest.Services.Helpers;
using Microsoft.EntityFrameworkCore;
using System;

namespace ManiFest.Services.Database
{
    public static class DataSeeder
    {
        private const string DefaultPhoneNumber = "+387 61 111 111";

        public static void SeedData(this ModelBuilder modelBuilder)
        {
            // Use a fixed date for all timestamps
            var fixedDate = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Local);

            // Seed Roles
            modelBuilder.Entity<Role>().HasData(
                   new Role
                   {
                       Id = 1,
                       Name = "Administrator",
                       Description = "Full system access and administrative privileges",
                       CreatedAt = fixedDate,
                       IsActive = true
                   },
                   new Role
                   {
                       Id = 2,
                       Name = "User",
                       Description = "Standard user with limited system access",
                       CreatedAt = fixedDate,
                       IsActive = true
                   }
            );


            const string defaultPassword = "test";

            // Admin user (desktop)
            var desktopSalt = PasswordGenerator.GenerateDeterministicSalt("desktop");
            var desktopHash = PasswordGenerator.GenerateHash(defaultPassword, desktopSalt);

            // Regular users
            var user1Salt = PasswordGenerator.GenerateDeterministicSalt("user");
            var user1Hash = PasswordGenerator.GenerateHash(defaultPassword, user1Salt);
            var user2Salt = PasswordGenerator.GenerateDeterministicSalt("user2");
            var user2Hash = PasswordGenerator.GenerateHash(defaultPassword, user2Salt);
            var user3Salt = PasswordGenerator.GenerateDeterministicSalt("user3");
            var user3Hash = PasswordGenerator.GenerateHash(defaultPassword, user3Salt);



            // Seed Users
            modelBuilder.Entity<User>().HasData(
                // Admin user (desktop)
                new User
                {
                    Id = 1,
                    FirstName = "Vedad",
                    LastName = "Nuhić",
                    Email = "admin@erent.com",
                    Username = "desktop",
                    PasswordHash = desktopHash,
                    PasswordSalt = desktopSalt,
                    IsActive = true,
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 1, 
                    CityId = 1,
                    //Picture = ImageConversion.ConvertImageToByteArray("Assets", "pic1.png")
                },
                new User
                {
                    Id = 2,
                    FirstName = "Amel",
                    LastName = "Musić",
                    Email = "test.vedadnuhic@gmail.com",
                    Username = "user",
                    PasswordHash = user1Hash,
                    PasswordSalt = user1Salt,
                    IsActive = true,
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 1, 
                    CityId = 1,
                    Picture = ImageConversion.ConvertImageToByteArray("Assets", "amel.png")

                },
                // User 2
                new User
                {
                    Id = 3,
                    FirstName = "Nina",
                    LastName = "Bijedić",
                    Email = "user2@erent.com",
                    Username = "user2",
                    PasswordHash = user2Hash,
                    PasswordSalt = user2Salt,
                    IsActive = true,
                    CreatedAt = fixedDate,
                    PhoneNumber = DefaultPhoneNumber,
                    GenderId = 2, 
                    CityId = 5, 
                }
            );

            // Seed UserRoles
            modelBuilder.Entity<UserRole>().HasData(
                // Admin user (desktop) - Administrator role
                new UserRole { Id = 1, UserId = 1, RoleId = 1, DateAssigned = fixedDate },
                // Landlord 1 - Landlord role
                // User 1 - User role
                new UserRole { Id = 2, UserId = 2, RoleId = 2, DateAssigned = fixedDate },
                // User 2 - User role
                new UserRole { Id = 3, UserId = 3, RoleId = 2, DateAssigned = fixedDate },
                // User 3 - User role
                new UserRole { Id = 4, UserId = 4, RoleId = 2, DateAssigned = fixedDate }
            );

            // Seed Genders
            modelBuilder.Entity<Gender>().HasData(
                new Gender { Id = 1, Name = "Male" },
                new Gender { Id = 2, Name = "Female" }
            );

      


        }
    }
}