# Client User Guide

The OpenCode Notify client receives live notifications, manages devices and
plugin ingest keys, and keeps a local notification history. Linux, Windows, and
Android are supported; signed public binaries are not available during the
pre-release phase, so use the build instructions in
[client-setup.md](client-setup.md).

## Server selection

The client stores its gateway URL locally. Select the server on the login page,
or change it later from **Settings > Server**. Changing servers signs out the
current account and returns to the login and registration flow for the selected
server.

Do not include `/v1`, `/v1/ws`, a query, or a fragment. Production gateways
must use HTTPS so the client derives a secure `wss://` WebSocket URL. Loopback
development servers may use HTTP.

## First run

1. Start the client.
2. Confirm or edit the server, then select **Register**, enter an email address
   and password, and submit.
3. Enter the eight-character verification code sent by the gateway's SMTP
   service.
4. After authentication, the client registers the current device and opens its
   realtime connection.
5. Open **Keys** and create a key for the machine running OpenCode.
6. Open the key's configuration dialog, enter a machine name, and copy the
   complete server environment commands. Newly created keys are saved locally
   for repeat viewing and copying.
7. Follow the in-app **Plugin** page or
   [plugin-install.md](plugin-install.md) to install and configure OpenCode.

Use one ingest key per machine or automation context. Revoke a key that is no
longer used or may have been exposed.

## 密钥与服务器配置

入口：**密钥页 → 点按密钥条目或终端图标**；插件页也可以直接选择已有密钥。

| 操作 | 行为 |
| --- | --- |
| 显示 / 隐藏、复制密钥 | 新建密钥自动保存到本机凭据存储，关闭弹窗、退出登录后仍可在原账号再次查看 |
| 补录、重新录入 | 老版本创建或另一台设备创建的密钥，可以粘贴已有的完整 `keyId.secret`；只检查格式，不向网关验证归属 |
| 选择 Shell | Bash/Zsh 输出 `export`，PowerShell 输出 `$env:`，选择的是目标服务器的 Shell |
| 填写机器名 | 使用实际变量名 `NOTIFY_MACHINE`，留空时输出 `YOUR_MACHINE_NAME` 占位符 |
| 复制完整配置 | 自动包含当前 `NOTIFY_GATEWAY_URL`、完整 `NOTIFY_INGEST_KEY` 和机器名；预览默认隐藏密钥，复制包含原值 |
| 撤销 | 确认后撤销服务器密钥，并删除本机保存的对应副本 |

复制到服务器后，在同一终端启动或重启 OpenCode。环境变量只对该终端及其子进程生效；需要持久配置时，将变量放入实际启动 OpenCode 的 Shell 配置或服务环境中。

本机副本按 Gateway 和账号隔离，不跨设备同步。Gateway 仍只保存哈希，不能还原未在本机保存、也没有其他副本的旧密钥；这种情况需要新建密钥。保存失败时弹窗保留本次返回的密钥，并提供重试保存入口。

## Navigation

| Page | Purpose |
| --- | --- |
| Home | Online Plugin entries, machine/project/status and an Open button; secondary local history and pinned session shortcuts, pending requests and persistent WebUI connections |
| History | Up to 10,000 local notifications with live updates and 20/30/50/100-row pages; expand a row for event details or to delete that local record |
| Devices | Registered Linux, Windows, and Android devices; rename, enable, or remove them |
| Keys | Create, recall/copy local secrets, export server configuration, and revoke keys |
| Plugin | Select a key to export configuration, or copy the install path and environment template |
| Settings | Alert sound, pause popups, desktop autostart, and desktop font scale |

## Notification behavior

Desktop, foreground Android, and background Android notification titles use
`machine · working-directory name · session title · status` so the originating
machine and task are identifiable without exposing an internal project or
session id.

- `terminal`: completion, failure, or stop outcome and elapsed time.
- `action_required/question`: question text and option labels.
- `action_required/permission`: permission type and bounded summary.
- `action_required/provider_action`: provider action that requires attention.
- `heartbeat`: updates active-session state silently.
- `action_resolved`: clears pending state silently.

