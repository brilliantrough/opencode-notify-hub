# Multi-Device Agent Workflow

This workflow lets agents on Linux, Windows, and other trusted development
machines collaborate through GitHub without sharing mutable checkouts or
credentials. Branches and pull requests carry code and verification evidence;
GitHub Issues define ownership when tasks cross machines or agents.

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

For solo maintainer work, define the task in the branch and pull request. Create
or claim a GitHub Issue before editing when multiple machines or agents need to
coordinate ownership or handoff. The task description must state:

- problem and user-visible outcome;
- files or component likely owned by the change;
- acceptance criteria;
- required target OS and test environment;
- commands or E2E steps that must pass;
- security, privacy, protocol, migration, and release impact;
- dependencies on other Issues.

For coordinated work, comment that the task is claimed, including the branch
name and development-machine platform. Do not claim a task already assigned or
actively claimed.

Recommended labels:

- platform: `windows`, `linux`, `android`, `cross-platform`;
- component: `client`, `plugin`, `gateway`, `contracts`, `deployment`, `docs`;
- kind: `bug`, `enhancement`, `testing`, `release`, `security`;
- state: `blocked`, `needs-reproduction`, `needs-review`.

## Branch and checkout isolation

Use a dedicated branch per task:

```bash
git fetch origin
git switch main
git pull --ff-only
git switch -c <platform-or-component>/<short-description>
```

If multiple agents run on one machine, give each agent a separate clone or
worktree:

```bash
git fetch origin
git worktree add ../opencode-notify-<task> \
  -b <platform-or-component>/<short-description> origin/main
```

Rules:

- Never run two writing agents in the same worktree.
- Never let two tasks share a branch.
- Never commit directly to `main`.
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
5. Run the required component and platform gates before opening the PR.
6. Update documentation when behavior, configuration, data, API, or operations
   change.
7. Commit a coherent change and push only the issue branch.

Common repository gates:

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
require Docker. Never mark a platform verified from unit tests alone.

## Pull request contract

Open a PR against `main`. Link a coordinated Issue with `Closes #<number>` when
one exists. Include:

- concise behavioral summary;
- risk and compatibility notes;
- exact verification commands and results;
- target OS, version, architecture, and display environment when relevant;
- sanitized screenshots or logs for native UI/E2E behavior;
- explicit list of untested platforms;
- migration, deployment, signing, or credential implications.

The reviewing agent should inspect the full diff, reproduce high-risk behavior,
and check that tests can fail on the reported bug. The implementing agent must
not approve its own PR. Merge through GitHub after required checks pass; use the
repository's chosen merge policy consistently.

## Cross-machine handoff

When an agent cannot finish on its current OS, push the branch and leave a
handoff in the PR or coordinated Issue containing:

- branch and latest commit SHA;
- what is complete;
- current failure or unanswered question;
- exact next command;
- expected result;
- relevant files;
- tests already run and tests still required;
- confirmation that logs and artifacts are sanitized.

The receiving agent fetches the existing branch rather than recreating the
work:

```bash
git fetch origin
git switch --track origin/<branch-name>
```

For example, a Linux agent can implement shared Dart tests and push the branch;
a Windows agent then validates native tray, notification, packaging, and DPI
behavior on the same commit.

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

Configure the repository before parallel agent work increases:

1. Protect `main`; require pull requests and passing CI.
2. Block force pushes and branch deletion on `main`.
3. Require branches to be current before merge for release-critical changes.
4. Enable private vulnerability reporting.
5. Create the component/platform/state labels above.
6. Create milestones matching the roadmap phases.
7. Use a GitHub Project only for live status; keep coordinated requirements in
   Issues and architecture/operations decisions in versioned documentation.
8. Limit Actions permissions to read-only by default and grant write access per
   job only when required.

GitHub remains the coordination boundary: an agent may have repository access,
but work is not considered integrated until it is reviewed, verified, and
merged through a pull request.

## First Windows agent brief

For solo work, create branch `windows/dev-node`. For coordinated work, create or
claim a Roadmap P0 provisioning Issue and use an issue-numbered branch. Then
give the Windows agent this repository-local assignment:

```text
Work only on Windows development-node provisioning. Read ROADMAP.md,
docs/agent-workflow.md, docs/client-setup.md, and CONTRIBUTING.md first. Create
the task branch from origin/main. Verify the toolchain, bootstrap the repo, run
analysis/tests, attempt a Windows release build with a staging gateway URL, and
document every prerequisite or failure. Do not implement unrelated product
features, use production credentials, commit generated build output, or push to
main. Push the task branch and open a PR with sanitized command results and
follow-up tasks for native Windows defects.
```

This brief deliberately separates environment provisioning from tray,
notification, DPI, autostart, and packaging fixes. That keeps the first Windows
pull request reviewable and makes later Issues independently assignable.
