#!/usr/bin/env node
/**
 * Create the synthetic loop account for the Issue #14 closed loop: registers
 * through the REAL gateway HTTP API, reads the 8-char code from the mailbox
 * file (the gateway's dev mailer), verifies, logs in, and creates ONE ingest
 * key whose `keyId.secret` credential is used by the TUI-driven real plugin.
 *
 * Usage: GATEWAY_URL=<url> MAILBOX_PATH=<path> scripts/beta/make-account.mjs
 *
 * Prints one JSON line: { email, password, accessToken, refreshToken,
 * credential, keyId }. Release tooling only; never CI.
 */

import { readFileSync, writeFileSync } from "node:fs";

const GATEWAY_URL = process.env.GATEWAY_URL?.replace(/\/+$/, "");
const MAILBOX_PATH = process.env.MAILBOX_PATH;
const OUT_PATH = process.env.ACCOUNT_OUT;
const NAME = process.env.ACCOUNT_NAME ?? "live-loop";

if (GATEWAY_URL === undefined || GATEWAY_URL === "") {
  console.error("make-account: GATEWAY_URL is required");
  process.exit(1);
}
if (MAILBOX_PATH === undefined || MAILBOX_PATH === "") {
  console.error("make-account: MAILBOX_PATH is required");
  process.exit(1);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function post(path, body, bearer) {
  const headers = { "Content-Type": "application/json" };
  if (bearer !== undefined) headers.Authorization = `Bearer ${bearer}`;
  const res = await fetch(`${GATEWAY_URL}${path}`, {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
  return { status: res.status, body: await res.text() };
}

const email = `loop-${Date.now()}@beta.local`;
const password = "LoopPassw0rd!";

await post("/v1/auth/register", { email, password });

let code = null;
for (let i = 0; i < 120; i++) {
  const lines = readFileSync(MAILBOX_PATH, "utf8").split("\n");
  for (const line of lines) {
    try {
      const entry = JSON.parse(line);
      if (entry.to === email && entry.kind === "verify") code = entry.code;
    } catch {
      // skip malformed lines
    }
  }
  if (code !== null) break;
  await sleep(250);
}
if (code === null) {
  console.error(`make-account: verification code never appeared for ${email}`);
  process.exit(1);
}

await post("/v1/auth/verify-email", { email, code });
const login = await post("/v1/auth/login", { email, password });
const pair = JSON.parse(login.body);
if (login.status !== 200 || pair.accessToken === undefined) {
  console.error(`make-account: login failed (${login.status}): ${login.body}`);
  process.exit(1);
}

const keyRes = await post(
  "/v1/ingest-keys",
  { name: NAME },
  pair.accessToken,
);
const key = JSON.parse(keyRes.body);
if (keyRes.status !== 201 || key.secret === undefined) {
  console.error(`make-account: ingest key creation failed (${keyRes.status}): ${keyRes.body}`);
  process.exit(1);
}

const account = {
  email,
  password,
  accessToken: pair.accessToken,
  refreshToken: pair.refreshToken,
  credential: key.secret, // already `keyId.secret`
  keyId: key.secret.split(".")[0],
  keyName: NAME,
  createdAt: new Date().toISOString(),
};

if (OUT_PATH !== undefined && OUT_PATH !== "") {
  writeFileSync(OUT_PATH, JSON.stringify(account, null, 2) + "\n");
}
process.stdout.write(JSON.stringify(account) + "\n");
