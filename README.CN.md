# NoKrnDocker

[English](README.md) | 中文

NoKrnDocker 是一个用于 Linux kernel 调试和 kernel exploit 开发的 Docker 工具箱。它提供一个可复现的环境，包含 QEMU、带 Python 支持的 GDB、[GEF](https://github.com/bata24/gef)、Python 3.13、pwntools、常用内核构建依赖，以及 initramfs/kernel CTF 调试时常用的工具。

这个镜像主要作为开发 shell 使用。你的 kernel image、`vmlinux`、rootfs、exploit 源码和题目文件都保留在镜像外，通过挂载进入容器的 `/workspace`。

## 包含内容

镜像中包含：

- 基于 Debian trixie 的 Python 3.13
- 带 Python 支持的 GDB 和 gdb-multiarch
- 来自 `bata24/gef` 的 GEF
- x86 QEMU system emulator
- 内核构建依赖，例如 `bc`、`bison`、`flex`、`libelf-dev`、`libssl-dev`、`dwarves`、`build-essential`
- exploit 开发工具，例如 `pwntools`、`capstone`、`keystone-engine`、`ropper`、`unicorn`、`strace`、`ltrace`、`socat`、`netcat-openbsd`、`musl-gcc`
- 辅助命令：
  - `run-qemu`
  - `debug-kernel`
  - `check-toolchain`
  - `extract-vmlinux`
  - `extract-fs`
  - `compress-fs`
  - `kcompile`
  - `nokrn-helper`

## 构建

使用 Docker Compose 构建：

```bash
docker compose build
```

或者直接使用 buildx：

```bash
docker buildx build --builder remote --progress=plain -t nokrndocker:dev --load .
```

## 启动 Shell

把当前仓库挂载到 `/workspace` 并进入容器：

```bash
docker compose run --rm shell
```

挂载其他题目目录：

```bash
WORKSPACE=/path/to/challenge docker compose run --rm shell
```

进入容器后，`/workspace` 就是挂载进去的目录。

## 启用 KVM

如果宿主机有 `/dev/kvm`，并且当前用户有权限访问，可以叠加 KVM override 文件：

```bash
docker compose -f docker-compose.yml -f docker-compose.kvm.yml run --rm shell
```

挂载其他目录并启用 KVM：

```bash
WORKSPACE=/path/to/challenge \
docker compose -f docker-compose.yml -f docker-compose.kvm.yml run --rm shell
```

## 运行 QEMU

默认情况下，`run-qemu` 会寻找：

```text
kernel/bzImage
rootfs/rootfs.cpio
```

运行：

```bash
run-qemu
```

也可以用环境变量覆盖路径或 QEMU 参数：

```bash
KERNEL=./bzImage ROOTFS=./rootfs.cpio run-qemu
```

```bash
MEM=1G SMP=2 run-qemu
```

默认 kernel command line 是：

```text
console=ttyS0 nokaslr panic=1 oops=panic quiet
```

覆盖启动参数：

```bash
APPEND="console=ttyS0 nokaslr panic=1 oops=panic" run-qemu
```

## 使用 GDB 调试

默认使用 debug 模式启动 QEMU：

这会让 QEMU 在 TCP `1234` 端口启动 GDB server，并在运行前暂停 VM。

如果不需要 debug，可以使用：

```bash
DEBUG=0 run-qemu
```

另一个终端里，可以在同一个容器环境中连接：

```bash
debug-kernel
```

默认情况下，`debug-kernel` 会寻找：

```text
kernel/vmlinux
```

覆盖路径：

```bash
VMLINUX=./vmlinux debug-kernel
```

Compose 文件会把 QEMU 的内部 GDB 端口 `1234` 暴露到宿主机的 `1234` 端口，所以你可以直接从宿主机 GDB 连接：

```bash
gdb ./vmlinux
```

然后在 GDB 中：

```gdb
target remote :1234
```

如果想改宿主机端口：

```bash
GDB_PORT=31337 docker compose run --rm shell
```

然后宿主机 GDB 连接：

```gdb
target remote :31337
```

GEF 会通过 `/root/.gdbinit` 自动加载。

## 检查工具链

运行：

```bash
check-toolchain
```

它会输出 Python、GDB Python 支持、QEMU、capstone、pwntools 等信息。

## 辅助工具

这些工具在容器里会安装到 `PATH`，也可以在仓库中直接运行对应的 `scripts/*.sh`。

从 `bzImage` 或 `vmlinuz` 中提取 ELF 格式的 `vmlinux`：

```bash
extract-vmlinux ./bzImage ./vmlinux
```

解包 initramfs：

```bash
extract-fs ./rootfs.cpio.gz ./rootfs/initramfs
```

重新打包 initramfs：

```bash
compress-fs ./rootfs/initramfs ./rootfs.cpio.gz
```

编译 exploit，放入 initramfs，并重新打包：

```bash
kcompile exploit.c
```

常用环境变量：

```bash
FS=./rootfs/initramfs ROOTFS=./rootfs.cpio OUT=bin/exploit kcompile exploit.c
```

`nokrn-helper` 提供一些 Python 小功能，也可以在 exploit 脚本里导入：

```python
from helper import upload, p64, u64, kbase
```

例如通过 pwntools 串口 shell 上传文件：

```python
import os
from pwn import *
from helper import upload

env = os.environ.copy()
env["DEBUG"] = "0"
io = process(["run-qemu"], env=env)
upload(io, "./exploit", "/tmp/exploit")
```

## 常见工作流

```bash
docker compose build
docker compose run --rm shell
```

容器中：

```bash
kcompile exploit.c
run-qemu
```

调试时：

```bash
run-qemu
```

然后从另一个容器 shell 里运行 `debug-kernel`，或者用宿主机 GDB 连接 `1234` 端口。
