/**
 * Release-tooling stand-in for the OpenCode plugin's external behavior.
 *
 * Issue #14 live closed loop only: this daemon is the honest alternative for
 * the plugin-INSIDE-opencode half of the loop, because no 1.18.18 launch mode
 * exposes the pending-question store to the plugin's `input.serverUrl`:
 *
 *   - `serve`/`web` never invoke the plugin factory;
 *   - `run` invokes it but denies the question tool headless;
 *   - the standalone TUI invokes the factory and its event hook works, but
 *     its `input.serverUrl` (`http://localhost:4096/`) has no reachable
 *     listener (verified with NO_PROXY + direct node:http → ECONNREFUSED);
 *   - `serve + attach` invokes the factory, fires the event hook, and
 *     registers the control channel as CONTROLLABLE, but the pending question
 *     lives in the attach process's private store while the plugin's
 *     `input.serverUrl` (the serve listener) does not hold it — the serve's
 *     question list and session messages are empty for the attached session
 *     (verified), so the plugin's pending/reply adapters can never reach the
 *     question and the answer round-trip cannot complete.
 *
 * This daemon therefore reproduces the plugin's EXTERNAL wire contract
 * against the REAL gateway and a REAL `opencode serve` instance (whose HTTP
 * listener IS reachable and DOES hold the pending question), reusing the
 * production plugin modules:
 *
 *   - notification delivery: subscribes to the real opencode `/api/event` SSE
 *     stream and, on `question.v2.asked` / `question.v2.replied`, builds the
 *     exact contract envelopes (`EnvelopeFactory`) and POSTs them to the real
 *     gateway `/v1/events` HMAC-signed (`GatewaySender`);
 *   - remote unblock: runs the production `ControlChannel` (register +
 *     `pending_snapshot_response` + `question_answer_result` /
 *     `permission_decide_result`) with the production V2 adapters
 *     (`PendingAdapter` / `QuestionReplyAdapter` / `PermissionReplyAdapter`)
 *     so the gateway can snapshot pending questions and route the client's
 *     answer command into the REAL opencode session.
 *
 * Configuration uses the exact same `NOTIFY_*` variables as the plugin
 * (`loadConfig`), plus `OPENCODE_BASE_URL` and `NOTIFY_DIRECTORY`. Run under
 * tsx from the plugin package so workspace imports resolve.
 *
 * Release tooling only; never wired into CI.
 */

import { createOpencodeClient } from "@opencode-ai/sdk/v2";
import { basename } from "node:path";

import { loadConfig, type PluginConfig } from "../../src/config.js";
import { ControlChannel } from "../../src/control-channel.js";
import { EnvelopeFactory } from "../../src/envelope.js";
import { PendingAdapter } from "../../src/pending-adapter.js";
import { PermissionReplyAdapter } from "../../src/permission-reply-adapter.js";
import { QuestionReplyAdapter } from "../../src/question-reply-adapter.js";
import { GatewaySender } from "../../src/sender.js";

const ENV = process.env;

function required(name: string): string {
  const value = ENV[name]?.trim();
  if (value === undefined || value === "") {
    console.error(`notify-daemon: ${name} is required`);
    process.exit(1);
  }
  return value;
}

const titleStore = new Map<string, string>();

function sessionTitle(sessionID: string): string {
  return titleStore.get(sessionID) ?? "";
}

function failClosed(detail: string): void {
  console.error(`notify-daemon: ${detail}`);
}

function describe(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function asNonEmptyString(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}

interface StreamHandlers {
  onQuestionAsked(sessionID: string, requestId: string, rawQuestions: Array<Record<string, unknown>>): void;
  onQuestionResolved(sessionID: string | undefined, requestId: string): void;
  onSessionUpsert(sessionID: string | null, title: unknown): void;
  onStarted(): void;
  onLog(detail: string): void;
}

function handleEvent(event: Record<string, unknown>, handlers: StreamHandlers): void {
  const type = event.type as string;
  const data = isRecord(event.data) ? event.data : null;
  switch (type) {
    case "session.created":
    case "session.updated": {
      const sessionID = asNonEmptyString(data?.sessionID) ?? asNonEmptyString(data?.id);
      handlers.onSessionUpsert(sessionID, data?.title);
      return;
    }
    case "question.v2.asked": {
      const requestId = asNonEmptyString(data?.id);
      const sessionID = asNonEmptyString(data?.sessionID);
      if (requestId === null || sessionID === null) return;
      const rawQuestions = Array.isArray(data?.questions)
        ? (data.questions as Array<Record<string, unknown>>)
        : [];
      handlers.onQuestionAsked(sessionID, requestId, rawQuestions);
      return;
    }
    case "question.v2.replied":
    case "question.v2.rejected":
    case "question.v2.resolved": {
      const requestId = asNonEmptyString(data?.requestID) ?? asNonEmptyString(data?.id);
      if (requestId === null) return;
      handlers.onQuestionResolved(asNonEmptyString(data?.sessionID) ?? undefined, requestId);
      return;
    }
    default:
      return;
  }
}

async function runEventStream(baseUrl: string, handlers: StreamHandlers): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, 500));
  handlers.onStarted();
  try {
    const response = await fetch(`${baseUrl}/api/event`, {
      headers: { Accept: "text/event-stream" },
    });
    if (!response.ok || response.body === null) {
      handlers.onLog(`event stream HTTP ${response.status}`);
      await reconnectLater(baseUrl, handlers);
      return;
    }
    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      let index: number;
      while ((index = buffer.indexOf("\n\n")) !== -1) {
        const frame = buffer.slice(0, index);
        buffer = buffer.slice(index + 2);
        const dataLine = frame.split("\n").find((line) => line.startsWith("data:"));
        if (dataLine === undefined) continue;
        let event: unknown;
        try {
          event = JSON.parse(dataLine.slice(5));
        } catch {
          continue;
        }
        if (!isRecord(event) || typeof event.type !== "string") continue;
        handleEvent(event, handlers);
      }
    }
  } catch (error) {
    handlers.onLog(`event stream error (${describe(error)}); reconnecting`);
  }
  await reconnectLater(baseUrl, handlers);
}

