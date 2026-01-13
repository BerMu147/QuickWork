using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace ManiFest.Services.Database
{
    /// <summary>
    /// Dynamic seeder koji se pokreće u runtime-u,
    /// obično pri startu aplikacije (npr. u Program.cs).
    /// Koristi se za unos demo/test podataka koji nisu dio migracije.
    /// </summary>
    public static class DynamicDataSeeder
    {
        public static async Task SeedAsync(Manif context)
        {
            // Osiguraj da baza postoji
            await context.Database.EnsureCreatedAsync();

            await SeedRuntimeReservationsAsync(context);
        }

        /// <summary>
        /// Kreira runtime rezervacije za user 2 (car id 1) na dan kada se aplikacija pokrene.
        /// Rezervacije: 15:00-18:00 i 19:00-23:00
        /// </summary>
        private static async Task SeedRuntimeReservationsAsync(MoSmartParkDbContext context)
        {
            const int userId = 2;
            const int carId = 1; // User 2's car
            const int hourlyReservationTypeId = 3; // Hourly reservation type

            // Check if user 2 and car 1 exist
            var user = await context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
            {
                Console.WriteLine("⚠️ Dynamic seed: User 2 not found. Skipping runtime reservations.");
                return;
            }

            var car = await context.Cars.FirstOrDefaultAsync(c => c.Id == carId);
            if (car == null)
            {
                Console.WriteLine("⚠️ Dynamic seed: Car 1 not found. Skipping runtime reservations.");
                return;
            }

            // Get today's date at midnight UTC
            var today = DateTime.UtcNow.Date;
            
            // First reservation: 15:00 to 18:00
            var firstReservationStart = today.AddHours(15);
            var firstReservationEnd = today.AddHours(18);
            
            // Second reservation: 19:00 to 23:00
            var secondReservationStart = today.AddHours(19);
            var secondReservationEnd = today.AddHours(23);

            // Check if reservations already exist for today
            var existingReservations = await context.Reservations
                .Where(r => r.CarId == carId
                    && r.StartDate.HasValue
                    && r.EndDate.HasValue
                    && r.StartDate.Value.Date == today)
                .ToListAsync();

            // Check if first reservation already exists
            var firstExists = existingReservations.Any(r =>
                r.StartDate.Value == firstReservationStart &&
                r.EndDate.Value == firstReservationEnd);

            // Check if second reservation already exists
            var secondExists = existingReservations.Any(r =>
                r.StartDate.Value == secondReservationStart &&
                r.EndDate.Value == secondReservationEnd);

            // Get all parking spots
            var parkingSpots = await context.ParkingSpots
                .Include(ps => ps.ParkingSpotType)
                .Where(ps => ps.IsActive)
                .ToListAsync();

            // Get hourly reservation type
            var hourlyType = await context.ReservationTypes.FirstOrDefaultAsync(rt => rt.Id == hourlyReservationTypeId);
            if (hourlyType == null)
            {
                Console.WriteLine("⚠️ Dynamic seed: Hourly reservation type not found. Skipping runtime reservations.");
                return;
            }

            // Find available parking spot for first reservation
            int? firstParkingSpotId = null;
            if (!firstExists)
            {
                firstParkingSpotId = await FindAvailableParkingSpotAsync(
                    context,
                    parkingSpots,
                    firstReservationStart,
                    firstReservationEnd);
            }

            // Find available parking spot for second reservation
            int? secondParkingSpotId = null;
            if (!secondExists)
            {
                secondParkingSpotId = await FindAvailableParkingSpotAsync(
                    context,
                    parkingSpots,
                    secondReservationStart,
                    secondReservationEnd);
            }

            // Create first reservation if it doesn't exist and we found a spot
            if (!firstExists && firstParkingSpotId.HasValue)
            {
                var firstSpot = parkingSpots.First(ps => ps.Id == firstParkingSpotId.Value);
                var firstPrice = CalculateFinalPrice(hourlyType, firstSpot.ParkingSpotType, firstReservationStart, firstReservationEnd);

                var firstReservation = new Reservation
                {
                    CarId = carId,
                    ParkingSpotId = firstParkingSpotId.Value,
                    ReservationTypeId = hourlyReservationTypeId,
                    StartDate = firstReservationStart,
                    EndDate = firstReservationEnd,
                    FinalPrice = firstPrice,
                    CreatedAt = DateTime.UtcNow
                };

                context.Reservations.Add(firstReservation);
                await context.SaveChangesAsync();

                // Generate QR code after saving (so we have the ID)
                firstReservation.QrCodeData = GenerateQrCodeData(firstReservation);
                await context.SaveChangesAsync();

                Console.WriteLine($"✅ Dynamic seed: Created first reservation (ID: {firstReservation.Id}) for {firstReservationStart:yyyy-MM-dd HH:mm} - {firstReservationEnd:HH:mm} on spot {firstSpot.ParkingNumber}.");
            }
            else if (firstExists)
            {
                Console.WriteLine("ℹ️ Dynamic seed: First reservation already exists for today. Skipping.");
            }
            else
            {
                Console.WriteLine("⚠️ Dynamic seed: No available parking spot found for first reservation (15:00-18:00).");
            }

            // Create second reservation if it doesn't exist and we found a spot
            if (!secondExists && secondParkingSpotId.HasValue)
            {
                var secondSpot = parkingSpots.First(ps => ps.Id == secondParkingSpotId.Value);
                var secondPrice = CalculateFinalPrice(hourlyType, secondSpot.ParkingSpotType, secondReservationStart, secondReservationEnd);

                var secondReservation = new Reservation
                {
                    CarId = carId,
                    ParkingSpotId = secondParkingSpotId.Value,
                    ReservationTypeId = hourlyReservationTypeId,
                    StartDate = secondReservationStart,
                    EndDate = secondReservationEnd,
                    FinalPrice = secondPrice,
                    CreatedAt = DateTime.UtcNow
                };

                context.Reservations.Add(secondReservation);
                await context.SaveChangesAsync();

                // Generate QR code after saving (so we have the ID)
                secondReservation.QrCodeData = GenerateQrCodeData(secondReservation);
                await context.SaveChangesAsync();

                Console.WriteLine($"✅ Dynamic seed: Created second reservation (ID: {secondReservation.Id}) for {secondReservationStart:yyyy-MM-dd HH:mm} - {secondReservationEnd:HH:mm} on spot {secondSpot.ParkingNumber}.");
            }
            else if (secondExists)
            {
                Console.WriteLine("ℹ️ Dynamic seed: Second reservation already exists for today. Skipping.");
            }
            else
            {
                Console.WriteLine("⚠️ Dynamic seed: No available parking spot found for second reservation (19:00-23:00).");
            }
        }

        /// <summary>
        /// Finds an available parking spot that doesn't conflict with existing reservations.
        /// </summary>
        private static async Task<int?> FindAvailableParkingSpotAsync(
            MoSmartParkDbContext context,
            List<ParkingSpot> parkingSpots,
            DateTime startDate,
            DateTime endDate)
        {
            // Get all existing reservations that might conflict
            var conflictingReservations = await context.Reservations
                .Where(r => r.StartDate.HasValue
                    && r.EndDate.HasValue
                    && r.StartDate < endDate
                    && startDate < r.EndDate)
                .Select(r => new { r.ParkingSpotId })
                .ToListAsync();

            var conflictingSpotIds = conflictingReservations
                .Select(r => r.ParkingSpotId)
                .Distinct()
                .ToHashSet();

            // Find first available spot
            var availableSpot = parkingSpots
                .FirstOrDefault(ps => !conflictingSpotIds.Contains(ps.Id));

            return availableSpot?.Id;
        }

        /// <summary>
        /// Calculates final price using the same logic as ReservationService.
        /// </summary>
        private static decimal CalculateFinalPrice(ReservationType reservationType, ParkingSpotType parkingSpotType, DateTime startDate, DateTime endDate)
        {
            var basePrice = reservationType.Price;
            var multiplier = parkingSpotType.PriceMultiplier;

            // Calculate price based on reservation type
            switch (reservationType.Name.ToLower())
            {
                case "hourly":
                    // For hourly: number of hours * price * multiplier
                    var hours = (decimal)(endDate - startDate).TotalHours;
                    return hours * basePrice * multiplier;

                case "daily":
                    // For daily: price * multiplier (per day)
                    return basePrice * multiplier;

                case "monthly":
                    // For monthly: price * multiplier (per month)
                    return basePrice * multiplier;

                default:
                    throw new InvalidOperationException($"Unknown reservation type: {reservationType.Name}");
            }
        }

        /// <summary>
        /// Generates QR code data using the same format as ReservationService.
        /// </summary>
        private static string GenerateQrCodeData(Reservation reservation)
        {
            var startDateStr = reservation.StartDate?.ToString("yyyyMMddHHmm") ?? "";
            var endDateStr = reservation.EndDate?.ToString("yyyyMMddHHmm") ?? "";
            return $"RESERVATION:{reservation.Id}:{reservation.CarId}:{reservation.ParkingSpotId}:{startDateStr}:{endDateStr}";
        }
    }
}

