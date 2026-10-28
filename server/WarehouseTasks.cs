// Warehouse task CRUD, status history, and QR confirmation. All task queries
// are scoped to the JWT user, following the same ownership rule as Notes.cs.

using System.Globalization;
using Microsoft.Data.Sqlite;

namespace PamBackend;

public record WarehouseTask(
    long Id, string Title, string Description, string Priority, string Status,
    long SourceLocationId, long DestinationLocationId, long AssigneeId,
    string DueAt, string CreatedAt, string UpdatedAt, string? CompletedAt);

public record WarehouseTaskInput(
    string? Title, string? Description, string? Priority, string? Status,
    long? SourceLocationId, long? DestinationLocationId, long? AssigneeId,
    string? DueAt);

public record TaskStatusInput(string? Status, string? Comment);
public record QrConfirmationInput(string? QrCodeValue);
public record TaskHistoryEntry(
    long Id, long TaskId, string? PreviousStatus, string NewStatus,
    string ChangedAt, string? Comment);
public record QrConfirmation(long Id, long TaskId, long LocationId, string ScannedAt);

internal record ValidatedTaskInput(
    string Title, string Description, string Priority, long SourceLocationId,
    long DestinationLocationId, long AssigneeId, string DueAt);

public static class WarehouseTasks
{
    // Temporary Lab 5 demo pass: the printed QR can confirm any task.
    private const string SharedDemoQrCode = "STH-LOC-B1";
    private const string Columns =
        "id, title, description, priority, status, source_location_id, " +
        "destination_location_id, assignee_id, due_at, created_at, updated_at, completed_at";

    private static WarehouseTask Read(SqliteDataReader reader) => new(
        reader.GetInt64(0), reader.GetString(1), reader.GetString(2),
        reader.GetString(3), reader.GetString(4), reader.GetInt64(5),
        reader.GetInt64(6), reader.GetInt64(7), reader.GetString(8),
        reader.GetString(9), reader.GetString(10),
        reader.IsDBNull(11) ? null : reader.GetString(11));

    private static WarehouseTask? Find(SqliteConnection conn, long userId, long id)
    {
        using var cmd = conn.Cmd(
            $"SELECT {Columns} FROM tasks WHERE id = $id AND user_id = $userId",
            ("$id", id), ("$userId", userId));
        using var reader = cmd.ExecuteReader();
        return reader.Read() ? Read(reader) : null;
    }

    private static bool LocationExists(SqliteConnection conn, long id)
    {
        using var cmd = conn.Cmd("SELECT 1 FROM locations WHERE id = $id", ("$id", id));
        return cmd.ExecuteScalar() is not null;
    }

    private static (ValidatedTaskInput? Value, IResult? Error) Validate(
        SqliteConnection conn, long userId, WarehouseTaskInput input)
    {
        var title = Errors.Trimmed(input.Title);
        if (title is null) return (null, Errors.Validation("title is required"));
        var description = Errors.Trimmed(input.Description);
        if (description is null) return (null, Errors.Validation("description is required"));
        if (input.Priority is not ("low" or "medium" or "high"))
            return (null, Errors.Validation("priority must be low, medium or high"));
        if (input.SourceLocationId is not long source || !LocationExists(conn, source))
            return (null, Errors.Validation("sourceLocationId must identify a location"));
        if (input.DestinationLocationId is not long destination ||
            !LocationExists(conn, destination))
            return (null, Errors.Validation("destinationLocationId must identify a location"));
        if (source == destination)
            return (null, Errors.Validation("Source and destination must differ"));
        if (input.AssigneeId is long assignee && assignee != userId)
            return (null, Errors.Validation("assigneeId must be the current user"));
        if (!DateTimeOffset.TryParse(input.DueAt, CultureInfo.InvariantCulture,
                DateTimeStyles.AssumeUniversal, out var dueAt))
            return (null, Errors.Validation("dueAt must be an ISO-8601 date-time"));

        return (new ValidatedTaskInput(
            title, description, input.Priority, source, destination, userId,
            dueAt.ToUniversalTime().ToString("O")), null);
    }

