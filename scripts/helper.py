#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
from pathlib import Path


def upload(io, local: str | Path, remote: str, chunk_size: int = 0x300) -> None:
    """Upload a local file to a shell using base64 chunks.

    The target shell needs common BusyBox/coreutils commands: printf, base64,
    chmod, and optionally sync. This works well for serial shells reached
    through pwntools.
    """

    data = Path(local).read_bytes()
    encoded = base64.b64encode(data).decode()

    io.sendline(f": > {remote}.b64".encode())
    for i in range(0, len(encoded), chunk_size):
        chunk = encoded[i : i + chunk_size]
        io.sendline(f"printf '%s' '{chunk}' >> {remote}.b64".encode())

    io.sendline(f"base64 -d {remote}.b64 > {remote}".encode())
    io.sendline(f"chmod +x {remote}".encode())
    io.sendline(f"rm -f {remote}.b64".encode())
    io.sendline(b"sync")


def recv_until_prompt(io, prompt: bytes = b"# ", timeout: float | None = None) -> bytes:
    return io.recvuntil(prompt, timeout=timeout)


def p64(value: int) -> bytes:
    return value.to_bytes(8, "little", signed=False)


def p32(value: int) -> bytes:
    return value.to_bytes(4, "little", signed=False)


def u64(data: bytes) -> int:
    return int.from_bytes(data[:8].ljust(8, b"\x00"), "little")


def u32(data: bytes) -> int:
    return int.from_bytes(data[:4].ljust(4, b"\x00"), "little")


def kbase(leak: int, symbol_offset: int) -> int:
    return leak - symbol_offset


def main() -> int:
    parser = argparse.ArgumentParser(description="Small NoKrnDocker helper utilities")
    sub = parser.add_subparsers(dest="cmd", required=True)

    b64 = sub.add_parser("b64", help="print base64 for a file")
    b64.add_argument("file")

    args = parser.parse_args()

    if args.cmd == "b64":
        print(base64.b64encode(Path(args.file).read_bytes()).decode())
        return 0

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
