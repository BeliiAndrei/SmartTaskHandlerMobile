// Shared warehouse locations. The catalogue is seeded in Db.Init and read by
// the task form; tasks refer to these IDs instead of accepting free-form names.

using Microsoft.Data.Sqlite;

namespace PamBackend;

public record Location(long Id, string Name, string Zone, string QrCodeValue);

public static class Locations
{
    private static Location Read(SqliteDataReader reader) => new(
        reader.GetInt64(0), reader.GetString(1), reader.GetString(2), reader.GetString(3));

    /// <summary>GET /locations?page=1&amp;limit=20&amp;search= -> paginated envelope.</summary>
    public static IResult List(int page = 1, int limit = 20, string search = "")
    {
        page = Math.Max(page, 1);
        limit = Math.Clamp(limit, 1, 100);
        var pattern = $"%{search}%";

        using var conn = Db.Open();
        using var count = conn.Cmd(
            "SELECT COUNT(*) FROM locations WHERE name LIKE $pattern OR zone LIKE $pattern",
            ("$pattern", pattern));
        var total = (long)count.ExecuteScalar()!;

        var items = new List<Location>();
        using var cmd = conn.Cmd(
            "SELECT id, name, zone, qr_code_value FROM locations " +
            "WHERE name LIKE $pattern OR zone LIKE $pattern " +
            "ORDER BY id LIMIT $limit OFFSET $offset",
            ("$pattern", pattern), ("$limit", limit),
            ("$offset", (page - 1) * limit));
        using var reader = cmd.ExecuteReader();
        while (reader.Read()) items.Add(Read(reader));
        return Results.Json(new { items, page, limit, total });
    }

    /// <summary>GET /locations/{id} -> 200 location | 404.</summary>
    public static IResult GetOne(long id)
    {
        using var conn = Db.Open();
        using var cmd = conn.Cmd(
            "SELECT id, name, zone, qr_code_value FROM locations WHERE id = $id",
            ("$id", id));
        using var reader = cmd.ExecuteReader();
        return reader.Read()
            ? Results.Json(Read(reader))
            : Errors.NotFound("Location not found");
    }
}
