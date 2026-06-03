#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: kcompile [exploit.c]

Compile an exploit, copy it into an initramfs tree, and repack the rootfs.

Environment variables:
  SRC       source file, default: exploit.c or first positional argument
  FS        initramfs directory, default: rootfs/initramfs
  OUT       path inside FS, default: exploit
  ROOTFS    output archive, default: rootfs/rootfs.cpio
  CC        compiler, default: musl-gcc
  CFLAGS    compiler flags, default: -static -O2 -Wall -Wextra
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

src="${SRC:-${1:-exploit.c}}"
fs="${FS:-rootfs/initramfs}"
out_name="${OUT:-exploit}"
rootfs="${ROOTFS:-rootfs/rootfs.cpio}"
cc="${CC:-musl-gcc}"
cflags="${CFLAGS:--static -O2 -Wall -Wextra}"

if [ ! -f "$src" ]; then
  echo "missing source: $src" >&2
  exit 1
fi

if [ ! -d "$fs" ]; then
  echo "missing initramfs directory: $fs" >&2
  exit 1
fi

mkdir -p "$(dirname "$fs/$out_name")"

# shellcheck disable=SC2086
"$cc" $cflags "$src" -o "$fs/$out_name"
chmod +x "$fs/$out_name"

compress-fs "$fs" "$rootfs"
