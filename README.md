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

### Rebuilding the Docker Image

The Docker image is built automatically on first run, but you'll need to manually rebuild it if you change either of these files:

- `Dockerfile` — the image definition (toolchain packages, base image)
- `Makefile.build` — the build logic baked into the image at `/opt/Makefile.build`

To rebuild:

```bash
docker compose build
```

Changes to source files (`src/`, `test/`) do **not** require a rebuild — they're volume-mounted into the container at runtime.

## Makefile Reference

| Command | Description |
|---------|-------------|
| `make build` | Compile the project |
| `make run` | Build and run the binary |
| `make test` | Build and run unit tests |
| `make clean` | Remove build artifacts |
| `make debug` | Build and start the debug container |
| `make debug-stop` | Stop and remove the debug container |

### How the Split Makefile Works

Build logic is split across two Makefiles:

- **`Makefile`** (host) — a thin dispatcher that calls `docker compose run --rm build make -f /opt/Makefile.build <target>`, spinning up a short-lived container for each command.
- **`Makefile.build`** (container) — baked into the Docker image at `/opt/Makefile.build`. Contains all compiler config, source/object rules, and test compilation. This file is never referenced from the host directly.

You always run the host-facing targets (`make build`, `make run`, etc.). The container-internal Makefile is an implementation detail.

## Architecture

```mermaid
flowchart TD
    subgraph Host["Host Machine"]
        User["Developer"]
        VSCode["VS Code + Extensions"]
        HostMake["Makefile (dispatcher)"]
        DC["docker compose run --rm"]
        SrcVol["src/ test/ unity/"]
    end

    subgraph Image["Docker Image (built from Dockerfile)"]
        BuildMake["/opt/Makefile.build"]
        Toolchain["clang | make | gdb | gdbserver | valgrind"]
    end

    subgraph BuildContainer["Ephemeral Build Container"]
        ContMake["make -f /opt/Makefile.build &lt;target&gt;"]
        Clang["clang (compile)"]
        Runner["./build/main or ./build/test_runner"]
        BuildDir["build/ (output artifacts)"]
    end

    subgraph DebugContainer["Debug Container (long-lived)"]
        GDB["gdb (via pipeTransport)"]
        DebugBin["./build/main (debuggee)"]
    end

    User -- "make build | run | test | clean" --> HostMake
    User -- "make debug" --> HostMake
    VSCode -- "Tasks (Ctrl+Shift+B)" --> HostMake
    VSCode -- "F5 (pipeTransport)" --> DebugContainer
    HostMake -- "docker compose run --rm build" --> DC
    HostMake -- "docker compose up -d debug" --> DebugContainer
    DC -- "spins up container" --> BuildContainer
    DC -. "volume mount .:/workspace" .-> SrcVol
    SrcVol -. "mounted at /workspace" .-> BuildContainer
    SrcVol -. "mounted at /workspace" .-> DebugContainer
    BuildMake -- "baked into image" --> ContMake
    ContMake -- "compiles sources" --> Clang
    Clang --> BuildDir
    ContMake -- "runs binary" --> Runner
    Runner --> BuildDir
    Toolchain -- "available in containers" --> Clang
    Toolchain -- "available in containers" --> GDB
    GDB -- "launches" --> DebugBin

    style Host fill:#e8f4f8,stroke:#2196F3
    style Image fill:#fff3e0,stroke:#FF9800
    style BuildContainer fill:#e8f5e9,stroke:#4CAF50
    style DebugContainer fill:#fce4ec,stroke:#E91E63
```

### Build Flow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant HM as Makefile (host)
    participant DC as docker compose
    participant C as Container
    participant BM as Makefile.build
    participant CC as clang

    Dev->>HM: make run
    HM->>DC: docker compose run --rm build<br/>make -f /opt/Makefile.build run
    DC->>C: Create ephemeral container<br/>Mount .:/workspace
    C->>BM: make -f /opt/Makefile.build run
    BM->>CC: clang -Wall -Wextra -Werror<br/>-std=c17 -g -Isrc -c src/*.c
    CC-->>BM: build/*.o
    BM->>CC: clang -o build/main build/*.o
    CC-->>BM: build/main
    BM->>C: ./build/main
    C-->>Dev: "Hello from clang in Docker!"
    DC->>C: Remove container (--rm)
```

### Debug Flow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant VS as VS Code
    participant HM as Makefile (host)
    participant DC as docker compose
    participant BC as Build Container
    participant DBG as Debug Container
    participant GDB as gdb

    Dev->>VS: F5 (Start Debugging)
    VS->>HM: preLaunchTask: make debug
    HM->>DC: docker compose run --rm build<br/>make -f /opt/Makefile.build build
    DC->>BC: Compile sources
    BC-->>HM: Build complete
    HM->>DC: docker compose up -d debug
    DC->>DBG: Start debug container<br/>(sleep infinity)
    HM-->>VS: Task complete
    VS->>DBG: docker compose exec -T debug<br/>/usr/bin/gdb (pipeTransport)
    DBG->>GDB: Launch gdb with build/main
    GDB-->>VS: MI protocol over stdin/stdout
    Dev->>VS: Set breakpoints, step, inspect
    VS->>GDB: GDB/MI commands
    GDB-->>VS: Execution state, variables
    Dev->>VS: Stop debugging
    VS->>HM: postDebugTask: make debug-stop
    HM->>DC: docker compose stop/rm debug
    DC->>DBG: Remove container
```

## Project Structure

```
c_sandbox02/
├── Dockerfile              # Compiler image (clang, make, gdb, valgrind)
├── docker-compose.yml      # Service definition for build container
├── Makefile                # Host-side dispatcher (docker compose run)
├── Makefile.build          # Container-internal build logic (baked into image)
├── CLAUDE.md               # Claude Code instructions
├── README.md               # This file
├── .gitignore
├── .vscode/
│   ├── launch.json         # Debug configuration (gdb via pipeTransport)
│   ├── tasks.json          # Build/Run/Test/Clean/Debug tasks
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

## Debugging

The project supports debugging via GDB running inside the Docker container, with VS Code connecting through `pipeTransport`. No local debugger installation is needed — VS Code pipes GDB commands directly into the container.

### Quick Start

1. Set breakpoints in VS Code
2. Press **F5** (or **Run > Start Debugging**)
3. VS Code will automatically:
   - Build the code and start a debug container (via the `Debug` preLaunchTask)
   - Connect GDB inside the container via `docker compose exec`
4. Step through code, inspect variables, set watches, etc.
5. When you stop debugging, the `Debug Stop` postDebugTask cleans up the container

### Manual Debugging

You can manage the debug container manually:

```bash
make debug        # Build and start the debug container
make debug-stop   # Stop and remove the debug container
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
