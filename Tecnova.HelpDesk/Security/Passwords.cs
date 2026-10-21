using System;
using System.Security.Cryptography;

namespace Tecnova.HelpDesk.Security
{
    public static class Passwords
    {
        public static string Hash(string password)
        {
            var salt = new byte[16];
            using (var rng = RandomNumberGenerator.Create()) rng.GetBytes(salt);
            using (var derive = new Rfc2898DeriveBytes(password, salt, 600000, HashAlgorithmName.SHA256))
                return "v1$600000$" + Convert.ToBase64String(salt) + "$" + Convert.ToBase64String(derive.GetBytes(32));
        }
        public static bool Verify(string password, string hash)
        {
            try
            {
                var parts = hash.Split('$');
                if (parts.Length != 4 || parts[0] != "v1" || parts[1] != "600000") return false;
                var expected = Convert.FromBase64String(parts[3]);
                using (var derive = new Rfc2898DeriveBytes(password, Convert.FromBase64String(parts[2]), 600000, HashAlgorithmName.SHA256))
                {
                    var actual = derive.GetBytes(32); int difference = actual.Length ^ expected.Length;
                    for (int i = 0; i < actual.Length && i < expected.Length; i++) difference |= actual[i] ^ expected[i];
                    return difference == 0;
                }
            }
            catch (FormatException) { return false; }
        }
    }
}
