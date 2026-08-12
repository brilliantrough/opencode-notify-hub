import { drizzle, type PostgresJsDatabase } from "drizzle-orm/postgres-js";
import postgres from "postgres";

import * as schema from "./schema.js";

/**
 * Handle returned by {@link createDb}. Callers own the lifecycle: `close`
 * ends the underlying connection pool. The application wires one handle at
 * startup (later tasks) and closes it on shutdown; tests close every handle
 * they open so pools never leak.
 */
export interface GatewayDatabase {
  readonly db: PostgresJsDatabase<typeof schema>;
  close(): Promise<void>;
}

/**
 * Open a Drizzle database handle for `databaseUrl`. Opening a handle never
 * mutates the database: schema changes happen only through the explicit
 * `db:migrate` CLI (see migrate.ts).
 */
export function createDb(databaseUrl: string): GatewayDatabase {
  const client = postgres(databaseUrl);
  return {
    db: drizzle(client, { schema }),
    close: async () => {
      await client.end();
    },
  };
}
