// Normalize the gateway OpenAPI 3.1 spec for the dart-dio generator.
//
// OpenAPI Generator 7.x does not model JSON Schema `const`; it maps a
// `const: <value>` property to a plain JsonObject, which destroys the
// NotifyEvent / WsServerMessage type discriminators. Rewriting each scalar
// `const` into a single-value `enum` makes the generator emit real enum
// classes, so oneOf deserialization selects (and rejects) variants by their
// discriminator. The transform is text-level and deterministic: every
// `const` in the spec is a scalar on its own line.
//
// Usage: node normalize-spec.mjs <input.yaml> <output.yaml>

import { readFileSync, writeFileSync } from 'node:fs';

const [input, output] = process.argv.slice(2);
if (!input || !output) {
  console.error('usage: node normalize-spec.mjs <input.yaml> <output.yaml>');
  process.exit(2);
}

const source = readFileSync(input, 'utf8');
let replaced = 0;
const normalized = source.replace(
  /^([ \t]*)const:[ \t]*(\S.*)$/gm,
  (_match, indent, value) => {
    replaced += 1;
    return `${indent}enum:\n${indent}  - ${value}`;
  },
);

if (replaced === 0) {
  console.error('normalize-spec: no `const` occurrences found; spec changed?');
  process.exit(1);
}

writeFileSync(output, normalized);
console.error(`normalize-spec: rewrote ${replaced} const -> enum occurrences`);
