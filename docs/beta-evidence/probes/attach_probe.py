#!/usr/bin/env python3
"""Probe: opencode serve + opencode attach — is the plugin factory invoked in
the attach process with a REACHABLE serverUrl (the serve listener)?"""
import os, pty, select, subprocess, time, tempfile, shutil, json, signal, urllib.request

ROOT = tempfile.mkdtemp(prefix="attach-probe-")
proj = os.path.join(ROOT, "project"); xdg = os.path.join(ROOT, "xdg"); home = os.path.join(ROOT, "home")
os.makedirs(os.path.join(proj, ".opencode", "plugins"), exist_ok=True)
os.makedirs(os.path.join(xdg, "opencode"), exist_ok=True); os.makedirs(home, exist_ok=True)
marker = os.path.join(ROOT, "loaded.txt")

with open(os.path.join(proj, ".opencode", "plugins", "marker.js"), "w") as f:
    f.write(f'''
import {{ appendFileSync }} from "node:fs";
appendFileSync({json.dumps(marker)}, "imported\\n");
export default async function markerPlugin(input) {{
  const url = input?.serverUrl?.toString?.() ?? "none";
  let reachable = "unknown";
  try {{
    const res = await fetch(url + "global/health", {{ signal: AbortSignal.timeout(5000) }});
    reachable = String(res.status);
  }} catch (e) {{ reachable = "err:" + (e?.cause?.code ?? e?.message ?? e); }}
  appendFileSync({json.dumps(marker)}, "invoked serverUrl=" + url + " health=" + reachable + "\\n");
  return {{ event: async ({{ event }}) => {{
    if (event?.type === "question.asked") appendFileSync({json.dumps(marker)}, "question.asked\\n");
  }} }};
}}
''')

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
            "TERM": "xterm-256color", "NO_PROXY": "localhost,127.0.0.1"})
for k in [k for k in env if k.startswith("NOTIFY_")]: del env[k]

serve_port = 45500 + (os.getpid() % 1000)
serve = subprocess.Popen([os.environ.get("OPENCODE_BIN", "opencode"), "serve", "--hostname", "127.0.0.1", "--port", str(serve_port)], cwd=proj, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
base = f"http://127.0.0.1:{serve_port}"
for _ in range(90):
    try:
        if urllib.request.urlopen(base + "/api/health", timeout=2).status == 200: break
    except Exception: time.sleep(0.5)

pid, fd = pty.fork()
if pid == 0:
    os.chdir(proj)
    os.execvpe(os.environ.get("OPENCODE_BIN", "opencode"), ["opencode", "attach", base], env)

output = b""; typed = False; start = time.time()
try:
    while time.time() - start < 180:
        r, _, _ = select.select([fd], [], [], 0.5)
        if r:
            try: chunk = os.read(fd, 65536)
            except OSError: break
            output += chunk
        text = output.decode("utf-8", "ignore")
        if not typed and "Ask anything" in text:
            os.write(fd, b"LIVE_Q_CLOSED_LOOP\r"); typed = True
        if os.path.exists(marker) and "question.asked" in open(marker).read():
            break
finally:
    try: os.write(fd, b"\x03")
    except OSError: pass
    time.sleep(1)
    try: os.kill(pid, 9)
    except ProcessLookupError: pass
    serve.terminate(); provider.terminate()
    if os.path.exists(marker):
        print("marker:", open(marker).read().replace(chr(10), " | "))
    else:
        print("marker: MISSING"); print("tui tail:", output.decode("utf-8", "ignore")[-800:])
    shutil.rmtree(ROOT, ignore_errors=True)
