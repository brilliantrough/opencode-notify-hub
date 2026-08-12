import websocket from "@fastify/websocket";
import type { FastifyInstance } from "fastify";

/**
 * WebSocket support for the gateway. `@fastify/websocket` is wrapped in
 * fastify-plugin, so its decorations land on the instance it is registered
 * on (the root, here) and every module's routes can declare
 * `{ websocket: true }`.
 */
export async function registerWebsocket(app: FastifyInstance): Promise<void> {
  await app.register(websocket);
}
