#!/usr/bin/env bash
set -euo pipefail

python --version
gdb --configuration | grep -i python || true
gdb -q -nx \
  -ex 'python import sys; print("gdb python:", sys.version.replace("\n", " "))' \
  -ex quit
qemu-system-x86_64 --version | head -n 1
python - <<'PY'
import capstone
import pwn
print("capstone:", capstone.__version__)
print("pwntools:", pwn.version)
PY
