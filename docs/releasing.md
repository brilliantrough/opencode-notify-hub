# Release Process

OpenCode Notify publishes one GitHub Release per version. The Release has
separate assets for each platform/component; Linux and Windows clients and the
Plugin must never be hidden inside one combined archive.

This document is the canonical Release SOP for both development agents. The
maintainer designates one Release coordinator for each release; it may be the
Linux or Windows agent. Linux builds the Linux client and Plugin, Windows builds
the Windows client, and the designated coordinator receives all complete
archives before creating the tag and uploading one GitHub Release.

## Ownership And Source Of Truth

- Every release artifact is built from one exact commit on `main`.
- Linux owns Contracts/OpenAPI, the Plugin build, and the Linux client build.
- Windows owns the Windows Release build and complete-bundle packaging. The
  maintainer owns final Windows native/UI acceptance.
- The maintainer-designated Release coordinator owns version preparation,
  cross-platform artifact collection, checksums, release notes, tag creation,
  and the single GitHub Release upload.
- Windows must not edit Plugin/Gateway/Contracts behavior or upload a partial
  `client.exe`. Neither platform creates the tag unless it is the designated
  coordinator and has verified all final assets.
- Release assets are platform-specific and independently downloadable.
- `docs/project_memory/linux-current-state.md` and
  `docs/project_memory/windows-current-state.md` are local coordination memory;
  they are not Release assets and must not be committed.

The Release coordinator must record the exact source SHA in the release notes.
If the Windows archive was built from another SHA, stop and rebuild it. Do not
silently mix artifacts from different commits.

## Versioning

Use Semantic Versioning for public releases. Until compatibility commitments are
finalized, use a `0.x` version and mark the GitHub Release as a pre-release.
For example:

```text
Version: 0.1.0-beta.1
Tag:     v0.1.0-beta.1
```

Keep component versions intentionally mapped in the release notes:

- Flutter client: `apps/client/pubspec.yaml`
- Plugin: `packages/plugin/package.json`
- Gateway image: immutable image tag and digest, when included in the release

Update `CHANGELOG.md` before the release-preparation commit. Do not tag a
working tree containing only local version edits.

## Asset Layout

The first desktop/Plugin beta publishes these separate assets:

```text
opencode-notify-client-linux-x64-<version>.tar.gz
opencode-notify-client-windows-x64-<version>.zip
opencode-notify-plugin-<version>.zip
SHA256SUMS.txt
```

The Linux and Windows archives contain the complete runtime bundle and the
repository `LICENSE` file. The Plugin archive contains:

```text
session-notify.js
LICENSE
PLUGIN-INSTALL.md
```

The Plugin is a single self-contained ESM file. Do not publish its `dist`
directory, source tree, or a `node_modules` directory as the install artifact.

Do not publish these as Release assets:

- `client.exe` without the rest of the Windows Release directory;
- a Linux executable without its Flutter bundle;
- raw `session-notify.js` without `LICENSE` and install instructions;
- CI artifacts downloaded directly from Actions;
- `.env` files, ingest keys, Firebase service-account JSON, keystores,
  `key.properties`, access/refresh tokens, staging logs, or production logs;
- Android APK/AAB until Firebase configuration, signing, and Android release
  gates are complete.

The Gateway is not bundled into either desktop archive. Publish its immutable
container image tag and digest in the release notes or a separate operator
release record.

## Release Verification Policy

The maintainer performs final application and desktop UI acceptance. A
maintainer statement that the application has been tested and a request to
release are release authorization. Release agents must not repeat expensive
interactive UI flows or the full cross-platform test matrix unless explicitly
asked to diagnose a failure.

For normal Linux development, use focused, risk-based checks for the changed
component. For Windows alignment, synchronize the shared client code, resolve
dependencies, fix only observed compile/native blockers, and build the complete
Release directory. The Windows maintainer performs the final manual run.

The following checks remain available for pull requests, explicit diagnostic
requests, or a release risk that cannot be covered locally, but are not default
release gates:

