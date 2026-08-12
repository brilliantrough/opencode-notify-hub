# Roadmap

OpenCode Notify is pre-release. The roadmap prioritizes a reproducible Windows
development node first, then closes desktop platform gaps before expanding the
release surface. Branches and pull requests are the source of truth for work in
progress; use GitHub Issues when work must be coordinated across machines or
agents. This file records sequencing and exit criteria.

## Working principles

- Build and test each desktop target on its native operating system. Flutter
  desktop applications are not cross-compiled.
- Keep gateway, plugin, contracts, and shared Dart behavior platform-neutral.
- Isolate platform-specific behavior behind the existing notification, tray,
  window, storage, and startup adapters.
- One branch, worktree, and pull request per task. Use an Issue when multiple
  machines or agents need ownership and handoff. Never let two agents write to
  the same checkout or branch.
- Merge only changes with reproducible verification and sanitized evidence.
- Keep production credentials, signing keys, Firebase service accounts, and
  user notification content outside repositories, prompts, logs, and issues.

## Start here

The next development session should run on the Windows machine and provision
the development node. A solo maintainer can use branch `windows/dev-node`; use
`issue-<number>-windows-dev-node` if the task is coordinated through an Issue.
Follow
[`docs/agent-workflow.md`](docs/agent-workflow.md).

The first Windows agent should stop after producing these artifacts:

- sanitized `flutter doctor -v`, `node --version`, `pnpm --version`, and
  `git --version` output;
- a documented, repeatable clone/bootstrap sequence;
- results from `flutter analyze` and `flutter test`;
- the first `flutter build windows --release` result;
- the complete list of runtime files in the release directory;
- a sanitized screenshot showing the unsigned client starts;
- follow-up tasks or Issues for every native failure found, without expanding
  the provisioning pull request into unrelated client fixes.

Use a staging gateway URL at build time. The first task must not receive a
production ingest key, Firebase service account, signing certificate, or
release-signing secret.

## P0: Windows development node

**Goal:** make a Windows machine independently usable by a human or agent to
clone, build, run, test, and submit Windows client changes.

### Deliverables

1. Provision a supported Windows 11 x64 machine with:
   - Git and GitHub authentication;
   - Flutter 3.44.9 stable;
   - Visual Studio 2022 with Desktop development with C++ and C++ ATL;
   - Node.js 22, Corepack, and pnpm 9.15.0;
   - Docker Desktop when gateway integration tests are required.
2. Clone the repository into a dedicated path. Each concurrent agent uses its
   own clone or `git worktree`; agents never share a mutable checkout.
3. Record a sanitized `flutter doctor -v` result and exact bootstrap commands in
   the Windows section of `docs/client-setup.md`.
