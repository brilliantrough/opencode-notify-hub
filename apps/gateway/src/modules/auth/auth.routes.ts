import {
  emailBodySchema,
  loginBodySchema,
  refreshBodySchema,
  registerBodySchema,
  resetPasswordBodySchema,
  tokenPairSchema,
  verifyEmailBodySchema,
  type EmailBody,
  type LoginBody,
  type RefreshBody,
  type RegisterBody,
  type ResetPasswordBody,
  type VerifyEmailBody,
} from "@notify/contracts";
import type { FastifyPluginAsync, FastifyReply } from "fastify";

import { ErrorCodes, errorBody } from "../../lib/errors.js";
import { AUTH_ENDPOINT_RATE_LIMIT } from "../../plugins/rate-limit.js";
import { AuthError, type AuthService } from "./auth.service.js";

/**
 * Map domain errors to contract error responses. Messages are static: no
 * SMTP internals, codes, or hashes ever reach the response body. Unknown
 * errors are rethrown for the app-level handler (logged, 500 INTERNAL).
 */
function sendAuthError(reply: FastifyReply, error: unknown): FastifyReply {
  if (error instanceof AuthError) {
    switch (error.kind) {
      case "EMAIL_TAKEN":
        return reply.status(409).send(errorBody(ErrorCodes.EMAIL_TAKEN, error.message));
      case "INVALID_CODE":
        return reply.status(400).send(errorBody(ErrorCodes.INVALID_CODE, error.message));
      case "MAIL_UNAVAILABLE":
        return reply
          .status(503)
          .send(errorBody(ErrorCodes.SERVICE_UNAVAILABLE, error.message));
      case "INVALID_CREDENTIALS":
        return reply
          .status(401)
          .send(errorBody(ErrorCodes.INVALID_CREDENTIALS, error.message));
      case "EMAIL_UNVERIFIED":
        return reply
          .status(403)
          .send(errorBody(ErrorCodes.EMAIL_UNVERIFIED, error.message));
      case "INVALID_REFRESH":
        return reply.status(401).send(errorBody(ErrorCodes.UNAUTHORIZED, error.message));
      case "REFRESH_REUSED":
        return reply.status(401).send(errorBody(ErrorCodes.REFRESH_REUSED, error.message));
    }
  }
  throw error;
}

/**
 * Registration, verification, session, and reset routes (specification
 * section 9). Bodies are validated against the shared contract schemas;
 * every endpoint is rate-limited at 10 requests/minute per client IP (the
 * limiter runs before any account lookup, so a 429 reveals nothing).
 */
export function authRoutes(service: AuthService): FastifyPluginAsync {
  return async (app) => {
    app.post(
      "/v1/auth/register",
      { config: { rateLimit: AUTH_ENDPOINT_RATE_LIMIT }, schema: { body: registerBodySchema } },
      async (request, reply) => {
        const body = request.body as RegisterBody;
        try {
          await service.register(body.email, body.password);
        } catch (error) {
          return sendAuthError(reply, error);
        }
        return reply.status(201).send();
      },
    );

    app.post(
      "/v1/auth/verify-email",
      { config: { rateLimit: AUTH_ENDPOINT_RATE_LIMIT }, schema: { body: verifyEmailBodySchema } },
      async (request, reply) => {
        const body = request.body as VerifyEmailBody;
        try {
          await service.verifyEmail(body.email, body.code);
        } catch (error) {
          return sendAuthError(reply, error);
        }
        return reply.status(204).send();
      },
    );

    app.post(
      "/v1/auth/resend-verification",
      { config: { rateLimit: AUTH_ENDPOINT_RATE_LIMIT }, schema: { body: emailBodySchema } },
      async (request, reply) => {
        const body = request.body as EmailBody;
        try {
          await service.resendVerification(body.email);
        } catch (error) {
          return sendAuthError(reply, error);
        }
        return reply.status(204).send();
      },
    );

    app.post(
      "/v1/auth/forgot-password",
      { config: { rateLimit: AUTH_ENDPOINT_RATE_LIMIT }, schema: { body: emailBodySchema } },
      async (request, reply) => {
        const body = request.body as EmailBody;
        try {
          await service.forgotPassword(body.email);
        } catch (error) {
          return sendAuthError(reply, error);
        }
        return reply.status(204).send();
      },
    );

    app.post(
      "/v1/auth/reset-password",
      { config: { rateLimit: AUTH_ENDPOINT_RATE_LIMIT }, schema: { body: resetPasswordBodySchema } },
      async (request, reply) => {
        const body = request.body as ResetPasswordBody;
        try {
          await service.resetPassword(body.email, body.code, body.password);
        } catch (error) {
          return sendAuthError(reply, error);
        }
        return reply.status(204).send();
      },
    );

    app.post(
      "/v1/auth/login",
      { config: { rateLimit: AUTH_ENDPOINT_RATE_LIMIT }, schema: { body: loginBodySchema, response: { 200: tokenPairSchema } } },
      async (request, reply) => {
        const body = request.body as LoginBody;
        try {
          const pair = await service.login(body.email, body.password);
          return reply.status(200).send(pair);
        } catch (error) {
          return sendAuthError(reply, error);
        }
      },
    );

    app.post(
      "/v1/auth/refresh",
      { config: { rateLimit: AUTH_ENDPOINT_RATE_LIMIT }, schema: { body: refreshBodySchema, response: { 200: tokenPairSchema } } },
      async (request, reply) => {
        const body = request.body as RefreshBody;
        try {
          const pair = await service.refresh(body.refreshToken);
          return reply.status(200).send(pair);
        } catch (error) {
          return sendAuthError(reply, error);
        }
      },
    );

    app.post(
      "/v1/auth/logout",
      { config: { rateLimit: AUTH_ENDPOINT_RATE_LIMIT }, schema: { body: refreshBodySchema } },
      async (request, reply) => {
        const body = request.body as RefreshBody;
        try {
          await service.logout(body.refreshToken);
        } catch (error) {
          return sendAuthError(reply, error);
        }
        return reply.status(204).send();
      },
    );
  };
}