function reconnectLater(baseUrl: string, handlers: StreamHandlers): Promise<void> {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve(runEventStream(baseUrl, handlers));
    }, 1000);
  });
}

function main(): void {
  const config: PluginConfig | null = loadConfig();
  if (config === null) {
    console.error("notify-daemon: invalid or missing NOTIFY_* configuration");
    process.exit(1);
  }

  const opencodeBaseUrl = required("OPENCODE_BASE_URL");
  const directory = required("NOTIFY_DIRECTORY");
  const project = basename(directory) || "unknown";
  const source = {
    machine: config.machine,
    project,
    directory,
  };

  const envelopes = new EnvelopeFactory({
    source,
    includeSummary: config.includeSummary,
  });
  const sender = new GatewaySender({
    gatewayUrl: config.gatewayUrl,
    ingestKey: config.ingestKey,
    timeoutMs: config.httpTimeoutMs,
    maxRetries: config.maxRetries,
  });

  const emit = (build: () => ReturnType<EnvelopeFactory["actionRequired"] | EnvelopeFactory["actionResolved"]>): void => {
    try {
      const event = build();
      void sender.send(event as never).catch((error) => {
        failClosed(
          `event delivery failed (${error instanceof Error ? error.message : String(error)})`,
        );
      });
    } catch (error) {
      failClosed(
        `event validation failed; dropping (${error instanceof Error ? error.message : String(error)})`,
      );
    }
  };

  const sessionOf = (sessionID: string): { id: string; title?: string } => {
    const title = sessionTitle(sessionID);
    return title.length > 0 ? { id: sessionID, title } : { id: sessionID };
  };

  const client = createOpencodeClient({ baseUrl: opencodeBaseUrl, directory });
  const v2 = client.v2;
  let pendingAdapter: PendingAdapter | null = null;
  let answerer: QuestionReplyAdapter | null = null;
  let decider: PermissionReplyAdapter | null = null;

  const control = new ControlChannel({
    gatewayUrl: config.gatewayUrl,
    credential: `${config.ingestKey.keyId}.${config.ingestKey.secret}`,
    machine: source.machine,
    project: source.project,
    directory,
    resolveOpenCodeVersion: async () => {
      try {
        const result = await client.global.health();
        return result.data?.version ?? "unknown";
      } catch {
        return "unknown";
      }
    },
    listPendingInteractions: (pendingSource, signal) => {
      pendingAdapter ??= new PendingAdapter({
        client: v2,
        titleForSession: (sessionID) => titleStore.get(sessionID),
      });
      return pendingAdapter.list(pendingSource, signal);
    },
    answerQuestion: (requestId, answerDirectory, answers, signal) => {
      answerer ??= new QuestionReplyAdapter({ client: v2 });
      return answerer.reply(requestId, answerDirectory, answers, signal);
    },
    decidePermission: (requestId, decisionDirectory, decision, signal) => {
      decider ??= new PermissionReplyAdapter({ client: v2 });
      return decider.reply(requestId, decisionDirectory, decision, signal);
    },
  });

  let controlStarted = false;
  const startControl = (): void => {
    if (controlStarted) return;
    controlStarted = true;
    try {
      control.start();
    } catch (error) {
      failClosed(`control channel failed to start (${describe(error)})`);
    }
  };

  const shutdown = async (): Promise<void> => {
    try {
      await control.stop();
    } catch {
      // best-effort
    }
    process.exit(0);
  };
  process.on("SIGINT", () => void shutdown());
  process.on("SIGTERM", () => void shutdown());

  void runEventStream(opencodeBaseUrl, {
    onQuestionAsked: (sessionID, requestId, rawQuestions) => {
      const questions = rawQuestions
        .map((item) => ({
          question: typeof item?.question === "string" ? item.question : "",
          options: Array.isArray(item?.options)
            ? item.options
                .filter((option) => typeof option?.label === "string")
                .map((option) => ({
                  label: option.label,
                  ...(typeof option.description === "string" ? { description: option.description } : {}),
                }))
            : [],
          multiple: typeof item?.multiple === "boolean" ? item.multiple : undefined,
        }))
        .filter((item) => item.question.length > 0);
      if (questions.length === 0) {
        failClosed(`question.v2.asked ${requestId}: no nonempty question remains`);
        return;
      }
      emit(() =>
        envelopes.actionRequired(sessionOf(sessionID), {
          kind: "question",
          sessionID,
          requestId,
          questions,
        }),
      );
    },
    onQuestionResolved: (sessionID, requestId) => {
      emit(() =>
        envelopes.actionResolved(sessionOf(sessionID ?? ""), {
          sessionID: sessionID ?? "",
          requestId,
          kind: "question",
        }),
      );
    },
    onSessionUpsert: (sessionID, title) => {
      if (sessionID !== null && typeof title === "string") {
        titleStore.set(sessionID, title);
      }
    },
    onStarted: () => startControl(),
    onLog: failClosed,
  });
}

main();
