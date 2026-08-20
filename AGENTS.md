## Agent skills

### Issue tracker

Issues and PRDs are tracked in GitHub Issues; external pull requests are not a triage request surface. See `docs/agents/issue-tracker.md`.

### Triage labels

The repository uses the five canonical engineering-skill triage labels. See `docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repository with a root glossary and root architectural decisions. See `docs/agents/domain.md`.

### Windows client work

Before changing or validating the Windows client, read
`docs/windows-agent-handoff.md` and follow its branch reconciliation and
lightweight source-alignment sequence.

### Verification and release policy

- The maintainer performs final desktop UI acceptance. When the maintainer says
  the application has been tested and requests a release, treat that as release
  authorization; do not repeat expensive automated or Agent-driven UI flows.
- Do not trigger GitHub CI for routine direct pushes or releases. CI is reserved
  for pull requests or an explicit maintainer request through the manual
  workflow.
- Linux development uses focused, risk-based local checks. Do not run the full
  repository/platform matrix by default when narrower tests cover the change.
- Shared client behavior is implemented and validated on Linux before the
  Windows handoff. Windows alignment should normally fast-forward the shared
  code, resolve dependencies, fix only observed compile/native blockers, build
  the complete Release directory, and leave interactive validation to the
  maintainer.
- Release work is file-oriented: verify one exact source SHA and version, build
  complete platform bundles, inspect archive contents, compute checksums, and
  publish the assets. See `docs/releasing.md`.
