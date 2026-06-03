# NoKrnDocker

English | [中文](README.CN.md)

NoKrnDocker is a Docker-based toolbox for Linux kernel debugging and kernel exploit development. It provides a reproducible environment with QEMU, GDB with Python support, [GEF](https://github.com/bata24/gef), Python 3.13, pwntools, common kernel build dependencies, and utilities commonly used when working with initramfs-based kernel labs or CTF challenges.

The image is meant to be used as a development shell. Your kernel image, `vmlinux`, rootfs, exploit source, and challenge files stay outside the image and are mounted into `/workspace`.

## Contents

The image includes:

- Python 3.13 on Debian trixie
- GDB and gdb-multiarch with Python support
- GEF from `bata24/gef`
- QEMU system emulator for x86
- Kernel build dependencies such as `bc`, `bison`, `flex`, `libelf-dev`, `libssl-dev`, `dwarves`, and `build-essential`
- Exploit development tools such as `pwntools`, `capstone`, `keystone-engine`, `ropper`, `unicorn`, `strace`, `ltrace`, `socat`, `netcat-openbsd`, and `musl-gcc`
- Helper commands:
  - `run-qemu`
  - `debug-kernel`
  - `check-toolchain`
  - `extract-vmlinux`
  - `extract-fs`
  - `compress-fs`
  - `kcompile`
  - `nokrn-helper`

## Build

Build the image with Docker Compose:

```bash
docker compose build
```

Or build it directly with buildx:

```bash
docker buildx build --builder remote --progress=plain -t nokrndocker:dev --load .
```

Images built from `main` are published to GHCR:

```bash
docker pull ghcr.io/muelnova/nokrndocker:latest
```

## Start A Shell

Open a shell with the current repository mounted as `/workspace`:

```bash
docker compose run --rm shell
```

Mount another challenge directory:

```bash
WORKSPACE=/path/to/challenge docker compose run --rm shell
```

Inside the container, `/workspace` is the mounted directory.

## Enable KVM

If your host has `/dev/kvm` and your user has permission to access it, use the KVM override file:

```bash
docker compose -f docker-compose.yml -f docker-compose.kvm.yml run --rm shell
```

With another workspace:

```bash
WORKSPACE=/path/to/challenge \
docker compose -f docker-compose.yml -f docker-compose.kvm.yml run --rm shell
```

## Run QEMU

By default, `run-qemu` expects:

```text
kernel/bzImage
rootfs/rootfs.cpio
```

Run:

```bash
run-qemu
```

Override paths or QEMU settings with environment variables:

```bash
KERNEL=./bzImage ROOTFS=./rootfs.cpio run-qemu
```

```bash
MEM=1G SMP=2 run-qemu
```

The default kernel command line is:

```text
console=ttyS0 nokaslr panic=1 oops=panic quiet
```

Override it with:

```bash
APPEND="console=ttyS0 nokaslr panic=1 oops=panic" run-qemu
```

## Debug With GDB

By default, QEMU starts in debug mode.

This starts QEMU with a GDB server on TCP port `1234` and pauses the VM before execution.

If you do not need debug mode, use:

```bash
DEBUG=0 run-qemu
```

In another terminal, connect with GDB inside the same container:

```bash
debug-kernel
```

By default, `debug-kernel` expects:

```text
kernel/vmlinux
```

Override it with:

```bash
VMLINUX=./vmlinux debug-kernel
```

The compose file also exposes QEMU's internal GDB port `1234` to host port `1234`, so you can connect from the host:

```bash
gdb ./vmlinux
```

Then in GDB:

```gdb
target remote :1234
```

Change the host port:

```bash
GDB_PORT=31337 docker compose run --rm shell
```

Then connect from the host:

```gdb
target remote :31337
```

GEF is loaded automatically from `/root/.gdbinit`.

## Check The Toolchain

Run:

```bash
check-toolchain
```

This prints Python, GDB Python support, QEMU, capstone, and pwntools information.

## Helper Tools

These tools are installed into `PATH` inside the container. They can also be run directly from the repository as `scripts/*.sh`.

Extract an ELF `vmlinux` from a `bzImage` or `vmlinuz`:

```bash
extract-vmlinux ./bzImage ./vmlinux
```

Extract an initramfs:

```bash
extract-fs ./rootfs.cpio.gz ./rootfs/initramfs
```

Repack an initramfs:

```bash
compress-fs ./rootfs/initramfs ./rootfs.cpio.gz
```

Compile an exploit, copy it into the initramfs, and repack the rootfs:

```bash
kcompile exploit.c
```

Common environment variables:

```bash
FS=./rootfs/initramfs ROOTFS=./rootfs.cpio OUT=bin/exploit kcompile exploit.c
```

`nokrn-helper` provides small Python helpers. You can also import them in exploit scripts:

```python
from helper import upload, p64, u64, kbase
```

For example, upload a file through a pwntools serial shell:

```python
import os
from pwn import *
from helper import upload

env = os.environ.copy()
env["DEBUG"] = "0"
io = process(["run-qemu"], env=env)
upload(io, "./exploit", "/tmp/exploit")
```

## Common Workflow

```bash
docker compose build
docker compose run --rm shell
```

Inside the container:

```bash
kcompile exploit.c
run-qemu
```

For debugging:

```bash
run-qemu
```

Then connect with `debug-kernel` from another container shell or use host GDB on port `1234`.
