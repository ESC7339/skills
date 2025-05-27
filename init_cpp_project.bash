#!/bin/bash

#USAGE:
#chmod +x init_cpp_project.sh
#./init_cpp_project.sh /opt/my_cpp_project


set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <target-directory>"
  exit 1
fi

BASE_DIR="$1"

declare -A descriptions=(
  [bin]="Compiled binaries for the application go here."
  [lib]="Static or shared libraries used or produced by the application."
  [include]="C++ header files for the project's public interface."
  [src]="C++ source code files implementing application logic."
  [etc]="Configuration files used by the application."
  [logs]="Log output generated during development or runtime."
  [tests]="Unit tests, integration tests, and test data."
  [docs]="Documentation related to the project."
  [build]="Temporary build artifacts (cleanable)."
  [tmp]="Temporary workspace for generated or intermediate files."
  [run]="Runtime state files like PID files or UNIX sockets."
)

for dir in "${!descriptions[@]}"; do
  mkdir -p "$BASE_DIR/$dir"
  echo "${descriptions[$dir]}" > "$BASE_DIR/$dir/README.txt"
done

LOG_TARGET="/var/log/$(basename "$BASE_DIR").log"
LOG_LINK="$BASE_DIR/logs/$(basename "$LOG_TARGET")"

touch "$LOG_TARGET"
ln -sf "$LOG_TARGET" "$LOG_LINK"
