import {
  commandAcceptedSchema,
  sendPromptBodySchema,
  type CommandAccepted,
  type SendPromptBody,
} from "@notify/contracts";
import type { FastifyPluginAsync } from "fastify";

import { ErrorCodes, errorBody } from "../../lib/errors.js";
import type { InstanceRegistry } from "./instance-registry.js";

/** Owner-scoped, online-only Session commands. */
export function sessionControlRoutes(registry: InstanceRegistry): FastifyPluginAsync {
  return async (app) => {
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
