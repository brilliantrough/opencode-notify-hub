# OpenCode Notify

OpenCode Notify delivers time-sensitive OpenCode state to a user's other
devices so the user can respond when they are away from the running instance.

## Language

**Remote unblock loop**:
A notification-driven interaction in which a user resolves an OpenCode session's pending human-input request from another device and the same session resumes execution.
_Avoid_: Remote chat, remote desktop, mini OpenCode client

**Remote authorization decision**:
A response made from another device to a pending OpenCode permission request: allow once, always allow, or reject.
_Avoid_: Confirm, approval

**Pending interaction**:
An unanswered question or permission request currently held by an online OpenCode instance. OpenCode is authoritative; a notification or client cache is only a projection of this state.
_Avoid_: Pending notification, notification history item

**OpenCode instance**:
One running `opencode serve` or `opencode web` process and its Plugin control connection. A machine may host multiple concurrent instances using the same global Plugin configuration.
_Avoid_: Machine, project, server port

**Last-known interaction**:
A read-only client projection of an interaction whose OpenCode instance is offline, so its pending status cannot currently be verified.
_Avoid_: Offline request, queued answer

**Plugin key**:
A credential configured once for a machine's OpenCode Notify Plugin and used for both notification delivery and remote unblock control. Revoking it disables both capabilities for every instance using that configuration.
_Avoid_: Ingest key, control key
