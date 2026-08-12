import {
  deviceListResponseSchema,
  deviceSchema,
  patchDeviceBodySchema,
  registerDeviceBodySchema,
  type Device,
  type PatchDeviceBody,
  type RegisterDeviceBody,
} from "@notify/contracts";
import type { FastifyPluginAsync, FastifyReply } from "fastify";

import { ErrorCodes, errorBody } from "../../lib/errors.js";
import type { DeviceRecord, DeviceRepository } from "./devices.repository.js";

/** Contract response shape: the optional FCM token is omitted when absent. */
function toResponse(record: DeviceRecord): Device {
  return {
    id: record.id,
    name: record.name,
    platform: record.platform,
    enabled: record.enabled,
    soundEnabled: record.soundEnabled,
    ...(record.fcmToken !== null ? { fcmToken: record.fcmToken } : {}),
  };
}

const UUID_PATTERN = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

function sendNotFound(reply: FastifyReply): FastifyReply {
  return reply.status(404).send(errorBody(ErrorCodes.NOT_FOUND, "Device not found"));
}

/**
 * Per-user device CRUD (specification: devices resource). Every route is
 * bearer-guarded and every query is scoped to the authenticated user, so
 * foreign device ids answer 404 exactly like unknown ones.
 */
export function deviceRoutes(repository: DeviceRepository): FastifyPluginAsync {
  return async (app) => {
    app.get(
      "/v1/devices",
      {
        preHandler: app.authenticate,
        schema: { response: { 200: deviceListResponseSchema } },
      },
      async (request, reply) => {
        const records = await repository.list(request.userId as string);
        return reply.status(200).send(records.map(toResponse));
      },
    );

    app.post(
      "/v1/devices",
      {
        preHandler: app.authenticate,
        schema: { body: registerDeviceBodySchema, response: { 201: deviceSchema } },
      },
      async (request, reply) => {
        const body = request.body as RegisterDeviceBody;
        const record = await repository.create({
          userId: request.userId as string,
          name: body.name,
          platform: body.platform,
          fcmToken: body.fcmToken,
          // Contract defaults, applied server-side when the body omits them.
          enabled: body.enabled ?? true,
          soundEnabled: body.soundEnabled ?? true,
        });
        return reply.status(201).send(toResponse(record));
      },
    );

    app.patch<{ Params: { id: string } }>(
      "/v1/devices/:id",
      {
        preHandler: app.authenticate,
        schema: { body: patchDeviceBodySchema, response: { 200: deviceSchema } },
      },
      async (request, reply) => {
        const { id } = request.params;
        if (!UUID_PATTERN.test(id)) {
          return sendNotFound(reply);
        }
        const body = request.body as PatchDeviceBody;
        const record = await repository.update({
          userId: request.userId as string,
          id,
          patch: body,
        });
        if (record === null) {
          return sendNotFound(reply);
        }
        return reply.status(200).send(toResponse(record));
      },
    );

    app.delete<{ Params: { id: string } }>(
      "/v1/devices/:id",
      { preHandler: app.authenticate },
      async (request, reply) => {
        const { id } = request.params;
        if (!UUID_PATTERN.test(id)) {
          return sendNotFound(reply);
        }
        const deleted = await repository.delete({ userId: request.userId as string, id });
        if (!deleted) {
          return sendNotFound(reply);
        }
        return reply.status(204).send();
      },
    );
  };
}
