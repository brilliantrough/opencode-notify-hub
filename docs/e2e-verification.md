# End-to-End Verification Matrix

Run this matrix against an isolated staging gateway with synthetic accounts.
Never use production credentials or attach unsanitized notification contents to
public issues.

## Environment record

Record before testing:

- gateway image tag and digest;
- plugin bundle checksum and OpenCode version;
- client version/checksum, OS, desktop environment, and architecture;
- staging gateway URL;
- Firebase project id (identifier only, no service-account JSON);
- test date and tester.

## Gateway smoke

| Scenario | Expected |
| --- | --- |
| Live and ready health | Both return 200 |
| Register, verify, login | Account authenticates |
| Refresh rotation | New refresh works; reused old refresh is rejected/revoked |
| Device CRUD | User can create/list/update/delete only owned devices |
| Ingest-key lifecycle | Secret appears once; successful event updates last used; list omits secret; revoke blocks use |
| Valid HMAC event | 202, `deduplicated:false` |
| Duplicate event id | 202, `deduplicated:true` |
| Tampered body or stale timestamp | 401 |
| Cross-user isolation | Account B receives none of account A's events |
| Backup and scratch restore | All seven tables restore successfully |

## OpenCode/client matrix

| Scenario | Linux | Windows | Android foreground | Android background/lock screen |
| --- | --- | --- | --- | --- |
| Heartbeats update status silently | [ ] | [ ] | [ ] | n/a |
| Completed: exactly one popup and history entry | [ ] | [ ] | [ ] | [ ] |
| Stopped: immediate, no later completed | [ ] | [ ] | [ ] | [ ] |
| Failed: exactly one alert | [ ] | [ ] | [ ] | [ ] |
| Question: immediate, labels only | [ ] | [ ] | [ ] | [ ] |
| Permission: immediate, bounded summary | [ ] | [ ] | [ ] | [ ] |
| Provider action: immediate | [ ] | [ ] | [ ] | [ ] |
| Child/subagent session ignored | [ ] | [ ] | [ ] | [ ] |
| Cross-user isolation | [ ] | [ ] | [ ] | [ ] |
| Offline desktop event is not replayed | [ ] | [ ] | n/a | n/a |
| Gateway restart reconnects (`1012`) | [ ] | [ ] | [ ] | n/a |
| Token expiry refreshes/reconnects (`4401`/Upgrade 401) | [ ] | [ ] | [ ] | n/a |

## Windows desktop checks

| Scenario | Windows |
| --- | --- |
| Tray left-click restores, shows, and focuses the window | [ ] |
| Tray right-click shows Open window, Pause notifications, and Quit | [ ] |
| Close hides the window and notifications continue | [ ] |
| Notification click restores the window after close and minimize | [ ] |
| Tray and notification behavior survives sleep/resume | [ ] |
| Tray behavior recovers after Explorer restarts | [ ] |
| Notification shortcut/AUMID follows the moved release directory | [ ] |
| Autostart survives restart and targets the tested executable | [ ] |
| Sign-out removes persisted credentials and leaves no active session | [ ] |
| Layout has no clipping at 100%, 125%, 150%, and 200% scaling | [ ] |
| Long titles, bodies, paths, and account identifiers remain readable | [ ] |

## Desktop tray sequence

1. Log in and verify a live WebSocket.
2. Close the window to the tray and wait longer than two gateway heartbeat
   intervals.
3. Trigger a real `opencode run` completion.
4. Trigger a question immediately afterward on the same connection.
5. Confirm both OS popups, both local History entries, branded titles, and the
   still-running tray process.
6. Restart the gateway while hidden and repeat after reconnect.

This sequence catches lifecycle disconnects, heartbeat failures, and accidental
socket removal after the first successful send.

## Android sequence

1. Verify client and gateway use the same staging Firebase project.
2. Grant Android notification permission.
3. Verify foreground WebSocket delivery.
4. Background the app and send terminal/question events.
5. Lock the device and repeat.
6. Tap a notification and verify navigation/history dedupe.
7. Disable the device server-side and verify push stops.

## Evidence

Keep sanitized:

- health/status codes and request ids;
- event ids, types, and timestamps;
- OS notification metadata without private prompt/question content;
- checksums of tested artifacts;
- test matrix result and known gaps.

Never retain passwords, verification/reset codes, access/refresh tokens, ingest
secrets, HMAC signatures, Firebase tokens, service-account JSON, private file
paths, or user conversation content.