```bash
pnpm install --frozen-lockfile
flutter pub get
pnpm docs:check
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

Do not trigger GitHub CI for routine direct pushes or releases. The workflow is
reserved for pull requests and explicit manual dispatch. A successful CI run is
not required before a maintainer-authorized file release.

Before the first public release, also:

- enable GitHub private vulnerability reporting or configure the private
  security contact documented in `SECURITY.md`;
- protect `main` according to the maintainer's chosen direct-push/PR policy;
- create the issue labels referenced by the issue forms;
- confirm the repository description, topics, support channel, and public
  owner/contact links;
- review Git history for secrets and private infrastructure identifiers.

## Phase 1: Prepare The Release

The maintainer-designated Release coordinator performs this phase from the
shared `main` checkout. Source ownership boundaries remain unchanged.

Shell examples below use Bash. A Windows coordinator may use PowerShell
equivalents (`Get-FileHash`, `Compress-Archive`, and `gh release create`) while
preserving the same source-SHA, archive-layout, checksum, and single-upload
requirements.

1. Start from a clean checkout and update `main`:

   ```bash
   git fetch origin --prune
   git switch main
   git pull --ff-only origin main
   test -z "$(git status --porcelain)"
   ```

2. Choose the version, update `CHANGELOG.md`, and update the component version
   fields. Commit and push the release-preparation change to `main`. Direct
   pushes do not trigger CI; do not manually dispatch it for routine releases.

3. Record the exact release-preparation SHA as `RELEASE_SHA`. Do not wait for or
   trigger GitHub CI unless the maintainer explicitly requests it:

   ```bash
   export RELEASE_VERSION="0.1.0-beta.2"
   export RELEASE_SHA="$(git rev-parse HEAD)"
   test "$(git branch --show-current)" = main
   test "$(git rev-parse origin/main)" = "$RELEASE_SHA"
   test -z "$(git status --porcelain)"
   ```

4. Send both platform agents the exact `RELEASE_SHA` and `RELEASE_VERSION`.
   Neither platform may build from a stale branch or uncommitted worktree.

## Phase 2: Build Linux And Plugin

Run these commands on Linux from `main@$RELEASE_SHA` after the maintainer has
authorized the release:

```bash
test "$(git rev-parse HEAD)" = "$RELEASE_SHA"

pnpm --filter @notify/plugin build
(cd apps/client && flutter build linux --release --no-pub)
```

Stage the complete Linux bundle and Plugin archive. The following example uses
an external temporary directory so release staging cannot pollute Git:

```bash
set -eu

: "${RELEASE_VERSION:?set RELEASE_VERSION}"
: "${RELEASE_SHA:?set RELEASE_SHA}"
REPO="$(git rev-parse --show-toplevel)"
RELEASE_DIR="$(mktemp -d)"
STAGE="$RELEASE_DIR/stage"
LINUX_DIR="opencode-notify-client-linux-x64-${RELEASE_VERSION}"
PLUGIN_DIR="opencode-notify-plugin-${RELEASE_VERSION}"

mkdir -p "$STAGE/$LINUX_DIR" "$STAGE/$PLUGIN_DIR"
cp -a "$REPO/apps/client/build/linux/x64/release/bundle/." "$STAGE/$LINUX_DIR/"
cp "$REPO/LICENSE" "$STAGE/$LINUX_DIR/LICENSE"
cp "$REPO/packages/plugin/dist/session-notify.js" \
  "$STAGE/$PLUGIN_DIR/session-notify.js"
cp "$REPO/LICENSE" "$STAGE/$PLUGIN_DIR/LICENSE"
cp "$REPO/docs/plugin-install.md" "$STAGE/$PLUGIN_DIR/PLUGIN-INSTALL.md"

tar -C "$STAGE" -czf \
  "$RELEASE_DIR/opencode-notify-client-linux-x64-${RELEASE_VERSION}.tar.gz" \
  "$LINUX_DIR"
(
  cd "$STAGE/$PLUGIN_DIR"
  zip -q -r "$RELEASE_DIR/opencode-notify-plugin-${RELEASE_VERSION}.zip" .
)

sha256sum \
  "$RELEASE_DIR/opencode-notify-client-linux-x64-${RELEASE_VERSION}.tar.gz" \
  "$RELEASE_DIR/opencode-notify-plugin-${RELEASE_VERSION}.zip"

printf 'Release staging directory: %s\n' "$RELEASE_DIR"
```

Inspect the archive contents before upload. The Linux archive must contain the
Flutter executable, its `data/` directory, native libraries, and `LICENSE`.
The Plugin archive must contain exactly the install file, license, and install
instructions.

## Phase 3: Build And Transfer Windows

The Windows agent performs this phase from a clean checkout of the same
`main@$RELEASE_SHA`:

```powershell
git fetch origin --prune
git switch main
git pull --ff-only origin main

$expected = "<RELEASE_SHA>"
$actual = (git rev-parse HEAD).Trim()
if ($actual -ne $expected) { throw "Wrong release SHA: $actual" }
if (git status --porcelain) { throw "Release worktree is not clean" }
```

Resolve dependencies and build the Windows Release bundle from the repository
root. Do not run the full Windows test matrix unless explicitly requested or
needed to diagnose a build/native failure:

```powershell
corepack enable
pnpm install --frozen-lockfile
flutter pub get

