import cors from "@fastify/cors";
import type { PostgresJsDatabase } from "drizzle-orm/postgres-js";
import Fastify, { type FastifyError, type FastifyInstance } from "fastify";
import type { DestinationStream } from "pino";

import { loadConfig, type GatewayConfig } from "./config.js";
import type * as schema from "./db/schema.js";
import { healthRoutes } from "./health/health.routes.js";
import { systemClock, type Clock } from "./lib/clock.js";
import { clientErrorCode, ErrorCodes, errorBody } from "./lib/errors.js";
import { DrizzleAuthRepository } from "./modules/auth/auth.repository.js";
import { authRoutes } from "./modules/auth/auth.routes.js";
import { AuthService } from "./modules/auth/auth.service.js";
import { DrizzleDeviceRepository } from "./modules/devices/devices.repository.js";
import { deviceRoutes } from "./modules/devices/devices.routes.js";
import { CompositeEventDispatcher } from "./modules/events/dispatcher.js";
import { eventRoutes, type EventDispatcher } from "./modules/events/events.routes.js";
import { messagingFromServiceAccountJson } from "./modules/fcm/firebase-app.js";
import { FirebaseAdminFcmSender } from "./modules/fcm/firebase-fcm-sender.js";
import type { FcmSender } from "./modules/fcm/fcm-sender.js";
import { DrizzleIngestKeyRepository } from "./modules/ingest-keys/ingest-keys.repository.js";
import { ingestKeyRoutes } from "./modules/ingest-keys/ingest-keys.routes.js";
import { IngestKeyService } from "./modules/ingest-keys/ingest-keys.service.js";
import type { Mailer } from "./modules/mail/mailer.js";
import { NodemailerMailer } from "./modules/mail/nodemailer.mailer.js";
import { controlWsRoutes } from "./modules/control/control-ws.routes.js";
import { InstanceRegistry } from "./modules/control/instance-registry.js";
import { pendingInteractionsRoutes } from "./modules/control/pending-interactions.routes.js";
import {
  ConnectionRegistry,
  WS_CLOSE_SERVER_SHUTDOWN,
} from "./modules/realtime/connection-registry.js";
import { wsRoutes } from "./modules/realtime/ws.routes.js";
import { createAccessTokens, registerJwtAuth } from "./plugins/jwt.js";
import { registerRateLimit } from "./plugins/rate-limit.js";
import { registerWebsocket } from "./plugins/websocket.js";

export interface GatewayDeps {
  /** Explicit configuration; defaults to `loadConfig()` (process.env). */
  config?: GatewayConfig;
  /** Optional log destination; tests capture log output through it. */
  loggerStream?: DestinationStream;
  /**
   * Database handle. When provided, the auth routes are mounted; the app
   * factory itself never opens connections (the entrypoint owns the handle
   * and its lifecycle).
   */
  db?: PostgresJsDatabase<typeof schema>;
  /** Outbound mail adapter; defaults to Nodemailer over `config.smtp`. */
  mailer?: Mailer;
  /** Time source; defaults to the wall clock. Tests inject a fake. */
  clock?: Clock;
  /**
   * Event fanout seam for POST /v1/events; defaults to the production
   * composite: WebSocket fanout through the connection registry plus
   * Android push for actionable events.
   */
  eventDispatcher?: EventDispatcher;
  /**
   * Push sender used by the default composite dispatcher; tests inject a
   * fake (or the helpers' no-op) so no Firebase app is initialized and no
   * network is touched. Defaults to a FirebaseAdminFcmSender built from
   * `config.firebaseServiceAccountJson`. Ignored when `eventDispatcher` is
   * supplied.
   */
  fcmSender?: FcmSender;
  /** Realtime tuning; tests shrink the heartbeat interval. */
  realtime?: { pingIntervalMs?: number };
  /**
   * Control-channel tuning; tests shrink the pending-snapshot timeout so
   * partial-snapshot behavior is exercised without real waits.
   */
  control?: { snapshotTimeoutMs?: number };
}

/**
 * Pino redaction, configured centrally from the start (design doc section
 * 13: logs must never contain passwords, tokens, ingest secrets, HMAC
 * signatures, FCM tokens, or question/permission content). Explicit paths
 * cover the request shapes of the planned modules; the wildcard paths catch
 * the same fields logged at any other depth. Applies to every log line of
 * the instance, including request logs.
 */