    /// <summary>GET /tasks?page=1&amp;limit=20&amp;search= -> paginated envelope.</summary>
    public static IResult List(HttpContext context,
        int page = 1, int limit = 20, string search = "")
    {
        page = Math.Max(page, 1);
        limit = Math.Clamp(limit, 1, 100);
        var userId = Auth.CurrentUserId(context);
        var pattern = $"%{search}%";
        const string where =
            "user_id = $userId AND (title LIKE $pattern OR description LIKE $pattern " +
            "OR EXISTS (SELECT 1 FROM locations l WHERE " +
            "l.id IN (source_location_id, destination_location_id) " +
            "AND (l.name LIKE $pattern OR l.zone LIKE $pattern)))";

        using var conn = Db.Open();
        using var count = conn.Cmd($"SELECT COUNT(*) FROM tasks WHERE {where}",
            ("$userId", userId), ("$pattern", pattern));
        var total = (long)count.ExecuteScalar()!;

        var items = new List<WarehouseTask>();
        using var cmd = conn.Cmd(
            $"SELECT {Columns} FROM tasks WHERE {where} " +
            "ORDER BY id DESC LIMIT $limit OFFSET $offset",
            ("$userId", userId), ("$pattern", pattern),
            ("$limit", limit), ("$offset", (page - 1) * limit));
        using var reader = cmd.ExecuteReader();
        while (reader.Read()) items.Add(Read(reader));
        return Results.Json(new { items, page, limit, total });
    }

    /// <summary>POST /tasks -> 201 task. The server assigns id and initial status.</summary>
    public static IResult Create(HttpContext context, WarehouseTaskInput input)
    {
        if (input.Status is not null and not "new")
            return Errors.Validation("A new task must have status 'new'");
        var userId = Auth.CurrentUserId(context);
        using var conn = Db.Open();
        var (data, error) = Validate(conn, userId, input);
        if (error is not null) return error;
        var value = data!;
        var now = Db.NowIso();

        using var transaction = conn.BeginTransaction();
        using (var insert = conn.Cmd(
            "INSERT INTO tasks (user_id, title, description, priority, status, " +
            "source_location_id, destination_location_id, assignee_id, due_at, " +
            "created_at, updated_at) VALUES ($userId, $title, $description, " +
            "$priority, 'new', $source, $destination, $assignee, $dueAt, $now, $now)",
            ("$userId", userId), ("$title", value.Title),
            ("$description", value.Description), ("$priority", value.Priority),
            ("$source", value.SourceLocationId),
            ("$destination", value.DestinationLocationId),
            ("$assignee", value.AssigneeId), ("$dueAt", value.DueAt), ("$now", now)))
        {
            insert.Transaction = transaction;
            insert.ExecuteNonQuery();
        }
        long id;
        using (var lastId = conn.Cmd("SELECT last_insert_rowid()"))
        {
            lastId.Transaction = transaction;
            id = (long)lastId.ExecuteScalar()!;
        }
        using (var history = conn.Cmd(
            "INSERT INTO task_history (task_id, previous_status, new_status, changed_at) " +
            "VALUES ($id, NULL, 'new', $now)", ("$id", id), ("$now", now)))
        {
            history.Transaction = transaction;
            history.ExecuteNonQuery();
        }
        transaction.Commit();
        return Results.Created($"/tasks/{id}", Find(conn, userId, id)!);
    }

    /// <summary>GET /tasks/{id} -> 200 task | 404, including another user's task.</summary>
    public static IResult GetOne(HttpContext context, long id)
    {
        using var conn = Db.Open();
        var task = Find(conn, Auth.CurrentUserId(context), id);
        return task is null ? Errors.NotFound("Task not found") : Results.Json(task);
    }

