import {
  adminChangePasswordBodySchema,
  adminCreateUserBodySchema,
  adminLoginBodySchema,
  adminResetPasswordBodySchema,
  adminTokenSchema,
  adminUserListSchema,
  adminUserSchema,
  adminWhitelistSchema,
  type AdminChangePasswordBody,
  type AdminCreateUserBody,
  type AdminLoginBody,
  type AdminResetPasswordBody,
  type AdminWhitelist,
} from "@notify/contracts";
import type { FastifyPluginAsync, FastifyReply, FastifyRequest } from "fastify";

import { ErrorCodes, errorBody } from "../../lib/errors.js";
import { ADMIN_TOKEN_ROLE } from "../../plugins/jwt.js";
import type { AccessTokens } from "../../plugins/jwt.js";
import { AUTH_ENDPOINT_RATE_LIMIT } from "../../plugins/rate-limit.js";
import { ADMIN_PANEL_HTML } from "./admin.panel.js";
import { AdminError, type AdminService } from "./admin.service.js";

const uuidParamsSchema = {
  type: "object",
  required: ["id"],
  properties: { id: { type: "string", format: "uuid" } },
} as const;

/**
 * Map admin domain errors to contract error responses. Unknown errors are
 * rethrown for the app-level handler (logged, 500 INTERNAL).
 */
function sendAdminError(reply: FastifyReply, error: unknown): FastifyReply {
  if (error instanceof AdminError) {
    switch (error.kind) {
      case "INVALID_CREDENTIALS":
        return reply
          .status(401)
          .send(errorBody(ErrorCodes.INVALID_CREDENTIALS, error.message));
      case "EMAIL_TAKEN":
        return reply.status(409).send(errorBody(ErrorCodes.EMAIL_TAKEN, error.message));
      case "USER_NOT_FOUND":
        return reply.status(404).send(errorBody(ErrorCodes.NOT_FOUND, error.message));
      case "INVALID_WHITELIST_ENTRY":
        return reply
          .status(400)
          .send(errorBody(ErrorCodes.VALIDATION_FAILED, error.message));
    }
  }
  throw error;
}

/**
 * The admin panel: the `/admin` page plus the `/v1/admin/*` JSON API it
 * drives. Panel sessions are role-scoped JWTs (see plugins/jwt.ts); the
 * user-facing `authenticate` guard rejects them and this guard rejects
 * user tokens, so the two token populations never cross.
 */
export function adminRoutes(service: AdminService, accessTokens: AccessTokens): FastifyPluginAsync {
  const requireAdmin = async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const header = request.headers.authorization;
    const token =
      typeof header === "string" && header.startsWith("Bearer ")
        ? header.slice("Bearer ".length)
        : null;
    const payload = token === null ? null : accessTokens.verify(token);
    if (payload === null || payload.role !== ADMIN_TOKEN_ROLE) {
      await reply
        .status(401)
        .send(errorBody(ErrorCodes.UNAUTHORIZED, "Missing or invalid admin token"));
    } else {
      request.adminId = payload.sub;
    }
  };

  return async (app) => {
    app.get("/admin", async (_request, reply) => {
      reply.header("content-type", "text/html; charset=utf-8");
      return reply.status(200).send(ADMIN_PANEL_HTML);
    });

    app.post(
      "/v1/admin/login",
      { config: { rateLimit: AUTH_ENDPOINT_RATE_LIMIT }, schema: { body: adminLoginBodySchema, response: { 200: adminTokenSchema } } },
      async (request, reply) => {
        const body = request.body as AdminLoginBody;
        try {
          const accessToken = await service.login(body.username, body.password);
          return reply.status(200).send({ accessToken });
        } catch (error) {
          return sendAdminError(reply, error);
        }
      },
    );

    app.post(
      "/v1/admin/change-password",
      { preHandler: [requireAdmin], schema: { body: adminChangePasswordBodySchema } },
      async (request, reply) => {
        const body = request.body as AdminChangePasswordBody;
        try {
          await service.changePasswordFor(
            request.adminId as string,
            body.currentPassword,
            body.newPassword,
          );
        } catch (error) {
          return sendAdminError(reply, error);
        }
        return reply.status(204).send();
      },
    );

    app.get(
      "/v1/admin/users",
      { preHandler: [requireAdmin], schema: { response: { 200: adminUserListSchema } } },
      async (_request, reply) => {
        const users = await service.listUsers();
        return reply.status(200).send({
          total: users.length,
          users: users.map((user) => ({
            id: user.id,
            email: user.email,
            verified: user.verified,
            createdAt: user.createdAt.toISOString(),
          })),
        });
      },
    );

    app.post(
      "/v1/admin/users",
      { preHandler: [requireAdmin], schema: { body: adminCreateUserBodySchema, response: { 201: adminUserSchema } } },
      async (request, reply) => {
        const body = request.body as AdminCreateUserBody;
        try {
          const user = await service.createUser(body.email, body.password);
          return reply.status(201).send({
            id: user.id,
            email: user.email,
            verified: user.verified,
            createdAt: user.createdAt.toISOString(),
          });
        } catch (error) {
          return sendAdminError(reply, error);
        }
      },
    );

    app.post(
      "/v1/admin/users/:id/reset-password",
      {
        preHandler: [requireAdmin],
        schema: { params: uuidParamsSchema, body: adminResetPasswordBodySchema },
      },
      async (request, reply) => {
        const { id } = request.params as { id: string };
        const body = request.body as AdminResetPasswordBody;
        try {
          await service.resetUserPassword(id, body.password);
        } catch (error) {
          return sendAdminError(reply, error);
        }
        return reply.status(204).send();
      },
    );

    app.get(
      "/v1/admin/whitelist",
      { preHandler: [requireAdmin], schema: { response: { 200: adminWhitelistSchema } } },
      async (_request, reply) => {
        return reply.status(200).send(await service.getWhitelist());
      },
    );

    app.put(
      "/v1/admin/whitelist",
      { preHandler: [requireAdmin], schema: { body: adminWhitelistSchema } },
      async (request, reply) => {
        const body = request.body as AdminWhitelist;
        try {
          await service.replaceWhitelist(body);
        } catch (error) {
          return sendAdminError(reply, error);
        }
        return reply.status(204).send();
      },
    );
  };
}

declare module "fastify" {
  interface FastifyRequest {
    /** Subject of the presented admin token; set by `requireAdmin`. */
    adminId?: string;
  }
}
