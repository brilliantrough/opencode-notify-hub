#!/usr/bin/env node
/**
 * Standalone fake OpenAI-compatible provider for the Issue #14 live closed
 * loop. Extracted from the smoke harness (`packages/plugin/scripts/
 * opencode-smoke.mjs`) so opencode can be pointed at a real HTTP server on
 * an ephemeral port instead of an in-process one.
 *
 * Behavior:
 *   - `GET /v1/models` answers a model list;
 *   - `POST /v1/chat/completions` (streaming and non-streaming) returns a
 *     `question` tool call when the first user message contains the
 *     `LIVE_Q_CLOSED_LOOP` marker, and a plain text reply once the
 *     conversation already holds a tool result (so the agent loop ends).
 *
 * Output: listens on an ephemeral port and writes JSON to `--port-file`
 * (recommended) and to stdout. Kills the server on SIGINT/SIGTERM.
 *
 * Release tooling only; never wired into CI.
 */

import { createServer } from "node:http";
import { appendFileSync, writeFileSync } from "node:fs";

const LIVE_MARKER = "LIVE_Q_CLOSED_LOOP";
const QUESTION_SENTINEL = "CLOSED_LOOP_QUESTION Which transport should the live acceptance closed loop use?";
const ANSWER_SENTINEL = "CLOSED_LOOP_ANSWER WebSocket";

const FIXTURES = {
  [LIVE_MARKER]: {
    questions: [
      {
        question: QUESTION_SENTINEL,
        header: "Transport",
        options: [
          { label: ANSWER_SENTINEL, description: "Bidirectional, push-based" },
          { label: "HTTP polling", description: "Simpler but pull-based" },
        ],
        multiple: false,
        custom: true,
      },
    ],
  },
};

function pickMarker(body) {
  const messages = Array.isArray(body?.messages) ? body.messages : [];
  for (const message of messages) {
    if (message?.role !== "user") continue;
    const text =
      typeof message.content === "string"
        ? message.content
        : JSON.stringify(message.content ?? "");
    if (typeof text === "string" && text.includes(LIVE_MARKER)) {
      return LIVE_MARKER;
    }
  }
  return null;
}

function toolCallArguments(fixture) {
  return JSON.stringify({ questions: fixture.questions });
}

function writeJson(res, body) {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify(body));
}

function writeJsonToolCall(res, fixture) {
  const id = `chatcmpl-live-${Date.now()}`;
  writeJson(res, {
    id,
    object: "chat.completion",
    created: Math.floor(Date.now() / 1000),
    model: "live-model",
    choices: [
      {
        index: 0,
        message: {
          role: "assistant",
          content: null,
          tool_calls: [
            {
              id: `call_${Date.now()}`,
              type: "function",
              function: { name: "question", arguments: toolCallArguments(fixture) },
            },
          ],
        },
        finish_reason: "tool_calls",
      },
    ],
    usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 },
  });
}

function writeJsonText(res) {
  const id = `chatcmpl-live-${Date.now()}`;
  writeJson(res, {
    id,
    object: "chat.completion",
    created: Math.floor(Date.now() / 1000),
    model: "live-model",
    choices: [
      {
        index: 0,
        message: { role: "assistant", content: "Understood. The question was answered." },
        finish_reason: "stop",
      },
    ],
    usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 },
  });
}

function sseChunk(res, id, created, delta, finish) {
  res.write(
    `data: ${JSON.stringify({
      id,
      object: "chat.completion.chunk",
      created,
      model: "live-model",
      choices: [{ index: 0, delta, finish_reason: finish ?? null }],
    })}\n\n`,
  );
}

function writeStreamToolCall(res, fixture) {
  res.writeHead(200, {
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache",
    Connection: "keep-alive",
  });
  const id = `chatcmpl-live-${Date.now()}`;
  const created = Math.floor(Date.now() / 1000);
  sseChunk(res, id, created, {
    role: "assistant",
    content: null,
    tool_calls: [
      {
        index: 0,
        id: `call_${Date.now()}`,
        type: "function",
        function: { name: "question", arguments: toolCallArguments(fixture) },
      },
    ],
  });
  sseChunk(res, id, created, {}, "tool_calls");
  res.write("data: [DONE]\n\n");
  res.end();
}

