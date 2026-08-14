# Issue Tracker: GitHub

Issues and PRDs for `brilliantrough/opencode-notify-hub` live as GitHub Issues. Use the `gh` CLI from this repository for all operations.

## Conventions

- Create issues with `gh issue create`.
- Read issues and comments with `gh issue view <number> --comments`.
- Apply and remove labels with `gh issue edit`.
- Close completed or rejected work with `gh issue close` and a concise comment.

## Pull Requests As A Triage Surface

External pull requests are not treated as incoming feature requests. Triage GitHub Issues only; do not pull collaborator or external PRs into the issue state machine.

## Skill Operations

When a skill says to publish to the issue tracker, create a GitHub Issue in this repository. When a skill requests a ticket, fetch the issue body, comments, and labels.