    /// <summary>PUT /tasks/{id} updates fields; status has its own PATCH route.</summary>
    public static IResult Update(HttpContext context, long id, WarehouseTaskInput input)
    {
        var userId = Auth.CurrentUserId(context);
        using var conn = Db.Open();
        var previous = Find(conn, userId, id);
        if (previous is null) return Errors.NotFound("Task not found");
        if (input.Status is not null && input.Status != previous.Status)
            return Errors.Validation("Use PATCH /tasks/{id}/status to change status");
        var (data, error) = Validate(conn, userId, input);
        if (error is not null) return error;
        var value = data!;

        if (previous.Status == "completed" &&
            value.DestinationLocationId != previous.DestinationLocationId)
            return Errors.Validation("Destination of a completed task cannot change");

        using var transaction = conn.BeginTransaction();
        using (var update = conn.Cmd(
            "UPDATE tasks SET title = $title, description = $description, " +
            "priority = $priority, source_location_id = $source, " +
            "destination_location_id = $destination, assignee_id = $assignee, " +
            "due_at = $dueAt, updated_at = $now WHERE id = $id AND user_id = $userId",
            ("$title", value.Title), ("$description", value.Description),
            ("$priority", value.Priority), ("$source", value.SourceLocationId),
            ("$destination", value.DestinationLocationId),
            ("$assignee", value.AssigneeId), ("$dueAt", value.DueAt),
            ("$now", Db.NowIso()), ("$id", id), ("$userId", userId)))
        {
            update.Transaction = transaction;
            update.ExecuteNonQuery();
        }
        if (value.DestinationLocationId != previous.DestinationLocationId)
        {
            using var clear = conn.Cmd(
                "DELETE FROM qr_confirmations WHERE task_id = $id", ("$id", id));
            clear.Transaction = transaction;
            clear.ExecuteNonQuery();
        }
        transaction.Commit();
        return Results.Json(Find(conn, userId, id)!);
    }

    /// <summary>DELETE /tasks/{id} -> 204 | 404, with history/QR cascade.</summary>
    public static IResult Delete(HttpContext context, long id)
    {
        var userId = Auth.CurrentUserId(context);
        using var conn = Db.Open();
        if (Find(conn, userId, id) is null) return Errors.NotFound("Task not found");
        using var delete = conn.Cmd(
            "DELETE FROM tasks WHERE id = $id AND user_id = $userId",
            ("$id", id), ("$userId", userId));
        delete.ExecuteNonQuery();
        return Results.NoContent();
    }

    /// <summary>PATCH /tasks/{id}/status -> task; completion requires a confirmed QR.</summary>
    public static IResult ChangeStatus(HttpContext context, long id, TaskStatusInput input)
    {
        var userId = Auth.CurrentUserId(context);
        using var conn = Db.Open();
        var task = Find(conn, userId, id);
        if (task is null) return Errors.NotFound("Task not found");
        if (input.Status is not ("new" or "in_progress" or "paused" or "completed"))
            return Errors.Validation("Invalid task status");
        if (input.Status == task.Status) return Results.Json(task);
        if (input.Status == "completed")
        {
            using var confirmed = conn.Cmd(
                "SELECT 1 FROM qr_confirmations WHERE task_id = $id " +
                "AND location_id = $destination LIMIT 1",
                ("$id", id), ("$destination", task.DestinationLocationId));
            if (confirmed.ExecuteScalar() is null)
                return Errors.Validation("Destination QR confirmation is required");
        }

        var now = Db.NowIso();
        using var transaction = conn.BeginTransaction();
        using (var update = conn.Cmd(
            "UPDATE tasks SET status = $status, updated_at = $now, " +
            "completed_at = $completed WHERE id = $id AND user_id = $userId",
            ("$status", input.Status), ("$now", now),
            ("$completed", input.Status == "completed" ? now : null),
            ("$id", id), ("$userId", userId)))
        {
            update.Transaction = transaction;
            update.ExecuteNonQuery();
        }
        using (var history = conn.Cmd(
            "INSERT INTO task_history (task_id, previous_status, new_status, changed_at, comment) " +
            "VALUES ($id, $previous, $new, $now, $comment)",
            ("$id", id), ("$previous", task.Status), ("$new", input.Status),
            ("$now", now), ("$comment", Errors.Trimmed(input.Comment))))
        {
            history.Transaction = transaction;
            history.ExecuteNonQuery();
        }
        if (task.Status == "completed")
        {
            using var clear = conn.Cmd(
                "DELETE FROM qr_confirmations WHERE task_id = $id", ("$id", id));
            clear.Transaction = transaction;
            clear.ExecuteNonQuery();
        }
        transaction.Commit();
        return Results.Json(Find(conn, userId, id)!);
    }

