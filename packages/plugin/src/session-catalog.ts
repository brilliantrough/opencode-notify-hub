import { createOpencodeClient, type Session } from "@opencode-ai/sdk/v2";
import { validateSessionCatalog, type SessionCatalog, type SessionCatalogQuery } from "@notify/contracts";

/** Read metadata only, scoped to this Plugin's directory; never load messages. */
export class SessionCatalogAdapter {
  private readonly client;

  constructor(private readonly directory: string, baseUrl: URL, fetch: typeof globalThis.fetch) {
    this.client = createOpencodeClient({ baseUrl: baseUrl.toString(), directory, fetch });
  }

  async list(query: SessionCatalogQuery, signal: AbortSignal): Promise<SessionCatalog> {
    const limit = query.limit ?? 50;
    const [listed, statuses] = await Promise.all([
      this.client.session.list(
        { directory: this.directory, roots: true, search: query.search, limit: limit + 1 },
        { signal, throwOnError: true },
      ),
      this.client.session.status({ directory: this.directory }, { signal })
        .catch(() => ({ data: undefined })),
    ]);
    if (!Array.isArray(listed.data)) throw new Error("Invalid session list");
    const visible = (session: Session) => session.directory === this.directory &&
      !session.parentID && !session.time.archived;
    const sessions = new Map(listed.data.slice(0, limit).filter(visible).map(s => [s.id, s]));
    const ids = [...new Set(query.sessionIds?.split(",").filter(Boolean) ?? [])].slice(0, 50);
    for (const sessionID of ids) {
      if (sessions.has(sessionID)) continue;
      const result = await this.client.session.get({ directory: this.directory, sessionID }, { signal });
      if (result.response.status === 404) continue;
      if (!result.data || result.error) throw new Error("Session lookup failed");
      if (visible(result.data)) sessions.set(sessionID, result.data);
    }
    const catalog: SessionCatalog = {
      hasMore: listed.data.length > limit,
      sessions: [...sessions.values()].map(s => ({
        sessionId: s.id,
        title: s.title.slice(0, 1000),
        directory: s.directory,
        updatedAt: new Date(s.time.updated).toISOString(),
        status: statuses.data ? (statuses.data[s.id]?.type ?? "idle") : "unknown",
      })),
    };
    if (!validateSessionCatalog(catalog)) throw new Error("Invalid session catalog");
    return catalog;
  }
}
