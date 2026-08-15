#!/usr/bin/env python3
"""Issue #14 closed loop: drive a REAL opencode interactive process in a pty
so the REAL production plugin factory is invoked and its event hook sees the
marker question.

Two modes:
  * TUI mode (default): fork `opencode` (standalone TUI) in an isolated
    project dir. NOTE (verified): on 1.18.18 the standalone TUI's
    `input.serverUrl` has no reachable listener, so only the notification
    side works there.
  * ATTACH mode (ATTACH_URL set): fork `opencode attach <ATTACH_URL>` in a
    project dir owned by the caller (PROJECT_DIR). The plugin factory is
    invoked in the attach process with serverUrl = the serve listener, which
    IS reachable (health 200) — this is the fully functional 1.18.18 mode
    (serve + attach). NOTIFY_* points at the beta gateway with the loop
    account's REAL ingest key.

In both modes the driver:
  - types the marker prompt once "Ask anything" is ready AND the client's
    GO file exists (GO-file handshake);
  - writes the reachable URL to OPENCODE_URL_FILE;
  - logs all pty output to TUI_LOG;
  - keeps the process alive until SIGTERM, then tears down only its own
    child and (in TUI mode) its own temp dirs.

Environment: NOTIFY_GATEWAY_URL, NOTIFY_INGEST_KEY, PROVIDER_BASE_URL,
PLUGIN_DIST, OPENCODE_BIN, MARKER, OPENCODE_URL_FILE, TUI_LOG, TUI_GO_FILE,
PERMISSION, and for ATTACH mode: ATTACH_URL, PROJECT_DIR.
Release tooling only; never CI.
"""
import json
import os
import pty
import re
import select
import shutil
import signal
import sys
import tempfile
import time

ENV = os.environ


def req(name, default=None):
    v = ENV.get(name)
    if v is None or v == "":
        if default is not None:
            return default
        print(f"tui-driver: {name} is required", file=sys.stderr)
        sys.exit(1)
    return v


GATEWAY = req("NOTIFY_GATEWAY_URL")
CRED = req("NOTIFY_INGEST_KEY")
PROVIDER = req("PROVIDER_BASE_URL")
PLUGIN_DIST = req("PLUGIN_DIST")
OPENCODE_BIN = req("OPENCODE_BIN", "/home/pzy000/.opencode/bin/opencode")
MARKER = req("MARKER", "LIVE_Q_CLOSED_LOOP")
URL_FILE = req("OPENCODE_URL_FILE")
TUI_LOG = req("TUI_LOG")
GO_FILE = req("TUI_GO_FILE", None)
PERMISSION = req("PERMISSION", "ask")
MODEL = req("MODEL", "live-model")
PROVIDER_ID = req("PROVIDER_ID", "livefake")
ATTACH_URL = req("ATTACH_URL", None)

cleanup_roots = []

if ATTACH_URL is not None:
    # Attach mode: the caller owns the project dir (serve already runs there
    # with the plugin + config). We only drive the attach pty.
    proj = req("PROJECT_DIR")
    xdg = req("XDG_CONFIG_HOME")
    home = req("HOME")
    ROOT = None
    cmd = [OPENCODE_BIN, "attach", ATTACH_URL]
else:
    # TUI mode: build an isolated project dir + XDG home.
    ROOT = tempfile.mkdtemp(prefix="notify-tui-", dir="/tmp/opencode")
    cleanup_roots.append(ROOT)
    proj = os.path.join(ROOT, "project")
    xdg = os.path.join(ROOT, "xdg")
    home = os.path.join(ROOT, "home")
    os.makedirs(os.path.join(proj, ".opencode", "plugins"), exist_ok=True)
    os.makedirs(os.path.join(xdg, "opencode"), exist_ok=True)
    os.makedirs(home, exist_ok=True)
    try:
        shutil.copy(PLUGIN_DIST, os.path.join(proj, ".opencode", "plugins", "session-notify.js"))
    except OSError as e:
        print(f"tui-driver: cannot copy plugin bundle: {e}", file=sys.stderr)
        sys.exit(1)
    with open(os.path.join(xdg, "opencode", "opencode.json"), "w") as f:
        json.dump({
            "$schema": "https://opencode.ai/config.json",
            "permission": PERMISSION,
            "provider": {PROVIDER_ID: {
                "npm": "@ai-sdk/openai-compatible",
                "name": "Live Fake",
                "options": {"baseURL": PROVIDER, "apiKey": "live-test"},
                "models": {MODEL: {"name": "Live Model"}},
            }},
            "model": f"{PROVIDER_ID}/{MODEL}",
        }, f)
    cmd = [OPENCODE_BIN]

