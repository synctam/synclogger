# SyncLogger UDP通信プロトコル仕様書

**バージョン**: 1.0.0-beta
**最終更新**: 2025-09-21
**対象システム**: Godot SyncLogger v1.0（統合実装版）

## 概要

SyncLoggerは、Godot 4.4.1+ゲームから外部ログ受信システムへリアルタイムでログを送信するUDPベースの通信プロトコルです。シンプルなメインスレッド実装により、安定した非ブロッキングログ送信を実現します。

## アーキテクチャ概要

```
Godot Game (SyncLogger AutoLoad)
    ↓ (direct implementation)
UDPSender (PacketPeerUDP)
    ↓ (UDP packets)
External Log Receiver
```

**設計思想**:
- **シンプル**: マルチスレッド処理なし、メインスレッドのみ
- **安定**: セグメンテーションフォルト回避
- **即座**: キューレス、ログの即座送信
## プロトコル詳細

### 1. 通信方式

- **プロトコル**: UDP/IP
- **ポート**: デフォルト 9999 (設定可能)
- **エンコーディング**: UTF-8
- **データ形式**: JSON
- **最大パケットサイズ**: 4096バイト (メッセージサイズ制限)

### 2. 接続方式

#### 2.1 接続ライフサイクル（統合実装）

SyncLoggerは単一の統合実装を採用：

**統合実装 (SyncLoggerNode)**
- setup時に永続的なUDP接続を確立
- 接続失敗時は自動再試行（最大1回）
- 送信失敗時は接続を再確立
- shutdown時にクリーンアップ

#### 2.2 接続手順

```gdscript
# setup時の初期化
1. _udp_socket = PacketPeerUDP.new()
2. _udp_socket.connect_to_host(host, port)  # 永続接続確立

# 送信時の処理フロー
1. _ensure_connection()             # 接続確認・再接続
2. _udp_socket.put_packet(data)     # データ送信
3. 送信失敗時は自動再試行（最大1回）

# shutdown時のクリーンアップ
1. _udp_socket.close()              # 接続クローズ
```

### 3. データフォーマット

#### 3.1 JSONメッセージ構造

すべてのログメッセージは以下のJSON構造で送信されます：

```json
{
  "timestamp": 1722556800.123,
  "frame": 12345,
  "physics_frame": 6789,
  "level": "info",
  "category": "general",
  "message": "Player spawned at position (100, 200)"
}
```

#### 3.2 フィールド詳細

| フィールド名 | 型 | 説明 | 例 |
|-------------|-----|------|-----|
| `timestamp` | float | Unix時刻（秒、小数点以下含む） | `1722556800.123` |
| `frame` | int | Godotプロセスフレーム番号 | `12345` |
| `physics_frame` | int | Godot物理フレーム番号 | `6789` |
| `level` | string | ログレベル | `"trace"`, `"debug"`, `"info"`, `"warning"`, `"error"`, `"critical"` |
| `category` | string | ログカテゴリ | `"general"`, `"gameplay"`, `"network"` |
| `message` | string | ログメッセージ本文 | `"Player spawned at position (100, 200)"` |

#### 3.3 ログレベル

| レベル | 説明 | 使用例 |
|--------|------|--------|
| `trace` | 最詳細デバッグ | 関数呼び出し、ループ処理、詳細追跡 |
| `debug` | デバッグ情報 | 変数値、処理フロー確認 |
| `info` | 一般情報 | アプリケーション状態、処理完了通知 |
| `warning` | 警告 | 非致命的エラー、性能劣化 |
| `error` | エラー | 例外、処理失敗 |
| `critical` | 致命的エラー | システムクラッシュ、回復不能エラー |

### 4. API使用例

#### 4.1 統合実装（AutoLoad使用）

```gdscript
# セットアップ（通常は_ready()内）
SyncLogger.setup("127.0.0.1", 9999)

# ログ送信（優先度順）
SyncLogger.trace("Function entered: process_input()")
SyncLogger.debug("Player position: (100, 200)")
SyncLogger.info("Game started successfully")
SyncLogger.warning("Performance degradation detected")
SyncLogger.error("Failed to load texture: player.png")
SyncLogger.critical("Out of memory - game will crash")

# クリーンアップ（通常は_exit_tree()内）
await SyncLogger.shutdown()
```

#### 4.2 システムログキャプチャ（Godot 4.5+）

```gdscript
# システムログキャプチャ有効化（Godot 4.5+のみ）
SyncLogger.enable_system_capture()

# print()文も自動的にUDP送信される
print("This message will be sent via UDP")

# エラー出力も自動キャプチャ
push_error("This error will be captured")
```

#### 4.3 設定ファイル（オプション）

`user://.synclogger.json`:
```json
{
    "host": "192.168.1.100",
    "port": 8888,
    "system_capture": true,
    "capture_errors": true,
    "capture_messages": true
}
```

### 5. サンプルレシーバー

#### 5.1 基本使用方法

```bash
# マイクロ秒精度タイムスタンプ付きで受信
python sample_receiver.py --timestamp --save logs.txt
```

#### 5.2 レシーバー機能
- **カラー表示**: ログレベル別の色分け
- **マイクロ秒精度**: 高精度タイムスタンプ
- **ファイル保存**: 自動ANSI除去
- **エラー処理**: 不正メッセージ耐性

---

**📝 更新履歴**
- 2025-09-21: 統合実装版に全面更新
- 将来: 必要に応じて仕様更新
