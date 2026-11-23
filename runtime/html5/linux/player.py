"""Native GTK/WebKit player. Run only in VNE's dedicated sandbox."""

import argparse
import ctypes
import fcntl
import json
import mimetypes
import os
import re
import stat
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlsplit

import gi

gi.require_version("Gdk", "3.0")
gi.require_version("Gtk", "3.0")
gi.require_version("WebKit2", "4.1")
from gi.repository import Gdk, GLib, Gtk, WebKit2


ADDRESS = "127.0.0.1"
PORT = 18462
AUTHORITY = f"{ADDRESS}:{PORT}"
ORIGIN = f"http://{AUTHORITY}"
POLICY = (
    "default-src 'none'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; "
    "img-src 'self' data: blob:; font-src 'self' data:; "
    "media-src 'self' blob:; connect-src 'self'; base-uri 'none'; "
    "form-action 'none'; frame-ancestors 'none'; worker-src 'none'"
)
MAX_BYTES = 1024 * 1024 * 1024


class OpenHow(ctypes.Structure):
    _fields_ = [("flags", ctypes.c_uint64), ("mode", ctypes.c_uint64),
                ("resolve", ctypes.c_uint64)]


libc = ctypes.CDLL(None, use_errno=True)
libc.syscall.argtypes = [
    ctypes.c_long, ctypes.c_int, ctypes.c_char_p, ctypes.POINTER(OpenHow),
    ctypes.c_size_t,
]
libc.syscall.restype = ctypes.c_long


def emit(event, **fields):
    print(json.dumps({"event": event, **fields}), flush=True)


def local_path(url):
    parsed = urlsplit(url)
    if parsed.netloc or parsed.scheme or not parsed.path.startswith("/"):
        raise ValueError("not a local path")
    if re.search(r"%2f|%5c", parsed.path, re.IGNORECASE):
        raise ValueError("encoded separator")
    path = unquote(parsed.path[1:], errors="strict")
    parts = path.split("/")
    if len(parts) > 33 or any(
        part in {"", ".", ".."} or len(part.encode()) > 255
        or any(c in "\\:" or ord(c) < 32 for c in part)
        for part in parts
    ):
        raise ValueError("invalid local path")
    return path


def open_path(root, path, flags, resolve):
    how = OpenHow(flags, 0, resolve)
    fd = libc.syscall(437, root, path.encode(), ctypes.byref(how), ctypes.sizeof(how))
    if fd < 0:
        raise OSError(ctypes.get_errno(), "resource unavailable")
    return fd


def open_resource(root, path):
    # O_PATH avoids opening devices or blocking on named pipes before fstat.
    fd = open_path(root, path, os.O_PATH | os.O_CLOEXEC, 0x01 | 0x04 | 0x08)
    try:
        metadata = os.fstat(fd)
        if not stat.S_ISREG(metadata.st_mode) or metadata.st_size > MAX_BYTES:
            raise ValueError("unsupported resource")
        return open(f"/proc/self/fd/{fd}", "rb"), metadata.st_size
    finally:
        os.close(fd)


def launch_sandbox(source, arguments):
    root = open_path(-100, source, os.O_PATH | os.O_CLOEXEC | os.O_DIRECTORY, 0x04)
    try:
        selected = os.readlink(f"/proc/self/fd/{root}")
        private = arguments[arguments.index("--bind") + 1]
        if os.path.commonpath([selected, private]) in {selected, private}:
            raise ValueError("overlapping player directories")
        arguments[arguments.index("@game")] = str(root)
        os.set_inheritable(root, True)
        os.execv("/usr/bin/bwrap", ["bwrap", *arguments])
    finally:
        os.close(root)


def byte_range(header, size):
    if header is None:
        return 0, size
    match = re.fullmatch(r"bytes=(\d{1,12})?-(\d{1,12})?", header)
    if not match or size == 0:
        raise ValueError("invalid range")
    start, end = match.groups()
    if start is None:
        if not end or int(end) <= 0:
            raise ValueError("invalid suffix")
        return max(0, size - int(end)), size
    lower, upper = int(start), min(size, int(end) + 1) if end else size
    if lower >= upper:
        raise ValueError("invalid limits")
    return lower, upper


