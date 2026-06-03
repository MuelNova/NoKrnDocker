#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: extract-fs <rootfs.cpio[.gz|.xz|.zst|.bz2|.lz4]> [directory]

Extract an initramfs cpio archive into a directory.
The output directory defaults to ./initramfs.
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ $# -lt 1 ]; then
  usage
  exit 0
fi

archive="$1"
outdir="${2:-initramfs}"

if [ ! -f "$archive" ]; then
  echo "missing archive: $archive" >&2
  exit 1
fi

if [ -e "$outdir" ] && [ "$(find "$outdir" -mindepth 1 -print -quit 2>/dev/null)" ]; then
  echo "refusing to extract into non-empty directory: $outdir" >&2
  exit 1
fi

mkdir -p "$outdir"

case "$archive" in
  *.gz) decompress=(gzip -dc "$archive") ;;
  *.xz) decompress=(xz -dc "$archive") ;;
  *.zst|*.zstd) decompress=(zstd -dc "$archive") ;;
  *.bz2) decompress=(bzip2 -dc "$archive") ;;
  *.lz4) decompress=(lz4 -dc "$archive") ;;
  *) decompress=(cat "$archive") ;;
esac

(
  cd "$outdir"
  "${decompress[@]}" | cpio -idmv --no-absolute-filenames
)

echo "extracted $archive to $outdir"
