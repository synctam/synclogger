# SyncLogger UDP通信プロトコル仕様書

バージョン: 1.0  
作成日: 2025-08-01  
対象システム: Godot SyncLogger v1.0 (Phase 1 MVP)

## 概要

SyncLoggerは、Godot 4.4.1ゲームから外部ログ受信システムへリアルタイムでログを送信するUDPベースの通信プロトコルです。メインゲームループをブロックしない非同期ログ送信を実現します。

## アーキテクチャ概要

```
Godot Game
    ↓
SyncLogger API (AutoLoad)
    ↓
UDP Socket (PacketPeerUDP)
    ↓
Network (UDP/IP)
    ↓
Log Receiver (Python/他)
```

## プロトコル詳細

### 1. 通信方式

- **プロトコル**: UDP/IP
- **ポート**: デフォルト 9999 (設定可能)
- **エンコーディング**: UTF-8
- **データ形式**: JSON
- **最大パケットサイズ**: 1024バイト (UDP受信バッファサイズ)

### 2. 接続方式

#### 2.1 接続ライフサイクル

SyncLoggerは2つの実装方式があります：

**A. メインスレッド版 (MainThreadSimpleLogger)**
- 各ログ送信時に接続を新規作成
- 送信後即座に接続をクローズ
- 接続プール無し（シンプル設計）

**B. スレッド版 (SyncLoggerMain + LogProcessingThread)**
- バックグラウンドスレッドで継続的処理
- 同様に各送信時に接続を再構築

#### 2.2 接続手順

```gdscript
# 各送信時の処理フロー
1. _udp_socket.close()              # 既存接続をクリア
2. _udp_socket.connect_to_host(host, port)  # 新規接続
3. _udp_socket.put_packet(data)     # データ送信
4. _udp_socket.close()              # 接続クローズ
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
| `level` | string | ログレベル | `"debug"`, `"info"`, `"warning"`, `"error"` |
| `category` | string | ログカテゴリ | `"general"`, `"gameplay"`, `"network"` |
| `message` | string | ログメッセージ本文 | `"Player spawned at position (100, 200)"` |

#### 3.3 ログレベル

| レベル | 説明 | 使用例 |
|--------|------|--------|
| `debug` | デバッグ情報 | 変数値、処理フロー確認 |
| `info` | 一般情報 | アプリケーション状態、処理完了通知 |
| `warning` | 警告 | 非致命的エラー、性能劣化 |
| `error` | エラー | 例外、処理失敗 |

### 4. API使用例

#### 4.1 メインスレッド版（推奨）

```gdscript
# セットアップ
const MainThreadSimpleLogger = preload("res://addons/synclogger/mainthread_simple_logger.gd")
var logger = MainThreadSimpleLogger.new()
logger.setup("127.0.0.1", 9998)

# ログ送信
logger.info("Application started")
logger.warning("Low memory warning")
logger.error("Failed to load resource")
logger.debug("Variable value: " + str(player_pos))
logger.log("Custom message", "gameplay")
```

#### 4.2 AutoLoad版（スレッド問題あり）

```gdscript
# セットアップ（AutoLoad経由）
SyncLogger.setup("192.168.1.100", 9999)

# ログ送信
SyncLogger.info("Player connected")
SyncLogger.warning("Network latency high")
SyncLogger.error("Database connection failed")

# 安全な終了
await SyncLogger.shutdown()
```

### 5. 受信側実装

#### 5.1 Python受信例

プロジェクトには `log_receiver.py` が含まれています：

```python
import socket
import json

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(('localhost', 9999))

while True:
    data, addr = sock.recvfrom(1024)
    log_data = json.loads(data.decode('utf-8'))
    
    # ログデータ処理
    timestamp = log_data['timestamp']
    level = log_data['level']
    message = log_data['message']
    frame = log_data['frame']
    
    print(f"[{level}] F:{frame} {message}")
