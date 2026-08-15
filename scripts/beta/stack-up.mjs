#!/usr/bin/env node
/**
 * Issue #14 live closed loop — stack up the REAL gateway.
 *
 * Release tooling (never CI). Two modes:
 *
 *   node scripts/beta/stack-up.mjs --state <path> [--tag <name>]
 *
 *     - starts one ephemeral PostgreSQL 16 container with a RANDOM host
 *       port (pinned to 127.0.0.1; never exposed beyond loopback);
 *     - runs the committed Drizzle migrations against it;
 *     - starts the REAL gateway from source via tsx using the dev entry
 *       (`apps/gateway/beta/dev-entry.ts`), which injects only the dev
 *       seams: a mailbox mailer appending `{to,code}` lines to the
 *       MAILBOX_PATH file, a no-op FCM sender, and a pino stream to the
 *       GATEWAY_LOG file. All other production code paths are identical.
 *     - waits until `/health/ready` answers 200 (schema current, Firebase
 *       synthetic init ok);
 *     - writes a state file with every PID/URL/path the runner needs and
 *       prints the base URL.
 *
 *   node scripts/beta/stack-up.mjs --stop --state <path>
 *
 *     - SIGTERMs the gateway, removes the ephemeral container, and deletes
 *       the temp work dir.
 *
 * The same teardown runs automatically on SIGINT/SIGTERM while in "up"
 * mode. The work dir (mailbox, gateway log, container id, gateway pid)
 * lives under a fresh `mktemp -d`, recorded in the state file.
 */

import { spawn } from "node:child_process";
import { randomBytes } from "node:crypto";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import net from "node:net";

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(HERE, "..", "..");
const GATEWAY_DIR = join(ROOT, "apps", "gateway");
const TSBIN = join(GATEWAY_DIR, "node_modules", ".bin", "tsx");
const DEV_ENTRY = join(GATEWAY_DIR, "beta", "dev-entry.ts");

const POSTGRES_IMAGE = "postgres:16-alpine";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function fail(message) {
  console.error(`\nstack-up FAIL: ${message}`);
  process.exit(1);
}

function argValue(name) {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : undefined;
}

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

function allocatePort() {
  return new Promise((resolvePort) => {
    const server = net.createServer();
    server.listen(0, "127.0.0.1", () => {
      const { port } = server.address();
      server.close(() => resolvePort(port));
    });
  });
}

async function run(command, args, options = {}) {
  return new Promise((resolveRun) => {
    const child = spawn(command, args, {
      stdio: options.stdio ?? "inherit",
      env: { ...process.env, ...(options.env ?? {}) },
      cwd: options.cwd ?? ROOT,
    });
    child.on("exit", (code) => resolveRun({ code, signal: null }));
    child.on("error", (error) => {
      console.error(`stack-up run spawn error for ${command} ${args.join(" ")}: ${error.code ?? ""} ${error.message}`);
      resolveRun({ code: -1, error });
    });
  });
}

async function waitReady(url, ms = 60_000) {
  const start = Date.now();
  let lastError;
  while (Date.now() - start < ms) {
    try {
      const res = await fetch(`${url}/health/live`, { signal: AbortSignal.timeout(3000) });
      if (res.ok) {
        const ready = await fetch(`${url}/health/ready`, { signal: AbortSignal.timeout(5000) });
        if (ready.ok) {
          return await ready.text();
        }
      }
    } catch (error) {
      lastError = error;
    }
    await sleep(500);
  }
  throw new Error(`gateway never became ready: ${lastError?.message ?? "unknown"}`);
}

async function waitForPgReady(containerId, ms = 90_000) {
  const start = Date.now();
  while (Date.now() - start < ms) {
    const { code } = await run(
      "docker",
      ["exec", containerId, "pg_isready", "-U", "notify", "-d", "notify"],
      { stdio: "ignore" },
    );
    if (code === 0) return;
    await sleep(500);
  }
  throw new Error("postgres never became ready (pg_isready never succeeded)");
}

