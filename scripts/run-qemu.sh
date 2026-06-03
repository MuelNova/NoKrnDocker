#!/usr/bin/env bash
set -euo pipefail

KERNEL="${KERNEL:-kernel/bzImage}"
ROOTFS="${ROOTFS:-rootfs/rootfs.cpio}"
MEM="${MEM:-512M}"
SMP="${SMP:-1}"
APPEND="${APPEND:-console=ttyS0 nokaslr panic=1 oops=panic quiet}"
DEBUG="${DEBUG:-1}"
GDB_PORT="${GDB_PORT:-1234}"

if [ ! -f "$KERNEL" ]; then
  echo "missing kernel image: $KERNEL" >&2
  exit 1
fi

if [ ! -f "$ROOTFS" ]; then
  echo "missing initramfs/rootfs: $ROOTFS" >&2
  exit 1
fi

accel_args=()
if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
  accel_args=(-enable-kvm -cpu host)
else
  accel_args=(-cpu max)
fi

debug_args=()
if [ "$DEBUG" = "1" ]; then
  debug_args=(-gdb "tcp::${GDB_PORT}" -S)
fi

exec qemu-system-x86_64 \
  "${accel_args[@]}" \
  -m "$MEM" \
  -smp "$SMP" \
  -kernel "$KERNEL" \
  -initrd "$ROOTFS" \
  -append "$APPEND" \
  -nographic \
  -no-reboot \
  -monitor none \
  -serial mon:stdio \
  "${debug_args[@]}"
