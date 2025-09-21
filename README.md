# SyncLogger

A real-time UDP logging addon for Godot Engine that sends logs over the network without blocking the main game loop.

リアルタイムUDPログ送信アドオン - ゲームループをブロックせずにネットワーク経由でログを送信

## ✨ Features

- 🚀 **Non-blocking**: Logs sent via UDP without affecting game performance
- ⚡ **Real-time**: Instant log transmission for live debugging
- 🎯 **Simple API**: Easy-to-use logging interface
- 🔧 **Configurable**: Flexible setup with JSON config files
- 🛡️ **Stable**: Comprehensive test coverage (60+ tests)
- 🎮 **Game-ready**: Automatic frame numbers and timestamps

## 📦 Installation

### Via Godot Asset Library (Recommended)
1. Open Godot Project Settings
2. Go to "AssetLib" tab
3. Search for "SyncLogger"
4. Download and install

### Manual Installation
1. Download this repository
2. Copy `addons/synclogger/` to your project's `addons/` folder
3. Enable "SyncLogger" in Project Settings > Plugins

## 🚀 Quick Start

### Basic Usage
```gdscript
# Setup (usually in _ready())
SyncLogger.setup("127.0.0.1", 9999)

# Send logs
SyncLogger.info("Player spawned")
SyncLogger.warning("Low health: %d" % health)
SyncLogger.error("Connection failed")

# Cleanup (usually in _exit_tree())
await SyncLogger.shutdown()
```

### Log Receiver (Python)
```python
import socket

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("127.0.0.1", 9999))

while True:
    data, addr = sock.recvfrom(4096)
    print(data.decode('utf-8'))
```

## 📚 API Reference

### Core Methods
- `setup(host: String, port: int)` - Initialize UDP connection
- `info(message: String)` - Send info level log
- `debug(message: String)` - Send debug level log
- `warning(message: String)` - Send warning level log
- `error(message: String)` - Send error level log
- `critical(message: String)` - Send critical level log
- `shutdown()` - Clean shutdown (returns awaitable)

### Configuration
```gdscript
# Optional: JSON config file at user://.synclogger.json
{
    "host": "127.0.0.1",
    "port": 9999,
    "system_capture": true,
    "capture_errors": true
}
```

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
# Disable system capture if needed
SyncLogger.set_system_capture_enabled(false)
```

## 🤝 Development

This project was developed with AI assistance from Claude (Anthropic).

### Contributing
- **Issues**: Report bugs or feature requests
- **Pull Requests**: Contributions welcome
- **Testing**: Run tests with GUT framework

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

Copyright (c) 2025 synctam (synctam@gmail.com)