4. Build the first unsigned Windows release bundle with the staging gateway:

   ```powershell
   flutter pub get
   flutter analyze
   flutter test
   flutter build windows --release `
     --dart-define=GATEWAY_URL=https://notify.example.com
   ```

5. Add a `windows-latest` CI job that at minimum resolves dependencies, runs
   analysis and tests, and builds the Windows release directory.
6. Upload the unsigned bundle as a CI artifact for maintainer testing. Do not
   describe it as a production release.

### Exit criteria

- A clean Windows clone can build without undocumented manual file changes.
- Windows CI passes from a pull request.
- The complete release directory starts on a second clean Windows account or
  machine.
- No production URL, account, ingest key, certificate, or signing key is stored
  in the repository or CI logs.

### Initial tasks

- `windows: provision and document the development node`
- `ci: add Windows client analysis, tests, build, and artifact upload`
- `windows: verify clean-machine release bundle startup`

## P1: Windows client parity

**Goal:** make the Windows client behavior match the verified Linux desktop
flow where Windows APIs permit it.

### Required flows

- Register, verify email, sign in, refresh credentials, and sign out.
- Register the Windows device and reconnect WebSocket sessions after gateway
  restart, token refresh, network loss, sleep, and resume.
- Show one native notification and one local history entry for each eligible
  event; heartbeat and resolved events remain silent.
- Play or suppress sound according to settings.
- Hide the close-requested window without exiting the process.
- Restore, show, and focus the main window from a notification click and tray
  menu.
- Left-click the tray icon to open the main window; right-click to show
  **Open window**, **Pause notifications**, and **Quit**.
- Enable, disable, and survive restart with launch-at-startup.
- Render correctly at 100%, 125%, 150%, and 200% display scaling.

### Known implementation checks

- Verify `tray_manager` Windows callback names. Its native implementation emits
  mouse-down callbacks, while the current Linux flow uses mouse-up.
- Replace `assets/tray/icon.ico` with a real multi-size ICO; a renamed PNG is not
  sufficient for the Windows native loader.
- Verify notification shortcut/AUMID creation by `local_notifier` and behavior
  when the application directory moves.
- Confirm Windows Credential Manager storage and deletion on sign-out.
- Verify autostart registry entries use the installed executable path.

### Exit criteria

- Every Windows column item in `docs/e2e-verification.md` has sanitized evidence
  from the tested commit and environment.
- Tray and notification restore behavior passes after close-to-tray, minimize,
  sleep/resume, and Explorer restart.
- No Windows-only conditional leaks into shared domain or protocol code without
  an explicit platform boundary and test.

### Initial tasks

- `windows: implement native tray click and context-menu behavior`
- `windows: replace the tray asset with a valid multi-size ICO`
- `windows: verify notification identity, click handling, and sound`
- `windows: verify close-to-tray, focus restoration, sleep, and resume`
- `windows: verify launch-at-startup and secure credential storage`
- `windows: complete DPI and long-text visual QA`

## P2: Reproducible desktop releases

**Goal:** produce installable, attributable, and upgradeable Linux and Windows
artifacts from tagged commits.

### Deliverables

- Choose Windows distribution format: signed installer or MSIX, with a stable
  application identity and install path.
- Choose the Linux distribution format while retaining the portable bundle.
- Add Authenticode signing for Windows and document certificate custody and
  rotation outside GitHub.
- Build release artifacts only from protected tags after all required checks.
- Publish checksums, source revision, gateway URL policy, license, release
  notes, and known limitations with every artifact.
- Add clean-machine install, upgrade, uninstall, autostart, tray, and
  notification smoke tests.
- Define compatibility policy among plugin, gateway, client, contracts, and
  database migrations.

### Exit criteria

- A tagged release can be reproduced from documented toolchains.
- Windows SmartScreen/signature inspection and Linux bundle smoke checks pass.
- Upgrade preserves credentials and settings; uninstall behavior is documented.

## P3: Android production readiness

**Goal:** replace development placeholders and validate foreground,
background, and lock-screen delivery.

### Deliverables

- Configure a release Firebase project without committing service credentials.
- Configure, back up, and document Android release signing.
- Test Android notification permission, FCM token lifecycle, deduplication,
  notification taps, process death, background, and lock-screen delivery.
- Add signed APK/AAB release automation and signature verification.
- Document upgrade and Firebase/signing recovery procedures.

### Exit criteria

- Every Android column item in `docs/e2e-verification.md` passes.
- A signed update installs over the prior release without data loss.
- Gateway and client Firebase project identities are verified in release gates.

## P4: Operations and protocol stability

**Goal:** make self-hosting upgrades predictable for operators and clients.

### Deliverables

- Add a compatibility matrix and explicit deprecation policy.
- Add staging deployment and gateway migration/rollback automation.
- Exercise scheduled backup and scratch restore in CI or a controlled staging
  environment.
- Add observable delivery/reconnect metrics without storing notification
  content or credentials.
- Add load and soak tests for WebSocket connections, event ingestion, token
  refresh, gateway restart, and clock skew.
- Add a self-service account-deletion flow with documented backup retention.

### Exit criteria

- A gateway upgrade and rollback are rehearsed against staging data.
- Supported old clients fail compatibly or continue to function as documented.
- Security and privacy documentation matches measured runtime behavior.

## P5: Product expansion

Work in this phase starts only after Windows and Android release gates are
complete.

Candidate work:

- Runtime gateway profiles for users who connect to multiple self-hosted
  instances.
- Notification routing and quiet-hour policies.
- Localization and accessibility expansion.
- Additional desktop targets after platform ownership exists.
- Operator administration and account lifecycle tooling.

Each candidate requires an issue describing protocol, privacy, migration,
compatibility, and rollback implications before implementation begins.

## Status updates

Update this roadmap only when priorities, phase scope, or exit criteria change.
Use GitHub milestones for dates and Issues/Projects when live coordination is
needed. Every completed task should have a pull request linked to the exact
verification evidence required by the phase.
