# Multi-Device Agent Workflow

This repository is maintained sequentially from trusted Linux and Windows
development machines. `origin/main` is the shared development and handoff
boundary: each machine starts from the latest main, reviews what the previous
machine changed, continues the same codebase, and pushes the verified result
back to main. Task branches are required only when the maintainer explicitly
runs concurrent work or when an external contribution needs review.

## Repository setup per machine

Authenticate GitHub using a machine-appropriate SSH key or GitHub CLI login.
Do not copy a private SSH key between machines. Grant each machine its own
credential and revoke it independently when needed.

```bash
git clone git@github.com:brilliantrough/opencode-notify-hub.git
cd opencode-notify-hub
git switch main
git pull --ff-only
```

On PowerShell, the Git commands are the same. Follow
[client-setup.md](client-setup.md) for platform toolchains.

Configure a public commit identity on each machine. Prefer a GitHub `noreply`
address when personal email disclosure is not intended:

```bash
git config user.name "<GitHub username>"
git config user.email "<GitHub noreply address>"
```

## Task contract

For normal sequential maintainer work, the current conversation and project
memory define the task. Create or claim a GitHub Issue when work needs durable
tracking, spans multiple agents concurrently, or will be submitted as a pull
request. A coordinated task description should state:

- problem and user-visible outcome;
- files or component likely owned by the change;
- acceptance criteria;
- required target OS and test environment;
- commands or E2E steps that must pass;
- security, privacy, protocol, migration, and release impact;
- dependencies on other Issues.

For concurrent work, record the branch name, development-machine platform, and
owned files or components. Do not start overlapping edits until the maintainer
has assigned the merge boundary.

Recommended labels:

- platform: `windows`, `linux`, `android`, `cross-platform`;
- component: `client`, `plugin`, `gateway`, `contracts`, `deployment`, `docs`;
- kind: `bug`, `enhancement`, `testing`, `release`, `security`;
- state: `blocked`, `needs-reproduction`, `needs-review`.

## Shared main and concurrent work

Normal sequential work starts by synchronizing the shared main:

```bash
git fetch origin
git switch main
git pull --ff-only
git status --short
git log --oneline -10
```

Before editing, inspect commits made by the other development machine and
verify that its client, gateway, contract, deployment, and documentation
changes are present locally. Do not treat Linux and Windows as independent
products or overwrite platform-specific behavior with an older local copy.

When the maintainer explicitly authorizes concurrent work, create a task branch
from the current `origin/main` and use a separate clone or worktree:

```bash
git fetch origin
git worktree add ../opencode-notify-<task> \
  -b <platform-or-component>/<short-description> origin/main
```

Rules:

- Never run two writing agents in the same worktree.
- The maintainer's sequential Linux and Windows agents may commit and push
  directly to `main` after required verification.
- Concurrent tasks must use separate branches and worktrees until the
  maintainer requests integration.
- Fetch immediately before integration or push; if main advanced, inspect and
  merge the other machine's work before continuing.
- Never force-push a shared branch.
- Never use destructive reset/clean commands to handle changes from another
  agent; stop and inspect ownership instead.
- Keep generated contract changes in the same pull request as their schema
  source.

## Implementation loop

1. Reproduce the issue or establish a failing test.
2. Make the smallest change that satisfies the acceptance criteria.
3. Add focused regression tests at the behavior boundary.
4. Run focused tests while developing.
5. Run only the affected component checks needed for the change's risk. Do not
   trigger or reproduce the full cross-platform CI matrix by default.
6. Update documentation when behavior, configuration, data, API, or operations
   change.
7. Re-fetch, inspect the final diff, commit a coherent change, and push the
   current shared main or explicitly assigned task branch.

Available repository checks (select the affected subset):

```bash
pnpm docs:check
pnpm typecheck
pnpm test
pnpm build

flutter analyze
(cd apps/client && flutter test)
(cd packages/notify_api && dart test)
```

Desktop builds must run on the target OS. Gateway integration and image tests
require Docker. The maintainer owns final desktop UI acceptance; an Agent should
not automate difficult native UI flows unless explicitly asked to diagnose one.

