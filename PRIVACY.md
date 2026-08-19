# Privacy

OpenCode Notify is self-hosted software. The operator of each gateway instance
controls its database, SMTP account, Firebase project, logs, backups, retention,
and user-support process.

## Data sent by the OpenCode plugin

The plugin sends validated notification envelopes containing:

- event id, event kind, timestamp, session id, and session title;
- machine name, OpenCode project id, and working directory;
- elapsed time and terminal outcome;
- question text and option labels, permission name/summary, or provider-action
  fields when OpenCode needs user action;
- an assistant-only terminal summary only when
  `NOTIFY_INCLUDE_SUMMARY=true`.

Notification delivery does not send user prompts, tool output, or full
conversation transcripts. When a user explicitly sends text or opens the
temporary WebUI, the selected prompt or proxied WebUI HTTP/SSE traffic passes
through gateway memory to that Plugin instance. Those bodies are not persisted
or logged. See [docs/plugin-install.md](docs/plugin-install.md#privacy) for
notification field limits.

## Data stored by the gateway

The gateway stores account and delivery configuration:

- normalized email address and password hash;
- email-verification and password-reset token hashes and timestamps;
- refresh-token families and token hashes;
- device name, platform, enabled/sound settings, and Android FCM token;
- ingest-key id, name, secret hash, timestamps, and revocation state.

Notification event payloads are routed live and are not persisted by the
gateway. Operators may still capture metadata through reverse-proxy,
application, infrastructure, or Firebase logs; operators must configure those
systems according to their own policy.

## Data stored by the client

Refresh credentials are stored through the operating system's secure credential
store. Client preferences and up to 10,000 rendered notification-history entries
are stored locally; history uses a device-local SQLite database and is never
uploaded for synchronization. Each history entry can include the event time and
type, machine, project, working directory, session title/id, request id, and
rendered notification text. A paused notification is still recorded in local
history.

## Retention and deletion

Gateway account records remain until the operator deletes them. The current
pre-release API has no self-service account-deletion endpoint. Users must
contact their gateway operator to request account/database deletion. Ingest keys
and devices can be revoked or removed from the client.

Backups can outlive live rows according to the operator's retention policy. The
example backup script defaults to 14 days; operators must document their actual
retention and deletion process.

## Third parties

- SMTP providers process verification and password-reset email.
- Firebase Cloud Messaging processes Android device tokens and push messages
  when Android delivery is enabled.
- The gateway's hosting, DNS, TLS, monitoring, and backup providers may process
  connection metadata.

Review and configure those services before inviting users.
