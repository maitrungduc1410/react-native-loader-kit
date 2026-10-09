// Copies the Swift sources of LoaderKit (https://github.com/maitrungduc1410/loader-kit) into
// ios/vendor/loader-kit, so the pod of this library builds them as part of its own module.
// The version is the one of the `@loader-kit/spec` dependency: JS, Android (Maven Central) and
// iOS always use the same LoaderKit release.
//
// Usage:
//   node scripts/sync-core.mjs                  copy the sources of the pinned release tag
//   node scripts/sync-core.mjs --from ../loader-kit
//                                               copy from a local checkout (for development)
//   node scripts/sync-core.mjs --check          fail when ios/vendor differs from the pinned tag
import { execFileSync } from 'node:child_process';
import {
  cpSync,
  existsSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  rmSync,
  statSync,
  writeFileSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPOSITORY = 'https://github.com/maitrungduc1410/loader-kit.git';
const TARGETS = ['LoaderKitCore', 'LoaderKit'];

const root = fileURLToPath(new URL('..', import.meta.url));
const vendor = join(root, 'ios', 'vendor', 'loader-kit');
const pkg = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8'));
const version = pkg.dependencies?.['@loader-kit/spec'];
if (!version || !/^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$/.test(version)) {
  console.error(
    'package.json must pin an exact version of @loader-kit/spec, for example "1.0.0".'
  );
  process.exit(1);
}

const args = process.argv.slice(2);
const check = args.includes('--check');
const fromIndex = args.indexOf('--from');
const from = fromIndex === -1 ? undefined : args[fromIndex + 1];

function checkout() {
  if (from) return { dir: resolve(from), label: relative(root, resolve(from)) };
  const dir = mkdtempSync(join(tmpdir(), 'loader-kit-'));
  execFileSync(
    'git',
    ['clone', '--quiet', '--depth', '1', '--branch', version, REPOSITORY, dir],
    { stdio: 'inherit' }
  );
  return { dir, label: version, temporary: true };
}

function listFiles(dir, base = dir) {
  if (!existsSync(dir)) return [];
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory()
      ? listFiles(path, base)
      : [relative(base, path)];
  });
}

function sync(source) {
  const sources = join(source.dir, 'apple', 'Sources');
  for (const target of TARGETS) {
    if (!existsSync(join(sources, target))) {
      console.error(`${source.label} has no apple/Sources/${target}`);
      return 1;
    }
  }
  const stamp = `${from ? 'local checkout' : version}\n`;
  const pairs = TARGETS.flatMap((target) => {
    const files = new Set([
      ...listFiles(join(sources, target)),
      ...listFiles(join(vendor, target)),
    ]);
    return [...files].map((file) => [
      join(sources, target, file),
      join(vendor, target, file),
      `${target}/${file}`,
    ]);
  });
  pairs.push([join(source.dir, 'LICENSE'), join(vendor, 'LICENSE'), 'LICENSE']);

  if (!check) {
    rmSync(vendor, { recursive: true, force: true });
    for (const target of TARGETS) {
      cpSync(join(sources, target), join(vendor, target), { recursive: true });
    }
    cpSync(join(source.dir, 'LICENSE'), join(vendor, 'LICENSE'));
    writeFileSync(join(vendor, 'VERSION'), stamp);
    console.log(`Copied LoaderKit ${source.label} into ios/vendor/loader-kit.`);
    return 0;
  }

  const differences = pairs
    .filter(
      ([a, b]) =>
        !existsSync(a) ||
        !existsSync(b) ||
        !readFileSync(a).equals(readFileSync(b))
    )
    .map(([, , label]) => label);
  const recorded = existsSync(join(vendor, 'VERSION'))
    ? readFileSync(join(vendor, 'VERSION'), 'utf8')
    : '';
  if (recorded !== stamp) differences.push('VERSION');
  if (differences.length > 0) {
    console.error(
      `ios/vendor/loader-kit does not match LoaderKit ${source.label}; run \`yarn sync-core\`:\n` +
        differences.map((file) => `  ${file}`).join('\n')
    );
    return 1;
  }
  console.log(`ios/vendor/loader-kit matches LoaderKit ${source.label}.`);
  return 0;
}

const source = checkout();
try {
  process.exitCode = sync(source);
} finally {
  if (source.temporary) rmSync(source.dir, { recursive: true, force: true });
}