env = dict(os.environ)
env.update({
    "HOME": home,
    "XDG_CONFIG_HOME": xdg,
    "XDG_DATA_HOME": os.path.join(home, ".local", "share"),
    "XDG_CACHE_HOME": os.path.join(home, ".cache"),
    "OPENCODE_DISABLE_AUTOUPDATE": "1",
    "TERM": "xterm-256color",
    # Plugin→OpenCode loopback traffic must never traverse the host proxy.
    "NO_PROXY": "localhost,127.0.0.1,::1",
    "no_proxy": "localhost,127.0.0.1,::1",
    "NOTIFY_GATEWAY_URL": GATEWAY,
    "NOTIFY_INGEST_KEY": CRED,
    "NOTIFY_IDLE_DEBOUNCE_MS": "5000",
    "NOTIFY_HEARTBEAT_MS": "30000",
    "NOTIFY_HTTP_TIMEOUT_MS": "3000",
    "NOTIFY_MAX_RETRIES": "1",
})

pid, fd = pty.fork()
if pid == 0:
    os.chdir(proj)
    os.execvpe(OPENCODE_BIN, cmd, env)

logf = open(TUI_LOG, "a")
output = b""
typed = False
url_written = False
waiting_printed = False
start = time.time()


def teardown(signum=None, frame=None):
    try:
        os.write(fd, b"\x03")
    except OSError:
        pass
    time.sleep(1)
    try:
        os.kill(pid, signal.SIGKILL)
    except (ProcessLookupError, PermissionError):
        pass
    try:
        os.close(fd)
    except OSError:
        pass
    logf.close()
    for root in cleanup_roots:
        shutil.rmtree(root, ignore_errors=True)
    sys.exit(0)


signal.signal(signal.SIGTERM, teardown)
signal.signal(signal.SIGINT, teardown)

try:
    while time.time() - start < 600:
        r, _, _ = select.select([fd], [], [], 0.5)
        if r:
            try:
                chunk = os.read(fd, 65536)
            except OSError:
                break
            output += chunk
            logf.write(chunk.decode("utf-8", "ignore"))
            logf.flush()
        text = output.decode("utf-8", "ignore")
        if not typed:
            tui_ready = "Ask anything" in text or ("Type" in text and "message" in text)
            go_ok = GO_FILE is None or (os.path.exists(GO_FILE) and open(GO_FILE).read().strip())
            if tui_ready and go_ok:
                os.write(fd, (MARKER + "\r").encode())
                typed = True
                print(f"tui-driver: typed marker at {time.time():.1f}", file=sys.stderr)
            elif tui_ready and GO_FILE is not None and not go_ok and not waiting_printed:
                waiting_printed = True
                print("tui-driver: TUI ready; waiting for GO file before typing the marker", file=sys.stderr)
        if not url_written:
            if ATTACH_URL is not None:
                with open(URL_FILE, "w") as f:
                    f.write(ATTACH_URL + "\n")
                url_written = True
                print(f"tui-driver: attach mode url {ATTACH_URL}", file=sys.stderr)
            else:
                m = re.search(r"http://localhost:\d+", text)
                if m:
                    with open(URL_FILE, "w") as f:
                        f.write(m.group(0) + "\n")
                    url_written = True
                    print(f"tui-driver: detected {m.group(0)}", file=sys.stderr)
                elif typed and time.time() - start > 10:
                    with open(URL_FILE, "w") as f:
                        f.write("http://localhost:4096\n")
                    url_written = True
                    print("tui-driver: assumed http://localhost:4096", file=sys.stderr)
    else:
        print("tui-driver: TUI output timeout", file=sys.stderr)
finally:
    teardown()
