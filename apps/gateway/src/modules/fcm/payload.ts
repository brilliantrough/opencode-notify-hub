import type { NotifyEvent } from "@notify/contracts";
import { posix, win32 } from "node:path";

/**
 * Conservative UTF-8 budget for the WHOLE push message: the serialized
 * `data.event` envelope plus the notification title/body and the JSON
 * wrapper around them. FCM's hard ceiling is 4096 bytes per message;
 * staying under 3600 leaves room for a maximum-length registration token
 * and the Android config (ttl/priority/channel) that ride along on the
 * wire.
 */
export const FCM_MESSAGE_BUDGET_BYTES = 3600;

/**
 * Absolute FCM ceiling, documented for reference: the budget above sits
 * deliberately below it so transport overhead can never push a message
 * past the hard limit. A message over budget is never submitted.
 */
export const FCM_HARD_LIMIT_BYTES = 4096;

/** Android notification channels (created client-side). */
export const CHANNEL_ALERTS = "opencode_alerts";
export const CHANNEL_SILENT = "opencode_silent";

/** Everything one Android push needs, derived from one event. */
export interface PushContent {
  title: string;
  body: string;
  /** Serialized event envelope for `data.event`, within the size budget. */
  dataEvent: string;
}

/**
 * Display-text caps for one compaction pass, in code points. `text` covers
 * question text and option labels, `section` permission summaries and
 * provider messages, `title`/`body` the notification itself. Every event
 * field keeps at least one character so the compacted envelope stays valid
 * against the contract schema (those fields declare `minLength: 1`).
 */
interface CompactionCaps {
  text: number;
  section: number;
  title: number;
  body: number;
}

const INITIAL_CAPS: CompactionCaps = { text: 500, section: 300, title: 100, body: 200 };

function utf8Bytes(text: string): number {
  return Buffer.byteLength(text, "utf8");
}

/** Code-point-safe truncation (never splits a surrogate pair). */
function truncate(text: string, maxChars: number): string {
  return [...text].slice(0, maxChars).join("");
}

/**
 * Size of the message as it goes on the wire, minus the token and Android
 * config the budget deliberately leaves headroom for.
 */
function measureMessage(title: string, body: string, dataEvent: string): number {
  return utf8Bytes(JSON.stringify({ notification: { title, body }, data: { event: dataEvent } }));
}

/**
 * Return the event with only optional display text compacted: the terminal
 * summary and option descriptions are dropped, and question text, option
 * labels, permission summaries and provider messages are truncated to the
 * caps. Identity fields (eventId, type, occurredAt, source, session,
 * outcome, kind, requestId) are never touched.
 */
function compactEvent(event: NotifyEvent, caps: CompactionCaps): NotifyEvent {
  if (event.type === "terminal") {
    const { summary: _dropped, ...rest } = event.payload;
    return { ...event, payload: rest };
  }
  if (event.type !== "action_required") {
    return event;
  }
  const payload = event.payload;
  if (payload.kind === "question") {
    return {
      ...event,
      payload: {
        ...payload,
        questions: payload.questions.map((item) => ({
          ...item,
          question: truncate(item.question, caps.text),
          ...(item.options !== undefined
            ? {
                options: item.options.map((option) => {
                  const { description: _dropped, ...rest } = option;
                  return { ...rest, label: truncate(option.label, caps.text) };
                }),
              }
            : {}),
        })),
      },
    };
  }
  if (payload.kind === "permission") {
    return {
      ...event,
      payload: {
        ...payload,
        permission: {
          ...payload.permission,
          summary: truncate(payload.permission.summary, caps.section),
        },
      },
    };
  }
  return {
    ...event,
    payload: {
      ...payload,
      providerAction: {
        ...payload.providerAction,
        message: truncate(payload.providerAction.message, caps.section),
      },
    },
  };
}

const INTERNAL_PROJECT_ID = /^(?:[0-9a-f]{32,64}|prj_[A-Za-z0-9_-]+)$/i;