async function findContainerPort(containerId) {
  const out = await new Promise((resolveOut) => {
    const child = spawn("docker", ["port", containerId, "5432"], { stdio: ["ignore", "pipe", "ignore"] });
    let text = "";
    child.stdout.on("data", (chunk) => (text += chunk.toString()));
    child.on("exit", () => resolveOut(text.trim()));
  });
  const direct = /:(\d+)\s*$/.exec(out);
  const port = direct ? Number.parseInt(direct[1], 10) : null;
  if (port === null) throw new Error(`cannot parse docker port output: ${out}`);
  return port;
}

// ---------------------------------------------------------------------------
// Teardown
// ---------------------------------------------------------------------------

async function teardown(state) {
  const failures = [];
  if (state.gatewayPid !== undefined && state.gatewayPid > 0) {
    try {
      process.kill(state.gatewayPid, "SIGTERM");
      // Give the graceful shutdown a moment to drain (it closes sockets with
      // 1012 and ends the database pool).
      await sleep(1500);
      try {
        process.kill(state.gatewayPid, 0);
        process.kill(state.gatewayPid, "SIGKILL");
      } catch {
        // already gone
      }
    } catch (error) {
      failures.push(`gateway kill: ${error.message}`);
    }
  }
  if (state.containerId !== undefined && state.containerId !== "") {
    const { code } = await run("docker", ["rm", "-f", state.containerId], { stdio: "ignore" });
    if (code !== 0) failures.push("docker rm -f failed");
  }
  if (state.workdir !== undefined && existsSync(state.workdir)) {
    try {
      rmSync(state.workdir, { recursive: true, force: true });
    } catch (error) {
      failures.push(`workdir removal: ${error.message}`);
    }
  }
  if (failures.length > 0) {
    console.error(`stack-up teardown had issues: ${failures.join("; ")}`);
  }
}

// ---------------------------------------------------------------------------
// Up
// ---------------------------------------------------------------------------

