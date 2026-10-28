"""Prepare a printable destination QR and a repeatable local Lab 5 demo.

Requires a running local backend and `pip install qrcode Pillow`.
The QR payload comes from GET /locations/3; no second copy of the code is
maintained in this script. Runtime users/tasks/file metadata live in app.db.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path

import qrcode
from PIL import Image, ImageDraw, ImageFont
from qrcode.image.svg import SvgPathImage


ROOT = Path(__file__).resolve().parents[1]
TITLE = "Демо QR: перенос груза на стеллаж B1"


def request_json(base_url: str, method: str, path: str, *, token: str | None = None,
                 body: dict | None = None) -> tuple[int, dict]:
    data = json.dumps(body, ensure_ascii=False).encode("utf-8") if body is not None else None
    headers = {"Content-Type": "application/json"} if body is not None else {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(base_url + path, data=data, headers=headers,
                                     method=method)
    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            return response.status, json.load(response)
    except urllib.error.HTTPError as error:
        return error.code, json.load(error)


def font(size: int, *, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = (["C:/Windows/Fonts/arialbd.ttf", "DejaVuSans-Bold.ttf"] if bold else
                  ["C:/Windows/Fonts/arial.ttf", "DejaVuSans.ttf"])
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            pass
    return ImageFont.load_default()


def centered_text(draw: ImageDraw.ImageDraw, width: int, y: int,
                  value: str, selected_font: ImageFont.ImageFont) -> None:
    bounds = draw.textbbox((0, 0), value, font=selected_font)
    draw.text(((width - (bounds[2] - bounds[0])) / 2, y), value,
              fill="black", font=selected_font)


def generate_qr(value: str, location_name: str, output_dir: Path) -> tuple[Path, Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    qr = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_Q,
                       box_size=36, border=4)
    qr.add_data(value)
    qr.make(fit=True)
    image = qr.make_image(fill_color="black", back_color="white").convert("RGB")
    canvas = Image.new("RGB", (image.width, image.height + 190), "white")
    canvas.paste(image, (0, 0))
    draw = ImageDraw.Draw(canvas)
    centered_text(draw, canvas.width, image.height + 18, location_name, font(42, bold=True))
    centered_text(draw, canvas.width, image.height + 79, f"Location ID: 3   QR: {value}", font(28))
    png_path = output_dir / "warehouse_b1_qr.png"
    canvas.save(png_path, format="PNG", dpi=(300, 300))

    svg_path = output_dir / "warehouse_b1_qr.svg"
    qr.make_image(image_factory=SvgPathImage).save(svg_path)
    return png_path, svg_path


def upload_file(base_url: str, token: str, path: Path) -> dict:
    boundary = uuid.uuid4().hex
    file_bytes = path.read_bytes()
    body = (f"--{boundary}\r\n"
            'Content-Disposition: form-data; name="file"; filename="warehouse_b1_qr.png"\r\n'
            "Content-Type: image/png\r\n\r\n").encode("ascii")
    body += file_bytes + f"\r\n--{boundary}--\r\n".encode("ascii")
    request = urllib.request.Request(base_url + "/files", data=body, method="POST",
        headers={"Authorization": f"Bearer {token}",
                 "Content-Type": f"multipart/form-data; boundary={boundary}"})
    with urllib.request.urlopen(request, timeout=20) as response:
        if response.status != 201:
            raise RuntimeError(f"Upload failed: HTTP {response.status}")
        return json.load(response)


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", default="http://127.0.0.1:8080")
    parser.add_argument("--email", default="lab5.demo@smarttask.local")
    parser.add_argument("--password", default="Lab5Demo2026!")
    args = parser.parse_args()
    base_url = args.base_url.rstrip("/")
    db_path = ROOT / "server" / "app.db"
    if not db_path.is_file():
        raise SystemExit("Start the backend first: cd server && dotnet run")

    status, auth = request_json(base_url, "POST", "/auth/register", body={
        "email": args.email, "password": args.password, "name": "Lab 5 Demo"})
    if status == 409:
        status, auth = request_json(base_url, "POST", "/auth/login", body={
            "email": args.email, "password": args.password})
    if status not in (200, 201):
        raise RuntimeError(f"Demo login failed: HTTP {status}, {auth}")
    token = auth["token"]
    user_id = auth["user"]["id"]

    status, location = request_json(base_url, "GET", "/locations/3", token=token)
    if status != 200:
        raise RuntimeError(f"Location 3 unavailable: HTTP {status}, {location}")
    value = location["qrCodeValue"]
    with sqlite3.connect(db_path) as db:
        stored = db.execute("SELECT qr_code_value FROM locations WHERE id = 3").fetchone()
    if stored != (value,):
        raise RuntimeError("The API and local database disagree about the QR payload")

    png_path, svg_path = generate_qr(value, location["name"], ROOT / "demo")
    status, listed = request_json(base_url, "GET", "/tasks?" +
        urllib.parse.urlencode({"search": TITLE}), token=token)
    if status != 200:
        raise RuntimeError(f"Task list failed: HTTP {status}, {listed}")
    existing = next((task for task in listed["items"] if task["title"] == TITLE and
                     task["destinationLocationId"] == 3 and task["status"] != "completed"), None)
    if existing is None:
        due = (datetime.now(timezone.utc) + timedelta(days=14)).isoformat()
        status, task = request_json(base_url, "POST", "/tasks", token=token, body={
            "title": TITLE,
            "description": "Взять коробку из Приёмки A1 и перенести на Стеллаж B1.",
            "priority": "high", "sourceLocationId": 1,
            "destinationLocationId": 3, "dueAt": due})
        if status != 201:
            raise RuntimeError(f"Task creation failed: HTTP {status}, {task}")
    else:
        task = existing

    with sqlite3.connect(db_path) as db:
        uploaded = db.execute("SELECT id, path FROM files WHERE user_id = ? AND name = ? "
            "ORDER BY id DESC LIMIT 1", (user_id, png_path.name)).fetchone()
    if uploaded is None or not (ROOT / "server" / uploaded[1]).is_file():
        file_record = upload_file(base_url, token, png_path)
        file_id = file_record["id"]
    else:
        file_id = uploaded[0]

    with sqlite3.connect(db_path) as db:
        assert db.execute("SELECT 1 FROM tasks WHERE id = ? AND destination_location_id = 3",
                          (task["id"],)).fetchone()
        assert db.execute("SELECT 1 FROM files WHERE id = ?", (file_id,)).fetchone()
    print(f"QR payload: {value} (locations.id=3)")
    print(f"Printable PNG: {png_path}")
    print(f"Vector SVG: {svg_path}")
    print(f"Demo login: {args.email} / {args.password}")
    print(f"Task ID: {task['id']} (destination: {location['name']})")
    print(f"Uploaded file ID: {file_id} (files table + uploads directory)")


if __name__ == "__main__":
    main()
