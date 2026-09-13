import {
  commandAcceptedSchema,
  sendPromptBodySchema,
  type CommandAccepted,
  type SendPromptBody,
  sessionCatalogSchema,
  sessionCatalogQuerySchema,
  type SessionCatalogQuery,
} from "@notify/contracts";
import type { FastifyPluginAsync } from "fastify";

import { ErrorCodes, errorBody } from "../../lib/errors.js";
import type { InstanceRegistry } from "./instance-registry.js";

/** Owner-scoped, online-only Session commands. */
export function sessionControlRoutes(registry: InstanceRegistry): FastifyPluginAsync {
  return async (app) => {
    app.get<{ Params: { instanceId: string }; Querystring: SessionCatalogQuery }>(
      "/v1/instances/:instanceId/sessions",
      {
        preHandler: app.authenticate,
        schema: {
          params: { type: "object", required: ["instanceId"], properties: { instanceId: { type: "string", format: "uuid" } } },
          querystring: sessionCatalogQuerySchema,
          response: { 200: sessionCatalogSchema },
        },
      },
      async (request, reply) => {
        const result = await registry.collectSessions(request.userId as string, request.params.instanceId, request.query);
        if (result.status === "ready") return result.catalog;
        const status = { not_found: 404, timeout: 504, unsupported: 501, error: 502 }[result.status];
        return reply.status(status).send(errorBody(
          result.status === "not_found" ? ErrorCodes.NOT_FOUND : ErrorCodes.SERVICE_UNAVAILABLE,
          `Session catalog ${result.status}`,
        ));
      },
    );
    app.post<{ Params: { instanceId: string; sessionId: string } }>(
      "/v1/instances/:instanceId/sessions/:sessionId/prompt",
      {
        preHandler: app.authenticate,
        schema: {
          body: sendPromptBodySchema,
          response: { 202: commandAcceptedSchema },
        },
      },
      async (request, reply) => {
        const body = request.body as SendPromptBody;
        const outcome = await registry.sendSessionPrompt(
          request.userId as string,
          request.params.instanceId,
          request.params.sessionId,
          body.commandId,
          body.text,
        );
        if (!outcome.ok) {
          if (outcome.error.code === "conflict") {
            return reply
              .status(409)
              .send(errorBody(ErrorCodes.CONFLICT, "Prompt command is already in flight"));
          }
          return reply
            .status(404)
            .send(errorBody(ErrorCodes.NOT_FOUND, "OpenCode instance not found"));
        }
        return reply.status(202).send(outcome.result satisfies CommandAccepted);
      },
    );
  };
}
