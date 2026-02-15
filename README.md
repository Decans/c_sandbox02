# c_sandbox02 — Compiler-Only Docker C Project

A C project that uses Docker purely as a compilation and build tool. VS Code and all editor tooling run natively on the host machine. Docker is invoked only for building, testing, and running the compiled binary.

## How It Works

Unlike a Dev Container approach (where VS Code itself runs inside Docker), this project keeps everything on the host except the compiler toolchain. The Makefile provides host-facing targets that wrap `docker compose run --rm` to execute short-lived build commands inside a container.

This is a lighter-weight approach:
- No "Reopen in Container" step
- No Dev Containers extension required
- Docker containers are ephemeral — spun up per command, then removed
- Editor extensions (IntelliSense, clang-format) run on the host

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Compose)
- Make (pre-installed on macOS)
- VS Code with recommended extensions (optional)

No Dev Containers extension needed.

## Quick Start

```bash
git clone --recurse-submodules <repo-url>
cd c_sandbox02
make run
```

On first run, Docker will build the compiler image (takes ~1 minute). Subsequent runs reuse the cached image.

## Makefile Reference

| Command | Description |
|---------|-------------|
| `make build` | Compile the project |
| `make run` | Build and run the binary |
| `make test` | Build and run unit tests |
| `make clean` | Remove build artifacts |

### How the Two-Layer Makefile Works

The Makefile has two layers of targets:

- **Host-facing targets** (`build`, `run`, `test`, `clean`) — these invoke `docker compose run --rm build make _<target>`, spinning up a short-lived container.
- **Container-internal targets** (`_build`, `_run`, `_test`, `_clean`) — these run inside the container and do the actual compilation with clang.

You always run the host-facing targets. The internal targets are implementation details.

## Project Structure

```
c_sandbox02/
├── Dockerfile              # Compiler image (clang, make, gdb, valgrind)
├── docker-compose.yml      # Service definition for build container
├── Makefile                # Two-layer host → Docker → compile targets
├── CLAUDE.md               # Claude Code instructions
├── README.md               # This file
├── .gitignore
├── .vscode/
│   ├── tasks.json          # Build/Run/Test/Clean tasks
│   ├── settings.json       # Editor settings (C17, format-on-save)
│   └── extensions.json     # Recommended extensions (no remote-containers)
├── src/
│   ├── main.c              # Entry point
│   ├── greeter.h           # Greeter module header
│   └── greeter.c           # Greeter module implementation
├── test/
│   └── test_greeter.c      # Unit tests
└── unity/                  # Unity test framework (git submodule)
```

## Testing

Tests use the [Unity](https://github.com/ThrowTheSwitch/Unity) test framework, included as a git submodule.

```bash
make test
```

## Comparison with Dev Container Approach

| Aspect | Dev Container (c_sandbox01) | Compiler-Only (this project) |
|--------|---------------------------|------------------------------|
| VS Code | Runs inside container | Runs on host |
| Extensions | Installed in container | Installed on host |
| Docker usage | Always running (`docker compose up`) | Short-lived (`docker compose run --rm`) |
| `.devcontainer/` | Required | Not needed |
| Startup | "Reopen in Container" | Just `make run` |
