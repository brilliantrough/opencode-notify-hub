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
6. Copy the `keyId.secret` value immediately. The raw secret is shown once and
   cannot be recovered later.
7. Follow the in-app **Plugin** page or
   [plugin-install.md](plugin-install.md) to install and configure OpenCode.

Use one ingest key per machine or automation context. Revoke a key that is no
longer used or may have been exposed.

## Navigation

| Page | Purpose |
| --- | --- |
| Home | OpenCode instances grouped by machine, active sessions, action-required state, text sending, and temporary WebUI access; offline instances can be forgotten and reappear when they reconnect |
| History | Up to 10,000 local notifications with live updates and 20/30/50/100-row pages; select a row for complete event details |
| Devices | Registered Linux, Windows, and Android devices; rename, enable, or remove them |
| Keys | Create, list, and revoke plugin ingest keys |
| Plugin | Copy the install path and required environment-variable template |
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

An active or recently completed Session shows two controls when its owning
Plugin instance is online and uniquely identifiable:

- **Send:** opens a native text composer. The Gateway returns as soon as it
  writes the prompt to the Plugin connection; it does not wait for the model
  turn. Failed or uncertain sends are never retried automatically.
- **WebUI:** opens OpenCode's own WebUI in the system browser. The client starts
  a loopback-only HTTP proxy and relays its HTTP/SSE traffic over a temporary
  authenticated WebSocket through the Gateway and Plugin. The client must stay
  running while the browser uses that localhost URL. Use the Home toolbar's
  close action to stop the local listener and tunnel.

Neither mode has an offline queue. The controls disappear when the owning
instance is offline, incompatible, conflicting, or ambiguous. Only one browser
tunnel is kept at a time; opening another instance closes the previous tunnel.
Signing out, exiting the client, losing the Plugin connection, or access-token
expiry also closes it.

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
