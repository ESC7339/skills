#!/usr/bin/env python3

import os
import sys
import shutil
import argparse
import tempfile
import subprocess
import atexit
import signal
from pathlib import Path

# ==============================
# Constants and Global Defaults
# ==============================

workdir = None
workdir_provided = False
mountdir = None
isomount = None
isoroot = None
chrootdir = None
output = None
input_iso = None

# ==================
# Utility Functions
# ==================

def die(msg):
    print(f"[ERROR] {msg}", file=sys.stderr)
    sys.exit(1)

def log(msg):
    print(f"[INFO] {msg}", flush=True)

def check_root():
    if os.name == 'posix' and os.geteuid() != 0:
        die("This script must be run as root.")

def run(cmd, check=True, **kwargs):
    log(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, **kwargs)
    if check and result.returncode != 0:
        log(result.stdout)
        log(result.stderr)
        die(f"Command failed: {' '.join(cmd)}")
    return result

# ======================
# Cleanup Registration
# ======================

def cleanup():
    global isomount, workdir, workdir_provided
    log("Running cleanup...")
    if isomount and Path(isomount).is_mount():
        try:
            run(["umount", "-lf", isomount], check=False)
        except Exception:
            pass
    if not workdir_provided and workdir and Path(workdir).exists():
        log(f"Removing temporary workdir {workdir}")
        shutil.rmtree(workdir, ignore_errors=True)
    log("Cleanup complete.")

atexit.register(cleanup)
for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
    signal.signal(sig, lambda signum, frame: sys.exit(1))

# ================
# Argument Parsing
# ================

def parse_args():
    parser = argparse.ArgumentParser(description="Custom ISO build script in Python")
    parser.add_argument("-i", "--input", required=True, help="Path to base ISO")
    parser.add_argument("-o", "--output", help="Path to output ISO/image")
    parser.add_argument("-w", "--workdir", help="Work directory (optional)")
    parser.add_argument("-d", "--debug", action="store_true", help="Enable debug logging")
    parser.add_argument("--clean", action="store_true", help="Run cleanup and exit")
    return parser.parse_args()

# ===============
# Main Execution
# ===============

def main():
    global workdir, workdir_provided, mountdir, chrootdir, isoroot, isomount, output, input_iso

    args = parse_args()
    check_root()

    input_iso = Path(args.input).resolve()
    if not input_iso.is_file():
        die(f"Input ISO not found: {input_iso}")

    if args.clean:
        cleanup()
        return

    if args.workdir:
        workdir = Path(args.workdir).resolve()
        workdir_provided = True
    else:
        workdir = Path(tempfile.mkdtemp(prefix="sudobuild-"))

    mountdir = workdir / "iso-mount"
    isoroot = workdir / "iso-root"
    chrootdir = workdir / "chroot"
    for path in (mountdir, isoroot, chrootdir):
        path.mkdir(parents=True, exist_ok=True)

    isomount = str(mountdir)

    if args.output:
        output = Path(args.output).resolve()
    else:
        output = input_iso.with_name(f"{input_iso.stem}-custom.img")

    if not str(output).lower().endswith(".img"):
        die("Output must end in .img")

    log(f"Input ISO: {input_iso}")
    log(f"Output: {output}")
    log(f"Workdir: {workdir} (provided={workdir_provided})")

    # Mount ISO
    log("Mounting ISO...")
    run(["mount", "-o", "loop", str(input_iso), isomount])

    # Copy ISO contents
    log(f"Copying ISO contents to {isoroot}")
    run(["cp", "-a", f"{isomount}/.", str(isoroot)])

    # unsquashfs / chroot patching
    log("Preparing chroot patching (placeholder)...")
    #  Extract squashfs, modify chrootdir, etc.

    #  generate final image
    log(f"Writing final image to {output} (placeholder)...")
    #  mkisofs/genisoimage logic

    log("Script completed successfully.")

if __name__ == "__main__":
    main()
