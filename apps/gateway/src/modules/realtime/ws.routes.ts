import type { FastifyPluginAsync } from "fastify";

import { ErrorCodes, errorBody } from "../../lib/errors.js";
import type { AccessTokens } from "../../plugins/jwt.js";
import type { ConnectionRegistry } from "./connection-registry.js";

declare module "fastify" {
  interface FastifyRequest {
    /** Access-token `exp` in epoch ms; stamped by the /v1/ws preValidation. */
    tokenExpiresAtMs?: number;
  }
}

export interface WsRouteDeps {
  registry: ConnectionRegistry;
  accessTokens: AccessTokens;
  /**
   * Normalized ALLOWED_ORIGINS entries. Browsers do not enforce CORS on
   * WebSockets, so the upgrade itself checks the Origin header against this
   * list; native clients that send no Origin header stay allowed.
   */
  allowedOrigins: string[];
  onConnect?: (userId: string) => void;
}

/**
 * `GET /v1/ws`: authenticated realtime channel. The Bearer access token is
 * verified during the HTTP Upgrade (preValidation), so an invalid, missing,
 * or expired token gets the contract-shaped 401 HTTP response and no socket
 * is ever established. A successful upgrade registers the socket under the
 * token's subject; the registry owns fanout, heartbeat, and the 4401 close
 * at token `exp`.
 */
export function wsRoutes(deps: WsRouteDeps): FastifyPluginAsync {
  return async (app) => {
    app.get(
      "/v1/ws",
      {
        websocket: true,
        preValidation: async (request, reply) => {
          const header = request.headers.authorization;
          const token =
            typeof header === "string" && header.startsWith("Bearer ")
              ? header.slice("Bearer ".length)
              : null;
          const payload = token === null ? null : deps.accessTokens.verify(token);
          if (payload === null) {
            await reply
              .status(401)
              .send(errorBody(ErrorCodes.UNAUTHORIZED, "Missing or invalid access token"));
            return;
          }
          const originHeader = request.headers.origin;
          const origin = Array.isArray(originHeader) ? originHeader[0] : originHeader;
          if (origin !== undefined && !deps.allowedOrigins.includes(origin)) {
            await reply
              .status(403)
              .send(errorBody(ErrorCodes.FORBIDDEN, "Origin is not allowed"));
            return;
          }
          request.userId = payload.sub;
          request.tokenExpiresAtMs = payload.exp * 1000;
        },
      },
      (socket, request) => {
        const userId = request.userId as string;
        deps.registry.add(userId, socket, {
          expiresAtMs: request.tokenExpiresAtMs as number,
        });
        deps.onConnect?.(userId);
      },
    );
  };
}
