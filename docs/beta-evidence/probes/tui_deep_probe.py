#!/usr/bin/env python3
"""TUI probe: enumerate input.client sub-surfaces and try in-process
session question/permission list after question.asked."""
import os, pty, select, subprocess, time, tempfile, shutil, json

ROOT = tempfile.mkdtemp(prefix="tui-deep-")
proj = os.path.join(ROOT, "project"); xdg = os.path.join(ROOT, "xdg"); home = os.path.join(ROOT, "home")
os.makedirs(os.path.join(proj, ".opencode", "plugins"), exist_ok=True)
os.makedirs(os.path.join(xdg, "opencode"), exist_ok=True); os.makedirs(home, exist_ok=True)
marker = os.path.join(ROOT, "loaded.txt")

plugin = '''
import { appendFileSync } from "node:fs";
const M = MARKER_PATH;
appendFileSync(M, "imported\\n");
export default async function markerPlugin(input) {
  const c = input.client;
  appendFileSync(M, "invoked clientKeys=" + Object.keys(c ?? {}).join(",") + "\\n");
  return { event: async ({ event }) => {
    if (event?.type !== "question.asked") return;
    const lines = ["question.asked"];
    const sid = event?.properties?.sessionID ?? event?.sessionID;
    const keysOf = (o) => Object.keys(o ?? {}).join(",");
    lines.push("session=" + keysOf(c?.session));
    lines.push("global=" + keysOf(c?.global));
    lines.push("instance=" + keysOf(c?.instance));
    if (c?.session?.question?.list) {
      try { const r = await c.session.question.list({ sessionID: sid }); lines.push("s.q.list=" + JSON.stringify(r?.data ?? r).slice(0, 250)); }
      catch (e) { lines.push("s.q.list err=" + (e?.message ?? e)); }
    } else lines.push("no session.question.list");
    if (c?.session?.permission?.list) {
      try { const r = await c.session.permission.list({ sessionID: sid }); lines.push("s.p.list=" + JSON.stringify(r?.data ?? r).slice(0, 250)); }
      catch (e) { lines.push("s.p.list err=" + (e?.message ?? e)); }
    } else lines.push("no session.permission.list");
    if (c?.global?.health) {
      try { const r = await c.global.health(); lines.push("health=" + JSON.stringify(r?.data ?? r)); }
      catch (e) { lines.push("health err=" + (e?.message ?? e)); }
    } else lines.push("no global.health");
    appendFileSync(M, lines.join(" | ") + "\\n");
  } };
}
'''.replace("MARKER_PATH", json.dumps(marker))

with open(os.path.join(proj, ".opencode", "plugins", "marker.js"), "w") as f:
    f.write(plugin)

provider = subprocess.Popen(["node", os.environ.get("FAKE_PROVIDER", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "scripts", "beta", "fake-provider.mjs")), "--port-file", os.path.join(ROOT, "provider.json")], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
for _ in range(60):
    if os.path.exists(os.path.join(ROOT, "provider.json")): break
    time.sleep(0.25)
pport = json.load(open(os.path.join(ROOT, "provider.json")))["port"]

with open(os.path.join(xdg, "opencode", "opencode.json"), "w") as f:
    json.dump({"$schema": "https://opencode.ai/config.json", "permission": "ask",
               "provider": {"smoke": {"npm": "@ai-sdk/openai-compatible", "name": "Smoke",
               "options": {"baseURL": f"http://127.0.0.1:{pport}/v1", "apiKey": "smoke-test"},
               "models": {"live-model": {"name": "Live Model"}}}}, "model": "smoke/live-model"}, f)

env = dict(os.environ)
env.update({"HOME": home, "XDG_CONFIG_HOME": xdg, "XDG_DATA_HOME": os.path.join(ROOT, "data"),
            "XDG_CACHE_HOME": os.path.join(ROOT, "cache"), "OPENCODE_DISABLE_AUTOUPDATE": "1",
            "TERM": "xterm-256color"})
for k in [k for k in env if k.startswith("NOTIFY_")]: del env[k]

pid, fd = pty.fork()
if pid == 0:
    os.chdir(proj)
    os.execvpe(os.environ.get("OPENCODE_BIN", "opencode"), ["opencode"], env)

output = b""; typed = False; start = time.time()
try:
    while time.time() - start < 180:
        r, _, _ = select.select([fd], [], [], 0.5)
        if r:
            try: chunk = os.read(fd, 65536)
            except OSError: break
            output += chunk
        if not typed and "Ask anything" in output.decode("utf-8", "ignore"):
            os.write(fd, b"LIVE_Q_CLOSED_LOOP\r"); typed = True
        if os.path.exists(marker) and "s.q.list" in open(marker).read():
            break
finally:
    try: os.write(fd, b"\x03")
    except OSError: pass
    time.sleep(1)
    try: os.kill(pid, 9)
    except ProcessLookupError: pass
    provider.terminate()
    if os.path.exists(marker):
        print("MARKER:", open(marker).read().replace(chr(10), chr(10) + "  "))
    else:
        print("MARKER MISSING"); print(output.decode("utf-8", "ignore")[-600:])
    shutil.rmtree(ROOT, ignore_errors=True)
