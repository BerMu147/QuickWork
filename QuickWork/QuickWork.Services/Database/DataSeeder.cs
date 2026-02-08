using eRent.Services.Helpers;
using QuickWork.Services.Helpers;
using Microsoft.EntityFrameworkCore;
using System;

namespace QuickWork.Services.Database
{
    public static class DataSeeder
    {
        private const string DefaultPhoneNumber = "+387 60 225 883";

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
            var desktopSalt = PasswordGenerator.GenerateDeterministicSalt("berinm");
            var desktopHash = PasswordGenerator.GenerateHash(defaultPassword, desktopSalt);

            // Regular users
            var user1Salt = PasswordGenerator.GenerateDeterministicSalt("goran");
            var user1Hash = PasswordGenerator.GenerateHash(defaultPassword, user1Salt);
            var user2Salt = PasswordGenerator.GenerateDeterministicSalt("lepal");
            var user2Hash = PasswordGenerator.GenerateHash(defaultPassword, user2Salt);
            var user3Salt = PasswordGenerator.GenerateDeterministicSalt("random");
            var user3Hash = PasswordGenerator.GenerateHash(defaultPassword, user3Salt);



            // Seed Users
            modelBuilder.Entity<User>().HasData(
                // Admin user (desktop)
                new User
                {
                    Id = 1,
                    FirstName = "Berin",
                    LastName = "Mujcinovic",
                    Email = "berin.mujcinovic.98@gmail.com",
                    Username = "berinm",
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
                    FirstName = "Goran",
                    LastName = "Skondric",
                    Email = "test.goranskondric@gmail.com",
                    Username = "goran",
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
                    FirstName = "Lepa",
                    LastName = "Lukic",
                    Email = "lepa@quickwork.com",
                    Username = "lepal",
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


                new UserRole { Id = 1, UserId = 1, RoleId = 1, DateAssigned = fixedDate },
                new UserRole { Id = 2, UserId = 2, RoleId = 2, DateAssigned = fixedDate },
                new UserRole { Id = 3, UserId = 3, RoleId = 2, DateAssigned = fixedDate }


            );

            // Seed Genders
            modelBuilder.Entity<Gender>().HasData(
                new Gender { Id = 1, Name = "Male" },
                new Gender { Id = 2, Name = "Female" }
            );

            // Seed Cities (30 Bosnia and Herzegovina cities)
            modelBuilder.Entity<City>().HasData(
                new City { Id = 1, Name = "Sarajevo" },
                new City { Id = 2, Name = "Banja Luka" },
                new City { Id = 3, Name = "Tuzla" },
                new City { Id = 4, Name = "Mostar" },
                new City { Id = 5, Name = "Zenica" },
                new City { Id = 6, Name = "Bihać" },
                new City { Id = 7, Name = "Prijedor" },
                new City { Id = 8, Name = "Brčko" },
                new City { Id = 9, Name = "Doboj" },
                new City { Id = 10, Name = "Cazin" },
                new City { Id = 11, Name = "Bijeljina" },
                new City { Id = 12, Name = "Travnik" },
                new City { Id = 13, Name = "Zvornik" },
                new City { Id = 14, Name = "Velika Kladuša" },
                new City { Id = 15, Name = "Gračanica" },
                new City { Id = 16, Name = "Lukavac" },
                new City { Id = 17, Name = "Tešanj" },
                new City { Id = 18, Name = "Gradačac" },
                new City { Id = 19, Name = "Visoko" },
                new City { Id = 20, Name = "Konjic" },
                new City { Id = 21, Name = "Živinice" },
                new City { Id = 22, Name = "Sanski Most" },
                new City { Id = 23, Name = "Livno" },
                new City { Id = 24, Name = "Orašje" },
                new City { Id = 25, Name = "Srebrenik" },
                new City { Id = 26, Name = "Gradiška" },
                new City { Id = 27, Name = "Kakanj" },
                new City { Id = 28, Name = "Bugojno" },
                new City { Id = 29, Name = "Jajce" },
                new City { Id = 30, Name = "Trebinje" }
            );

            // Seed Categories
            modelBuilder.Entity<Category>().HasData(
                new Category { Id = 1, Name = "Zastitar" },
                new Category { Id = 2, Name = "Fizicki pomocnik" },
                new Category { Id = 3, Name = "Fotograf" },
                new Category { Id = 4, Name = "Drvosjeca" },
                new Category { Id = 5, Name = "Muzicar" },
                new Category { Id = 6, Name = "Elektricar" },
                new Category { Id = 7, Name = "Dostavljac" },
                new Category { Id = 8, Name = "Pomoć u organizaciji" },
                new Category { Id = 9, Name = "Vrtlar" },
                new Category { Id = 10, Name = "Farmer" },
                new Category { Id = 11, Name = "Vodoinstalater" },
                new Category { Id = 12, Name = "Babysitter" },
                new Category { Id = 13, Name = "Njegovatelj" },
                new Category { Id = 14, Name = "Kuhar" },
                new Category { Id = 15, Name = "Ostalo" }
            );

            // Seed JobPostings
            modelBuilder.Entity<JobPosting>().HasData(
                new JobPosting
                {
                    Id = 1,
                    Title = "Potreban babysitter za vikend",
                    Description = "Tražim pouzdanu osobu za čuvanje dvoje djece (5 i 8 godina) tokom vikenda. Potrebno iskustvo sa djecom.",
                    CategoryId = 12, // Babysitter
                    PostedByUserId = 2, // Goran
                    CityId = 1, // Sarajevo
                    Address = "Ulica Zmaja od Bosne 12",
                    PaymentAmount = 50.00m,
                    EstimatedDurationHours = 8.0m,
                    ScheduledDate = new DateTime(2026, 2, 15, 0, 0, 0, DateTimeKind.Local),
                    ScheduledTimeStart = new TimeSpan(9, 0, 0),
                    ScheduledTimeEnd = new TimeSpan(17, 0, 0),
                    Status = "Open",
                    IsActive = true,
                    CreatedAt = fixedDate
                },
                new JobPosting
                {
                    Id = 2,
                    Title = "Vodoinstalater za popravku slavine",
                    Description = "Hitno potreban vodoinstalater za popravku curenja slavine u kupatilu. Jednostavan posao.",
                    CategoryId = 11, // Vodoinstalater
                    PostedByUserId = 3, // Lepa
                    CityId = 5, // Zenica
                    Address = "Trg Slobode 5",
                    PaymentAmount = 30.00m,
                    EstimatedDurationHours = 2.0m,
                    ScheduledDate = new DateTime(2026, 2, 10, 0, 0, 0, DateTimeKind.Local),
                    ScheduledTimeStart = new TimeSpan(14, 0, 0),
                    ScheduledTimeEnd = new TimeSpan(16, 0, 0),
                    Status = "InProgress",
                    IsActive = true,
                    CreatedAt = fixedDate
                },
                new JobPosting
                {
                    Id = 3,
                    Title = "Fotograf za rođendan",
                    Description = "Tražim profesionalnog fotografa za snimanje dječijeg rođendana. Potrebno iskustvo sa event fotografijom.",
                    CategoryId = 3, // Fotograf
                    PostedByUserId = 1, // Berin
                    CityId = 1, // Sarajevo
                    Address = "Restoran Kod Muje, Ferhadija 20",
                    PaymentAmount = 100.00m,
                    EstimatedDurationHours = 4.0m,
                    ScheduledDate = new DateTime(2026, 2, 20, 0, 0, 0, DateTimeKind.Local),
                    ScheduledTimeStart = new TimeSpan(15, 0, 0),
                    ScheduledTimeEnd = new TimeSpan(19, 0, 0),
                    Status = "Open",
                    IsActive = true,
                    CreatedAt = fixedDate
                },
                new JobPosting
                {
                    Id = 4,
                    Title = "Pomoć u selidbi",
                    Description = "Potrebna pomoć za seljenje stana. Nosenje kutija i namještaja. Fizički zahtjevan posao.",
                    CategoryId = 2, // Fizicki pomocnik
                    PostedByUserId = 2, // Goran
                    CityId = 1, // Sarajevo
                    Address = "Grbavica, Safvet-bega Bašagića 15",
                    PaymentAmount = 80.00m,
                    EstimatedDurationHours = 6.0m,
                    ScheduledDate = new DateTime(2026, 1, 25, 0, 0, 0, DateTimeKind.Local),
                    ScheduledTimeStart = new TimeSpan(8, 0, 0),
                    ScheduledTimeEnd = new TimeSpan(14, 0, 0),
                    Status = "Completed",
                    IsActive = true,
                    CreatedAt = fixedDate,
                    CompletedAt = new DateTime(2026, 1, 25, 14, 30, 0, DateTimeKind.Local)
                },
                new JobPosting
                {
                    Id = 5,
                    Title = "Vrtlar za uređenje dvorišta",
                    Description = "Potreban vrtlar za košenje trave i uređenje cvijeća u dvorištu. Alat obezbijeđen.",
                    CategoryId = 9, // Vrtlar
                    PostedByUserId = 3, // Lepa
                    CityId = 5, // Zenica
                    Address = "Crkvice, Ulica Maršala Tita 88",
                    PaymentAmount = 40.00m,
                    EstimatedDurationHours = 3.0m,
                    ScheduledDate = new DateTime(2026, 2, 18, 0, 0, 0, DateTimeKind.Local),
                    ScheduledTimeStart = new TimeSpan(10, 0, 0),
                    ScheduledTimeEnd = new TimeSpan(13, 0, 0),
                    Status = "Open",
                    IsActive = true,
                    CreatedAt = fixedDate
                }
            );

            // Seed JobApplications
            modelBuilder.Entity<JobApplication>().HasData(
                new JobApplication
                {
                    Id = 1,
                    JobPostingId = 1, // Babysitter job
                    ApplicantUserId = 3, // Lepa
                    Message = "Imam veliko iskustvo sa djecom. Radila sam kao babysitter 3 godine. Volim djecu i odgovorna sam osoba.",
                    Status = "Pending",
                    AppliedAt = fixedDate.AddDays(1),
                    IsActive = true
                },
                new JobApplication
                {
                    Id = 2,
                    JobPostingId = 2, // Vodoinstalater job
                    ApplicantUserId = 1, // Berin
                    Message = "Certificirani vodoinstalater sa 5 godina iskustva. Mogu doći sutra.",
                    Status = "Accepted",
                    AppliedAt = fixedDate.AddDays(1),
                    RespondedAt = fixedDate.AddDays(2),
                    IsActive = true
                },
                new JobApplication
                {
                    Id = 3,
                    JobPostingId = 3, // Fotograf job
                    ApplicantUserId = 2, // Goran
                    Message = "Profesionalni fotograf sa 10 godina iskustva u event fotografiji. Imam profesionalnu opremu.",
                    Status = "Pending",
                    AppliedAt = fixedDate.AddDays(2),
                    IsActive = true
                },
                new JobApplication
                {
                    Id = 4,
                    JobPostingId = 4, // Selidba job (completed)
                    ApplicantUserId = 3, // Lepa
                    Message = "Fizički sam sposobna i imam iskustva sa selidbama.",
                    Status = "Accepted",
                    AppliedAt = fixedDate.AddDays(-5),
                    RespondedAt = fixedDate.AddDays(-4),
                    IsActive = true
                },
                new JobApplication
                {
                    Id = 5,
                    JobPostingId = 5, // Vrtlar job
                    ApplicantUserId = 1, // Berin
                    Message = "Volim rad u prirodi i imam iskustva sa vrtlarstvom.",
                    Status = "Pending",
                    AppliedAt = fixedDate.AddDays(1),
                    IsActive = true
                }
            );

            // Seed Messages
            modelBuilder.Entity<Message>().HasData(
                new Message
                {
                    Id = 1,
                    JobPostingId = 1,
                    SenderUserId = 2, // Goran (poster)
                    ReceiverUserId = 3, // Lepa (applicant)
                    Content = "Zdravo! Hvala na prijavi. Da li imate reference od prethodnih poslova?",
                    SentAt = fixedDate.AddDays(2),
                    IsRead = true,
                    ReadAt = fixedDate.AddDays(2).AddHours(2)
                },
                new Message
                {
                    Id = 2,
                    JobPostingId = 1,
                    SenderUserId = 3, // Lepa (applicant)
                    ReceiverUserId = 2, // Goran (poster)
                    Content = "Naravno! Mogu vam poslati kontakte prethodnih poslodavaca. Radila sam za 5 porodica u Sarajevu.",
                    SentAt = fixedDate.AddDays(2).AddHours(3),
                    IsRead = true,
                    ReadAt = fixedDate.AddDays(2).AddHours(4)
                },
                new Message
                {
                    Id = 3,
                    JobPostingId = 2,
                    SenderUserId = 3, // Lepa (poster)
                    ReceiverUserId = 1, // Berin (applicant)
                    Content = "Odlično! Kada možete doći?",
                    SentAt = fixedDate.AddDays(2),
                    IsRead = true,
                    ReadAt = fixedDate.AddDays(2).AddHours(1)
                },
                new Message
                {
                    Id = 4,
                    JobPostingId = 2,
                    SenderUserId = 1, // Berin (applicant)
                    ReceiverUserId = 3, // Lepa (poster)
                    Content = "Mogu sutra u 14h. Adresa je Trg Slobode 5, tačno?",
                    SentAt = fixedDate.AddDays(2).AddHours(2),
                    IsRead = false
                }
            );

            // Seed Reviews
            modelBuilder.Entity<Review>().HasData(
                new Review
                {
                    Id = 1,
                    JobPostingId = 4, // Completed selidba job
                    ReviewerUserId = 2, // Goran (poster)
                    ReviewedUserId = 3, // Lepa (worker)
                    Rating = 5,
                    Comment = "Odličan rad! Lepa je bila veoma profesionalna i efikasna. Sve je završeno na vrijeme.",
                    CreatedAt = fixedDate.AddDays(-3),
                    IsActive = true
                },
                new Review
                {
                    Id = 2,
                    JobPostingId = 4, // Completed selidba job
                    ReviewerUserId = 3, // Lepa (worker)
                    ReviewedUserId = 2, // Goran (poster)
                    Rating = 5,
                    Comment = "Odličan poslodavac, sve je bilo jasno dogovoreno. Preporučujem!",
                    CreatedAt = fixedDate.AddDays(-3),
                    IsActive = true
                }
            );

            // Seed Payments
            modelBuilder.Entity<Payment>().HasData(
                new Payment
                {
                    Id = 1,
                    JobPostingId = 4, // Completed selidba job
                    PayerUserId = 2, // Goran (poster)
                    ReceiverUserId = 3, // Lepa (worker)
                    Amount = 80.00m,
                    StripePaymentIntentId = "pi_test_1234567890abcdef",
                    StripeChargeId = "ch_test_1234567890abcdef",
                    Status = "Completed",
                    CreatedAt = fixedDate.AddDays(-4),
                    CompletedAt = fixedDate.AddDays(-3)
                },
                new Payment
                {
                    Id = 2,
                    JobPostingId = 2, // InProgress vodoinstalater job
                    PayerUserId = 3, // Lepa (poster)
                    ReceiverUserId = 1, // Berin (worker)
                    Amount = 30.00m,
                    StripePaymentIntentId = "pi_test_abcdef1234567890",
                    Status = "Pending",
                    CreatedAt = fixedDate.AddDays(2)
                }
            );

            // Seed Notifications
            modelBuilder.Entity<Notification>().HasData(
                new Notification
                {
                    Id = 1,
                    UserId = 2, // Goran
                    Type = "NewApplication",
                    Title = "Nova prijava na vaš oglas",
                    Message = "Lepa Lukic se prijavila na vaš oglas 'Potreban babysitter za vikend'",
                    RelatedEntityType = "JobApplication",
                    RelatedEntityId = 1,
                    IsRead = true,
                    CreatedAt = fixedDate.AddDays(1),
                    ReadAt = fixedDate.AddDays(1).AddHours(1)
                },
                new Notification
                {
                    Id = 2,
                    UserId = 3, // Lepa
                    Type = "ApplicationAccepted",
                    Title = "Vaša prijava je prihvaćena",
                    Message = "Vaša prijava za posao 'Pomoć u selidbi' je prihvaćena!",
                    RelatedEntityType = "JobApplication",
                    RelatedEntityId = 4,
                    IsRead = true,
                    CreatedAt = fixedDate.AddDays(-4),
                    ReadAt = fixedDate.AddDays(-4).AddHours(2)
                },
                new Notification
                {
                    Id = 3,
                    UserId = 1, // Berin
                    Type = "MessageReceived",
                    Title = "Nova poruka",
                    Message = "Primili ste novu poruku od Lepa Lukic",
                    RelatedEntityType = "Message",
                    RelatedEntityId = 3,
                    IsRead = true,
                    CreatedAt = fixedDate.AddDays(2),
                    ReadAt = fixedDate.AddDays(2).AddHours(1)
                },
                new Notification
                {
                    Id = 4,
                    UserId = 3, // Lepa
                    Type = "PaymentReceived",
                    Title = "Plaćanje primljeno",
                    Message = "Primili ste plaćanje od 80.00 KM za posao 'Pomoć u selidbi'",
                    RelatedEntityType = "Payment",
                    RelatedEntityId = 1,
                    IsRead = true,
                    CreatedAt = fixedDate.AddDays(-3),
                    ReadAt = fixedDate.AddDays(-3).AddMinutes(30)
                },
                new Notification
                {
                    Id = 5,
                    UserId = 2, // Goran
                    Type = "NewApplication",
                    Title = "Nova prijava na vaš oglas",
                    Message = "Goran Skondric se prijavio na vaš oglas 'Fotograf za rođendan'",
                    RelatedEntityType = "JobApplication",
                    RelatedEntityId = 3,
                    IsRead = false,
                    CreatedAt = fixedDate.AddDays(2)
                }
            );

        }
    }
}