async function up() {
  const statePath = argValue("--state");
  if (statePath === undefined) fail("--state <path> is required");
  const tag = argValue("--tag") ?? "live";
  const workdir = mkdtempSync(join(tmpdir(), `notify-beta-${tag}-`));

  const state = {
    tag,
    workdir,
    startedAt: new Date().toISOString(),
    gatewayPid: null,
    containerId: null,
    gatewayUrl: null,
    databaseUrl: null,
    mailboxPath: join(workdir, "mailbox.jsonl"),
    gatewayLog: join(workdir, "gateway.log"),
  };

  const cleanup = async (code = 0) => {
    try {
      await teardown(state);
    } finally {
      process.exit(code);
    }
  };
  process.on("SIGINT", () => void cleanup(1));
  process.on("SIGTERM", () => void cleanup(1));

  try {
    // 1. Ephemeral postgres with a random loopback host port.
    console.log("[stack-up] starting ephemeral postgres (postgres:16-alpine)...");
    const containerId = await new Promise((resolveContainer, rejectContainer) => {
      const child = spawn(
        "docker",
        [
          "run", "-d",
          "--rm",
          "-p", "127.0.0.1::5432",
          "-e", "POSTGRES_USER=notify",
          "-e", "POSTGRES_PASSWORD=notify",
          "-e", "POSTGRES_DB=notify",
          POSTGRES_IMAGE,
        ],
        { stdio: ["ignore", "pipe", "pipe"] },
      );
      let out = "";
      let err = "";
      child.stdout.on("data", (chunk) => (out += chunk.toString()));
      child.stderr.on("data", (chunk) => (err += chunk.toString()));
      child.on("exit", (code) => {
        const id = out.trim();
        if (code === 0 && id !== "") {
          resolveContainer(id);
        } else {
          rejectContainer(new Error(`docker run failed (${code}): ${err.trim() || out.trim()}`));
        }
      });
    });
    state.containerId = containerId;

    const hostPort = await findContainerPort(containerId);
    state.databaseUrl = `postgres://notify:notify@127.0.0.1:${hostPort}/notify`;
    console.log(`[stack-up] postgres up at 127.0.0.1:${hostPort}`);
    await waitForPgReady(containerId);
    // Give the fresh cluster a beat after pg_isready before the first real
    // connection; a first-run init can still be finalizing.
    await sleep(1000);

    // 2. Migrations.
    console.log("[stack-up] running migrations...");
    const migrated = await run(TSBIN, [join(GATEWAY_DIR, "src", "db", "migrate.ts")], {
      env: { DATABASE_URL: state.databaseUrl },
    });
    if (migrated.code !== 0) fail(`migrations exited ${migrated.code}`);

    // 3. Start the real gateway from source.
    const gatewayPort = await allocatePort();
    state.gatewayUrl = `http://127.0.0.1:${gatewayPort}`;
    const jwtKey = Buffer.from(randomBytes(32)).toString("base64");
    const gatewayEnv = {
      DATABASE_URL: state.databaseUrl,
      PORT: String(gatewayPort),
      PUBLIC_BASE_URL: "https://notify.beta.local",
      JWT_SIGNING_KEY: jwtKey,
      SMTP_HOST: "smtp.dev",
      SMTP_PORT: "587",
      SMTP_SECURE: "false",
      SMTP_USER: "dev",
      SMTP_PASSWORD: "dev",
      SMTP_FROM: "OpenCode Notify <notify@beta.local>",
      ALLOWED_ORIGINS: "http://localhost",
      LOG_LEVEL: "info",
      MAILBOX_PATH: state.mailboxPath,
      GATEWAY_LOG: state.gatewayLog,
    };
    console.log(`[stack-up] starting gateway on ${state.gatewayUrl}...`);
    const gateway = spawn(TSBIN, [DEV_ENTRY], {
      env: { ...process.env, ...gatewayEnv },
      cwd: GATEWAY_DIR,
      stdio: ["ignore", "pipe", "pipe"],
    });
    state.gatewayPid = gateway.pid;
    let gatewayLog = "";
    gateway.stdout.on("data", (chunk) => (gatewayLog += chunk.toString()));
    gateway.stderr.on("data", (chunk) => (gatewayLog += chunk.toString()));
    gateway.on("exit", (code, signal) => {
      state.gatewayPid = null;
      console.error(`[stack-up] gateway exited code=${code} signal=${signal}`);
    });

    // 4. Wait for readiness.
    const readyBody = await waitReady(state.gatewayUrl);
    console.log(`[stack-up] gateway ready: ${readyBody.trim()}`);

    writeFileSync(statePath, JSON.stringify(state, null, 2) + "\n");
    console.log(`[stack-up] state written to ${statePath}`);
    console.log(`[stack-up] GATEWAY_URL=${state.gatewayUrl}`);
    console.log(`[stack-up] MAILBOX_PATH=${state.mailboxPath}`);
    console.log(`[stack-up] GATEWAY_LOG=${state.gatewayLog}`);
    console.log(`[stack-up] DATABASE_URL=${state.databaseUrl}`);
  } catch (error) {
    await cleanup(1);
    fail(error instanceof Error ? error.message : String(error));
  }
}

// ---------------------------------------------------------------------------
// Stop
// ---------------------------------------------------------------------------

async function stop() {
  const statePath = argValue("--state");
  if (statePath === undefined) fail("--stop requires --state <path>");
  if (!existsSync(statePath)) {
    console.log(`[stack-up] no state file at ${statePath}; nothing to stop`);
    return;
  }
  const state = JSON.parse(readFileSync(statePath, "utf8"));
  await teardown(state);
  try {
    rmSync(statePath, { force: true });
  } catch {
    // best-effort
  }
  console.log("[stack-up] torn down: gateway stopped, container removed, workdir deleted");
}

if (process.argv.includes("--stop")) {
  stop().catch((error) => {
    console.error(error);
    process.exit(1);
  });
} else {
  up().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}