Events from child/subagent sessions are intentionally ignored. Events missed
while a desktop client is offline are not replayed. Android background delivery
uses FCM instead of replay.

## Session control

### 首页：在线入口优先

在线入口及历史会话使用两行紧凑列表，名称与路径在左、关注/固定与打开在右；窄屏改为带提示的打开图标，长文本省略后可悬停或长按查看。历史会话的发送与本机删除在“更多会话操作”中。未确认WebUI能力的在线入口显示“WebUI 未确认”，不等于服务器一定没有HTTP服务。

| 入口 | 展示与管理 |
| --- | --- |
| 在线入口（默认） | Gateway 当前连接池，每条显示机器、项目和状态；服务健康检查通过的入口提供“打开”，进入该目录 WebUI；每次展示 20 条 |
| 刷新 | 直接读取 Gateway 已知的连接池，不等待 Plugin 查询目录或会话；失败时保留现有数据并提示本次刷新失败 |
| 自动同步 | 客户端连接/重连立即收到完整快照，Plugin 上下线即时广播；每 10 分钟对同账号在线客户端再广播完整快照，空池也发送 |
| 关注 | 星标入口优先排序，关注按机器/目录保存，进程 UUID 变化不影响关注 |
| 本机历史 | 离线入口、固定与历史会话、离线请求；包含旧版隐藏的会话，均可逐项手动删除 |
| 删除 | 只删除本机记录，不删远端 OpenCode 会话、不影响其他设备；离线入口真正重新连接后可作为在线入口再次出现 |

首页不再每 30 秒逐个查询目录，不显示“若干实例暂未同步”。连接池中的一个条目是目录级 Plugin 入口，不是某个 attach 当前选中的会话；具体会话在 OpenCode WebUI 内选择。

- 本机历史来自已有缓存和本机收到的通知；冷启动显示本机记录，不自动抓取所有服务器的历史会话。
- 入口历史、会话记录和固定设置按 Gateway/账号隔离并持久保存；缓存入口在收到当前在线快照前一律视为离线。
- 最多固定 50 个具体会话。固定项在默认页折叠展示，也可在本机历史里取消固定或删除；会话快捷入口只按唯一在线目录重新绑定，不声称已重新验证远端会话仍存在。
- 本地搜索不会触发远端会话查询。想查找服务器上的其他会话，先打开对应在线入口。

A local Session shortcut shows controls when its unique owning Plugin has an available HTTP server:

- **Send:** opens a native text composer. The Gateway returns as soon as it
  writes the prompt to the Plugin connection; it does not wait for the model
  turn. Failed or uncertain sends are never retried automatically.
  Enter inserts a newline; Ctrl+Enter (also Cmd+Enter) sends. Empty text and a
  send already in progress cannot be submitted again.
- **WebUI:** opens OpenCode's own WebUI in the system browser. The client starts
  a loopback-only HTTP proxy and relays its HTTP/SSE traffic over a renewable
  authenticated WebSocket through the Gateway and Plugin. The client must stay
  running while the browser uses that localhost URL. Use the Home toolbar's
  close action to stop all connections, or close one instance in its connection row.
  Tap a connection row to reopen its latest session, or copy its full local URL
  using the copy icon. That URL works on the same device while Notify runs.

Neither mode has an offline queue. The controls disappear when the owning
instance is offline, incompatible, conflicting, or has no verified HTTP listener. Each opened
instance has an independent loopback origin; switching sessions only changes the
path, and other instances' browser tabs stay usable. Authentication renews before
the 900-second token expiry without interrupting SSE. Network failures reconnect
with backoff behind the same local listener; HTTP writes are never replayed.
An interrupted page navigation shows a retrying connection page; if the upstream
WebUI does not recover its own request, refresh the existing browser tab.

Keep Notify running in the desktop tray. Signing out, explicitly closing a
connection, or exiting the client stops its listener. Ports are stable for that
listener's lifetime, not across app exits; there is no public browser-only URL.
An OpenCode process restart creates a new instance identity: local shortcuts are
rebound only to the unique matching online machine/directory before opening a new tunnel.

