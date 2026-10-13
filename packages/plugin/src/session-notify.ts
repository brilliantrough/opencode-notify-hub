import { SessionNotifyPlugin } from "./index.js";
import { setupV2 } from "./v2.js";

/** Single-file entrypoint: OpenCode 1.18.29+ calls server; OpenCode 2 calls setup. */
export default {
  id: "opencode-notify",
  server: (input: Parameters<typeof SessionNotifyPlugin>[0]) => SessionNotifyPlugin(input),
  setup: setupV2,
};
