import {
  answerQuestionBodySchema,
  commandOutcomeSchema,
  decidePermissionBodySchema,
  pendingSnapshotSchema,
  permissionCommandResultSchema,
  questionCommandResultSchema,
  type AnswerQuestionBody,
  type CommandOutcome,
  type DecidePermissionBody,
  type PendingSnapshot,
  type PermissionCommandResult,
  type QuestionCommandResult,
} from "@notify/contracts";
import type { FastifyPluginAsync } from "fastify";

import { ErrorCodes, errorBody } from "../../lib/errors.js";
import type {
  AnswerQuestionOutcome,
  DecidePermissionOutcome,
  InstanceRegistry,
} from "./instance-registry.js";

/**
 * `GET /v1/pending-interactions`: owner-scoped read-only snapshot. The route
 * is bearer-guarded by the existing access-token `authenticate` preHandler,
 * and the registry only ever queries the authenticated user's own connected,
 * controllable instances. Conflicting, incompatible, offline, and foreign
 * instances are never contacted; a partial 200 snapshot is returned when an
 * instance times out. Interaction payloads are relayed through memory only —
 * never persisted and never logged.
 *
 * `POST /v1/pending-interactions/:instanceId/questions/:requestId/answer`:
 * submit one complete ordered answer set for a pending question owned by the
 * authenticated account. The registry routes the command to the exact Plugin
 * instance and awaits its terminal outcome; the 200 response carries the
 * client-generated `commandId` and confirms gateway routing, not that
 * OpenCode applied the answers. Unknown/foreign/non-actionable targets and
 * never-projected request ids answer a uniform 404; stale requests and the
 * wrong interaction kind answer 409. Answer bodies are redacted from logs and
 * never persisted.
 *
 * `POST /v1/pending-interactions/:instanceId/permissions/:requestId/decision`:
 * submit one immediate decision (`once`, `always`, or `reject`) for a pending
 * permission owned by the authenticated account. The registry routes the
 * command to the exact Plugin instance and awaits its terminal outcome; the
 * 200 response carries the client-generated `commandId` and confirms gateway
 * routing, not that OpenCode applied the decision. Unknown/foreign/non-actionable
 * targets and never-projected request ids answer a uniform 404; stale
 * requests, the wrong interaction kind, and a second in-flight decision on
 * the same connection answer 409. Decision bodies are redacted from logs and
 * never persisted.
 *
 * `GET /v1/pending-interactions/commands/:commandId`: query the body-free,
 * in-memory outcome correlation of one command the authenticated account
 * submitted, keyed by the client-generated `commandId`. The 200 response
 * carries only correlation and lifecycle metadata (commandId, requestId,
 * instanceId, kind, status, updatedAt) — never answers, decisions, or
 * payloads. Unknown, expired, and foreign command ids all answer the same
 * uniform 404, so a client that timed out can distinguish accepted, confirmed,
 * stale, and result_unknown before resubmitting.
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

    app.post<{ Params: { instanceId: string; requestId: string } }>(
      "/v1/pending-interactions/:instanceId/questions/:requestId/answer",
      {
        preHandler: app.authenticate,
        schema: {
          body: answerQuestionBodySchema,
          response: { 200: questionCommandResultSchema },
        },
      },
      async (request, reply) => {
        const body = request.body as AnswerQuestionBody;
        const outcome: AnswerQuestionOutcome = await registry.answerQuestion(
          request.userId as string,
          request.params.instanceId,
          request.params.requestId,
          body.commandId,
          body.answers,
        );
        if (!outcome.ok) {
          if (outcome.error.code === "conflict") {
            return reply
              .status(409)
              .send(errorBody(ErrorCodes.CONFLICT, "Question request is stale or not pending"));
          }
          return reply
            .status(404)
            .send(errorBody(ErrorCodes.NOT_FOUND, "Question request not found"));
        }
        return reply.status(200).send(outcome.result satisfies QuestionCommandResult);
      },
    );

    app.post<{ Params: { instanceId: string; requestId: string } }>(
      "/v1/pending-interactions/:instanceId/permissions/:requestId/decision",
      {
        preHandler: app.authenticate,
        schema: {
          body: decidePermissionBodySchema,
          response: { 200: permissionCommandResultSchema },
        },
      },
      async (request, reply) => {
        const body = request.body as DecidePermissionBody;
        const outcome: DecidePermissionOutcome = await registry.decidePermission(
          request.userId as string,
          request.params.instanceId,
          request.params.requestId,
          body.commandId,
          body.decision,
        );
        if (!outcome.ok) {
          if (outcome.error.code === "conflict") {
            return reply
              .status(409)
              .send(
                errorBody(ErrorCodes.CONFLICT, "Permission request is stale or not pending"),
              );
          }
          return reply
            .status(404)
            .send(errorBody(ErrorCodes.NOT_FOUND, "Permission request not found"));
        }
        return reply.status(200).send(outcome.result satisfies PermissionCommandResult);
      },
    );

    app.get<{ Params: { commandId: string } }>(
      "/v1/pending-interactions/commands/:commandId",
      {
        preHandler: app.authenticate,
        schema: { response: { 200: commandOutcomeSchema } },
      },
      async (request, reply) => {
        const outcome = registry.outcomeFor(
          request.userId as string,
          request.params.commandId,
        );
        if (outcome === undefined) {
          // Unknown, expired, and foreign command ids are indistinguishable:
          // one uniform 404, never a hint about another account's command.
          return reply
            .status(404)
            .send(errorBody(ErrorCodes.NOT_FOUND, "Command outcome not found"));
        }
        return reply.status(200).send(outcome satisfies CommandOutcome);
      },
    );
  };
}