class ResourceHandler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def do_GET(self):
        self.serve_resource(body=True)

    def do_HEAD(self):
        self.serve_resource(body=False)

    def serve_resource(self, body):
        if self.headers.get("Host") != AUTHORITY:
            self.send_error(403)
            return
        try:
            path = local_path(self.path)
            handle, size = open_resource(self.server.root, path)
        except (OSError, ValueError):
            self.send_error(404)
            return
        with handle:
            requested = self.headers.get("Range")
            try:
                start, end = byte_range(requested, size)
            except ValueError:
                self.send_response(416)
                self.send_header("Content-Range", f"bytes */{size}")
                self.end_headers()
                return
            type_, _ = mimetypes.guess_type(path)
            self.send_response(206 if requested else 200)
            self.send_header("Content-Type", type_ or "application/octet-stream")
            self.send_header("Content-Security-Policy", POLICY)
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Accept-Ranges", "bytes")
            self.send_header("Content-Length", str(end - start))
            if requested:
                self.send_header("Content-Range", f"bytes {start}-{end - 1}/{size}")
            self.end_headers()
            if body:
                handle.seek(start)
                remaining = end - start
                try:
                    while remaining:
                        chunk = handle.read(min(65536, remaining))
                        if not chunk:
                            break
                        remaining -= len(chunk)
                        self.wfile.write(chunk)
                except OSError:
                    pass


