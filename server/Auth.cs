// Authentication: register/login/me, password hashing, JWT (HS256).

using System.Buffers.Text;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace PamBackend;

public record RegisterRequest(string? Email, string? Password, string? Name);
public record LoginRequest(string? Email, string? Password);
public record User(long Id, string Email, string Name);

public static class Auth
{
    /// <summary>Secret used to sign JWTs. Override with the JWT_SECRET env variable.</summary>
    private static readonly string JwtSecret =
        Environment.GetEnvironmentVariable("JWT_SECRET") ?? "dev-secret-change-me";

    // -----------------------------------------------------------------------
    // Route handlers
    // -----------------------------------------------------------------------

    /// <summary>POST /auth/register  {email, password, name} -> 201 {token, user}</summary>
    public static IResult Register(RegisterRequest body)
    {
        var email = Errors.Trimmed(body.Email);
        var password = Errors.Trimmed(body.Password);
        var name = Errors.Trimmed(body.Name);
        if (email is null || !email.Contains('@'))
            return Errors.Validation("A valid email is required");
        if (password is null) return Errors.Validation("password is required");
        if (name is null) return Errors.Validation("name is required");

        using var conn = Db.Open();
        using (var existing = conn.Cmd("SELECT id FROM users WHERE email = $email",
                   ("$email", email)))
        {
            if (existing.ExecuteScalar() is not null) return Errors.EmailTaken();
        }

        using (var insert = conn.Cmd(
                   "INSERT INTO users (email, password_hash, name, created_at) " +
                   "VALUES ($email, $hash, $name, $createdAt)",
                   ("$email", email), ("$hash", HashPassword(password)),
                   ("$name", name), ("$createdAt", Db.NowIso())))
        {
            insert.ExecuteNonQuery();
        }
        var id = conn.LastInsertRowId();

        return Results.Json(
            new { token = IssueToken(id), user = new User(id, email, name) },
            statusCode: 201);
    }

    /// <summary>POST /auth/login  {email, password} -> 200 {token, user}</summary>
    public static IResult Login(LoginRequest body)
    {
        var email = Errors.Trimmed(body.Email);
        var password = Errors.Trimmed(body.Password);
        if (email is null || password is null)
            return Errors.Unauthorized("Invalid email or password");

        using var conn = Db.Open();
        using var cmd = conn.Cmd(
            "SELECT id, email, name, password_hash FROM users WHERE email = $email",
            ("$email", email));
        using var reader = cmd.ExecuteReader();
        if (!reader.Read()) return Errors.Unauthorized("Invalid email or password");

        var user = new User(reader.GetInt64(0), reader.GetString(1), reader.GetString(2));
        if (!VerifyPassword(password, reader.GetString(3)))
            return Errors.Unauthorized("Invalid email or password");

        return Results.Json(new { token = IssueToken(user.Id), user });
    }

    /// <summary>GET /me  (Bearer) -> 200 {id, email, name}</summary>
    public static IResult Me(HttpContext context)
    {
        using var conn = Db.Open();
        using var cmd = conn.Cmd("SELECT id, email, name FROM users WHERE id = $id",
            ("$id", CurrentUserId(context)));
        using var reader = cmd.ExecuteReader();
        if (!reader.Read()) return Errors.Unauthorized();
        return Results.Json(
            new User(reader.GetInt64(0), reader.GetString(1), reader.GetString(2)));
    }

    // -----------------------------------------------------------------------
    // Auth filter
    // -----------------------------------------------------------------------

    /// <summary>
    /// Endpoint filter: the handler only runs with a valid `Authorization:
    /// Bearer` token. Inside the handler, the logged-in user is available via
    /// <see cref="CurrentUserId"/>. Attach it with `.AddEndpointFilter(Auth.RequireAuth)`.
    /// </summary>
    public static async ValueTask<object?> RequireAuth(
        EndpointFilterInvocationContext context, EndpointFilterDelegate next)
    {
        var header = context.HttpContext.Request.Headers.Authorization.ToString();
        if (!header.StartsWith("Bearer ")) return Errors.Unauthorized();
        var userId = VerifyToken(header["Bearer ".Length..]);
        if (userId is null) return Errors.Unauthorized();
        context.HttpContext.Items["userId"] = userId.Value;
        return await next(context);
    }