```

#### 5.2 受信側フォーマット出力例

```
[23:15:20.123] INFO     F: 12345 PF:  6789 [general] Application started
[23:15:20.456] WARNING  F: 12350 PF:  6792 [network] Connection timeout
[23:15:20.789] ERROR    F: 12355 PF:  6795 [gameplay] Player health below zero
```

### 6. エラーハンドリング

#### 6.1 送信エラー

| エラー状況 | 処理 | 戻り値 |
|-----------|-----|--------|
| 未セットアップ | 送信スキップ | `false` |
| 無効なホスト/ポート | 送信失敗 | `false` |
| UDP接続失敗 | 送信失敗 | `false` |
| パケット送信失敗 | 送信失敗 | `false` |
| 正常送信 | 送信完了 | `true` |

#### 6.2 受信側エラー

```python
try:
    data, addr = sock.recvfrom(1024)
    log_data = json.loads(data.decode('utf-8'))
except json.JSONDecodeError as e:
    print(f"JSON decode error: {e}")
except UnicodeDecodeError as e:
    print(f"Unicode decode error: {e}")
```

### 7. パフォーマンス仕様

#### 7.1 送信性能

- **送信レイテンシ**: < 1ms（ローカルネットワーク）
- **CPU影響**: メインスレッドブロック無し
- **メモリ使用量**: 最小限（接続プール無し）
- **スループット**: 30+ logs/秒対応

#### 7.2 制限事項

- **最大メッセージサイズ**: JSON文字列として1024バイト以内
- **接続永続化**: 無し（各送信時に新規接続）
- **送達保証**: 無し（UDP特性）
- **順序保証**: 無し（UDP特性）

### 8. セキュリティ考慮事項

#### 8.1 本番環境での注意

- センシティブ情報のログ出力を避ける
- プロダクションビルドでの自動無効化を検討
- ホットキー機能の本番環境での無効化

#### 8.2 ネットワークセキュリティ

- ローカルネットワーク内での使用を想定
- 外部ネットワーク使用時は適切なファイアウォール設定が必要

### 9. 設定パラメータ

#### 9.1 基本設定

```gdscript
# ホスト設定
host: String = "127.0.0.1"  # 受信側IPアドレス
port: int = 9999            # 受信側ポート番号

# タイムアウト設定（UDPのため接続タイムアウトは適用されない）
```

#### 9.2 スレッド版追加設定

```gdscript
# スレッド処理間隔
thread_sleep_usec: int = 1000  # 1ms (1000マイクロ秒)
```

### 10. トラブルシューティング

#### 10.1 よくある問題

| 問題 | 原因 | 解決方法 |
|------|------|----------|
| ログが届かない | ファイアウォール | ポート9999を開放 |
| 送信失敗 | 受信側未起動 | log_receiver.pyを起動 |
| 文字化け | エンコーディング | UTF-8設定確認 |
| パフォーマンス低下 | 高頻度送信 | 送信頻度を調整 |

#### 10.2 デバッグ方法

```gdscript
# 送信結果確認
var result = logger.info("Test message")
print("Send result: ", result)

# 接続情報確認
print("Host: ", logger.get_host())
print("Port: ", logger.get_port())
```

## 付録

### A. 実装ファイル構造

```
res://addons/synclogger/
├── synclogger.gd                   # AutoLoad版（スレッド使用）
├── mainthread_simple_logger.gd     # メインスレッド版（推奨）
├── udp_sender.gd                   # UDP送信クラス
├── log_processing_thread.gd        # スレッド処理クラス
└── thread_safe_queue.gd            # スレッドセーフキュー
```

### B. テストファイル

```
tests/
├── test_mainthread_simple_logger.gd
├── test_synclogger.gd
├── test_udp_sender.gd
└── test_log_processing_thread.gd
```

### C. デモファイル

```
├── demo_mainthread_simple.gd       # メインスレッド版デモ
├── demo_scene.gd                   # AutoLoad版デモ
└── log_receiver.py                 # Python受信スクリプト
```

---

**注意**: 現在スレッド版にはセグメンテーションフォルト問題があるため、安定性が必要な場合は `MainThreadSimpleLogger` の使用を推奨します。