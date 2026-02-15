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

When making changes that affect the project structure, build targets, tooling, dependencies, or developer workflow, update `README.md` to reflect those changes.
