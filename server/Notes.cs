// Notes: the example CRUD entity, scoped per user.
//
// THIS FILE IS THE TEMPLATE FOR YOUR OWN ENTITIES.
// To add e.g. "recipes": copy this file to Recipes.cs, rename the table
// and the fields, add a CREATE TABLE in Db.cs, register routes in
// Program.cs. That's the whole recipe.

using Microsoft.Data.Sqlite;

namespace PamBackend;

public record Note(long Id, string Title, string Content, string CreatedAt);
public record NoteInput(string? Title, string? Content);

public static class Notes
{
    private static Note ReadNote(SqliteDataReader reader) => new(
        reader.GetInt64(0), reader.GetString(1), reader.GetString(2), reader.GetString(3));

    /// <summary>
    /// Finds a note by id, but only among the current user's notes.
    /// Someone else's note is indistinguishable from a missing one (404).
    /// </summary>
    private static Note? Find(SqliteConnection conn, long userId, long id)
    {
        using var cmd = conn.Cmd(
            "SELECT id, title, content, created_at FROM notes " +
            "WHERE id = $id AND user_id = $userId",
            ("$id", id), ("$userId", userId));
        using var reader = cmd.ExecuteReader();
        return reader.Read() ? ReadNote(reader) : null;
    }

    /// <summary>GET /notes?page=1&amp;limit=20&amp;search=  -> {items, page, limit, total}</summary>
    public static IResult List(HttpContext context,
        int page = 1, int limit = 20, string search = "")
    {
        page = Math.Max(page, 1);
        limit = Math.Clamp(limit, 1, 100);

        // %/_ in the search term act as LIKE wildcards (parameterized, so safe -
        // purely a semantic quirk).
        const string where = "user_id = $userId AND (title LIKE $pattern OR content LIKE $pattern)";
        var userId = Auth.CurrentUserId(context);
        var pattern = $"%{search}%";

        using var conn = Db.Open();
        long total;
        using (var count = conn.Cmd($"SELECT COUNT(*) FROM notes WHERE {where}",
                   ("$userId", userId), ("$pattern", pattern)))
        {
            total = (long)count.ExecuteScalar()!;
        }

        var items = new List<Note>();
        using var cmd = conn.Cmd(
            $"SELECT id, title, content, created_at FROM notes WHERE {where} " +
            "ORDER BY id DESC LIMIT $limit OFFSET $offset",
            ("$userId", userId), ("$pattern", pattern),
            ("$limit", limit), ("$offset", (page - 1) * limit));
        using var reader = cmd.ExecuteReader();
        while (reader.Read()) items.Add(ReadNote(reader));

        return Results.Json(new { items, page, limit, total });
    }

    /// <summary>POST /notes  {title, content} -> 201 note</summary>
    public static IResult Create(HttpContext context, NoteInput input)
    {
        var title = Errors.Trimmed(input.Title);
        if (title is null) return Errors.Validation("title is required");
        var content = input.Content ?? "";
        var userId = Auth.CurrentUserId(context);

        using var conn = Db.Open();
        using (var insert = conn.Cmd(
                   "INSERT INTO notes (user_id, title, content, created_at) " +
                   "VALUES ($userId, $title, $content, $createdAt)",
                   ("$userId", userId), ("$title", title),
                   ("$content", content), ("$createdAt", Db.NowIso())))
        {
            insert.ExecuteNonQuery();
        }
        var note = Find(conn, userId, conn.LastInsertRowId())!;
        return Results.Created($"/notes/{note.Id}", note);
    }

    /// <summary>GET /notes/{id} -> 200 note | 404</summary>
    public static IResult GetOne(HttpContext context, long id)
    {
        using var conn = Db.Open();
        var note = Find(conn, Auth.CurrentUserId(context), id);
        return note is null ? Errors.NotFound("Note not found") : Results.Json(note);
    }

    /// <summary>PUT /notes/{id}  {title, content} -> 200 updated note | 404</summary>
    public static IResult Update(HttpContext context, long id, NoteInput input)
    {
        var userId = Auth.CurrentUserId(context);
        using var conn = Db.Open();
        if (Find(conn, userId, id) is null) return Errors.NotFound("Note not found");

        var title = Errors.Trimmed(input.Title);
        if (title is null) return Errors.Validation("title is required");
        var content = input.Content ?? "";

        using (var update = conn.Cmd(
                   "UPDATE notes SET title = $title, content = $content WHERE id = $id",
                   ("$title", title), ("$content", content), ("$id", id)))
        {
            update.ExecuteNonQuery();
        }
        return Results.Json(Find(conn, userId, id)!);
    }

    /// <summary>DELETE /notes/{id} -> 204 | 404</summary>
    public static IResult Delete(HttpContext context, long id)
    {
        using var conn = Db.Open();
        if (Find(conn, Auth.CurrentUserId(context), id) is null)
            return Errors.NotFound("Note not found");

        using var delete = conn.Cmd("DELETE FROM notes WHERE id = $id", ("$id", id));
        delete.ExecuteNonQuery();
        return Results.NoContent();
    }
}