const LOG_REDACT_PATHS = [
  // Request headers.
  "req.headers.authorization",
  "req.headers['x-notify-signature']",
  // Request body credentials and tokens.
  "body.password",
  "body.newPassword",
  "body.refreshToken",
  "body.token",
  "body.secret",
  "body.fcmToken",
  // One-time SMTP codes (email verification now, password reset later).
  "body.code",
  // Event payload content.
  "body.payload.questions",
  "body.payload.permission",
  "body.payload.providerAction",
  "body.payload.summary",
  // Remote-unblock pending interactions: full question/permission payloads
  // must never reach the logs regardless of nesting (wildcards below match
  // exactly one segment, so array-index segments inside `interactions` are
  // covered by the deepest wildcard). `session` stays visible so operators
  // can correlate a log line to a session without the sensitive content.
  "body.interactions",
  // Catch-alls for the same fields logged at any other depth: one wildcard
  // per nesting level (fast-redact wildcards match exactly one segment), so
  // credentials, tokens, codes, signatures, FCM tokens, event payloads, and
  // interaction question/permission content are redacted however deep inside
  // a logged object they end up.
  ...[
    "password",
    "newPassword",
    "refreshToken",
    "token",
    "secret",
    "code",
    "fcmToken",
    "signature",
    "payload",
    "interactions",
    "question",
    "questions",
    "permission",
    "patterns",
    "always",
    "options",
    "metadata",
    "providerAction",
    "summary",
  ].flatMap((key) => [`*.${key}`, `*.*.${key}`, `*.*.*.${key}`]),
];

const LOG_REDACT_CENSOR = "[redacted]";

/**
 * Build the gateway application. Never binds a port and never touches the
 * database, so tests drive it through `app.inject` and later tasks can
 * register their modules on the returned instance.
 */
