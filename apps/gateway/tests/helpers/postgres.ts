import {
  PostgreSqlContainer,
  type StartedPostgreSqlContainer,
} from "@testcontainers/postgresql";
import postgres from "postgres";

import { migrateDatabase } from "../../src/db/migrate.js";

/** Pinned by the brief: PostgreSQL 16 for every integration database. */
export const POSTGRES_IMAGE = "postgres:16-alpine";

/**
 * Reusable Testcontainers harness for gateway integration tests.
 *
 * Owns the whole lifecycle of one ephemeral database: the container and
 * every SQL client opened through it. Callers must invoke {@link stop}
 * (typically in `afterAll`); `stop` ends any still-open clients before
 * stopping the container, so neither pools nor containers leak when a test
 * forgets to clean up. Testcontainers' Ryuk sidecar is the final backstop
 * for containers abandoned by a crashed test run.
 */
export class TestPostgres {
  private readonly clients = new Set<postgres.Sql>();
  private stopped = false;

  private constructor(
    private readonly container: StartedPostgreSqlContainer,
    readonly databaseUrl: string,
  ) {}

  static async start(): Promise<TestPostgres> {
    const container = await new PostgreSqlContainer(POSTGRES_IMAGE).start();
    return new TestPostgres(container, container.getConnectionUri());
  }

  /**
   * Run the committed Drizzle migrations (the same code path as the
   * `db:migrate` CLI). Opens and ends its own single-connection client.
   */
  async migrate(): Promise<void> {
    await migrateDatabase(this.databaseUrl);
  }

  /**
   * Open a raw SQL client tracked by this harness. Prefer
   * {@link release} when done, but {@link stop} ends whatever is left.
   */
  connect(options: postgres.Options<never> = {}): postgres.Sql {
    const client = postgres(this.databaseUrl, options);
    this.clients.add(client);
    return client;
  }

  /** End a client opened via {@link connect} and untrack it. */
  async release(client: postgres.Sql): Promise<void> {
    this.clients.delete(client);
    await client.end();
  }

  /** End all tracked clients and stop the container. Idempotent. */
  async stop(): Promise<void> {
    if (this.stopped) {
      return;
    }
    this.stopped = true;
    for (const client of this.clients) {
      await client.end();
    }
    this.clients.clear();
    await this.container.stop();
  }
}
