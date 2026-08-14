import type { FastifyPluginAsync } from "fastify";

import { ErrorCodes, errorBody } from "../../lib/errors.js";
import type { IngestKeyService, VerifiedIngestKey } from "../ingest-keys/ingest-keys.service.js";
import type { InstanceRegistry } from "./instance-registry.js";

declare module "fastify" {
  interface FastifyRequest {
    verifiedPluginKey?: VerifiedIngestKey;
  }
}

export function controlWsRoutes(deps: {
  pluginKeys: IngestKeyService;
  registry: InstanceRegistry;
}): FastifyPluginAsync {
  return async (app) => {
    app.get(
      "/v1/plugin/ws",
      {
        websocket: true,
        preValidation: async (request, reply) => {
          const header = request.headers.authorization;
          const credential =
            typeof header === "string" && header.startsWith("Bearer ")
              ? header.slice("Bearer ".length)
              : null;
          const verified = credential === null ? null : await deps.pluginKeys.verify(credential);
          if (verified === null) {
            await reply
              .status(401)
              .send(errorBody(ErrorCodes.UNAUTHORIZED, "Missing or invalid Plugin key"));
            return;
          }
          request.verifiedPluginKey = verified;
        },
      },
      (socket, request) => {
        deps.registry.add(request.verifiedPluginKey as VerifiedIngestKey, socket);
      },
    );
  };
}
