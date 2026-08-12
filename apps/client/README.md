# OpenCode Notify Client

Flutter client for Linux, Windows, and Android. It connects to an OpenCode
Notify gateway, manages devices and ingest keys, receives realtime/FCM alerts,
and stores a bounded local history.

Start with the repository documentation:

- [Client user guide](../../docs/client-guide.md)
- [Build setup](../../docs/client-setup.md)
- [Development guide](../../docs/development.md)
- [Testing guide](../../docs/testing.md)

The gateway URL is a required build-time choice for real use:

```bash
flutter run -d linux \
  --dart-define=GATEWAY_URL=https://notify.example.com
```

The checked-in Android Firebase configuration is a placeholder. Do not publish
an Android artifact until Firebase and release signing are configured as
described in the build and release guides.
