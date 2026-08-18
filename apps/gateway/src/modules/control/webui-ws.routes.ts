import type { FastifyPluginAsync } from "fastify";

import { ErrorCodes, errorBody } from "../../lib/errors.js";
import type { AccessTokens } from "../../plugins/jwt.js";
import type { InstanceRegistry } from "./instance-registry.js";

export function webUiWsRoutes(deps: {
  registry: InstanceRegistry;
  accessTokens: AccessTokens;
  allowedOrigins: string[];
}): FastifyPluginAsync {
  return async (app) => {
    app.get(
      "/v1/webui/ws",
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
        deps.registry.addWebUiClient(request.userId as string, socket, {
          expiresAtMs: request.tokenExpiresAtMs as number,
        });
      },
    );
  };
}
