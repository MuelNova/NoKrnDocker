#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: compress-fs <directory> [output]

Create a Linux initramfs cpio archive from a directory.
The output defaults to ./rootfs.cpio.

Compression is selected by output suffix:
  .gz, .xz, .zst/.zstd, .bz2, .lz4, or no compression.
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ $# -lt 1 ]; then
  usage
  exit 0
fi

root="$1"
output="${2:-rootfs.cpio}"

if [ ! -d "$root" ]; then
  echo "missing directory: $root" >&2
  exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

(
  cd "$root"
  find . -print0 | LC_ALL=C sort -z | cpio --null -ov --format=newc > "$tmp"
)

case "$output" in
  *.gz) gzip -9c "$tmp" > "$output" ;;
  *.xz) xz -T0 -9c "$tmp" > "$output" ;;
  *.zst|*.zstd) zstd -19 -q -c "$tmp" > "$output" ;;
  *.bz2) bzip2 -9c "$tmp" > "$output" ;;
  *.lz4) lz4 -9 -q -c "$tmp" > "$output" ;;
  *) cp "$tmp" "$output" ;;
esac

echo "wrote $output"
