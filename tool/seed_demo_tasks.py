"""Add repeatable demonstration tasks to the local SQLite database.

Run after the backend has created server/app.db:
    python tool/seed_demo_tasks.py --count 120

The script only inserts missing rows with its own title prefix. It does not
delete or modify existing application data.
"""

from __future__ import annotations

import argparse
import sqlite3
from datetime import datetime, timedelta, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DB = ROOT / "server" / "app.db"
DEFAULT_EMAIL = "lab5.demo@smarttask.local"
TITLE_PREFIX = "Демо L6"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--count", type=int, default=120)
    parser.add_argument("--email", default=DEFAULT_EMAIL)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    args = parser.parse_args()
    if args.count < 1:
        parser.error("--count must be greater than zero")
    if not args.db.is_file():
        raise SystemExit(f"Database not found: {args.db}. Start the backend once first.")

    now = datetime.now(timezone.utc)
    statuses = ("new", "in_progress", "paused", "completed")
    priorities = ("low", "medium", "high")
    locations = ((1, 3), (2, 4), (3, 5), (4, 1), (5, 2))

    with sqlite3.connect(args.db) as db:
        db.execute("PRAGMA foreign_keys = ON")
        user = db.execute(
            "SELECT id, name FROM users WHERE email = ?", (args.email,)
        ).fetchone()
        if user is None:
            raise SystemExit(
                f"Demo user {args.email!r} not found. Register it in the app first."
            )
        user_id, user_name = user
        existing = {
            row[0]
            for row in db.execute(
                "SELECT title FROM tasks WHERE user_id = ? AND title LIKE ?",
                (user_id, f"{TITLE_PREFIX} · %"),
            )
        }
        inserted = 0
        skipped = 0
        for number in range(1, args.count + 1):
            title = f"{TITLE_PREFIX} · задача {number:03d}"
            if title in existing:
                skipped += 1
                continue

            status = statuses[(number - 1) % len(statuses)]
            priority = priorities[(number - 1) % len(priorities)]
            source_id, destination_id = locations[(number - 1) % len(locations)]
            created = now - timedelta(days=number % 28, hours=number % 12)
            due = now + timedelta(days=(number % 21) - 7)
            completed_at = created + timedelta(hours=2) if status == "completed" else None
            created_text = created.isoformat()
            due_text = due.isoformat()
            updated_text = (completed_at or created).isoformat()

            cursor = db.execute(
                """INSERT INTO tasks (
                    user_id, title, description, priority, status,
                    source_location_id, destination_location_id, assignee_id,
                    due_at, created_at, updated_at, completed_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    user_id,
                    title,
                    f"Переместить демонстрационный груз из точки {source_id} "
                    f"в точку {destination_id}. Ответственный: {user_name}.",
                    priority,
                    status,
                    source_id,
                    destination_id,
                    user_id,
                    due_text,
                    created_text,
                    updated_text,
                    completed_at.isoformat() if completed_at else None,
                ),
            )
            task_id = cursor.lastrowid
            history = [(None, "new", created_text, "Создана для демонстрации")]
            if status in ("in_progress", "paused", "completed"):
                history.append(("new", "in_progress", updated_text, "Начата работа"))
            if status in ("paused", "completed"):
                history.append(
                    ("in_progress", "paused", updated_text, "Приостановлена для демонстрации")
                )
            if status == "completed":
                scanned_at = completed_at.isoformat()
                qr = db.execute(
                    "SELECT qr_code_value FROM locations WHERE id = ?",
                    (destination_id,),
                ).fetchone()[0]
                db.execute(
                    "INSERT INTO qr_confirmations (task_id, location_id, scanned_at) "
                    "VALUES (?, ?, ?)",
                    (task_id, destination_id, scanned_at),
                )
                history.append(
                    ("paused", "completed", scanned_at, f"QR подтверждён: {qr}")
                )
            db.executemany(
                "INSERT INTO task_history "
                "(task_id, previous_status, new_status, changed_at, comment) "
                "VALUES (?, ?, ?, ?, ?)",
                [
                    (task_id, previous, new, changed_at, comment)
                    for previous, new, changed_at, comment in history
                ],
            )
            inserted += 1
        total_for_account = db.execute(
            "SELECT COUNT(*) FROM tasks WHERE user_id = ?", (user_id,)
        ).fetchone()[0]

    print(f"Database: {args.db}")
    print(f"Account: {args.email} (user id {user_id})")
    print(f"Requested demo rows: {args.count}")
    print(f"Inserted: {inserted}; already present: {skipped}")
    print(f"Demo rows in database: {len(existing) + inserted}")
    print(f"All tasks for this account: {total_for_account}")


if __name__ == "__main__":
    main()