The online-pool interface and WebUI capability flag require updated Gateway,
Plugin and client builds. Deploy Gateway before updating Plugins, then restart
the actual OpenCode service. Old Plugins without the capability flag remain
visible but do not offer an Open button in the new client.

实例是目录级远程入口，不是系统进程数。Plugin 继续跳过已确认没有主会话的目录；需提前保留空项目可设置 [NOTIFY_REMOTE_DIRECTORIES](plugin-install.md#目录按需注册)。只有本机真实 HTTP 健康检查通过才提供隧道；普通 TUI 无可用监听端口时仍可接收通知。

On narrow screens or with large text, session actions wrap below the session
details. Android uses the in-app WebView and starts the existing foreground
service before opening when keep-alive is enabled. Returning to Notify receives
a fresh connection-pool snapshot and retries disconnected tunnels. The Windows source also forwards
power-resume events to reconnect remote sockets behind the same local listener.
These platform changes await native acceptance; see
[Android handoff](android-agent-handoff.md) and
[Windows handoff](windows-agent-handoff.md).

## Desktop tray

Closing the Linux or Windows window hides it to the tray rather than exiting.
The realtime connection remains active while hidden. Use the tray menu to:

- show the window;
- pause or resume popup notifications;
- exit the process.

Paused events still appear in History. Use **Exit** from the tray when you want
to stop the client and close its WebSocket.

## Settings

- **Alert sound:** Linux and Windows can choose and preview one of the bundled
  sounds. A WAV, MP3, OGG, or OGA file up to 10 MiB can also be imported; the
  client copies it into its application-support directory and keeps the choice
  across restarts. Android continues to use its system notification-channel
  sound.
- **Font scale:** desktop settings provide a persistent 75%–150% text scale.
  `Ctrl++` and `Ctrl+-` adjust it by 10%; `Ctrl+0` resets it to 100%.
  This application scale replaces the desktop environment's accessibility text
  multiplier; Android continues to follow the system text-size setting.
- **Pause notifications:** suppresses popups but still records History.
- **Launch at startup:** available on Linux and Windows.

Android notification permission must be granted on Android 13 and newer. The
device must remain enabled in the Devices page for FCM delivery.

## Updating

Desktop builds are portable bundles. Stop the tray process, replace the entire
bundle, and restart it; do not replace only the executable because Flutter
assets and native libraries must stay synchronized.

History now uses a local SQLite database. The application deliberately does not
import the previous `notification_history_v1` JSON value during startup. To keep
those legacy entries, close the client and run the optional
[one-time converter](../apps/client/tool/README.md) before starting the updated
build.

For Android, updates must use the same release signing key and a higher
`versionCode`. Installing an APK signed by a different key requires uninstalling
the old app and loses local credentials/history.

## Troubleshooting

### Login or verification fails

- Confirm the server shown on the login page is correct; edit it there when
  necessary.
- Check the selected server's `/health/ready` endpoint.
- Ask the gateway operator to verify SMTP delivery and gateway logs.

### No desktop popup

- Confirm notifications are not paused in Settings or the tray.
- Check that the event appears in History. If it does, inspect desktop OS
  notification permissions and the notification daemon.
- If History also stays empty, confirm the client remains running in the tray
  and the gateway's `/v1/ws` reverse-proxy configuration supports upgrades and
  long-lived connections.

### Plugin events never arrive

- Confirm the ingest key belongs to the same account logged into the client.
- Restart OpenCode after changing plugin files or environment variables.
- Follow [plugin troubleshooting](plugin-install.md#troubleshooting).

### Android works only in the foreground

The build probably has placeholder Firebase options or the gateway has the
wrong Firebase service account. Configure both from the same Firebase project,
rebuild, reinstall, grant notification permission, and re-register the device.

### Reset local state

Use the application's normal logout flow first. Removing application data also
removes locally stored credentials, settings, device id, and History; it does
not delete the server account. Contact the gateway operator for account
deletion.

## Security

Treat refresh credentials and ingest keys as secrets. Never post client storage,
authorization headers, HMAC signatures, or complete logs publicly. See
[SECURITY.md](../SECURITY.md) and [PRIVACY.md](../PRIVACY.md).