    /// <summary>GET /tasks/{id}/history -> paginated status changes.</summary>
    public static IResult History(HttpContext context, long id,
        int page = 1, int limit = 20)
    {
        using var conn = Db.Open();
        if (Find(conn, Auth.CurrentUserId(context), id) is null)
            return Errors.NotFound("Task not found");
        page = Math.Max(page, 1);
        limit = Math.Clamp(limit, 1, 100);
        using var count = conn.Cmd(
            "SELECT COUNT(*) FROM task_history WHERE task_id = $id", ("$id", id));
        var total = (long)count.ExecuteScalar()!;
        var items = new List<TaskHistoryEntry>();
        using var cmd = conn.Cmd(
            "SELECT id, task_id, previous_status, new_status, changed_at, comment " +
            "FROM task_history WHERE task_id = $id ORDER BY id DESC " +
            "LIMIT $limit OFFSET $offset",
            ("$id", id), ("$limit", limit), ("$offset", (page - 1) * limit));
        using var reader = cmd.ExecuteReader();
        while (reader.Read())
            items.Add(new TaskHistoryEntry(
                reader.GetInt64(0), reader.GetInt64(1),
                reader.IsDBNull(2) ? null : reader.GetString(2),
                reader.GetString(3), reader.GetString(4),
                reader.IsDBNull(5) ? null : reader.GetString(5)));
        return Results.Json(new { items, page, limit, total });
    }

    /// <summary>POST /tasks/{id}/qr-confirmation with {qrCodeValue} -> 201.</summary>
    public static IResult ConfirmDestination(
        HttpContext context, long id, QrConfirmationInput input)
    {
        var userId = Auth.CurrentUserId(context);
        using var conn = Db.Open();
        var task = Find(conn, userId, id);
        if (task is null) return Errors.NotFound("Task not found");
        if (task.Status == "completed")
            return Errors.Validation("Task is already completed");
        var qr = Errors.Trimmed(input.QrCodeValue);
        if (qr is null) return Errors.Validation("qrCodeValue is required");
        using (var location = conn.Cmd(
            "SELECT id FROM locations WHERE id = $destination AND qr_code_value = $qr",
            ("$destination", task.DestinationLocationId), ("$qr", qr)))
        {
            if (qr != SharedDemoQrCode && location.ExecuteScalar() is null)
                return Errors.Validation("QR code does not match the destination");
        }

        var now = Db.NowIso();
        using (var insert = conn.Cmd(
            "INSERT INTO qr_confirmations (task_id, location_id, scanned_at) " +
            "VALUES ($id, $destination, $now)",
            ("$id", id), ("$destination", task.DestinationLocationId), ("$now", now)))
        {
            insert.ExecuteNonQuery();
        }
        var confirmation = new QrConfirmation(
            conn.LastInsertRowId(), id, task.DestinationLocationId, now);
        return Results.Created($"/tasks/{id}/qr-confirmation", confirmation);
    }
}
