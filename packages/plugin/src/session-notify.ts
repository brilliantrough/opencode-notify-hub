/**
 * Bundle entrypoint for the installable artifact.
 *
 * The deployed plugin file must present EXACTLY one export: the default
 * plugin function. Older OpenCode loaders reject plugin modules that
 * carry extra named runtime exports, so the library surface of
 * `index.ts` (`createSessionNotifyHooks`, `LOG_SERVICE`, types used by
 * tests) is deliberately NOT re-exported here. Tests continue to import
 * `index.ts` directly; this module exists only as the tsup entry for
 * `dist/session-notify.js`.
 */

export { default } from "./index.js";
