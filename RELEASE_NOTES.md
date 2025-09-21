# 🚀 SyncLogger v1.0.0 - Official Release

We're excited to announce the official release of **SyncLogger** - a high-performance, real-time UDP logging system designed specifically for Godot Engine games.

## ✨ Key Features

### 🎮 Game-Specific Logging
- **Automatic Frame Tracking**: Every log includes both process and physics frame numbers
- **Real-time UDP Transmission**: Zero-blocking network logging
- **6 Log Levels**: trace, debug, info, warning, error, critical
- **Godot 4.4.1+ Compatible**: Full support for Godot 4.4.1 and 4.5+

### 🔒 Security First Design
- **Explicit Start/Stop Control**: No automatic connections
- **No Config Files**: Removed automatic config file creation for better security
- **Type-Safe GDScript**: Full type annotations for robust code

### 📊 Frame Information (Unique Feature!)
Every log automatically includes:
```json
{
  "timestamp": 1722556800.123,
  "frame": 12345,           // Process frame number
  "physics_frame": 6789,    // Physics frame number
  "level": "info",
  "category": "gameplay",
  "message": "Player action"
}
```

## 🎯 Perfect For
- Game debugging with frame-perfect precision
- Performance analysis and optimization
- Network gameplay troubleshooting
- Production monitoring without performance impact

## 📦 Installation
1. Download the addon from releases
2. Extract to `res://addons/synclogger/`
3. Enable in Project Settings > Plugins
4. Start logging with simple API:

```gdscript
func _ready():
    SyncLogger.setup("192.168.1.100", 8888)
    SyncLogger.start()
    SyncLogger.info("Game started!")
```

## 🔧 Version Compatibility
- **Godot 4.4.1**: Full core functionality
- **Godot 4.5+**: Additional system log capture support

## 📄 Documentation
- [README (English)](https://github.com/synctam/synclogger/blob/master/README.md)
- [README (日本語)](https://github.com/synctam/synclogger/blob/master/README_ja.md)
- [Protocol Specification](https://github.com/synctam/synclogger/blob/master/docs/PROTOCOL_SPECIFICATION.md)

## 🙏 Acknowledgments
Special thanks to all contributors and testers who helped make this release possible.

---

**Full Changelog**: https://github.com/synctam/synclogger/compare/v1.0.0-beta...v1.0.0