    /// <summary>The id of the logged-in user. Only valid behind <see cref="RequireAuth"/>.</summary>
    public static long CurrentUserId(HttpContext context) => (long)context.Items["userId"]!;

    // -----------------------------------------------------------------------
    // JWT (HS256), implemented by hand so you can see exactly how it works.
    // A JWT is:  base64url(header) . base64url(payload) . signature
    // where signature = HMAC-SHA256("header.payload", secret).
    //
    // (The JwtBearer/System.IdentityModel packages would work too, but they
    // hide these ~40 lines behind configuration - and by default they even
    // rename the `sub` claim via MapInboundClaims. Here nothing is hidden.)
    // -----------------------------------------------------------------------

    /// <summary>Creates a token for the user, valid for 7 days. `sub` holds the user id.</summary>
    public static string IssueToken(long userId)
    {
        var header = B64Json(new { alg = "HS256", typ = "JWT" });
        var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var payload = B64Json(new
        {
            sub = userId.ToString(),
            iat = now,
            exp = now + 7 * 24 * 60 * 60, // 7 days
        });
        return $"{header}.{payload}.{Sign($"{header}.{payload}")}";
    }

    /// <summary>Returns the user id from a valid token, or null when invalid/expired.</summary>
    public static long? VerifyToken(string token)
    {
        var parts = token.Split('.');
        if (parts.Length != 3) return null;
        var expected = Sign($"{parts[0]}.{parts[1]}");
        if (!CryptographicOperations.FixedTimeEquals(
                Encoding.ASCII.GetBytes(expected), Encoding.ASCII.GetBytes(parts[2])))
        {
            return null;
        }
        try
        {
            var payload = JsonNode.Parse(Base64Url.DecodeFromChars(parts[1]))!.AsObject();
            var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            if (now >= payload["exp"]!.GetValue<long>()) return null;
            return long.Parse(payload["sub"]!.GetValue<string>());
        }
        catch
        {
            return null; // any malformed payload counts as an invalid token
        }
    }

    private static string B64Json(object data) =>
        Base64Url.EncodeToString(JsonSerializer.SerializeToUtf8Bytes(data));

    private static string Sign(string data) => Base64Url.EncodeToString(
        HMACSHA256.HashData(Encoding.UTF8.GetBytes(JwtSecret), Encoding.UTF8.GetBytes(data)));

    // -----------------------------------------------------------------------
    // Passwords: PBKDF2-HMAC-SHA256 with a random salt (no plaintext, ever),
    // via Rfc2898DeriveBytes from the BCL - no external packages needed.
    // Stored as "iterations:salt:hash" (salt and hash base64-encoded), the
    // same format as the Dart reference implementation.
    // -----------------------------------------------------------------------

    private const int Iterations = 100_000;
    private const int HashBytes = 32; // one SHA-256 output

    public static string HashPassword(string password)
    {
        var salt = RandomNumberGenerator.GetBytes(16);
        var hash = Rfc2898DeriveBytes.Pbkdf2(
            password, salt, Iterations, HashAlgorithmName.SHA256, HashBytes);
        return $"{Iterations}:{Convert.ToBase64String(salt)}:{Convert.ToBase64String(hash)}";
    }

    public static bool VerifyPassword(string password, string stored)
    {
        var parts = stored.Split(':');
        if (parts.Length != 3 || !int.TryParse(parts[0], out var iterations)) return false;
        try
        {
            var salt = Convert.FromBase64String(parts[1]);
            var expected = Convert.FromBase64String(parts[2]);
            var hash = Rfc2898DeriveBytes.Pbkdf2(
                password, salt, iterations, HashAlgorithmName.SHA256, expected.Length);
            // Fixed-time comparison: does not leak where the bytes differ.
            return CryptographicOperations.FixedTimeEquals(hash, expected);
        }
        catch
        {
            return false;
        }
    }
}
