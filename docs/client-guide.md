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
| Home | Searchable idle/recent sessions, fixed session shortcuts, action-required state, text sending, and persistent client-held WebUI connections; instances remain grouped by machine |
| History | Up to 10,000 local notifications with live updates and 20/30/50/100-row pages; select a row for complete event details |
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

Home queries each online Plugin for main sessions, including idle sessions, on
startup and reconnect, and every 30 seconds while foregrounded. It first shows
the local cache, then verifies the current instance binding. Snapshot failures
show stale/unknown state rather than an empty list or a fabricated idle status.

- Search by session title, project, machine, or working directory. Title searches
  also query OpenCode, so older sessions need not first appear in notifications.
  The clear button resets the search; returning to Home restores its current text.
- Recent pages start at 50 sessions per instance and can expand to 200; search
  for older entries. Child/subagent and archived sessions are excluded.
- Star up to 50 sessions. Bookmarks are looked up even outside the recent page.
  Missing/deleted/archived bookmarks remain visible but cannot be opened.
- The local cache holds up to 1,000 metadata records, isolated by Gateway and
  account; bookmarks and last-opened timestamps survive client restarts.
- The instance browser icon resumes the last session opened through Notify,
  otherwise the most recently updated session, then the project's new-session
  page. A session row's browser icon always opens that exact session.

A verified Session shows two controls when its owning Plugin is online:

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
instance is offline, incompatible, conflicting, or not yet verified. Each opened
instance has an independent loopback origin; switching sessions only changes the
path, and other instances' browser tabs stay usable. Authentication renews before
the 900-second token expiry without interrupting SSE. Network failures reconnect
with backoff behind the same local listener; HTTP writes are never replayed.
An interrupted page navigation shows a retrying connection page; if the upstream
WebUI does not recover its own request, refresh the existing browser tab.

Keep Notify running in the desktop tray. Signing out, explicitly closing a
connection, or exiting the client stops its listener. Ports are stable for that
listener's lifetime, not across app exits; there is no public browser-only URL.
An OpenCode process restart creates a new instance identity: bookmarks are
revalidated against the new online instance before opening a new tunnel.

Session discovery and seamless WebUI renewal require updated Gateway, Plugin,
and client builds. Restart OpenCode after updating its Plugin. Older Plugins
may time out on discovery; the client reports this and retains the old metadata.

On narrow screens or with large text, session actions wrap below the session
details. Android uses the in-app WebView and starts the existing foreground
service before opening when keep-alive is enabled. Returning to Notify refreshes
the catalog and retries disconnected tunnels. The Windows source also forwards
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
