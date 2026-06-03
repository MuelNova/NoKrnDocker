#!/usr/bin/env bash
set -euo pipefail

VMLINUX="${VMLINUX:-kernel/vmlinux}"
GDB_HOST="${GDB_HOST:-127.0.0.1}"
GDB_PORT="${GDB_PORT:-1234}"
GDB_BIN="${GDB_BIN:-gdb}"

if [ ! -f "$VMLINUX" ]; then
  echo "missing vmlinux with symbols: $VMLINUX" >&2
  exit 1
fi

exec "$GDB_BIN" "$VMLINUX" \
  -ex "target remote ${GDB_HOST}:${GDB_PORT}" \
  -ex "set disassembly-flavor intel" \
  -ex "set pagination off"
