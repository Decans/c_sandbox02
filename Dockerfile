FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    clang \
    clang-format \
    clang-tidy \
    make \
    gdb \
    gdbserver \
    valgrind \
    && rm -rf /var/lib/apt/lists/*

COPY Makefile.build /opt/Makefile.build

WORKDIR /workspace
