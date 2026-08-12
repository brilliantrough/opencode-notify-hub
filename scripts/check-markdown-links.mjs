import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, extname, resolve } from "node:path";

const root = resolve(import.meta.dirname, "..");
const ignored = new Set([
  ".dart_tool",
  ".git",
  ".plugin_symlinks",
  ".superpowers",
  "build",
  "dist",
  "ephemeral",
  "node_modules",
]);

function markdownFiles(directory) {
  const files = [];
  for (const entry of readdirSync(directory)) {
    if (ignored.has(entry)) continue;
    const path = resolve(directory, entry);
    const stat = statSync(path);
    if (stat.isDirectory()) files.push(...markdownFiles(path));
    else if (extname(entry).toLowerCase() === ".md") files.push(path);
  }
  return files;
}

const failures = [];
const linkPattern = /\[[^\]]*\]\(([^)]+)\)/g;

for (const file of markdownFiles(root)) {
  const content = readFileSync(file, "utf8");
  for (const match of content.matchAll(linkPattern)) {
    let target = match[1].trim();
    if (target.startsWith("<") && target.endsWith(">")) {
      target = target.slice(1, -1);
    }
    if (
      target === "" ||
      target.startsWith("#") ||
      /^[a-z][a-z0-9+.-]*:/i.test(target)
    ) {
      continue;
    }
    target = decodeURIComponent(target.split("#", 1)[0]);
    const absolute = resolve(dirname(file), target);
    if (!existsSync(absolute)) {
      const line = content.slice(0, match.index).split("\n").length;
      failures.push(`${file.slice(root.length + 1)}:${line} -> ${match[1]}`);
    }
  }
}

if (failures.length > 0) {
  console.error("Broken local Markdown links:\n" + failures.join("\n"));
  process.exit(1);
}

console.log("Markdown links: OK");
