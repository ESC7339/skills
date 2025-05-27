#!/usr/bin/env node



const { execSync, spawnSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { program } = require('commander');

function abs(p) {
  return path.resolve(p);
}

function exists(p) {
  try {
    fs.accessSync(p, fs.constants.R_OK);
    return true;
  } catch {
    return false;
  }
}

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function run(cmd, args) {
  console.log(`[INFO] Running: ${cmd} ${args.join(' ')}`);
  const result = spawnSync(cmd, args, { stdio: 'inherit' });
  if (result.status !== 0) {
    console.error(`[ERROR] Command failed: ${cmd} ${args.join(' ')}`);
    process.exit(result.status);
  }
}

function isRoot() {
  return process.getuid && process.getuid() === 0;
}

program
  .requiredOption('-i, --input <path>', 'Input ISO path')
  .option('-o, --output <path>', 'Output image path (.img)')
  .option('-w, --workdir <path>', 'Working directory');

program.parse(process.argv);
const options = program.opts();

if (!isRoot()) {
  console.error('[ERROR] Must be run as root.');
  process.exit(1);
}

const inputISO = abs(options.input);
if (!exists(inputISO)) {
  console.error(`[ERROR] Input ISO does not exist: ${inputISO}`);
  process.exit(1);
}

const baseName = path.basename(inputISO, path.extname(inputISO));
const outputImage = abs(options.output || `${baseName}-custom.img`);

if (!outputImage.endsWith('.img')) {
  console.error('[ERROR] Output image must end in .img');
  process.exit(1);
}

const workDir = abs(options.workdir || path.join(os.tmpdir(), `sudobuild-${process.pid}`));
const isoMount = path.join(workDir, 'iso-mount');
const isoRoot = path.join(workDir, 'iso-root');
const chrootDir = path.join(workDir, 'chroot');

ensureDir(isoMount);
ensureDir(isoRoot);
ensureDir(chrootDir);

const cleanupTasks = [];

function cleanup() {
  console.log('[INFO] Performing cleanup...');
  try {
    run('umount', ['-lf', isoMount]);
  } catch {}
  if (!options.workdir) {
    try {
      fs.rmSync(workDir, { recursive: true, force: true });
    } catch {}
  }
}

process.on('exit', cleanup);
process.on('SIGINT', () => process.exit(1));
process.on('SIGTERM', () => process.exit(1));

console.log('[INFO] Input ISO:', inputISO);
console.log('[INFO] Output Image:', outputImage);
console.log('[INFO] Workdir:', workDir);

run('mount', ['-o', 'loop', inputISO, isoMount]);
run('cp', ['-a', `${isoMount}/.`, isoRoot]);

console.log('[INFO] Placeholder: chroot patching to be implemented...');
// unsquashfs, chroot, patching, resquash

console.log('[INFO] Placeholder: writing final ISO...');
// xorriso or genisoimage invocation

console.log('[INFO] Build completed.');
