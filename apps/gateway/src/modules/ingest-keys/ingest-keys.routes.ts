import {
  createIngestKeyBodySchema,
  createIngestKeyResponseSchema,
  ingestKeyListResponseSchema,
  type CreateIngestKeyBody,
} from "@notify/contracts";
import type { FastifyPluginAsync, FastifyReply } from "fastify";

import { ErrorCodes, errorBody } from "../../lib/errors.js";
import type { IngestKeyRecord, IngestKeyRepository } from "./ingest-keys.repository.js";
import { IngestKeyService } from "./ingest-keys.service.js";

/** Contract list item: metadata only; `lastUsedAt` omitted while unused. */
function toListItem(record: IngestKeyRecord) {
  return {
    id: record.id,
    name: record.name,
    createdAt: record.createdAt.toISOString(),
    ...(record.lastUsedAt !== null ? { lastUsedAt: record.lastUsedAt.toISOString() } : {}),
  };
}

const UUID_PATTERN = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

function sendNotFound(reply: FastifyReply): FastifyReply {
  return reply.status(404).send(errorBody(ErrorCodes.NOT_FOUND, "Ingest key not found"));
}

/**
 * Per-user ingest-key management (specification section 7.2). Every route is
 * bearer-guarded and every query is scoped to the authenticated user. The
 * secret is returned exactly once, in the creation response; the list
 * contract omits it by construction (additionalProperties: false).
 */
export function ingestKeyRoutes(
  repository: IngestKeyRepository,
  options: { onRevoked?: (id: string) => void } = {},
): FastifyPluginAsync {
  const service = new IngestKeyService(repository);
  return async (app) => {
    app.get(
      "/v1/ingest-keys",
      {
        preHandler: app.authenticate,
        schema: { response: { 200: ingestKeyListResponseSchema } },
      },
      async (request, reply) => {
        const records = await repository.list(request.userId as string);
        return reply.status(200).send(records.map(toListItem));
      },
    );

    app.post(
      "/v1/ingest-keys",
      {
        preHandler: app.authenticate,
        schema: { body: createIngestKeyBodySchema, response: { 201: createIngestKeyResponseSchema } },
      },
      async (request, reply) => {
        const body = request.body as CreateIngestKeyBody;
        const { record, credential } = await service.create(request.userId as string, body.name);
        return reply.status(201).send({
          id: record.id,
          name: record.name,
          createdAt: record.createdAt.toISOString(),
          secret: credential,
        });
      },
    );

    app.delete<{ Params: { id: string } }>(
      "/v1/ingest-keys/:id",
      { preHandler: app.authenticate },
      async (request, reply) => {
        const { id } = request.params;
        if (!UUID_PATTERN.test(id)) {
          return sendNotFound(reply);
        }
        const revoked = await repository.revoke({ userId: request.userId as string, id });
        if (!revoked) {
          return sendNotFound(reply);
        }
        options.onRevoked?.(id);
        return reply.status(204).send();
      },
    );
  };
}
