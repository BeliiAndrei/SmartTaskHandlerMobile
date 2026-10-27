// SQLite setup. The database file is created automatically on first start.
//
// To add your own entity: add a CREATE TABLE below, then copy the pattern
// of Notes.cs for its routes.

using Microsoft.Data.Sqlite;

namespace PamBackend;

public static class Db
{
    private static string _connectionString = "";

    /// <summary>Creates the database (and its schema) on first run.</summary>
    public static void Init(string path)
    {
        _connectionString = $"Data Source={path}";
        using var conn = Open();
        using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            CREATE TABLE IF NOT EXISTS users (
              id            INTEGER PRIMARY KEY AUTOINCREMENT,
              email         TEXT    NOT NULL UNIQUE,
              password_hash TEXT    NOT NULL,
              name          TEXT    NOT NULL,
              role          TEXT    NOT NULL DEFAULT 'user' CHECK (role IN ('administrator', 'user')),
              created_at    TEXT    NOT NULL
            );

            CREATE TABLE IF NOT EXISTS notes (
              id         INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id    INTEGER NOT NULL REFERENCES users (id),
              title      TEXT    NOT NULL,
              content    TEXT    NOT NULL DEFAULT '',
              created_at TEXT    NOT NULL
            );

            CREATE TABLE IF NOT EXISTS files (
              id         INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id    INTEGER NOT NULL REFERENCES users (id),
              name       TEXT    NOT NULL,
              mime_type  TEXT    NOT NULL,
              size       INTEGER NOT NULL,
              path       TEXT    NOT NULL,
              created_at TEXT    NOT NULL
            );

            -- Shared warehouse catalogue. QR values are the exact strings printed at a point.
            CREATE TABLE IF NOT EXISTS locations (
              id            INTEGER PRIMARY KEY,
              name          TEXT    NOT NULL,
              zone          TEXT    NOT NULL,
              qr_code_value TEXT    NOT NULL UNIQUE
            );

            INSERT OR IGNORE INTO locations (id, name, zone, qr_code_value) VALUES
              (1, 'Приёмка A1', 'A', 'STH-LOC-A1'),
              (2, 'Стеллаж A2', 'A', 'STH-LOC-A2'),
              (3, 'Стеллаж B1', 'B', 'STH-LOC-B1'),
              (4, 'Упаковка B2', 'B', 'STH-LOC-B2'),
              (5, 'Отгрузка C1', 'C', 'STH-LOC-C1');

            CREATE TABLE IF NOT EXISTS tasks (
              id                      INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id                 INTEGER NOT NULL REFERENCES users (id),
              title                   TEXT    NOT NULL,
              description             TEXT    NOT NULL,
              priority                TEXT    NOT NULL CHECK (priority IN ('low', 'medium', 'high')),
              status                  TEXT    NOT NULL CHECK (status IN ('new', 'in_progress', 'paused', 'completed')),
              source_location_id      INTEGER NOT NULL REFERENCES locations (id),
              destination_location_id INTEGER NOT NULL REFERENCES locations (id),
              assignee_id             INTEGER NOT NULL REFERENCES users (id),
              due_at                  TEXT    NOT NULL,
              created_at              TEXT    NOT NULL,
              updated_at              TEXT    NOT NULL,
              completed_at            TEXT
            );

            CREATE TABLE IF NOT EXISTS task_history (
              id              INTEGER PRIMARY KEY AUTOINCREMENT,
              task_id         INTEGER NOT NULL REFERENCES tasks (id) ON DELETE CASCADE,
              previous_status TEXT,
              new_status      TEXT    NOT NULL,
              changed_at      TEXT    NOT NULL,
              comment         TEXT
            );

            CREATE TABLE IF NOT EXISTS qr_confirmations (
              id          INTEGER PRIMARY KEY AUTOINCREMENT,
              task_id     INTEGER NOT NULL REFERENCES tasks (id) ON DELETE CASCADE,
              location_id INTEGER NOT NULL REFERENCES locations (id),
              scanned_at  TEXT    NOT NULL
            );

            CREATE INDEX IF NOT EXISTS tasks_user_id_idx ON tasks (user_id, id DESC);
            CREATE INDEX IF NOT EXISTS task_history_task_id_idx ON task_history (task_id, id DESC);
            """;
        cmd.ExecuteNonQuery();

        // The imported template may already have created app.db before L5.
        // CREATE TABLE IF NOT EXISTS does not add a new column to that database.
        using var roleColumn = conn.Cmd(
            "SELECT 1 FROM pragma_table_info('users') WHERE name = 'role'");
        if (roleColumn.ExecuteScalar() is null)
        {
            using var migrate = conn.Cmd(
                "ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'user' " +
                "CHECK (role IN ('administrator', 'user'))");
            migrate.ExecuteNonQuery();
        }
    }

    /// <summary>
    /// Opens a connection for one request. Always wrap it in `using` -
    /// Microsoft.Data.Sqlite pools connections, so this is cheap.
    /// </summary>
    public static SqliteConnection Open()
    {
        var conn = new SqliteConnection(_connectionString);
        conn.Open();
        using (var pragma = conn.Cmd("PRAGMA foreign_keys = ON"))
            pragma.ExecuteNonQuery();
        return conn;
    }

    /// <summary>Current UTC time in ISO-8601, the format used for all timestamps.</summary>
    public static string NowIso() => DateTime.UtcNow.ToString("o");
}

/// <summary>
/// Two small helpers that keep the ADO.NET boilerplate out of the handlers
/// (the equivalent of Dart's `db.select(sql, args)`).
/// </summary>
public static class SqliteExtensions
{
    /// <summary>A parameterized command in one call. NEVER interpolate user
    /// input into the SQL string itself - always use parameters.</summary>
    public static SqliteCommand Cmd(this SqliteConnection conn, string sql,
        params (string Name, object? Value)[] args)
    {
        var cmd = conn.CreateCommand();
        cmd.CommandText = sql;
        foreach (var (name, value) in args)
            cmd.Parameters.AddWithValue(name, value ?? DBNull.Value);
        return cmd;
    }

    /// <summary>The id generated by the last INSERT on this connection.</summary>
    public static long LastInsertRowId(this SqliteConnection conn)
    {
        using var cmd = conn.Cmd("SELECT last_insert_rowid()");
        return (long)cmd.ExecuteScalar()!;
    }
}
