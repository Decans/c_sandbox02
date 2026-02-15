# Claude Code Instructions

## Build Environment

This project uses Docker as a compiler service. VS Code and editor tooling run on the host. Docker is invoked only for building, testing, and running.

All Makefile targets automatically wrap commands in Docker — just run:
```
make build
make run
make test
make clean
```

## Documentation

When making changes that affect the project structure, build targets, tooling, dependencies, or developer workflow, update `README.md` to reflect those changes. This includes:

- **Mermaid diagrams** — The README contains three Mermaid diagrams that must stay in sync with the actual architecture:
  - **Architecture flowchart** — Shows host, Docker image, build container, and debug container topology. Update when adding/removing services, changing container lifecycles, or modifying how VS Code connects.
  - **Build Flow sequence diagram** — Shows the `make run` lifecycle. Update when changing the build pipeline, Makefile dispatch, or container orchestration.
  - **Debug Flow sequence diagram** — Shows the F5 debug lifecycle (preLaunchTask → pipeTransport → postDebugTask). Update when changing the debug workflow, container management, or VS Code integration.
- **Makefile Reference table** — Update when adding, removing, or renaming `make` targets.
- **Project Structure tree** — Update when adding or removing files/directories.
