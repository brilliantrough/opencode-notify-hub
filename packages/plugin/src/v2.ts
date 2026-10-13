import { setTimeout as delay } from "node:timers/promises";
import { loadConfig } from "./config.js";
import { createSessionNotifyHooks, type HostSession } from "./index.js";
import { createSafeLogger } from "./log.js";
import { hostSession, questionFromForm, V2Api, type V2Form, type V2Session } from "./v2-api.js";

/** Structural subset of @opencode/plugin's Promise context; no runtime SDK dependency. */
export interface V2Context {
  app: { version: string };
  location: { directory: string; project: { directory: string; canonical: string } };
  session: { get(input: { sessionID: string }): Promise<V2Session> };
  event: { subscribe(options: { signal: AbortSignal }): AsyncIterable<{
    type: string;
    data: Record<string, unknown>;
    location?: { directory: string };
  }> };
}

export async function setupV2(ctx: V2Context) {
  const config = loadConfig();
  const logger = createSafeLogger({
    service: "opencode-notify",
    secrets: config ? [config.ingestKey.secret, `${config.ingestKey.keyId}.${config.ingestKey.secret}`] : [],
    sink: entry => console.error(`[${entry.service}] ${entry.level}: ${entry.message}`),
  });
  if (!config) {
    logger.warn("opencode-notify disabled: missing or invalid NOTIFY_* configuration");
    return;
  }
  const directory = ctx.location.directory;
  const sessions = new Map<string, HostSession>();
  const api = new V2Api(directory, id => sessions.get(id)?.title);
  const controller = new AbortController();
  let endpointWarning = false;
  const getSession = async (id: string) => {
    const session = hostSession(await ctx.session.get({ sessionID: id }));
    if (session.id !== id || session.directory !== directory) throw new Error("Session is outside this plugin location");
    sessions.set(id, session);
    return session;
  };
  const hooks = createSessionNotifyHooks({
    directory,
    worktree: ctx.location.project.directory,
    project: { worktree: ctx.location.project.canonical },
    client: {
      app: { log: ({ body }) => console.error(`[${body.service}] ${body.level}: ${body.message}`) },
      session: {
        get: async ({ path }) => ({ data: await getSession(path.id) }),
        list: async ({ query, signal }) => {
          const page = await api.sessions(query.limit, signal);
          for (const session of page.data) if (session.directory === directory) sessions.set(session.id, session);
          return page;
        },
      },
    },
  }, config, {
    logger,
    remote: {
      resolveOpenCodeVersion: async () => {
        try { await api.probe(); return ctx.app.version; }
        catch (error) {
          if (!endpointWarning && !controller.signal.aborted) logger.warn("notify: V2 HTTP endpoint unavailable; dedicated serve requires NOTIFY_OPENCODE_URL and NOTIFY_OPENCODE_PASSWORD");
          endpointWarning = true;
          throw error;
        }
      },
      webUiAvailable: () => api.webUiAvailable,
      listPendingInteractions: (source, signal) => api.listPending(source, signal),
      answerQuestion: (id, session, answers, signal) => api.answer(id, session, answers, signal),
      decidePermission: (id, session, decision, signal) => api.decide(id, session, decision, signal),
      sendPrompt: (session, text, signal) => api.prompt(session, text, signal),
      listSessions: (query, signal) => api.catalog(query, signal),
      webUiRequest: (request, signal, emit) => api.webUi(request, signal, emit),
    },
  });
  // The shared pipeline still consumes V1-shaped events; only this boundary translates V2.
  const emit = (type: string, properties: unknown) => hooks.event?.({ event: { type, properties } } as Parameters<NonNullable<typeof hooks.event>>[0]);

  const run = async () => {
    while (!controller.signal.aborted) {
      try {
        for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
          if (controller.signal.aborted) break;
          const { type, data } = event;
          if (!data || (event.location && event.location.directory !== directory && type !== "session.moved")) continue;
          try {
            const sessionID = typeof data.sessionID === "string" ? data.sessionID : undefined;
            if (["session.created", "session.renamed", "session.moved", "session.forked", "session.metadata.updated"].includes(type) && sessionID) {
              const target = (data.location as { directory?: string } | undefined)?.directory;
              if (type === "session.moved" && target && target !== directory) {
                if (sessions.has(sessionID)) {
                  await emit("session.deleted", { info: sessions.get(sessionID) });
                  sessions.delete(sessionID);
                }
              } else await emit("session.updated", { info: await getSession(sessionID) });
            } else if (type === "session.deleted" && sessionID) {
              await emit(type, { info: { id: sessionID, directory, title: sessions.get(sessionID)?.title ?? "" } });
              sessions.delete(sessionID);
            } else if (type === "session.status") {
              await emit(type, data);
            } else if (type === "session.retry.scheduled") {
              await emit("session.status", { sessionID, status: { type: "retry", attempt: data.attempt, next: data.at,
                message: (data.error as { message?: string } | undefined)?.message ?? "" } });
            } else if (type === "session.step.started") {
              await emit("session.status", { sessionID, status: { type: "busy" } });
            } else if (type === "session.execution.started" || type === "session.execution.succeeded") {
              await emit("session.status", { sessionID, status: { type: type.endsWith("started") ? "busy" : "idle" } });
            } else if (type === "session.execution.failed" || type === "session.execution.interrupted") {
              await emit("session.error", { sessionID, error: { name: type.endsWith("interrupted") ? "MessageAbortedError" : "V2ExecutionError" } });
            } else if (type === "session.text.ended") {
              const messageID = data.assistantMessageID;
              await emit("message.updated", { info: { id: messageID, sessionID, role: "assistant" } });
              await emit("message.part.updated", { part: { id: `${messageID}:${data.ordinal}`, messageID, sessionID, type: "text", text: data.text } });
            } else if (type === "form.created") {
              const question = questionFromForm(data.form as V2Form);
              if (question) await emit("question.asked", question);
            } else if (type === "form.replied" || type === "form.cancelled") {
              await emit("question.replied", { sessionID, requestID: data.id });
            } else if (type === "permission.asked") {
              await emit(type, { ...data, permission: data.action, patterns: data.resources });
            } else if (type === "permission.replied") {
              await emit(type, data);
            }
          } catch { logger.warn("notify: V2 event could not be processed"); }
        }
      } catch {
        if (!controller.signal.aborted) logger.warn("notify: V2 event subscription interrupted; reconnecting");
      }
      if (!controller.signal.aborted) await delay(1000, undefined, { signal: controller.signal }).catch(() => {});
    }
  };
  const stream = run();
  return async () => {
    controller.abort();
    await hooks.dispose?.();
    await stream;
    sessions.clear();
  };
}