function displayProject(event: NotifyEvent): string {
  if (!INTERNAL_PROJECT_ID.test(event.source.project)) {
    return event.source.project;
  }
  const path = event.source.directory.includes("\\") ? win32 : posix;
  const label = path.basename(path.normalize(event.source.directory));
  return label.length > 0 && label !== "." ? label : "unknown";
}

function statusLabel(event: NotifyEvent): string {
  if (event.type === "terminal") {
    return event.payload.outcome === "completed"
      ? "任务已完成"
      : event.payload.outcome === "failed"
        ? "任务失败"
        : "任务已停止";
  }
  if (event.type === "action_required") {
    return event.payload.kind === "question"
      ? "需要回答"
      : event.payload.kind === "permission"
        ? "需要授权"
        : "需要操作";
  }
  return event.type === "heartbeat" ? "任务进行中" : "操作已处理";
}

function questionBody(event: Extract<NotifyEvent, { type: "action_required" }>): string {
  if (event.payload.kind !== "question") {
    return "";
  }
  const shown = event.payload.questions.slice(0, 3);
  const lines = shown.flatMap((question) => [
    question.question,
    ...(question.options !== undefined && question.options.length > 0
      ? [`选项：${question.options.map((option) => option.label).join("、")}`]
      : []),
  ]);
  const remaining = event.payload.questions.length - shown.length;
  if (remaining > 0) {
    lines.push(`还有 ${remaining} 个问题`);
  }
  return lines.join("\n");
}

/** Notification title/body, derived from the (possibly compacted) event. */
function describeEvent(
  event: NotifyEvent,
  caps: CompactionCaps,
): { title: string; body: string } {
  const title = truncate(
    `${displayProject(event)} · ${event.source.machine} · ${statusLabel(event)}`,
    caps.title,
  );
  if (event.type === "terminal") {
    const base = `用时 ${event.payload.elapsedSeconds} 秒`;
    return {
      title,
      body: truncate(
        event.payload.summary === undefined ? base : `${base}\n${event.payload.summary}`,
        caps.body,
      ),
    };
  }
  if (event.type === "action_required") {
    const payload = event.payload;
    if (payload.kind === "question") {
      return {
        title,
        body: truncate(questionBody(event), caps.body),
      };
    }
    if (payload.kind === "permission") {
      return {
        title,
        body: truncate(
          `请求权限：${payload.permission.permission}\n${payload.permission.summary}`,
          caps.body,
        ),
      };
    }
    return {
      title,
      body: truncate(payload.providerAction.message, caps.body),
    };
  }
  // heartbeat / action_resolved never reach FCM; included for exhaustiveness.
  return { title: "OpenCode", body: "" };
}

/**
 * Build the push content for one event. Typical events carry the complete
 * serialized envelope unchanged. When the whole message (envelope plus
 * notification title/body and wrapper) exceeds
 * {@link FCM_MESSAGE_BUDGET_BYTES}, display text and the title/body caps
 * are compacted deterministically — caps halve each pass until the message
 * fits or every cap reaches its one-character floor. Returns null when even
 * the fully compacted message is oversized (only possible through unbounded
 * identity fields, e.g. a pathological session title): an oversize message
 * is never submitted to FCM.
 */
export function buildPushContent(event: NotifyEvent): PushContent | null {
  let caps = INITIAL_CAPS;
  let candidate = event;
  for (;;) {
    const dataEvent = JSON.stringify(candidate);
    const { title, body } = describeEvent(candidate, caps);
    if (measureMessage(title, body, dataEvent) <= FCM_MESSAGE_BUDGET_BYTES) {
      return { title, body, dataEvent };
    }
    if (caps.text === 1 && caps.section === 1 && caps.title === 1 && caps.body === 1) {
      return null;
    }
    caps = {
      text: Math.max(1, Math.floor(caps.text / 2)),
      section: Math.max(1, Math.floor(caps.section / 2)),
      title: Math.max(1, Math.floor(caps.title / 2)),
      body: Math.max(1, Math.floor(caps.body / 2)),
    };
    candidate = compactEvent(event, caps);
  }
}