function writeStreamText(res) {
  res.writeHead(200, {
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache",
    Connection: "keep-alive",
  });
  const id = `chatcmpl-live-${Date.now()}`;
  const created = Math.floor(Date.now() / 1000);
  sseChunk(res, id, created, {
    role: "assistant",
    content: "Understood. The question was answered.",
  });
  sseChunk(res, id, created, {}, "stop");
  res.write("data: [DONE]\n\n");
  res.end();
}

const server = createServer((req, res) => {
  let raw = "";
  req.on("data", (chunk) => (raw += chunk.toString()));
  req.on("end", () => {
    let parsed = null;
    try {
      parsed = raw ? JSON.parse(raw) : null;
    } catch {
      parsed = null;
    }
    const url = req.url ?? "";
    if (req.method === "GET" && url.includes("/models")) {
      writeJson(res, {
        object: "list",
        data: [{ id: "live-model", object: "model", owned_by: "live" }],
      });
      return;
    }
    if (req.method === "POST" && url.includes("/chat/completions")) {
      recordHit(parsed);
      const marker = pickMarker(parsed);
      const fixture = marker !== null ? FIXTURES[marker] : null;
      if (fixture === null) {
        writeJsonText(res);
        return;
      }
      const hasToolResult =
        Array.isArray(parsed?.messages) && parsed.messages.some((m) => m?.role === "tool");
      if (parsed?.stream === true) {
        hasToolResult ? writeStreamText(res) : writeStreamToolCall(res, fixture);
      } else {
        hasToolResult ? writeJsonText(res) : writeJsonToolCall(res, fixture);
      }
      return;
    }
    res.writeHead(404, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: { message: `not found ${url}` } }));
  });
});

function main() {
  const portFile = process.argv.find((arg, index) => arg === "--port-file" && process.argv[index + 1])
    ? process.argv[process.argv.indexOf("--port-file") + 1]
    : null;
  const hitsFile = process.argv.find((arg, index) => arg === "--hits-file" && process.argv[index + 1])
    ? process.argv[process.argv.indexOf("--hits-file") + 1]
    : null;

  server.listen(0, "127.0.0.1", () => {
    const { port } = server.address();
    const info = { port, baseURL: `http://127.0.0.1:${port}/v1`, marker: LIVE_MARKER };
    if (portFile !== null) {
      writeFileSync(portFile, JSON.stringify(info) + "\n");
    }
    process.stdout.write(`PROVIDER_PORT=${port}\n`);
    process.stdout.write(`PROVIDER_BASE_URL=http://127.0.0.1:${port}/v1\n`);
    process.stdout.write(`PROVIDER_MARKER=${LIVE_MARKER}\n`);
    if (hitsFile !== null) {
      appendFileSync(hitsFile, JSON.stringify({ kind: "ready", at: new Date().toISOString() }) + "\n");
    }
  });
}

/**
 * Append one JSON line per chat-completions request: `{ at, marker,
 * toolResultWithAnswerSentinel }`. The last field is true when the request
 * carries a tool-role message whose content contains the answer sentinel —
 * the observable proof that the SAME session resumed with the submitted
 * answer (the provider only receives that tool result after the question
 * tool completes with our answer).
 */
function recordHit(parsed) {
  const hitsFile = process.argv.find((arg, index) => arg === "--hits-file" && process.argv[index + 1])
    ? process.argv[process.argv.indexOf("--hits-file") + 1]
    : null;
  if (hitsFile === null) return;
  let toolResultWithAnswerSentinel = false;
  if (Array.isArray(parsed?.messages)) {
    for (const message of parsed.messages) {
      if (message?.role !== "tool") continue;
      const text = typeof message.content === "string"
        ? message.content
        : JSON.stringify(message.content ?? "");
      if (typeof text === "string" && text.includes(ANSWER_SENTINEL)) {
        toolResultWithAnswerSentinel = true;
      }
    }
  }
  appendFileSync(
    hitsFile,
    JSON.stringify({
      at: new Date().toISOString(),
      marker: pickMarker(parsed),
      toolResultWithAnswerSentinel,
    }) + "\n",
  );
}

main();

const shutdown = () => {
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(0), 500).unref();
};
process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
