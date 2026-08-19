import type { FastifyPluginAsync, FastifyReply } from "fastify";

import { ErrorCodes, errorBody } from "../../lib/errors.js";
import type { InstanceRegistry } from "./instance-registry.js";

const UUID_PATTERN = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

function notFound(reply: FastifyReply): FastifyReply {
  return reply.status(404).send(errorBody(ErrorCodes.NOT_FOUND, "OpenCode instance not found"));
}

/** Owner-scoped lifecycle operations for the in-memory instance projection. */
export function instanceRoutes(registry: InstanceRegistry): FastifyPluginAsync {
  return async (app) => {
    app.delete<{ Params: { instanceId: string } }>(
      "/v1/instances/:instanceId",
      { preHandler: app.authenticate },
      async (request, reply) => {
        const { instanceId } = request.params;
        if (!UUID_PATTERN.test(instanceId)) {
          return notFound(reply);
        }
        const outcome = registry.forgetOffline(request.userId as string, instanceId);
        if (outcome === "not_found") {
          return notFound(reply);
        }
        if (outcome === "not_offline") {
          return reply
            .status(409)
            .send(errorBody(ErrorCodes.CONFLICT, "Active OpenCode instances cannot be forgotten"));
        }
        return reply.status(204).send();
      },
    );
  };
}
