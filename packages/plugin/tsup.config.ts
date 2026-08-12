import { defineConfig } from "tsup";

// Single-file ESM build for the OpenCode plugin runtime (Node 22 / Bun).
// The entry is the thin `session-notify.ts` re-export so the artifact
// presents EXACTLY one default function export (older OpenCode loaders
// reject plugin modules with extra named runtime exports).
// @notify/contracts is bundled so the artifact is self-contained, while the
// OpenCode runtime packages stay external and are provided by the host.
export default defineConfig({
  entry: {
    "session-notify": "src/session-notify.ts",
  },
  format: ["esm"],
  platform: "node",
  target: "node22",
  dts: true,
  sourcemap: true,
  clean: true,
  noExternal: ["@notify/contracts"],
  external: ["@opencode-ai/plugin", "@opencode-ai/sdk"],
});
