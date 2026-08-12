import type { FastifyInstance } from "fastify";

declare module "fastify" {
  interface FastifyRequest {
    /**
     * Exact request-body bytes (UTF-8 string), captured by the raw-body
     * parser before JSON parsing. The signed event-ingress route
     * authenticates over these bytes — never over a re-serialization of the
     * parsed body, which could reorder keys or normalize whitespace.
     */
    rawBody?: string;
  }
}

/**
 * JSON content-type parser that stashes the exact raw body bytes on
 * `request.rawBody` before parsing. Register it in an encapsulated scope:
 * it overrides the default JSON parser for every route in that scope.
 */
export async function registerRawBody(app: FastifyInstance): Promise<void> {
  app.addContentTypeParser(
    "application/json",
    { parseAs: "string" },
    (request, body, done) => {
      const raw = body as string;
      request.rawBody = raw;
      try {
        done(null, raw === "" ? undefined : JSON.parse(raw));
      } catch (error) {
        // Match Fastify's default parser: malformed JSON is a client error.
        (error as { statusCode?: number }).statusCode = 400;
        done(error as Error, undefined);
      }
    },
  );
}
