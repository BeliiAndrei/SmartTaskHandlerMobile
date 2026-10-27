// File upload/download. Bytes live in uploads/, metadata in the database.

using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Http.Features;

namespace PamBackend;

public static class Files
{
    /// <summary>
    /// Upload size cap: 5 MB - plenty for lab photos. Documented in
    /// ../openapi.yaml at POST /files. Over the cap -> 400 VALIDATION_ERROR
    /// (the contract deliberately has no 413).
    /// </summary>
    public const long MaxUploadBytes = 5 * 1024 * 1024;

    private static string _uploadsDir = "uploads";

    /// <summary>Creates the uploads/ folder on first start.</summary>
    public static void InitStorage(string path)
    {
        _uploadsDir = path;
        Directory.CreateDirectory(path);
    }

    private static IResult TooLarge() => Errors.Validation(
        $"File too large: the upload limit is 5 MB ({MaxUploadBytes} bytes)");

    /// <summary>POST /files  (multipart, field "file") -> 201 {id, url, name, size, mimeType}</summary>
    // (The parameter is HttpRequest, not HttpContext: a handler shaped exactly
    // like `HttpContext -> Task<...>` would be treated as a raw RequestDelegate
    // and its IResult return value silently discarded.)
    public static async Task<IResult> Upload(HttpRequest request)
    {
        var context = request.HttpContext;

        // Cheap early rejection when the client declares the size upfront.
        // Not sufficient on its own: Content-Length can be absent (chunked
        // encoding) or lie, so the server also counts while reading (below).
        if (request.ContentLength is > MaxUploadBytes) return TooLarge();

        if (!request.HasFormContentType)
            return Errors.Validation("Expected a multipart/form-data body");

        // Enforce the cap DURING reading too: this FormFeature makes
        // ReadFormAsync count the multipart body bytes as they stream in and
        // abort past the limit - which covers chunked uploads. The +64 KB is
        // slack for the boundary lines and part headers; the exact per-file
        // cap is checked on file.Length below.
        context.Features.Set<IFormFeature>(new FormFeature(request, new FormOptions
        {
            MultipartBodyLengthLimit = MaxUploadBytes + 64 * 1024,
        }));

        // A corrupt multipart body (bad boundary, truncated part, ...) makes
        // the parser throw mid-stream. Without the catch the exception would
        // escape and the client would hang on a dead connection - any parse
        // error must answer 400 immediately instead.
        IFormCollection form;
        try
        {
            form = await request.ReadFormAsync();
        }
        catch (Exception ex) when (ex is InvalidDataException or IOException)
        {
            // InvalidDataException: bad boundary / over the length limit.
            // IOException: body truncated mid-part.
            return Errors.Validation("Malformed or too large multipart/form-data body");
        }

        var file = form.Files.GetFile("file");
        if (file is null) return Errors.Validation("Missing multipart field 'file'");
        if (file.Length > MaxUploadBytes) return TooLarge();

        var name = string.IsNullOrEmpty(file.FileName) ? "file" : file.FileName;
        var mimeType = string.IsNullOrEmpty(file.ContentType)
            ? "application/octet-stream" : file.ContentType;

        // Store under a unique name: no collisions, no path tricks.
        var safeName = Regex.Replace(name, "[^A-Za-z0-9._-]", "_");
        var storedPath = Path.Combine(_uploadsDir, $"{Guid.NewGuid():N}_{safeName}");
        await using (var target = File.Create(storedPath))
        {
            await file.CopyToAsync(target);
        }

        using var conn = Db.Open();
        using (var insert = conn.Cmd(
                   "INSERT INTO files (user_id, name, mime_type, size, path, created_at) " +
                   "VALUES ($userId, $name, $mimeType, $size, $path, $createdAt)",
                   ("$userId", Auth.CurrentUserId(context)), ("$name", name),
                   ("$mimeType", mimeType), ("$size", file.Length),
                   ("$path", storedPath), ("$createdAt", Db.NowIso())))
        {
            insert.ExecuteNonQuery();
        }
        var id = conn.LastInsertRowId();

        return Results.Json(
            new { id, url = $"/files/{id}", name, size = file.Length, mimeType },
            statusCode: 201);
    }

    /// <summary>
    /// GET /files/{id} -> the stored bytes with their original Content-Type | 404.
    /// Public on purpose: lets a Flutter app show images by plain URL.
    /// </summary>
    public static IResult Download(long id, HttpContext context)
    {
        using var conn = Db.Open();
        using var cmd = conn.Cmd("SELECT mime_type, path FROM files WHERE id = $id",
            ("$id", id));
        using var reader = cmd.ExecuteReader();
        if (!reader.Read()) return Errors.NotFound("File not found");

        var mimeType = reader.GetString(0);
        var path = reader.GetString(1);
        if (!File.Exists(path)) return Errors.NotFound("File not found");

        // The stored Content-Type is client-supplied; nosniff stops browsers
        // from second-guessing it into something executable.
        context.Response.Headers["X-Content-Type-Options"] = "nosniff";
        // Anyone can upload text/html or image/svg+xml, so a direct visit to
        // this URL would run their scripts on our origin (stored XSS).
        // attachment = browsers download instead of rendering; the CSP
        // sandbox neutralizes anything that still renders. <img> tags and
        // Flutter's Image.network ignore both, so images keep working.
        context.Response.Headers.ContentDisposition = "attachment";
        context.Response.Headers.ContentSecurityPolicy = "default-src 'none'; sandbox";
        return Results.File(Path.GetFullPath(path), contentType: mimeType);
    }
}