Set-Location apps\client
flutter build windows --release
```

The Windows agent must inspect and package the entire directory:

```text
apps\client\build\windows\x64\runner\Release\
```

Create a versioned archive containing a top-level directory and `LICENSE`:

```powershell
$version = "0.1.0-beta.2"
$name = "opencode-notify-client-windows-x64-$version"
$stage = Join-Path $env:TEMP $name
$archive = Join-Path $env:TEMP "$name.zip"

Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $stage | Out-Null
Copy-Item "build\windows\x64\runner\Release\*" $stage -Recurse -Force
Copy-Item "..\..\LICENSE" (Join-Path $stage "LICENSE") -Force
Compress-Archive -Path $stage -DestinationPath $archive -Force
Get-FileHash $archive -Algorithm SHA256
```

Transfer the complete ZIP to the designated Release coordinator out of band.
Also send:

- the exact `RELEASE_SHA` and version;
- the ZIP filename and SHA-256;
- any focused checks run, manual acceptance status supplied by the maintainer,
  and remaining risks;
- checksums for `client.exe`, `data/app.so`, native notification/audio DLLs,
  and the complete ZIP.

The Windows archive is a handoff artifact, not a repository file. The Windows
agent must not push a tag or upload the GitHub Release unless the maintainer has
designated it as the coordinator and it has received every final platform asset.

## Phase 4: Coordinator Verification

Copy the transferred Windows ZIP into the same external `$RELEASE_DIR` used in
Phase 2. The designated coordinator verifies it before publishing:

```bash
unzip -l "$RELEASE_DIR/opencode-notify-client-windows-x64-${RELEASE_VERSION}.zip"
sha256sum \
  "$RELEASE_DIR/opencode-notify-client-windows-x64-${RELEASE_VERSION}.zip"
```

Confirm the archive has the complete Release directory, `client.exe`,
`data/app.so`, native DLLs, and `LICENSE`. Confirm the reported Windows hash
matches the transferred file and that the Windows SHA was built from the same
`RELEASE_SHA` as Linux.

Stage `SHA256SUMS.txt` only after all final assets are present:

```bash
sha256sum \
  "$RELEASE_DIR/opencode-notify-client-linux-x64-${RELEASE_VERSION}.tar.gz" \
  "$RELEASE_DIR/opencode-notify-client-windows-x64-${RELEASE_VERSION}.zip" \
  "$RELEASE_DIR/opencode-notify-plugin-${RELEASE_VERSION}.zip" \
  | sed "s#${RELEASE_DIR}/##" > "$RELEASE_DIR/SHA256SUMS.txt"
```

Review the checksums and archive listings. The Release asset set is exactly:

```text
opencode-notify-client-linux-x64-<version>.tar.gz
opencode-notify-client-windows-x64-<version>.zip
opencode-notify-plugin-<version>.zip
SHA256SUMS.txt
```

## Phase 5: Tag And Create The GitHub Release

Only the maintainer-designated Release coordinator creates the annotated tag and
publishes the Release, after all platform archives have been received and
file-verified. Write the final notes to `$RELEASE_DIR/release-notes.md`, using
the required content list below, before running these commands:

```bash
git -C "$REPO" status --short
git -C "$REPO" fetch origin --prune
git -C "$REPO" switch main
git -C "$REPO" pull --ff-only origin main
test "$(git -C "$REPO" rev-parse HEAD)" = "$RELEASE_SHA"
test -z "$(git -C "$REPO" status --porcelain)"

git -C "$REPO" tag -a "v${RELEASE_VERSION}" \
  -m "OpenCode Notify ${RELEASE_VERSION}"
git -C "$REPO" push origin "v${RELEASE_VERSION}"

(
  cd "$REPO"
  gh release create "v${RELEASE_VERSION}" \
    --title "OpenCode Notify ${RELEASE_VERSION}" \
    --prerelease \
    --notes-file "$RELEASE_DIR/release-notes.md" \
    "$RELEASE_DIR/opencode-notify-client-linux-x64-${RELEASE_VERSION}.tar.gz" \
    "$RELEASE_DIR/opencode-notify-client-windows-x64-${RELEASE_VERSION}.zip" \
    "$RELEASE_DIR/opencode-notify-plugin-${RELEASE_VERSION}.zip" \
    "$RELEASE_DIR/SHA256SUMS.txt"
)
```

Use `--prerelease` for beta versions. Omit it only for a release that has
passed the stable release gates. GitHub automatically provides source archives;
do not upload a second manually-created source archive.

Do not manually dispatch GitHub CI for the release commit or tag. The repository
workflow intentionally does not run on direct pushes or tags.

The release notes must include:

- version and exact source SHA;
- supported OpenCode version range;
- separate installation instructions for Linux, Windows, and Plugin;
- asset checksums or a link to `SHA256SUMS.txt`;
- unsigned/code-signing status and platform warnings;
- known limitations and unverified acceptance items;
- Gateway image tag and immutable digest, if a Gateway image is part of the
  release;
- explicit statement that Android is not included when Android release gates
  are incomplete.

## Gateway And Android

The Gateway is released independently from desktop assets. Use an immutable
container tag, record its digest in the notes, run migrations explicitly, and
verify `/health/ready`, WebSocket routing, backup, and rollback before changing
traffic.

Do not publish an Android APK/AAB until the release Firebase project, release
signing key, notification delivery, and install/upgrade gates are complete.

## Repository Safety

Never publish raw `.env`, Firebase service-account JSON, Android keystores,
`key.properties`, access/refresh tokens, ingest keys, or logs. Keep release
staging outside the repository, inspect `git status --short` after packaging,
and delete temporary archives only after the GitHub Release upload has been
verified.