export async function buildServer(deps: GatewayDeps = {}): Promise<FastifyInstance> {
  const config = deps.config ?? loadConfig();

  const app = Fastify({
    // Deployment assumption: the gateway only ever sits behind the mandated
    // reverse proxy (see index.ts / port.ts), which owns the client-facing
    // connection and sets a trustworthy X-Forwarded-For. Trusting it makes
    // request.ip the real client address, so the per-client-IP rate buckets
    // (auth endpoints, ingest pre-auth ceiling) key per end client instead
    // of collapsing onto the proxy's peer IP.
    trustProxy: true,
    logger: {
      level: config.logLevel,
      redact: { paths: LOG_REDACT_PATHS, censor: LOG_REDACT_CENSOR },
      ...(deps.loggerStream !== undefined ? { stream: deps.loggerStream } : {}),
    },
    ajv: {
      customOptions: {
        // The shared contract schemas declare additionalProperties: false;
        // Fastify's default removeAdditional would silently strip unknown
        // fields instead of rejecting them, so turn it off.
        removeAdditional: false,
      },
    },
  });

  // Liveness is DB-independent; readiness checks the database, the bundled
  // migration set, and the production Firebase initialization.
  await app.register(
    healthRoutes({
      ...(deps.db !== undefined ? { db: deps.db } : {}),
      firebaseServiceAccountJson: config.firebaseServiceAccountJson,
    }),
  );

  app.setNotFoundHandler(async (_request, reply) => {
    await reply.status(404).send(errorBody(ErrorCodes.NOT_FOUND, "Route not found"));
  });

  // Browser CORS from the configured ALLOWED_ORIGINS (exact, normalized
  // origins): matching Origins get allow headers, others get none (the
  // browser enforces). Requests without an Origin header — native clients —
  // are unaffected. The WebSocket Origin check lives in the ws route, since
  // browsers do not enforce CORS on sockets.
  await app.register(cors, { origin: config.allowedOrigins });

  // Opt-in rate limiting: only routes with a `config.rateLimit` policy (the
  // auth endpoints and the event-ingress pre-auth IP ceiling) are limited.
  // Registered before any route so the onRoute hook sees every module.
  await registerRateLimit(app);

  app.setErrorHandler((error: FastifyError, request, reply) => {
    if (error.validation) {
      reply
        .status(400)
        .send(errorBody(ErrorCodes.VALIDATION_FAILED, error.message));
      return;
    }
    const statusCode = error.statusCode ?? 500;
    if (statusCode >= 400 && statusCode < 500) {
      // Client errors keep their status and message in the contract shape.
      reply
        .status(statusCode)
        .send(errorBody(clientErrorCode(statusCode), error.message));
      return;
    }
    request.log.error(error);
    // Server errors: a genuine 5xx status (e.g. an AppError raised for a
    // retryable dependency outage) is preserved so orchestrators and
    // clients can react, but the body never carries internals.
    const status = statusCode >= 500 && statusCode < 600 ? statusCode : 500;
    if (status === 503) {
      reply
        .status(503)
        .send(errorBody(ErrorCodes.SERVICE_UNAVAILABLE, "Service unavailable"));
      return;
    }
    reply
      .status(status)
      .send(errorBody(ErrorCodes.INTERNAL, "Internal server error"));
  });

  // The auth module needs persistence; without a database handle the app
  // stays DB-free (tests, liveness-only embedding) and the routes are absent.
  // Registered last: Fastify plugins inherit the instance error handler only
  // when registered after `setErrorHandler`.
  if (deps.db !== undefined) {
    const clock = deps.clock ?? systemClock;
    // HS256 access tokens; the authenticate decorator guards bearer routes.
    // Applied to the root instance so every module can use it.
    const accessTokens = createAccessTokens({ signingKey: config.jwtSigningKey, clock });
    registerJwtAuth(app, accessTokens);
    const authService = new AuthService({
      repository: new DrizzleAuthRepository(deps.db),
      mailer: deps.mailer ?? new NodemailerMailer(config.smtp),
      clock,
      accessTokens,
      logger: app.log,
    });
    await app.register(authRoutes(authService));
    const deviceRepository = new DrizzleDeviceRepository(deps.db);
    await app.register(deviceRoutes(deviceRepository));
    const ingestKeyRepository = new DrizzleIngestKeyRepository(deps.db);
    const ingestKeys = new IngestKeyService(ingestKeyRepository);
    // Realtime: authenticated WebSocket routing. The registry is the
    // WebSocket leg of the composite ingest dispatcher composed below.
    const registry = new ConnectionRegistry({
      clock,
      ...(deps.realtime?.pingIntervalMs !== undefined
        ? { pingIntervalMs: deps.realtime.pingIntervalMs }
        : {}),
    });
    const instances = new InstanceRegistry({
      clock,
      publish: (userId, message) => registry.send(userId, message),
      ...(deps.realtime?.pingIntervalMs !== undefined
        ? { pingIntervalMs: deps.realtime.pingIntervalMs }
        : {}),
      ...(deps.control?.snapshotTimeoutMs !== undefined
        ? { snapshotTimeoutMs: deps.control.snapshotTimeoutMs }
        : {}),
    });
    await app.register(
      ingestKeyRoutes(ingestKeyRepository, { onRevoked: (id) => instances.revokeKey(id) }),
    );
    // preClose (not onClose): the 1012 close frames must be flushed while
    // the sockets are still alive — by onClose the server has torn them
    // down. Registered BEFORE the websocket plugin so this hook runs first:
    // `ws` ignores close() on an already-CLOSING socket, so the plugin's
    // later code-less close cannot overwrite our 1012.
    app.addHook("preClose", async () => {
      registry.closeAll(WS_CLOSE_SERVER_SHUTDOWN);
      instances.closeAll();
    });
    await registerWebsocket(app);
    await app.register(
      wsRoutes({
        registry,
        accessTokens,
        allowedOrigins: config.allowedOrigins,
        onConnect: (userId) => instances.publishSnapshot(userId),
      }),
    );
    await app.register(controlWsRoutes({ pluginKeys: ingestKeys, registry: instances }));
    await app.register(pendingInteractionsRoutes(instances));
    // Production default fanout: WebSocket (registry) + Android push (FCM)
    // composed behind the ingest route's dispatcher seam. The Firebase app
    // is only initialized when the real sender is needed — an injected
    // dispatcher or sender keeps tests hermetic.
    const dispatcher =
      deps.eventDispatcher ??
      new CompositeEventDispatcher({
        realtime: registry,
        devices: deviceRepository,
        fcm:
          deps.fcmSender ??
          new FirebaseAdminFcmSender(
            messagingFromServiceAccountJson(config.firebaseServiceAccountJson),
          ),
        logger: app.log,
      });
    await app.register(
      eventRoutes({
        ingestKeys,
        clock,
        dispatcher,
      }),
    );
  }

  return app;
}
