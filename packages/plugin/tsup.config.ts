import { defineConfig } from "tsup";

// Single-file ESM build for the OpenCode plugin runtime (Node 22 / Bun).
// The entry is the thin `session-notify.ts` re-export so the artifact
// presents EXACTLY one default function export (older OpenCode loaders
// reject plugin modules with extra named runtime exports).
// @notify/contracts and the runtime SDK client are bundled so the installed
// artifact is self-contained. @opencode-ai/plugin is type-only and may remain
// external.
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
  banner: {
    js: 'import { createRequire as __createRequire } from "node:module"; const require = __createRequire(import.meta.url);',
  },
  noExternal: ["@notify/contracts", "@opencode-ai/sdk"],
  external: ["@opencode-ai/plugin"],
});
