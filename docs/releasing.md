# Release Process

OpenCode Notify is currently pre-release. This checklist defines the gate for
the first public artifacts and later releases.

## Versioning

Use Semantic Versioning for public releases. Until compatibility commitments
are finalized, publish `0.x` versions. Keep package, OpenAPI, plugin artifact,
gateway image, and client versions intentionally mapped in the release notes;
they do not need to share one number if their compatibility is documented.

Update [CHANGELOG.md](../CHANGELOG.md) before tagging.

## Release gates

```bash
pnpm install --frozen-lockfile
flutter pub get
pnpm test
pnpm typecheck
pnpm build
pnpm --filter @notify/gateway test:integration
flutter analyze
(cd apps/client && flutter test)
(cd packages/notify_api && dart test)
bash apps/gateway/tests/deploy/image-smoke.sh
git diff --check
```

Also run manual E2E from [e2e-verification.md](e2e-verification.md) against a
staging gateway.

## Repository settings before going public

- Enable GitHub private vulnerability reporting, or replace the fallback in
  `SECURITY.md` with a tested private contact channel.
- Protect the default branch and require the CI workflow before merge.
- Create the `bug` and `enhancement` labels referenced by the issue forms.
- Enable Discussions if it will be the support channel described in
  `SUPPORT.md`; otherwise keep support in the issue tracker.
- Set the repository description, topics, public owner/contact links, and
  source URL metadata once the final repository URL is known.
- Review the full Git history for legacy infrastructure identifiers as well as
  secrets. If those identifiers must remain private, publish a reviewed clean
  snapshot or new public history instead of exposing the existing history.

## Artifacts

Publish checksums for:

- `session-notify.js` plugin bundle;
- Linux complete release bundle archive;
- Windows complete Release directory archive;
- signed Android APK and/or AAB;
- gateway container image by immutable tag and digest;
- source archive.

Every downloadable binary archive must include the repository `LICENSE` file.
Distribute the plugin as an archive containing both `session-notify.js` and
`LICENSE`; the gateway image carries the same notice at `/app/LICENSE`.

Never publish raw `.env`, Firebase service-account JSON, Android keystores,
`key.properties`, access/refresh tokens, ingest keys, or staging logs.

## Android signing and Firebase

Before the first Android artifact:

1. Replace placeholder Firebase options with the release Firebase project.
2. Configure and back up a private release keystore.
3. Remove debug signing from the release build.
4. Store signing and Firebase build inputs in CI secrets, not the repository.
5. Verify package id, app label, versionCode/versionName, notification
   permission, foreground delivery, background delivery, and lock-screen
   delivery.
6. Verify the final APK/AAB signature independently.

## Desktop checks

- Build Linux on a supported Linux runner and Windows on a Windows runner.
- Verify runtime server selection and persistence on each desktop target.
- Verify complete-bundle startup on a clean machine.
- Verify tray, autostart, sound, notification click, reconnect, and uninstall.
- Sign/notarize artifacts when the target platform ecosystem requires it.

## Gateway image

- Use an immutable version tag; do not deploy only `latest`.
- Record the image digest in release notes.
- Run migrations explicitly before switching traffic.
- Verify backup restore and rollback with staging data.
- Confirm reverse-proxy forwarding headers and WebSocket timeouts.

## Tag and publish

1. Ensure the working tree contains only intended release changes.
2. Merge through reviewed CI.
3. Create an annotated version tag.
4. Publish release notes from the changelog, including compatibility and known
   limitations.
5. Upload signed artifacts and checksums.
6. Deploy by immutable image digest and verify `/health/ready`.

Release automation should be added only after repository ownership, signing
secrets, target registries, and artifact naming are finalized.