Direct pushes to shared `main` do not trigger GitHub CI. The workflow runs for
pull requests or by explicit manual dispatch. A release request made after the
maintainer has run the application is authorization to build and publish files,
not a request to repeat the full automated or interactive test matrix.

## Pull request contract

Pull requests are used for external contributions, review-sensitive work, and
explicitly concurrent tasks. They are not required for the maintainer's normal
sequential cross-machine handoff. When a PR is used, link a coordinated Issue
with `Closes #<number>` when one exists and include:

- concise behavioral summary;
- risk and compatibility notes;
- exact verification commands and results;
- target OS, version, architecture, and display environment when relevant;
- sanitized screenshots or logs for native UI/E2E behavior;
- explicit list of untested platforms;
- migration, deployment, signing, or credential implications.

The reviewing agent should inspect the full diff, reproduce high-risk behavior,
and check that tests can fail on the reported bug. The implementing agent must
not approve its own PR. Merge through GitHub after the checks requested for that
PR pass; use the repository's chosen merge policy consistently.

## Cross-machine handoff

At the end of work on one machine, push the verified commit to `origin/main`
and update the ignored `docs/project_memory/current-state.md`. The handoff must
contain:

- pushed commit SHA and the confirmed `origin/main` SHA;
- what is complete;
- current failure or unanswered question;
- exact next command;
- expected result;
- relevant files;
- tests already run and tests still required;
- confirmation that logs and artifacts are sanitized.

The receiving machine synchronizes main before making any edits:

```bash
git fetch origin
git switch main
git pull --ff-only
git status --short
git log --oneline -10
```

For example, Windows may update native tray behavior and Gateway logic in one
turn and push main; Linux then fetches that exact revision, preserves both
changes, adds Linux validation or follow-up work, and pushes the next main
revision. If both machines work concurrently, the maintainer will explicitly
request a branch merge before either side pushes the integrated result.

## Credentials and production access

Repository access does not imply permission to expose production credentials to
an agent. Follow these constraints on every machine:

- Use staging accounts, ingest keys, SMTP, Firebase, databases, and gateway URLs
  for development and E2E tests.
- Keep `.env`, Firebase JSON, certificates, signing keys, keystores, tokens, and
  database dumps outside the repository.
- Store CI secrets in GitHub Environments with the minimum required scope and
  protected deployment approval.
- Do not paste secrets into prompts, Issue bodies, PRs, terminal transcripts, or
  screenshots.
- Rotate any credential that appears in logs or agent context.
- Production deploy and release-signing jobs require explicit maintainer
  approval, even when an agent prepared the change.

## Maintainer setup on GitHub

Configure the repository for safe shared-main maintenance:

1. Block force pushes and branch deletion on `main`.
2. Run CI on pull requests and explicit manual dispatch, not routine direct
   pushes or release tags.
3. Require concurrent branches to be current before release-critical merges.
4. Enable private vulnerability reporting.
5. Create the component/platform/state labels above.
6. Create milestones matching the roadmap phases.
7. Use a GitHub Project only for live status; keep coordinated requirements in
   Issues and architecture/operations decisions in versioned documentation.
8. Limit Actions permissions to read-only by default and grant write access per
   job only when required.

GitHub remains the coordination boundary: work is not handed off until it is
reviewed, verified, and present on `origin/main` (or on an explicitly assigned
concurrent branch awaiting integration).

## Machine handoff brief

Use this repository-local assignment when moving development to the other
machine:

```text
Read docs/project_memory/current-state.md, docs/agent-workflow.md, the latest
origin/main commits, and the relevant component documentation first. Fast-
forward local main before editing. Treat changes from the previous Linux or
Windows machine as part of the same product state, including shared server
logic. Preserve them while continuing the requested work. Run the available
cross-platform gates plus native checks for this machine, remove environment-
only generated drift, update project memory, and push the verified commit to
origin/main. Use a task branch only when the maintainer explicitly says work is
concurrent and requests a later merge.
```
