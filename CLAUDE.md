# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Language**: All responses should be in Japanese (日本語) as this is a Japanese development project.

## Project Overview

This is a **Godot SyncLogger addon** project currently in **planning phase**. The goal is to create a real-time UDP-based logging system for Godot 4.4.1-stable games that sends logs over the network without blocking the main game loop.

## Development Status

**Current State**: Documentation and planning phase - no implementation files exist yet.
**Next Phase**: Phase 1 (MVP) implementation using Test-Driven Development (TDD).

## Architecture Overview

The planned system uses a multi-threaded architecture to avoid blocking the main game loop:

```
SyncLogger (AutoLoad Singleton API)
    ↓ (queue logs)
ThreadSafeQueue (Mutex-protected)
    ↓ (worker thread processes)
LogProcessingThread (Background Thread)
    ↓ (sends via)
UDPSender → Network (UDP) / Fallback to File
```

**Key Design Principles**:
- **Non-blocking**: Main thread only queues logs, never blocks on network I/O
- **Thread-safe**: Uses Mutex-protected queue for thread communication  
- **Fault-tolerant**: Falls back to local file if network fails
- **Game-optimized**: Automatically includes frame numbers, FPS, memory usage

## Development Workflow

### Test-Driven Development (TDD)
All features must follow Red-Green-Refactor cycle using **GUT (Godot Unit Test)**:

1. **Red**: Write failing test first
2. **Green**: Implement minimal code to pass test  
3. **Refactor**: Improve code while keeping tests passing

### Required Tools (Not Yet Installed)
- **GUT (Godot Unit Test)**: Testing framework
- **gdLinter**: Static analysis
- **GDScript Formatter**: Code formatting

### Git Workflow
- **Main branch**: `main` (currently `master`) - release-ready code only
- **Development**: `develop` branch - integration branch
- **Features**: `feature/issue-name` branches from `develop`
- **Commit format**: Conventional Commits in Japanese (e.g., `feat(sender): UDP送信機能の基本を実装`)

## Implementation Roadmap

### Phase 1 Tasks (from WORK_PLAN.md):
1. **Project Setup**: Create `addons/network_logger/` structure, `plugin.cfg`, `plugin.gd`
2. **Test Environment**: Install GUT framework, create test directory
3. **Core Components** (TDD approach):
   - `ThreadSafeQueue` (mutex-protected queue)
   - `UDPSender` (network transmission)
   - `LogProcessingThread` (worker thread)
   - `SyncLogger` (main API singleton)
4. **Godot Integration**: AutoLoad registration, project settings, hotkeys
5. **Documentation**: README, API reference, Python receiver script

### Planned Directory Structure:
```
res://addons/synclogger/
├── plugin.cfg                 # Plugin configuration
├── plugin.gd                  # Plugin main class  
├── synclogger.gd          # AutoLoad singleton
├── udp_sender.gd             # UDP transmission
├── log_thread.gd             # Worker thread
├── thread_safe_queue.gd      # Thread-safe queue
└── settings/
    └── project_settings.gd    # Settings management
```

## Key APIs (Planned)

```gdscript
# Basic logging
SyncLogger.setup("192.168.1.100", 9999)
SyncLogger.log("message")
SyncLogger.info("information") 
SyncLogger.error("error message")

# Advanced features
SyncLogger.set_min_level(LogLevel.INFO)
SyncLogger.set_mode(LoggingMode.DEVELOPMENT)
```

## Important Files

- `docs/WORK_PLAN.md`: Detailed task breakdown and progress tracking
- `docs/synclogger_requirements.md`: Complete feature requirements and technical specifications
- `docs/DEVELOPMENT_POLICY.md`: TDD methodology and coding standards

## Development Commands

**Godot実行ファイル**: `/mnt/h/devs/godot/bin/godot` (Godot 4.4.1-stable)

```bash
# Run all tests
../bin/godot --headless -s addons/gut/gut_cmdln.gd

# Run specific test
../bin/godot --headless -s addons/gut/gut_cmdln.gd -gsource:res://tests/test_specific.gd

# Development tools (installed):
# Lint code
~/.local/bin/gdlint addons/synclogger/ tests/

# Format code  
~/.local/bin/gdformat addons/synclogger/ tests/
```

## Performance Requirements

- Log processing must complete within 1ms
- Network failures must not block or crash the game
- Memory usage must be minimal
- Support high-frequency logging (30+ logs/second)

## Security Considerations

- Prevent sensitive information in logs for production builds
- Optional automatic disable in release builds
- Hotkey security in production environments