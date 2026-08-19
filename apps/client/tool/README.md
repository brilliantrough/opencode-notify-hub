# Notification history import

`import_notification_history.dart` is a one-time external converter for the old
`notification_history_v1` JSON value. The application does not run this
migration itself.

Close OpenCode Notify first. From `apps/client`, run:

```bash
dart run tool/import_notification_history.dart \
  --input "$HOME/.local/share/dev.opencodenotify.client/shared_preferences.json" \
  --database "$HOME/.local/share/dev.opencodenotify.client/notification_history.sqlite"
```

The equivalent current Windows paths are:

```powershell
dart run tool/import_notification_history.dart `
  --input "$env:APPDATA\dev.opencodenotify\client\shared_preferences.json" `
  --database "$env:APPDATA\dev.opencodenotify\client\notification_history.sqlite"
```

The input may be either the complete desktop `shared_preferences.json` file or
the decoded JSON history list. Existing event IDs are skipped, only the newest
10,000 rows are retained, and the source file is never modified or removed.
