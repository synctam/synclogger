# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Language**: All responses should be in Japanese (日本語) as this is a Japanese development project.

## Project Overview

This is a **Godot SyncLogger addon** project currently in **planning phase**. The goal is to create a real-time UDP-based logging system for Godot 4.4.1-stable games that sends logs over the network without blocking the main game loop.

## Development Status

**Current State**: Phase 1 MVP完成 + MainThreadSimpleLogger追加実装済み
**Phase 1完成**: スレッドベースのリアルタイムUDPログシステム実装完了
**追加機能**: MainThreadSimpleLogger（メインスレッド版、安定動作）
**Next Phase**: Phase 2（機能拡張・最適化・プロダクション向け機能）

## Architecture Overview

シンプルなメインスレッド実装でUDPログ送信を実現：

```
SyncLogger (AutoLoad Singleton API)
    ↓ (delegate to)
MainThreadSimpleLogger (Main Thread)
    ↓ (sends via)
UDPSender → Network (UDP)
```

**Key Design Principles**:
- **Simple**: メインスレッドのみ使用、複雑なマルチスレッド処理なし
- **Stable**: セグメンテーションフォルト問題を回避した安定動作
- **Immediate**: ログを即座にUDP送信（キューなし）
- **Game-optimized**: 自動的にフレーム番号、タイムスタンプを含む

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

### 実装済みDirectory Structure:
```
res://addons/synclogger/
├── plugin.cfg                     # Plugin configuration
├── plugin.gd                      # Plugin main class  
├── synclogger.gd                   # AutoLoad singleton (MainThreadLoggerベース)
├── mainthread_simple_logger.gd     # メインスレッド版ロガー（コア実装）
├── udp_sender.gd                   # UDP transmission (修正済み)
└── settings/                       # Settings management (構造のみ)
```

## 実装済みKey APIs

### AutoLoad経由（推奨・本格運用）
```gdscript
# 基本ログ送信（スレッド版・問題あり）
SyncLogger.setup("192.168.1.100", 9999)
SyncLogger.log("message")
SyncLogger.info("information") 
SyncLogger.warning("warning message")
SyncLogger.error("error message")
SyncLogger.debug("debug message")
await SyncLogger.shutdown()  # 安全な終了処理
```

### MainThreadSimpleLogger（安定版・推奨）
```gdscript
# メインスレッド版（安定動作）
const MainThreadSimpleLogger = preload("res://addons/synclogger/mainthread_simple_logger.gd")
var logger = MainThreadSimpleLogger.new()
logger.setup("127.0.0.1", 9998)
logger.log("message", "category")
logger.info("information")
logger.error("error message")
```

## 現在の実装状況

### ✅ 完成済み機能
- **UDPSender**: UDP通信機能（接続問題修正済み）
- **MainThreadSimpleLogger**: メインスレッド版ロガー（**コア実装**）
- **SyncLoggerMain**: AutoLoadシングルトン（MainThreadLoggerベース）
- **ログレベル**: 6レベル対応（trace, debug, info, warning, error, critical）
- **テストスイート**: 全テスト成功
- **デモシーン**: メインスレッド版
- **log_receiver.py**: Python受信スクリプト

### 🎯 特徴
- **シンプル**: キューレス、メインスレッドのみ
- **安定**: セグメンテーションフォルト問題を解決
- **即座送信**: ログを即座にUDP送信

## Important Files

- `docs/WORK_PLAN.md`: Detailed task breakdown and progress tracking
- `docs/synclogger_requirements.md`: Complete feature requirements and technical specifications  
- `docs/DEVELOPMENT_POLICY.md`: TDD methodology and coding standards
- `debug/README.md`: 開発中のデバッグファイル説明

## Development Commands

**Godot実行ファイル**: `/mnt/h/devs/godot/bin/godot` (Godot 4.4.1-stable)

```bash
# Run all tests
../bin/godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

# Run specific test
../bin/godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_specific.gd -gexit

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