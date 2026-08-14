import { pendingSnapshotSchema, type PendingSnapshot } from "@notify/contracts";
import type { FastifyPluginAsync } from "fastify";

import type { InstanceRegistry } from "./instance-registry.js";

/**
 * `GET /v1/pending-interactions`: owner-scoped read-only snapshot. The route
 * is bearer-guarded by the existing access-token `authenticate` preHandler,
 * and the registry only ever queries the authenticated user's own connected,
 * controllable instances. Conflicting, incompatible, offline, and foreign
 * instances are never contacted; a partial 200 snapshot is returned when an
 * instance times out. Interaction payloads are relayed through memory only —
 * never persisted and never logged.
 */
export function pendingInteractionsRoutes(registry: InstanceRegistry): FastifyPluginAsync {
  return async (app) => {
    app.get(
      "/v1/pending-interactions",
      {
        preHandler: app.authenticate,
        schema: { response: { 200: pendingSnapshotSchema } },
      },
      async (request, reply) => {
        const snapshot = await registry.collectPendingInteractions(
          request.userId as string,
        );
        return reply.status(200).send(snapshot satisfies PendingSnapshot);
      },
    );
  };
}
