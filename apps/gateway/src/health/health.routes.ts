import { healthStatusSchema } from "@notify/contracts";
import { sql } from "drizzle-orm";
import type { PostgresJsDatabase } from "drizzle-orm/postgres-js";
import type { FastifyPluginAsync } from "fastify";

import type * as schema from "../db/schema.js";
import { isSchemaCurrent } from "../db/migrate.js";
import { ErrorCodes, errorBody } from "../lib/errors.js";
import { messagingFromServiceAccountJson } from "../modules/fcm/firebase-app.js";

export interface HealthDeps {
  /**
   * Database handle. Absent (DB-free embedding) readiness always fails:
   * the gateway cannot serve without its store.
   */
  db?: PostgresJsDatabase<typeof schema>;
  /**
   * The configured service account. Readiness verifies the production
   * Firebase initialization works (parse + app init; no network), even when
   * tests injected an FCM sender that bypassed startup initialization.
   */
  firebaseServiceAccountJson: string;
}

/**
 * Liveness and readiness probes (specification: single-instance container
 * behind an orchestrator).
 *
 * `/health/live` is deliberately DB-independent: a dead database must never
 * restart the container, only remove it from rotation.
 *
 * `/health/ready` answers the contract health status only when PostgreSQL
 * answers `SELECT 1`, the applied schema matches the bundled Drizzle
 * migrations exactly, and the production Firebase initialization works.
 * Every failure answers the same generic retryable 503 — no internals in
 * the body; the failing check names (never values) go to the warn log.
 * Readiness is a probe: it never mutates the database and never runs
 * migrations.
 */
export function healthRoutes(deps: HealthDeps): FastifyPluginAsync {
  return async (app) => {
    app.get(
      "/health/live",
      { schema: { response: { 200: healthStatusSchema } } },
      async () => ({ status: "ok" as const }),
    );

    // No response schema: the 503 failure body must not be constrained by
    // the 200 health contract (the integration tests validate both shapes).
    app.get(
      "/health/ready",
      async (request, reply) => {
        const failures: string[] = [];

        let databaseReady = false;
        if (deps.db !== undefined) {
          try {
            await deps.db.execute(sql`select 1`);
            databaseReady = true;
          } catch {
            // Unreachable or ended pool: not ready.
          }
        }
        if (!databaseReady) {
          failures.push("database");
        }

        // Skipped when the database is down: the schema query would fail
        // for the same reason, and "database" already says enough.
        if (databaseReady && deps.db !== undefined && !(await isSchemaCurrent(deps.db))) {
          failures.push("schema");
        }

        try {
          messagingFromServiceAccountJson(deps.firebaseServiceAccountJson);
        } catch {
          failures.push("firebase");
        }

        if (failures.length > 0) {
          request.log.warn({ checks: failures }, "readiness probe failed");
          return reply
            .status(503)
            .send(errorBody(ErrorCodes.SERVICE_UNAVAILABLE, "Service unavailable"));
        }
        return { status: "ok" as const };
      },
    );
  };
}
