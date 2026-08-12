# Security Policy

## Supported versions

OpenCode Notify is currently pre-release. Security fixes are applied to the
latest commit on the default branch. After the first stable release, this file
will list supported release lines explicitly.

## Reporting a vulnerability

Do not open a public issue for a suspected vulnerability.

Use GitHub's **Security > Report a vulnerability** private reporting flow. If
private vulnerability reporting is unavailable, contact a maintainer privately
through the project owner's profile and include only enough information to
establish a secure follow-up channel.

Please include:

- affected component and revision;
- reproduction steps or a minimal proof of concept;
- expected impact and required preconditions;
- whether credentials or personal data may have been exposed;
- any suggested mitigation.

Do not test against infrastructure or accounts you do not own. Do not include
live access tokens, ingest secrets, passwords, Firebase keys, signing keys, or
user conversation content in the report.

Maintainers will acknowledge a complete report, investigate it, coordinate a
fix and disclosure timeline, and credit the reporter when requested and safe.
No fixed response SLA is promised during the pre-release phase.

## Security model

The high-level trust boundaries and credential lifecycle are documented in
[docs/architecture.md](docs/architecture.md). Data collection and retention are
documented in [PRIVACY.md](PRIVACY.md).
