using System.Security.Cryptography;
using System.Text;

namespace eRent.Services.Helpers
{
    public class PasswordGenerator
    {
        private const int SaltSize = 16;
        private const int KeySize = 32;
        private const int Iterations = 10000;

        public static string GenerateSalt()
        {
            byte[] salt = RandomNumberGenerator.GetBytes(SaltSize);
            return Convert.ToBase64String(salt);
        }

        /// <summary>
        /// Generates a deterministic salt for seed data based on a seed string.
        /// This ensures consistent salt values for database seeding.
        /// </summary>
        public static string GenerateDeterministicSalt(string seed)
        {
            using (var sha256 = SHA256.Create())
            {
                byte[] seedBytes = Encoding.UTF8.GetBytes(seed);
                byte[] hash = sha256.ComputeHash(seedBytes);
                byte[] salt = new byte[SaltSize];
                Array.Copy(hash, 0, salt, 0, SaltSize);
                return Convert.ToBase64String(salt);
            }
        }

        public static string GenerateHash(string password, string salt)
        {
            byte[] saltBytes = Convert.FromBase64String(salt);

            using (var pbkdf2 = new Rfc2898DeriveBytes(password, saltBytes, Iterations))
            {
                byte[] hashBytes = pbkdf2.GetBytes(KeySize);
                return Convert.ToBase64String(hashBytes);
            }
        }

        public static bool VerifyPassword(string password, string passwordHash, string passwordSalt)
        {
            byte[] salt = Convert.FromBase64String(passwordSalt);
            byte[] hash = Convert.FromBase64String(passwordHash);

            using (var pbkdf2 = new Rfc2898DeriveBytes(password, salt, Iterations))
            {
                byte[] hashBytes = pbkdf2.GetBytes(KeySize);
                return hash.SequenceEqual(hashBytes);
            }
        }
    }
}
