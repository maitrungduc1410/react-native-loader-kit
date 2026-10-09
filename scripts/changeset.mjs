// Runs the Changesets CLI with the library as the only package.
// Usage: node scripts/changeset.mjs [changeset arguments]
//
// With `workspaces` and yarn.lock in the root, Changesets (through @manypkg/get-packages) sees a
// Yarn monorepo whose only package is example/, so the library itself cannot be versioned.
// yarn.lock is hidden while the CLI runs, which makes it treat the root as a single package.
// Listing "." in `workspaces` would also work, but it breaks turbo.
import { spawn } from 'node:child_process';
import { existsSync, renameSync } from 'node:fs';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('..', import.meta.url));
const lockfile = `${root}yarn.lock`;
const hidden = `${root}yarn.lock.changeset`;

if (existsSync(hidden)) {
  if (existsSync(lockfile)) {
    console.error(
      'Both yarn.lock and yarn.lock.changeset exist; keep the right one and delete the other.'
    );
    process.exit(1);
  }
  // Left behind by a run that was killed before it could restore the lockfile.
  renameSync(hidden, lockfile);
}

const bin = createRequire(import.meta.url).resolve('@changesets/cli/bin.js');
renameSync(lockfile, hidden);
const child = spawn(process.execPath, [bin, ...process.argv.slice(2)], {
  cwd: root,
  stdio: 'inherit',
});
for (const signal of ['SIGINT', 'SIGTERM', 'SIGHUP']) {
  process.on(signal, () => child.kill(signal));
}
child.on('exit', (code) => {
  renameSync(hidden, lockfile);
  process.exit(code ?? 1);
});
