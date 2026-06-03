# syntax=docker/dockerfile:1.7

FROM python:3.13-trixie AS nokrndocker

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1
ENV PYTHONPATH=/opt/nokrndocker/scripts

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && apt-get install -y --no-install-recommends \
      bash-completion \
      bc \
      binutils \
      bison \
      bzip2 \
      build-essential \
      busybox-static \
      ca-certificates \
      clang \
      cmake \
      cpio \
      curl \
      dwarves \
      e2fsprogs \
      elfutils \
      file \
      flex \
      gdb \
      gdb-multiarch \
      gdbserver \
      git \
      gzip \
      iproute2 \
      jq \
      less \
      libarchive-tools \
      libelf-dev \
      libncurses-dev \
      libssl-dev \
      lz4 \
      lld \
      ltrace \
      make \
      musl-tools \
      nano \
      netcat-openbsd \
      ninja-build \
      openssl \
      patch \
      pkg-config \
      procps \
      qemu-system-x86 \
      qemu-utils \
      ripgrep \
      rsync \
      socat \
      squashfs-tools \
      strace \
      sudo \
      tmux \
      unzip \
      vim \
      wget \
      xxd \
      xz-utils \
      zstd \
    && rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --upgrade pip setuptools wheel && \
    python -m pip install \
      capstone \
      keystone-engine \
      pwntools \
      pyelftools \
      ropper \
      unicorn

RUN git clone --depth 1 https://github.com/bata24/gef.git /opt/gef && \
    printf '%s\n' \
      'source /opt/gef/gef.py' \
      'set disassembly-flavor intel' \
      'set pagination off' \
      > /root/.gdbinit

WORKDIR /workspace

COPY scripts/ /opt/nokrndocker/scripts/
RUN chmod +x /opt/nokrndocker/scripts/*.sh /opt/nokrndocker/scripts/*.py && \
    for script in /opt/nokrndocker/scripts/*.sh; do \
      ln -s "$script" "/usr/local/bin/$(basename "$script" .sh)"; \
    done && \
    ln -s /opt/nokrndocker/scripts/helper.py /usr/local/bin/nokrn-helper

CMD ["bash"]
