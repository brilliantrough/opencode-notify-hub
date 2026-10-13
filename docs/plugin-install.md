# Installing the session-notify OpenCode plugin

The plugin ships as a single self-contained ESM file,
`packages/plugin/dist/session-notify.js`. It watches OpenCode session
events and POSTs privacy-bounded notification envelopes to your
notification gateway (`POST {NOTIFY_GATEWAY_URL}/v1/events`, HMAC-signed).

同一份 `session-notify.js` 兼容 **OpenCode V1 ≥ 1.18.29 与 V2**。
唯一默认导出包含 `id`、V1 `server()`、V2 `setup()`；宿主选择自己的入口。
无需额外安装 SDK，也无需分发两份插件。构建后的 smoke 检查导出形状与通知链路。

## 下载预构建插件

从 [Plugin 0.2.0-beta.4](https://github.com/brilliantrough/opencode-notify-hub/releases/tag/v0.2.0-beta.4)
下载 `opencode-notify-plugin-0.2.0-beta.4.zip` 与 `SHA256SUMS.txt`，核对 SHA256 后解压。
ZIP 内含 `session-notify.js`、`LICENSE`、`PLUGIN-INSTALL.md`；只需安装 JS，保留现有环境变量配置。
客户端继续使用 [0.2.0-beta.3](https://github.com/brilliantrough/opencode-notify-hub/releases/tag/v0.2.0-beta.3)，Gateway 无需更新。

## Prerequisites

- **OpenCode V1 ≥ 1.18.29 或 V2**；V1 更早版本不支持本插件的双入口导出。
- **Node.js ≥ 22** and **pnpm 9** to build the bundle. (The produced
  bundle itself also runs under Bun, which is what OpenCode's plugin
  host uses.)
- A reachable **notification gateway** and an **ingest key** issued by
  that gateway, in the form `keyId.secret` (both parts base64url).

## Build

From the repository root:

```bash
pnpm install --frozen-lockfile
pnpm --filter @notify/plugin... build
```

This produces `packages/plugin/dist/session-notify.js`. The bundle is
fully self-contained: `@notify/contracts` (including its validator) and the
runtime parts of `@opencode-ai/sdk` are bundled, while
`@opencode-ai/plugin` is type-only and erased at build time. Remaining runtime
imports are Node builtins. No `node_modules` needs to sit next to the installed
file.

可选加载检查：两条命令均应输出 `opencode-notify function function`。

```bash
node -e "import('./packages/plugin/dist/session-notify.js').then(({default:p}) => console.log(p.id, typeof p.server, typeof p.setup))"
bun  -e "import('./packages/plugin/dist/session-notify.js').then(({default:p}) => console.log(p.id, typeof p.server, typeof p.setup))"
```

For a stronger gate, the committed smoke script additionally asserts the
export set is exactly `["default"]` and loads the plugin against a fake
OpenCode host with the network disabled. It runs automatically at the
end of every `pnpm --filter @notify/plugin build` (and therefore of the
root `pnpm build`); it can also be run standalone under either runtime:

```bash
pnpm --filter @notify/plugin smoke:dist    # Node
bun packages/plugin/scripts/smoke-dist.mjs # Bun
```

## Install

OpenCode loads plugins two ways:

1. **Plugin directories (used here).** Direct `.js`/`.ts` children of
   the global directory `~/.config/opencode/plugins/` (or the
   project-level `.opencode/plugins/`) are auto-discovered and loaded at
   startup. No config entry is required.
2. **`plugin` array in `opencode.json`.** This is primarily for **npm
   packages** (installed with Bun at startup and cached in
   `~/.cache/opencode/node_modules/`), e.g.:

   ```jsonc
   // ~/.config/opencode/opencode.json — npm plugins only.
   // session-notify is a local file and is NOT listed here.
   {
     "$schema": "https://opencode.ai/config.json",
     "plugin": ["opencode-wakatime"]
   }
   ```

   Some OpenCode versions also accept explicit local file paths in this
   array, but that behavior has varied between releases, while the
   plugin directories have worked consistently across them — so the
   recommended install for this bundle is auto-discovery via
   `~/.config/opencode/plugins/`, with **no** `plugin` entry. Do **not**
   add the bare name `session-notify` to the array: it is not an npm
   package, the name would not resolve, and a file placed in the plugin
   directory is already loaded by auto-discovery.

Install the bundle globally:

```bash
mkdir -p ~/.config/opencode/plugins
cp packages/plugin/dist/session-notify.js ~/.config/opencode/plugins/
```

PowerShell on Windows uses the same OpenCode configuration directory:

```powershell
New-Item -ItemType Directory -Force "$HOME\.config\opencode\plugins"
Copy-Item "packages\plugin\dist\session-notify.js" `
  "$HOME\.config\opencode\plugins\session-notify.js"
```

(For a project-only install, copy it to `<project>/.opencode/plugins/`
instead.)

## Configuration

The plugin is configured entirely through environment variables, which
must be present in the environment OpenCode is started from (shell
profile, desktop launcher environment, or `VAR=value opencode`).

### Required

| Variable | Rules |
| --- | --- |
| `NOTIFY_GATEWAY_URL` | Absolute URL, no trailing slash. `https://` for anything real; `http://` is accepted **only** for loopback hosts (`localhost`, `127.0.0.1`, `[::1]`) for local gateway development. URLs with embedded `user:pass@` credentials are rejected. |
| `NOTIFY_INGEST_KEY` | `keyId.secret`, exactly one dot; both parts nonempty base64url (`A–Z a–z 0–9 - _`), as issued by the gateway. Sent as `Authorization: Bearer` and used as the HMAC-SHA256 signing secret. |

Example:

```bash
export NOTIFY_GATEWAY_URL="https://notify.example.com"
export NOTIFY_INGEST_KEY="Ab12Cd34.xY9_verylongsecret-token"
```

For a PowerShell session:

```powershell
$env:NOTIFY_GATEWAY_URL = "https://notify.example.com"
$env:NOTIFY_INGEST_KEY = "Ab12Cd34.xY9_verylongsecret-token"
opencode
```

Never commit the ingest key or paste it into OpenCode itself.

### Optional

| Variable | Default | Bounds / values |
| --- | --- | --- |
| `NOTIFY_MACHINE` | OS hostname | Any nonempty string; stamped as the event source machine. |
| `NOTIFY_REMOTE_DIRECTORIES` | `[]` | JSON array of exact absolute paths on the OpenCode host. These directories register even with no sessions; child directories are not included. |
| `NOTIFY_INCLUDE_SUMMARY` | `false` | `true` / `false` only. When `true`, terminal events (completed/failed/stopped) include an assistant-only text summary, capped at 500 characters. See *Privacy* before enabling. |
| `NOTIFY_QUEUE_CAPACITY` | `100` | Integer 1–10 000. Bounded offline queue; overflow drops lowest-priority events. |
| `NOTIFY_HEARTBEAT_MS` | `60000` | Integer 1–3 600 000. Progress heartbeat interval while a round runs. |
| `NOTIFY_IDLE_DEBOUNCE_MS` | `15000` | Integer 1–600 000. Stable-idle delay before a round is declared completed. |
| `NOTIFY_HTTP_TIMEOUT_MS` | `5000` | Integer 1–300 000. Per-attempt gateway POST timeout; also the total startup session-discovery deadline. |
| `NOTIFY_MAX_RETRIES` | `3` | Integer 1–100. Delivery retries with backoff before an event is dropped. |
| `NOTIFY_OPENCODE_URL` | 自动发现 V2 本机服务 | 仅 V2：独立 `serve` 的 HTTP(S) origin，例如 `http://127.0.0.1:4096`；必须指向承载插件的同一进程。 |
| `NOTIFY_OPENCODE_PASSWORD` | V2 服务注册文件中的密码 | 指定 URL 时使用的服务密码；未设置则读取 `OPENCODE_PASSWORD` / `OPENCODE_SERVER_PASSWORD`。不上传 Gateway。 |

### V1 / V2 API 兼容

| 能力 | V1 | V2 |
| --- | --- | --- |
| 插件生命周期 | `server(input)` 返回 hooks | `setup(ctx)` 订阅事件，返回清理函数 |
| 会话事件 | `properties`、`session.status` | `data`、`session.execution.*`、`session.retry.scheduled` |
| 问答 | question 请求与 `string[][]` 答案 | 内置 question 工具的 `form`，按 `q0/q1` 转换答案 |
| 权限回复 | SDK 的 `reply` | `/api/session/:id/permission/:requestID/reply` 的 `decision` |
| 会话状态 | `/session/status` | `/api/session/active` + 实时执行事件；查询失败为 unknown |
| WebUI 深链 | 目录编码 + session | 插件将旧客户端链接转换为浏览器 origin 对应的 V2 链接 |

- Gateway：继续使用 Notify control protocol **2**；现有支持 `webUiAvailable` 的 Gateway 可直接使用，不因 OpenCode 升级而部署。
- V2 只将内置 question 工具的表单转为远程问答；登录、MCP 等通用表单在 WebUI 中处理。
- V2 默认从 `$XDG_STATE_HOME/opencode/service.json`（默认 `~/.local/state/opencode/service.json`）发现服务，核对注册 PID、HTTP `/api/info` 的 PID 与宿主版本，再使用本机 Basic 认证。
- V2 独立 `serve`：在**服务进程环境**显式设置 URL 和密码，避免误连另一份共享服务：

  ```bash
  export OPENCODE_PASSWORD='your-server-password'
  export NOTIFY_OPENCODE_URL='http://127.0.0.1:4096'
  export NOTIFY_OPENCODE_PASSWORD="$OPENCODE_PASSWORD"
  opencode serve --hostname 127.0.0.1 --port 4096
  ```

- V2 无可认证 HTTP 入口时仍接收宿主通知事件；远程列表、问答回复和隧道不可用，日志提示 `V2 HTTP endpoint unavailable`。
- V2 的普通 TUI 默认连接共享服务，因此共享服务中的插件可以提供隧道；私有进程不能冒用共享服务的入口。
- 对照来源：[双入口与插件迁移](https://opencode.ai/v2/docs/build/plugins)、[V2 API](https://opencode.ai/v2/docs/api)、[V2 WebUI](https://opencode.ai/v2/docs/cli/web)。

### 目录按需注册

- 同一个 `opencode serve` 可以加载许多目录，Notify 的实例并不等于系统进程。
- Plugin 初始化完成后查询本目录的主会话元数据：V1 使用宿主 SDK，V2 使用已认证 HTTP；有未归档的历史会话（含 idle）才自动建立控制连接。通常只查最近 1 条，若被归档记录占据则扩大到 50/200 条，总超时默认 5 秒，不查询消息正文或运行状态。
- 没有有效主会话、或已完整确认只有归档/内部任务的目录只保留事件 hooks；首次创建或收到可确认的用户主会话事件时自动注册。仅浏览 `.cache`、`node_modules` 等空目录不会创建 Notify 连接。
- `magic-context-` 标题前缀保留给 Magic Context 内部后台任务，启动查询、生命周期事件和 SDK 补查统一排除，既不激活入口也不发送任务通知；即使任务没有 `parentID` 也一样。当前依据该插件的命名约定识别，尚无通用的上游内部会话标志；其他自动化创建的普通根会话仍按主会话处理。
- 删除或归档会话时重新查询目录：确认没有有效主会话就撤下控制入口并关闭关联隧道，hooks 保留，后续新建或取消归档可重新注册；有真实 idle 历史或在 `NOTIFY_REMOTE_DIRECTORIES` 中显式指定则保留。没有新增周期轮询。
- 查询失败、返回格式/目录不兼容或达到 200 条仍不能确认时，记录 `directory state unknown` 并保留远程入口，避免把故障或更早历史误判为空；晚到的旧快照不得撤下刚创建的会话入口。
- 从其他 OpenCode 进程创建会话不会触发当前空目录的事件 hooks；该创建进程的 Notify 会自行注册，当前目录在重新加载或收到后续主会话事件时再次接入。

确实需要在创建会话前保留某个空目录入口时，在启动 **server 的环境**中配置（不要只在 attach 终端设置）：

```bash
export NOTIFY_REMOTE_DIRECTORIES='["/home/me/work/project"]'
```

Windows OpenCode 主机示例：

```powershell
$env:NOTIFY_REMOTE_DIRECTORIES = '["C:/work/project"]'
```

路径是精确目录，不是递归白名单；未列出的目录仍按会话自动发现。不要把这段可选配置加到所有导出命令里。

更新 `session-notify.js` 后需重启实际 OpenCode 服务进程，重连 `attach` 本身不会卸载旧 Plugin。旧空目录入口会转为离线，可在 Notify 的“本机历史”逐项删除；无需删除 OpenCode 会话数据库。

### V1 服务入口和版本识别

- Plugin 通过真实 HTTP `/global/health` 获取版本并确认监听服务可用；只有健康响应有效时才上报 `webUiAvailable: true`。普通 TUI 的进程内 SDK 可用不代表存在可隧道访问的服务，无有效 HTTP 服务时仍保留通知功能。
- Plugin 到 OpenCode 的 HTTP 请求绕过代理，并仅向宿主 `serverUrl` 同源地址附加 `OPENCODE_SERVER_PASSWORD` / `OPENCODE_SERVER_USERNAME` 对应的 Basic 认证；用户名默认 `opencode`。这些是 OpenCode 原有环境变量，不是新的 Notify 配置项，凭据不发给 Gateway 或客户端。
- 修复旧 SDK 缺少 health 方法后回退 HTTP 客户端未带服务密码的 401；未知版本在控制连接重试时重新探测，不永久缓存 unknown。
- 此能力字段需要先部署新 Gateway，再安装 Plugin 并重启实际 OpenCode 服务，最后使用新客户端。旧 Plugin 缺少能力字段时显示在线但不提供“打开”。

### Validation behavior (fail closed)

通知投递配置在插件加载时校验；V2 HTTP 入口另行探测，失败只影响远程能力。

Configuration is validated once at plugin load. **Any** missing or
invalid value — including a malformed URL, a bad key format, a
non-`true`/`false` summary flag, or an out-of-bounds number — disables
the plugin entirely: it registers no hooks, sends nothing, and emits a
single warning through the OpenCode log:

```
opencode-notify disabled: missing or invalid NOTIFY_* configuration
```

The warning deliberately echoes no environment value, so the ingest
credential can never leak through this path. Fix the variable and
restart OpenCode.

## Privacy

Every event is validated against the shared contract before it leaves
the process; an event that cannot be built validly is dropped, never
sent partially. Envelopes carry:

- event kind, event id, timestamp, and session id/title;
- source identity: machine name, project id, working directory;
- round timing (elapsed seconds) and outcome
  (`completed` / `failed` / `stopped`, heartbeats while running);
- action details when the agent needs you: question text and option
  labels (≤ 8 questions, text ≤ 2000 chars), permission name and its
  summary (≤ 500 chars), provider action fields;
- **only with `NOTIFY_INCLUDE_SUMMARY=true`**: an assistant-only message
  summary (≤ 500 chars) on terminal events.

Never sent: user prompts, tool output, permission metadata beyond the
summary, full conversation text. Delivery uses
`Authorization: Bearer keyId.secret` plus an `X-Notify-Signature`
HMAC-SHA256 over the timestamped body. Logs contain ids, kinds, and
counts only, and the logger additionally scrubs the ingest credential
from anything it emits.

## Troubleshooting

Plugin log entries go through OpenCode's `app.log` with service name
`opencode-notify`. Find them in OpenCode's log files
(`~/.local/share/opencode/log/`, timestamped files, newest 10 kept) or
run OpenCode in the foreground with `opencode --print-logs` /
`--log-level DEBUG`.

V2 使用进程 stderr，前缀 `[opencode-notify]`；查看共享服务或独立 `serve` 的输出。

- **No notifications, one "disabled" warning** → a required variable is
  missing/invalid; see *Validation behavior* above.
- **Events dropped with a gateway error in the log** → the gateway is
  unreachable or rejecting the key; the message carries only the event
  id and a sanitized reason. Check `NOTIFY_GATEWAY_URL` reachability and
  that the key was issued for that gateway.
- **Plugin not loaded at all** → confirm the file is a *direct* child of
  `~/.config/opencode/plugins/` named `session-notify.js`, and that you
  restarted OpenCode.

## Restart required

替换文件或修改 `NOTIFY_*` 后，重启承载插件的服务进程。V2 支持本地插件热加载，
但环境变量不会随终端修改自动更新；共享服务用 `opencode service restart`，
独立 `serve` 则在正确环境下重新启动。只重连 TUI/attach 不会更新服务环境。

## Non-interactive shutdown

`opencode run` disposes its plugin instance immediately after the session
becomes idle, before a normal debounce timer is guaranteed another event-loop
turn. During graceful disposal, session-notify therefore flushes only rounds
that have already entered the idle debounce and waits for their accepted
deliveries. A still-busy round is never reclassified as completed. Long-lived
interactive OpenCode sessions continue to use the configured
`NOTIFY_IDLE_DEBOUNCE_MS` window normally.
