#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: extract-vmlinux <bzImage|vmlinuz> [output]

Extract an ELF vmlinux image from a compressed Linux kernel image.
The output defaults to ./vmlinux.
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ $# -lt 1 ]; then
  usage
  exit 0
fi

input="$1"
output="${2:-vmlinux}"

if [ ! -f "$input" ]; then
  echo "missing input: $input" >&2
  exit 1
fi

if readelf -h "$input" >/dev/null 2>&1; then
  cp "$input" "$output"
  echo "wrote $output"
  exit 0
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

try_decompress() {
  local offset="$1"
  local cmd="$2"
  local candidate="$tmpdir/vmlinux"

  dd if="$input" bs=1 skip="$offset" status=none 2>/dev/null | eval "$cmd" > "$candidate" 2>/dev/null || return 1
  readelf -h "$candidate" >/dev/null 2>&1 || return 1
  cp "$candidate" "$output"
  echo "wrote $output"
  return 0
}

search_and_try() {
  local magic="$1"
  local cmd="$2"
  local offsets

  offsets="$(LC_ALL=C grep -abo "$magic" "$input" 2>/dev/null | cut -d: -f1 || true)"
  for offset in $offsets; do
    if try_decompress "$offset" "$cmd"; then
      return 0
    fi
  done
  return 1
}

search_and_try "$(printf '\037\213\010')" "gzip -dc" && exit 0
search_and_try "$(printf '\3757zXZ\000')" "xz -dc" && exit 0
search_and_try "BZh" "bzip2 -dc" && exit 0
search_and_try "$(printf '\002!L\030')" "lz4 -dc" && exit 0
search_and_try "$(printf '\050\265\057\375')" "zstd -dc" && exit 0

echo "failed to extract an ELF vmlinux from $input" >&2
exit 1
