import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { sql } from "drizzle-orm";
import { drizzle, type PostgresJsDatabase } from "drizzle-orm/postgres-js";
import { migrate } from "drizzle-orm/postgres-js/migrator";
import { readMigrationFiles } from "drizzle-orm/migrator";
import postgres from "postgres";

import type * as schema from "./schema.js";

/**
 * The committed migrations. Resolved relative to this module so the same
 * path works from `src/db/migrate.ts` (tsx CLI, tests) and from
 * `dist/db/migrate.js` (built image): both live two levels below the
 * gateway package root.
 */
export const MIGRATIONS_FOLDER = resolve(
  dirname(fileURLToPath(import.meta.url)),
  "../../drizzle",
);

/**
 * Apply the committed migrations to `databaseUrl`. This is the only code
 * path that mutates the schema; the application entrypoint never calls it
 * (specification section 12: migrations ship with the image and run as an
 * explicit command, never concurrently at instance startup).
 */
export async function migrateDatabase(databaseUrl: string): Promise<void> {
  // Silence the migrator's idempotent-setup NOTICEs ("schema/table already
  // exists, skipping") so repeat runs produce clean CLI output.
  const client = postgres(databaseUrl, { max: 1, onnotice: () => {} });
  try {
    await migrate(drizzle(client), { migrationsFolder: MIGRATIONS_FOLDER });
  } finally {
    await client.end();
  }
}

/**
 * sha256 of every bundled migration file, computed exactly the way
 * drizzle-orm's migrator does, so the hashes compare directly against the
 * `drizzle.__drizzle_migrations` bookkeeping rows. Memoized: the bundled
 * files cannot change during the process lifetime.
 */
let bundledMigrationHashes: string[] | null = null;

function bundledHashes(): string[] {
  bundledMigrationHashes ??= readMigrationFiles({ migrationsFolder: MIGRATIONS_FOLDER }).map(
    (migration) => migration.hash,
  );
  return bundledMigrationHashes;
}

/**
 * Readiness check: true only when the database's applied migration set is
 * exactly the bundled set (same hashes, same count — behind, empty, and
 * ahead-of-image all read as not current). Purely read-only: a missing
 * `drizzle` schema/table, an unreachable database, or unreadable bundled
 * files all yield false rather than throwing or mutating anything.
 */
export async function isSchemaCurrent(
  db: PostgresJsDatabase<typeof schema>,
): Promise<boolean> {
  let expected: string[];
  try {
    expected = [...bundledHashes()].sort();
  } catch {
    return false;
  }
  try {
    const rows = await db.execute(sql`select hash from drizzle.__drizzle_migrations`);
    const applied = rows.map((row) => String(row.hash)).sort();
    return (
      applied.length === expected.length &&
      applied.every((hash, index) => hash === expected[index])
    );
  } catch {
    return false;
  }
}

// Explicit CLI: `pnpm db:migrate` (tsx) or `node dist/db/migrate.js`.
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const databaseUrl = process.env.DATABASE_URL;
  if (databaseUrl === undefined || databaseUrl.trim() === "") {
    console.error("DATABASE_URL is required");
    process.exit(1);
  }
  try {
    await migrateDatabase(databaseUrl);
    console.log(`Applied migrations from ${MIGRATIONS_FOLDER}`);
  } catch (error) {
    console.error("Migration failed:", error);
    process.exit(1);
  }
}
