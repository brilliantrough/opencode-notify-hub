# Contributing

Thank you for contributing to OpenCode Notify. Keep changes focused, tested,
and free of credentials or personal data.

## Before you start

1. Search existing issues before filing a new one.
2. Use a discussion or issue for behavior changes that affect contracts,
   stored data, authentication, or notification semantics.
3. Report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).
4. Read [docs/development.md](docs/development.md) and
   [docs/testing.md](docs/testing.md).
5. Agent-assisted and cross-device work follows
   [docs/agent-workflow.md](docs/agent-workflow.md).

## Development workflow

```bash
corepack enable
pnpm install --frozen-lockfile
flutter pub get
pnpm typecheck
pnpm test
pnpm build
```

Run the focused tests for your component while developing, then run the full
relevant suites before submitting. Gateway integration tests require Docker.

## Pull requests

- Explain the problem and the behavioral change.
- Add or update tests for changed behavior.
- Update user, operator, API, or privacy documentation when the public surface
  changes.
- Keep generated OpenAPI/Dart output synchronized when contracts change.
- Do not include `.env` files, access tokens, ingest keys, SMTP credentials,
  Firebase service accounts, signing keys, production logs, or user content.
- Do not rewrite unrelated code or generated files.

## Contract changes

When a gateway contract changes:

```bash
pnpm --filter @notify/contracts generate:openapi
pnpm --filter @notify/contracts test
bash packages/notify_api/tool/regen.sh
```

Commit the schema, generated OpenAPI file, and generated Dart client together.
Regeneration must produce no unrelated lockfile or formatting churn.

## Style

- TypeScript uses the repository TypeScript configuration and existing local
  style. Run `pnpm typecheck`.
- Dart uses `dart format` and `flutter analyze`.
- Comments should explain non-obvious constraints, not restate code.
- Documentation examples must use reserved domains such as `example.com` and
  obvious placeholders, never real infrastructure.

## Commit and review expectations

Small, coherent commits are easier to review. Maintainers may request changes
for missing tests, unsafe migration behavior, protocol incompatibility,
credential exposure, or undocumented user-facing behavior.

Participation is governed by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
