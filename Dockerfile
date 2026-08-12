# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Build stage: full (dev + prod) install, compile contracts then gateway.
# ---------------------------------------------------------------------------
FROM node:22-bookworm-slim AS build
WORKDIR /app

# Corepack supplies the pnpm version pinned by the root packageManager field
# (pnpm@9.15.0), keeping the toolchain reproducible.
RUN corepack enable

# Manifests first so the dependency layer caches independently of sources.
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./
COPY packages/contracts/package.json packages/contracts/package.json
COPY apps/gateway/package.json apps/gateway/package.json
RUN pnpm install --frozen-lockfile

COPY tsconfig.base.json ./
COPY packages/contracts ./packages/contracts
COPY apps/gateway ./apps/gateway

# Contracts first: the gateway build consumes its compiled dist.
RUN pnpm --filter @notify/contracts build \
  && pnpm --filter @notify/gateway build

# ---------------------------------------------------------------------------
# Runtime stage: production dependencies only, workspace layout preserved so
# the @notify/contracts symlink keeps resolving, non-root `node` user.
# ---------------------------------------------------------------------------
FROM node:22-bookworm-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production
LABEL org.opencontainers.image.licenses="MIT"

RUN corepack enable

COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./
COPY packages/contracts/package.json packages/contracts/package.json
COPY apps/gateway/package.json apps/gateway/package.json
RUN pnpm install --frozen-lockfile --prod
COPY LICENSE ./LICENSE

# Compiled output plus the committed Drizzle migrations: the readiness probe
# hashes the bundled SQL/meta files and the explicit migrate command applies
# them. The generated OpenAPI document is build-time only — nothing at
# runtime or in the probes reads it, so it is not shipped.
COPY --from=build /app/packages/contracts/dist ./packages/contracts/dist
COPY --from=build /app/apps/gateway/dist ./apps/gateway/dist
COPY apps/gateway/drizzle ./apps/gateway/drizzle

# Built-in unprivileged user from the node base image (uid/gid 1000).
USER node
EXPOSE 8080

WORKDIR /app/apps/gateway

# Default command: serve. Application startup never migrates; migrations
# ship in the image and run as an explicit command instead:
#   docker run --rm -e DATABASE_URL=... <image> \
#     node /app/apps/gateway/dist/db/migrate.js
CMD ["node", "dist/index.js"]
