import { buildServer } from "./app.js";
import { loadConfig } from "./config.js";
import { createDb } from "./db/client.js";
import { DrizzleAdminRepository } from "./modules/admin/admin.repository.js";
import { WhitelistRegistrationPolicy } from "./modules/admin/admin.service.js";
import { resolvePort } from "./port.js";
import { installGracefulShutdown } from "./shutdown.js";

// Validates every specification environment variable before listening; a
// ConfigError here aborts startup with all problems listed at once.
const config = loadConfig();

// The entrypoint owns the database handle; the app factory only borrows it.
const db = createDb(config.databaseUrl);
// Production registration gate: self-service sign-up requires the email to
// match the admin-managed whitelist (suffix or exact address).
const registrationPolicy = new WhitelistRegistrationPolicy(new DrizzleAdminRepository(db.db));
const app = await buildServer({ config, db: db.db, registrationPolicy });

// SIGINT/SIGTERM: stop accepts, close every realtime socket with 1012 and
// drain (app.close runs the registry's preClose hook), then end the
// database pool, then exit 0. Migrations never run here.
installGracefulShutdown({ app, closeDatabase: db.close });

// PORT is an operational override for local runs; it is not one of the
// specification variables and defaults to 8080 behind the reverse proxy.
const port = resolvePort();

await app.listen({ host: "0.0.0.0", port });
