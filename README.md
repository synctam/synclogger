# SyncLogger

A real-time UDP logging addon for Godot Engine that sends logs over the network without blocking the main game loop.

## ✨ Features

- 🚀 **Non-blocking**: Logs sent via UDP without affecting game performance
- ⚡ **Real-time**: Instant log transmission for live debugging
- 🎯 **Simple API**: Easy-to-use logging interface
- 🔧 **Configurable**: Flexible setup with start/stop API
- 🛡️ **Stable**: Comprehensive test coverage (60+ tests)
- 🎮 **Game-ready**: Automatic frame tracking with process & physics frame numbers

## 📦 Installation

### ~~Via Godot Asset Library (Recommended)~~
1. ~~Open Godot Project Settings~~
2. ~~Go to "AssetLib" tab~~
3. ~~Search for "SyncLogger"~~
4. ~~Download and install~~

### Manual Installation
1. Download this repository
2. Copy `addons/synclogger/` to your project's `addons/` folder
3. Enable "SyncLogger" in Project Settings > Plugins

## 🚀 Quick Start

### Basic Usage
```gdscript
# Setup (usually in _ready())
SyncLogger.setup("127.0.0.1", 9999)
SyncLogger.start()  # Start logging

# Send logs
SyncLogger.info("Player spawned")
SyncLogger.warning("Low health: %d" % health)
SyncLogger.error("Connection failed")

# Stop logging (usually in _exit_tree())
SyncLogger.stop()

# Optional: Restart logging
SyncLogger.restart()
```

### Log Receiver

**🚀 Quick Start**
```bash
# Basic usage (sample implementation)
python sample_receiver.py

# With features
python sample_receiver.py --timestamp --save logs.txt

# Use sample scripts (optional)
sample_receiver.bat    # Windows
./sample_receiver.sh   # Linux/macOS
```

**📋 Features**
- ✨ **Color-coded logs** by level (trace, debug, info, warning, error, critical)
- ⏰ **Timestamp display** with microsecond precision
- 💾 **File saving** with automatic ANSI code cleanup
- 🎯 **JSON parsing** with structured log display
- 🛡️ **Error handling** for malformed messages

## 📚 API Reference

### Core Methods
- `setup(host: String = "127.0.0.1", port: int = 9999)` - Configure connection settings (no connection made)
- `start()` - Start UDP connection and enable logging
- `stop()` - Stop UDP connection and disable logging
- `restart()` - Restart connection (stop + start)
- `info(message: String, category: String = "general")` - Send info level log
- `debug(message: String, category: String = "general")` - Send debug level log
- `warning(message: String, category: String = "general")` - Send warning level log
- `error(message: String, category: String = "general")` - Send error level log
- `critical(message: String, category: String = "general")` - Send critical level log
- `trace(message: String, category: String = "general")` - Send trace level log

### Security Features
```gdscript
# Secure start/stop API - no network communication until explicitly started
SyncLogger.setup("127.0.0.1", 9999)  # Configuration only (no connection)
SyncLogger.start()                    # Explicit network start
# ... logging happens ...
SyncLogger.stop()                     # Complete network shutdown
```

### Frame Information
Every log automatically includes precise frame tracking for game debugging:

```json
{
  "timestamp": 1722556800.123,
  "frame": 12345,           // Process frame number
  "physics_frame": 6789,    // Physics frame number
  "level": "info",
  "category": "gameplay",
  "message": "Player spawned"
}
```

**Benefits for Game Development:**
- 🎯 **Frame-perfect debugging**: Correlate logs with specific game frames
- ⏱️ **Performance analysis**: Track frame timing issues
- 🔍 **Physics debugging**: Separate process and physics frame tracking
- 📊 **Timeline reconstruction**: Rebuild exact game state progression

## 📋 Requirements

- **Godot**: 4.4.1 or later
- **Platform**: Windows, macOS, Linux
- **Network**: UDP communication capability
- **Optional**: Python 3.x for log receiver

## ⚡ Performance

- **Log processing**: < 1ms per message
- **High frequency**: 30+ logs/second supported
- **Memory efficient**: No memory leaks detected
- **Thread safe**: Concurrent logging support

## 🔧 Troubleshooting

### Common Issues

**Logs not appearing**
- Check network connectivity
- Verify host/port settings
- Ensure firewall allows UDP traffic

**Performance impact**
- Reduce log frequency in production
- Use debug builds for development only

**System log capture (Godot 4.5+)**
```gdscript
# System capture is automatically enabled with start()
# To disable manually:
SyncLogger.set_capture_errors(false)
SyncLogger.set_capture_messages(false)
```

## 🤝 Development

This project was developed with AI assistance from Claude (Anthropic).

### Development Environment (dev branch)
- **Testing Framework**: GUT (Godot Unit Test)
- **Test Suite**: 60+ comprehensive tests
- **Documentation**: Located in `docs/` directory
- **Release Workflow**: See `docs/RELEASE_WORKFLOW.md`

### Development Commands
```bash
# Run all tests
../bin/godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

# Code quality check
gdlint addons/synclogger/ tests/
```

### Contributing
- **Issues**: Report bugs or feature requests
- **Pull Requests**: Contributions welcome
- **Testing**: All tests must pass before merge
- **Documentation**: Update relevant docs when adding features

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

Copyright (c) 2025 synctam (synctam@gmail.com)

---

**📖 Language / 言語**
- [English](README.md) (This file)

- [日本語](README_ja.md)
