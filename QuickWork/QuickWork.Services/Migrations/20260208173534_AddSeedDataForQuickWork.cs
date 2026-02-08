using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace QuickWork.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddSeedDataForQuickWork : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "JobPostings",
                columns: new[] { "Id", "Address", "CategoryId", "CityId", "CompletedAt", "CreatedAt", "Description", "EstimatedDurationHours", "IsActive", "PaymentAmount", "PostedByUserId", "ScheduledDate", "ScheduledTimeEnd", "ScheduledTimeStart", "Status", "Title", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, "Ulica Zmaja od Bosne 12", 12, 1, null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Local), "Tražim pouzdanu osobu za čuvanje dvoje djece (5 i 8 godina) tokom vikenda. Potrebno iskustvo sa djecom.", 8.0m, true, 50.00m, 2, new DateTime(2026, 2, 15, 0, 0, 0, 0, DateTimeKind.Local), new TimeSpan(0, 17, 0, 0, 0), new TimeSpan(0, 9, 0, 0, 0), "Open", "Potreban babysitter za vikend", null },
                    { 2, "Trg Slobode 5", 11, 5, null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Local), "Hitno potreban vodoinstalater za popravku curenja slavine u kupatilu. Jednostavan posao.", 2.0m, true, 30.00m, 3, new DateTime(2026, 2, 10, 0, 0, 0, 0, DateTimeKind.Local), new TimeSpan(0, 16, 0, 0, 0), new TimeSpan(0, 14, 0, 0, 0), "InProgress", "Vodoinstalater za popravku slavine", null },
                    { 3, "Restoran Kod Muje, Ferhadija 20", 3, 1, null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Local), "Tražim profesionalnog fotografa za snimanje dječijeg rođendana. Potrebno iskustvo sa event fotografijom.", 4.0m, true, 100.00m, 1, new DateTime(2026, 2, 20, 0, 0, 0, 0, DateTimeKind.Local), new TimeSpan(0, 19, 0, 0, 0), new TimeSpan(0, 15, 0, 0, 0), "Open", "Fotograf za rođendan", null },
                    { 4, "Grbavica, Safvet-bega Bašagića 15", 2, 1, new DateTime(2026, 1, 25, 14, 30, 0, 0, DateTimeKind.Local), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Local), "Potrebna pomoć za seljenje stana. Nosenje kutija i namještaja. Fizički zahtjevan posao.", 6.0m, true, 80.00m, 2, new DateTime(2026, 1, 25, 0, 0, 0, 0, DateTimeKind.Local), new TimeSpan(0, 14, 0, 0, 0), new TimeSpan(0, 8, 0, 0, 0), "Completed", "Pomoć u selidbi", null },
                    { 5, "Crkvice, Ulica Maršala Tita 88", 9, 5, null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Local), "Potreban vrtlar za košenje trave i uređenje cvijeća u dvorištu. Alat obezbijeđen.", 3.0m, true, 40.00m, 3, new DateTime(2026, 2, 18, 0, 0, 0, 0, DateTimeKind.Local), new TimeSpan(0, 13, 0, 0, 0), new TimeSpan(0, 10, 0, 0, 0), "Open", "Vrtlar za uređenje dvorišta", null }
                });

            migrationBuilder.InsertData(
                table: "Notifications",
                columns: new[] { "Id", "CreatedAt", "IsRead", "Message", "ReadAt", "RelatedEntityId", "RelatedEntityType", "Title", "Type", "UserId" },
                values: new object[,]
                {
                    { 1, new DateTime(2026, 1, 2, 0, 0, 0, 0, DateTimeKind.Local), true, "Lepa Lukic se prijavila na vaš oglas 'Potreban babysitter za vikend'", new DateTime(2026, 1, 2, 1, 0, 0, 0, DateTimeKind.Local), 1, "JobApplication", "Nova prijava na vaš oglas", "NewApplication", 2 },
                    { 2, new DateTime(2025, 12, 28, 0, 0, 0, 0, DateTimeKind.Local), true, "Vaša prijava za posao 'Pomoć u selidbi' je prihvaćena!", new DateTime(2025, 12, 28, 2, 0, 0, 0, DateTimeKind.Local), 4, "JobApplication", "Vaša prijava je prihvaćena", "ApplicationAccepted", 3 },
                    { 3, new DateTime(2026, 1, 3, 0, 0, 0, 0, DateTimeKind.Local), true, "Primili ste novu poruku od Lepa Lukic", new DateTime(2026, 1, 3, 1, 0, 0, 0, DateTimeKind.Local), 3, "Message", "Nova poruka", "MessageReceived", 1 },
                    { 4, new DateTime(2025, 12, 29, 0, 0, 0, 0, DateTimeKind.Local), true, "Primili ste plaćanje od 80.00 KM za posao 'Pomoć u selidbi'", new DateTime(2025, 12, 29, 0, 30, 0, 0, DateTimeKind.Local), 1, "Payment", "Plaćanje primljeno", "PaymentReceived", 3 },
                    { 5, new DateTime(2026, 1, 3, 0, 0, 0, 0, DateTimeKind.Local), false, "Goran Skondric se prijavio na vaš oglas 'Fotograf za rođendan'", null, 3, "JobApplication", "Nova prijava na vaš oglas", "NewApplication", 2 }
                });

            migrationBuilder.InsertData(
                table: "JobApplications",
                columns: new[] { "Id", "ApplicantUserId", "AppliedAt", "IsActive", "JobPostingId", "Message", "RespondedAt", "Status" },
                values: new object[,]
                {
                    { 1, 3, new DateTime(2026, 1, 2, 0, 0, 0, 0, DateTimeKind.Local), true, 1, "Imam veliko iskustvo sa djecom. Radila sam kao babysitter 3 godine. Volim djecu i odgovorna sam osoba.", null, "Pending" },
                    { 2, 1, new DateTime(2026, 1, 2, 0, 0, 0, 0, DateTimeKind.Local), true, 2, "Certificirani vodoinstalater sa 5 godina iskustva. Mogu doći sutra.", new DateTime(2026, 1, 3, 0, 0, 0, 0, DateTimeKind.Local), "Accepted" },
                    { 3, 2, new DateTime(2026, 1, 3, 0, 0, 0, 0, DateTimeKind.Local), true, 3, "Profesionalni fotograf sa 10 godina iskustva u event fotografiji. Imam profesionalnu opremu.", null, "Pending" },
                    { 4, 3, new DateTime(2025, 12, 27, 0, 0, 0, 0, DateTimeKind.Local), true, 4, "Fizički sam sposobna i imam iskustva sa selidbama.", new DateTime(2025, 12, 28, 0, 0, 0, 0, DateTimeKind.Local), "Accepted" },
                    { 5, 1, new DateTime(2026, 1, 2, 0, 0, 0, 0, DateTimeKind.Local), true, 5, "Volim rad u prirodi i imam iskustva sa vrtlarstvom.", null, "Pending" }
                });

            migrationBuilder.InsertData(
                table: "Messages",
                columns: new[] { "Id", "Content", "IsRead", "JobPostingId", "ReadAt", "ReceiverUserId", "SenderUserId", "SentAt" },
                values: new object[,]
                {
                    { 1, "Zdravo! Hvala na prijavi. Da li imate reference od prethodnih poslova?", true, 1, new DateTime(2026, 1, 3, 2, 0, 0, 0, DateTimeKind.Local), 3, 2, new DateTime(2026, 1, 3, 0, 0, 0, 0, DateTimeKind.Local) },
                    { 2, "Naravno! Mogu vam poslati kontakte prethodnih poslodavaca. Radila sam za 5 porodica u Sarajevu.", true, 1, new DateTime(2026, 1, 3, 4, 0, 0, 0, DateTimeKind.Local), 2, 3, new DateTime(2026, 1, 3, 3, 0, 0, 0, DateTimeKind.Local) },
                    { 3, "Odlično! Kada možete doći?", true, 2, new DateTime(2026, 1, 3, 1, 0, 0, 0, DateTimeKind.Local), 1, 3, new DateTime(2026, 1, 3, 0, 0, 0, 0, DateTimeKind.Local) },
                    { 4, "Mogu sutra u 14h. Adresa je Trg Slobode 5, tačno?", false, 2, null, 3, 1, new DateTime(2026, 1, 3, 2, 0, 0, 0, DateTimeKind.Local) }
                });

            migrationBuilder.InsertData(
                table: "Payments",
                columns: new[] { "Id", "Amount", "CompletedAt", "CreatedAt", "FailureReason", "JobPostingId", "PayerUserId", "ReceiverUserId", "Status", "StripeChargeId", "StripePaymentIntentId" },
                values: new object[,]
                {
                    { 1, 80.00m, new DateTime(2025, 12, 29, 0, 0, 0, 0, DateTimeKind.Local), new DateTime(2025, 12, 28, 0, 0, 0, 0, DateTimeKind.Local), null, 4, 2, 3, "Completed", "ch_test_1234567890abcdef", "pi_test_1234567890abcdef" },
                    { 2, 30.00m, null, new DateTime(2026, 1, 3, 0, 0, 0, 0, DateTimeKind.Local), null, 2, 3, 1, "Pending", null, "pi_test_abcdef1234567890" }
                });

            migrationBuilder.InsertData(
                table: "Reviews",
                columns: new[] { "Id", "Comment", "CreatedAt", "IsActive", "JobPostingId", "Rating", "ReviewedUserId", "ReviewerUserId" },
                values: new object[,]
                {
                    { 1, "Odličan rad! Lepa je bila veoma profesionalna i efikasna. Sve je završeno na vrijeme.", new DateTime(2025, 12, 29, 0, 0, 0, 0, DateTimeKind.Local), true, 4, 5, 3, 2 },
                    { 2, "Odličan poslodavac, sve je bilo jasno dogovoreno. Preporučujem!", new DateTime(2025, 12, 29, 0, 0, 0, 0, DateTimeKind.Local), true, 4, 5, 2, 3 }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "JobApplications",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "JobApplications",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "JobApplications",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "JobApplications",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "JobApplications",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Messages",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Messages",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Messages",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Messages",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Notifications",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Reviews",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Reviews",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "JobPostings",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "JobPostings",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "JobPostings",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "JobPostings",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "JobPostings",
                keyColumn: "Id",
                keyValue: 5);
        }
    }
}
