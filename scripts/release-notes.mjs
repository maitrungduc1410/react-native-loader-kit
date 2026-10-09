// Prints the CHANGELOG.md section of one version, used as the body of its GitHub release.
// Usage: node scripts/release-notes.mjs 1.2.3
import { readFileSync } from 'node:fs';

const version = process.argv[2];
if (!version) {
  console.error('usage: node scripts/release-notes.mjs <version>');
  process.exit(2);
}

const lines = readFileSync(
  new URL('../CHANGELOG.md', import.meta.url),
  'utf8'
).split('\n');
// Headings look like `## 1.2.3` or `## [1.2.3](compare link)`.
const start = lines.findIndex(
  (line) => /^##\s+\[?v?([^\s\]]+)/.exec(line)?.[1] === version
);
if (start === -1) {
  console.error(`CHANGELOG.md has no section for ${version}`);
  process.exit(1);
}
let end = lines.findIndex((line, i) => i > start && /^##\s/.test(line));
if (end === -1) end = lines.length;
let notes = lines
  .slice(start + 1, end)
  .join('\n')
  .trim();

// Links relative to the repository root would resolve against the releases page.
const repository = process.env.GITHUB_REPOSITORY;
if (repository) {
  const base = `https://github.com/${repository}/blob/v${version}/`;
  notes = notes.replace(
    /\]\((?![a-z][a-z0-9+.-]*:|#|\/)([^)\s]+)\)/gi,
    `](${base}$1)`
  );
}
console.log(notes);
