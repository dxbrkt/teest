#!/usr/bin/env python3
"""
TF2 Skin Generator - Python Backend HTTP Server
Wraps all backend services as a REST API for the C++ frontend.
"""

import sys
import os
import json
import uuid
import threading
import socket
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path
from typing import Dict, Optional

# в замороженном PyInstaller-бандле __file__ ведёт в _MEIPASS
# в обычном режиме — просто рядом со скриптом
if getattr(sys, "frozen", False):
    ROOT = Path(sys._MEIPASS)          # распакованные данные в temp
    # порт-файл пишем в temp — в bundle директория может быть read-only
    _PORT_FILE = Path(os.environ.get("TMPDIR", "/tmp")) / "tf2sg_backend.port"
else:
    ROOT = Path(__file__).parent
    _PORT_FILE = ROOT / "backend.port"

sys.path.insert(0, str(ROOT))

from src.data.weapons import TF2_WEAPONS, TF2_CLASSES, get_weapon_type_name
from src.config.app_config import AppConfig
from src.shared.version import __version__
from src.shared.logging_config import get_logger

logger = get_logger(__name__)


# ─── Job Management ──────────────────────────────────────────────────────── #

class BuildJob:
    def __init__(self, job_id: str):
        self.id = job_id
        self.status = "pending"   # pending | running | done | error | cancelled
        self.progress = 0
        self.message = ""
        self.result: Optional[str] = None
        self.error: Optional[str] = None
        self._lock = threading.Lock()
        self._cancel_flag = False

    def update_progress(self, pct: int, msg: str):
        with self._lock:
            self.progress = pct
            self.message = msg
            self.status = "running"

    def mark_done(self, success: bool, result: str):
        with self._lock:
            self.status = "done" if success else "error"
            self.result = result if success else None
            self.error = None if success else result
            if success:
                self.progress = 100

    def cancel(self):
        with self._lock:
            self._cancel_flag = True
            self.status = "cancelled"

    def is_cancelled(self) -> bool:
        return self._cancel_flag

    def to_dict(self) -> dict:
        with self._lock:
            return {
                "id": self.id,
                "status": self.status,
                "progress": self.progress,
                "message": self.message,
                "result": self.result,
                "error": self.error,
            }


_jobs: Dict[str, BuildJob] = {}
_jobs_lock = threading.Lock()


def create_job() -> BuildJob:
    job = BuildJob(str(uuid.uuid4()))
    with _jobs_lock:
        _jobs[job.id] = job
    return job


def get_job(job_id: str) -> Optional[BuildJob]:
    with _jobs_lock:
        return _jobs.get(job_id)


# ─── HTTP Handler ─────────────────────────────────────────────────────────── #

class APIHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        logger.debug(f"HTTP {fmt % args}")

    def send_json(self, data, status: int = 200):
        body = json.dumps(data, ensure_ascii=False, default=str).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def send_err(self, msg: str, status: int = 400):
        self.send_json({"error": msg}, status)

    def read_body(self) -> dict:
        length = int(self.headers.get("Content-Length", 0))
        return json.loads(self.rfile.read(length)) if length else {}

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        import urllib.parse
        parts = urllib.parse.urlparse(self.path)
        path = parts.path
        qs = dict(urllib.parse.parse_qsl(parts.query))

        routes = {
            "/api/ping":    lambda: self.send_json({"ok": True}),
            "/api/version": lambda: self.send_json({"version": __version__}),
            "/api/weapons": self._get_weapons,
            "/api/config":  lambda: self.send_json(AppConfig.load_config()),
        }

        if path in routes:
            routes[path]()
        elif path == "/api/hats":
            self._get_hats(qs.get("tf2_root", ""))
        elif path.startswith("/api/jobs/"):
            job_id = path[len("/api/jobs/"):].strip("/")
            job = get_job(job_id)
            self.send_json(job.to_dict()) if job else self.send_err("Not found", 404)
        elif path.startswith("/static/"):
            # отдаём статику для Three.js вьювера
            self._serve_static(path[len("/static/"):])
        else:
            self.send_err("Not found", 404)

    def do_POST(self):
        import urllib.parse
        path = urllib.parse.urlparse(self.path).path

        if path == "/api/config":
            data = self.read_body()
            for k, v in data.items():
                AppConfig.set(k, v)
            self.send_json({"ok": True})
        elif path == "/api/build":
            self._start_build()
        elif path.startswith("/api/jobs/") and path.endswith("/cancel"):
            job_id = path[len("/api/jobs/"):].rstrip("/cancel").strip("/")
            job = get_job(job_id)
            if job:
                job.cancel()
                self.send_json({"ok": True})
            else:
                self.send_err("Not found", 404)
        else:
            self.send_err("Not found", 404)

    # ── Handlers ─────────────────────────────────────────────────────────── #

    def _get_weapons(self):
        cfg = AppConfig.load_config()
        lang = cfg.get("language", "en")

        classes = []
        for class_name, info in TF2_CLASSES.items():
            types = []
            for type_key, weapons_dict in TF2_WEAPONS.get(class_name, {}).items():
                weapons = [
                    {"key": wk, "name": names.get(lang, names.get("en", wk))}
                    for wk, names in weapons_dict.items()
                ]
                types.append({
                    "key": type_key,
                    "name": get_weapon_type_name(type_key, lang),
                    "weapons": weapons,
                })
            types.append({"key": "Custom", "name": get_weapon_type_name("Custom", lang), "weapons": []})
            classes.append({"name": class_name, "icon": info.get("icon", ""), "types": types})

        self.send_json({"classes": classes})

    def _serve_static(self, filename: str):
        """Отдаёт файлы из src/static/ — нужно для Three.js вьювера."""
        import mimetypes
        # защита от path traversal
        filename = os.path.normpath(filename).lstrip("/").lstrip("\\")
        filepath = ROOT / "src" / "static" / filename
        if not filepath.exists() or not filepath.is_file():
            self.send_err("Not found", 404)
            return
        mime, _ = mimetypes.guess_type(str(filepath))
        mime = mime or "application/octet-stream"
        data = filepath.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", mime)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(data)

    def _get_hats(self, tf2_root: str):
        if not tf2_root:
            self.send_json({"hats": []})
            return
        try:
            from src.data.hats_parser import parse_hats_from_vpk
            from src.services.tf2_paths import TF2Paths
            _, misc_vpk, _ = TF2Paths.resolve(tf2_root)
            raw = parse_hats_from_vpk(misc_vpk) if misc_vpk else []
            self.send_json({"hats": [{"name": h[0], "mdl_path": h[1]} for h in raw]})
        except Exception as e:
            logger.error(f"Hats error: {e}")
            self.send_err(str(e))

    def _start_build(self):
        data = self.read_body()
        job = create_job()

        def run():
            try:
                job.status = "running"
                from src.services.vpk_service import VPKService

                success, message, cancelled = VPKService.build_with_progress(
                    image_path=data.get("image_path"),
                    mode=data.get("mode", ""),
                    hat_mdl_path=data.get("hat_mdl_path"),
                    filename=data.get("filename", "skin"),
                    size=tuple(data.get("size", [512, 512])),
                    format_type=data.get("format", "DXT1"),
                    flags=data.get("flags", []),
                    vtf_options=data.get("vtf_options", {}),
                    tf2_root_dir=data.get("tf2_root", ""),
                    export_folder=data.get("export_folder", "export"),
                    keep_temp_on_error=data.get("keep_temp_on_error", False),
                    debug_mode=data.get("debug_mode", False),
                    replace_model_enabled=data.get("replace_model_enabled", False),
                    replace_model_path=data.get("replace_model_path"),
                    model_ready_path=data.get("model_ready_path"),
                    draw_uv_layout=data.get("draw_uv_layout", False),
                    language=data.get("language", "en"),
                    custom_vtf_path=data.get("custom_vtf_path"),
                    blu_mode=data.get("blu_mode", "none"),
                    blu_image_path=data.get("blu_image_path"),
                    custom_vpk_source_path=data.get("custom_vpk_source_path"),
                    hat_apply_game_paints=data.get("hat_apply_game_paints", True),
                    panel_extra_textures=data.get("panel_extra_textures", {}),
                    progress_callback=lambda p, m: job.update_progress(p, m),
                    sub_progress_callback=lambda p, m: None,
                    cancel_callback=job.is_cancelled,
                    model_file_callback=None,
                    extra_texture_callback=None,
                    extra_model_callback=None,
                    texture_mismatch_callback=None,
                )

                if cancelled or job.is_cancelled():
                    job.status = "cancelled"
                else:
                    job.mark_done(success, message)

            except Exception as e:
                logger.error(f"Build job {job.id} failed: {e}", exc_info=True)
                job.mark_done(False, str(e))

        threading.Thread(target=run, daemon=True).start()
        self.send_json({"job_id": job.id})


# ─── Entry point ─────────────────────────────────────────────────────────── #

def _free_port() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def main():
    port = 0
    args = sys.argv[1:]
    for i, a in enumerate(args):
        if a == "--port" and i + 1 < len(args):
            port = int(args[i + 1])
        elif a.startswith("--port="):
            port = int(a.split("=", 1)[1])

    if not port:
        port = _free_port()

    _PORT_FILE.write_text(str(port))

    server = HTTPServer(("127.0.0.1", port), APIHandler)
    logger.info(f"Backend HTTP server on 127.0.0.1:{port}")
    print(f"BACKEND_PORT={port}", flush=True)

    try:
        server.serve_forever()
    finally:
        try:
            _PORT_FILE.unlink()
        except FileNotFoundError:
            pass


if __name__ == "__main__":
    main()
