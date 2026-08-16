# OpenCode Notify Client

Flutter client for Linux, Windows, and Android. It connects to an OpenCode
Notify gateway, manages devices and ingest keys, receives realtime/FCM alerts,
and stores a bounded local history.

Start with the repository documentation:

- [Client user guide](../../docs/client-guide.md)
- [Build setup](../../docs/client-setup.md)
- [Development guide](../../docs/development.md)
- [Testing guide](../../docs/testing.md)

Run the client and select the server from the login page or settings:

```bash
flutter run -d linux
```

The selected HTTPS origin is persisted locally. Changing it signs out the
current account so credentials are never reused against another server.

The checked-in Android Firebase configuration is a placeholder. Do not publish
an Android artifact until Firebase and release signing are configured as
described in the build and release guides.