class Player:
    def __init__(self, entry, fullscreen):
        self.ready = False
        self.failed = False
        self.fullscreen = fullscreen
        self.reported = set()
        manager = WebKit2.WebsiteDataManager(
            base_data_directory="/state/data", base_cache_directory="/state/cache",
        )
        context = WebKit2.WebContext.new_with_website_data_manager(manager)
        context.set_sandbox_enabled(True)
        if not context.get_sandbox_enabled():
            raise RuntimeError("WebKit sandbox unavailable")
        context.connect("download-started", lambda _, download: download.cancel())
        self.view = WebKit2.WebView.new_with_context(context)
        settings = self.view.get_settings()
        for name, value in {
            "enable-javascript": True, "enable-html5-local-storage": True,
            "allow-file-access-from-file-urls": False,
            "allow-universal-access-from-file-urls": False,
            "javascript-can-open-windows-automatically": False,
            "enable-media-stream": False, "enable-webrtc": False,
            "enable-developer-extras": False, "media-playback-requires-user-gesture": True,
        }.items():
            settings.set_property(name, value)
        self.view.connect("decide-policy", self.decide_policy)
        self.view.connect("permission-request", self.deny_permission)
        self.view.connect("run-file-chooser", self.deny_chooser)
        self.view.connect("create", lambda *_: None)
        self.view.connect("load-changed", self.load_changed)
        self.view.connect("load-failed", self.load_failed)
        self.view.connect("resource-load-started", self.resource_started)
        self.view.connect("web-process-terminated", lambda *_: self.fail("renderer_stopped"))
        self.window = Gtk.Window(title="VNE · HTML5", default_width=960, default_height=600)
        self.window.connect("destroy", lambda *_: Gtk.main_quit())
        self.window.connect("key-press-event", self.key_pressed)
        layout = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        buttons = Gtk.Box(spacing=10, margin=6)
        for label, callback in [
            ("Volver", lambda *_: self.window.destroy()),
            ("Pantalla completa", self.toggle_fullscreen),
            ("Silenciar", self.toggle_mute),
        ]:
            button = Gtk.Button(label=label)
            button.connect("clicked", callback)
            buttons.pack_start(button, False, False, 0)
        self.status = Gtk.Label(label="Cargando juego…", xalign=0)
        buttons.pack_start(self.status, True, True, 0)
        layout.pack_start(buttons, False, False, 0)
        layout.pack_start(self.view, True, True, 0)
        self.window.add(layout)
        self.window.show_all()
        if fullscreen:
            self.window.fullscreen()
        GLib.io_add_watch(sys.stdin, GLib.IO_IN | GLib.IO_HUP, self.control)
        self.view.load_uri(ORIGIN + entry)

    def decide_policy(self, _view, decision, kind):
        if kind == WebKit2.PolicyDecisionType.RESPONSE:
            response = decision.get_response()
            if not self.is_local(response.get_uri()):
                decision.ignore()
                return True
            if response.get_status_code() >= 400:
                if decision.is_main_frame_main_resource() and not self.ready:
                    decision.ignore()
                    self.fail("entry_load_failed")
                    return True
                self.warn("resource_unavailable", "No se pudo cargar un recurso del juego.")
            return False
        uri = decision.get_navigation_action().get_request().get_uri()
        if kind == WebKit2.PolicyDecisionType.NEW_WINDOW_ACTION or not self.is_local(uri):
            decision.ignore()
            self.warn("navigation_blocked", "Se bloqueó una navegación fuera del juego.")
            return True
        return False

    @staticmethod
    def is_local(uri):
        return uri == ORIGIN or uri.startswith(ORIGIN + "/")

    def deny_permission(self, _view, permission):
        permission.deny()
        self.warn("permission_blocked", "Se bloqueó un permiso web.")
        return True

    def deny_chooser(self, _view, request):
        request.cancel()
        self.warn("permission_blocked", "Se bloqueó una solicitud de archivos.")
        return True

    def resource_started(self, _view, resource, request):
        if self.is_local(request.get_uri()):
            resource.connect("finished", self.resource_finished)

    def resource_finished(self, resource):
        response = resource.get_response()
        if response and response.get_status_code() >= 400:
            self.warn("resource_unavailable", "No se pudo cargar un recurso del juego.")

    def load_changed(self, _view, event):
        if event == WebKit2.LoadEvent.FINISHED and not self.ready and not self.failed:
            self.ready = True
            if not self.reported:
                self.status.hide()
            emit("ready")

    def load_failed(self, *_):
        if not self.ready:
            self.fail("entry_load_failed")
        else:
            self.warn("resource_unavailable", "No se pudo cargar un recurso del juego.")
        return True

    def warn(self, code, message):
        if code not in self.reported:
            self.reported.add(code)
            self.status.set_text(message)
            self.status.show()
            emit("warning", code=code)

    def fail(self, code):
        if not self.failed:
            self.failed = True
            emit("error", code=code)
            self.window.destroy()

    def toggle_fullscreen(self, _button):
        self.fullscreen = not self.fullscreen
        if self.fullscreen:
            self.window.fullscreen()
        else:
            self.window.unfullscreen()

    def key_pressed(self, _window, event):
        if event.keyval == Gdk.KEY_F11 or (event.keyval == Gdk.KEY_Escape and self.fullscreen):
            self.toggle_fullscreen(None)
            return True
        return False

    def toggle_mute(self, button):
        muted = not self.view.get_is_muted()
        self.view.set_is_muted(muted)
        button.set_label("Activar sonido" if muted else "Silenciar")

    def control(self, source, condition):
        if (condition & GLib.IO_HUP) or source.readline().strip() == "close":
            self.window.destroy()
            return False
        return True


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "--launch":
        launch_sandbox(sys.argv[2], sys.argv[3:])
        return
    parser = argparse.ArgumentParser()
    parser.add_argument("entry")
    parser.add_argument("--fullscreen", action="store_true")
    args = parser.parse_args()
    # The caller supplies distinct network, PID and mount namespaces.
    with open("/proc/net/dev", encoding="ascii") as interfaces:
        if {line.split(":")[0].strip() for line in interfaces if ":" in line} != {"lo"}:
            raise RuntimeError("network namespace unavailable")
    local_path(args.entry)
    lock = open("/state/session.lock", "a")
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    root = os.open("/game", os.O_PATH | os.O_CLOEXEC | os.O_DIRECTORY)
    server = ThreadingHTTPServer((ADDRESS, PORT), ResourceHandler)
    server.root = root
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        player = Player(args.entry, args.fullscreen)
        Gtk.main()
        # Keep the view and its context alive until the GTK loop has stopped.
        player.view.stop_loading()
    finally:
        server.shutdown()
        server.server_close()
        os.close(root)
        lock.close()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        emit("error", code="runtime_unavailable")
        sys.exit(1)
