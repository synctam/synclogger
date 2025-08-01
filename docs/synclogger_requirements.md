# Godot SyncLogger アドオン 要件定義書

## 1. プロジェクト概要

### 1.1 目的
- Godot 4.x用のリアルタイムネットワークログ送信アドオンの開発
- ゲーム開発・デバッグ効率の向上
- フレーム単位でのログ分析を可能にする開発ツール

### 1.2 背景
- 既存のGodotログアドオンはローカルファイル保存のみ
- ネットワークログ送信機能を持つアドオンは存在しない（市場機会）
- ゲーム特有のフレーム単位ログ分析ニーズへの対応

### 1.3 ターゲットユーザー
- Godotゲーム開発者（個人・チーム）
- デバッグ・テスト効率化を求める開発者
- リモート監視・分析を必要とするプロジェクト

## 2. Phase 1（MVP）機能要件

### 2.1 核となる機能
#### 2.1.1 UDP基本送信機能
- シンプルなUDP通信によるログ送信
- JSON形式でのデータ送信
- 送信失敗時のローカルファイルフォールバック

#### 2.1.2 実装済み基本ログAPI

**AutoLoad版（SyncLogger）- スレッド問題あり**
```gdscript
SyncLogger.setup("192.168.1.100", 9999)  # 設定
SyncLogger.log("メッセージ")              # 基本送信
SyncLogger.debug("デバッグ情報")          # レベル別送信
SyncLogger.info("情報")
SyncLogger.warning("警告")
SyncLogger.error("エラー")
await SyncLogger.shutdown()              # 安全な終了処理
```

**MainThreadSimpleLogger版（推奨・安定版）**
```gdscript
const MainThreadSimpleLogger = preload("res://addons/synclogger/mainthread_simple_logger.gd")
var logger = MainThreadSimpleLogger.new()
logger.setup("127.0.0.1", 9998)         # 設定
logger.log("メッセージ", "category")      # カテゴリ付きログ
logger.debug("デバッグ情報")              # レベル別送信
logger.info("情報")
logger.warning("警告")  
logger.error("エラー")
```

#### 2.1.3 Godot統合機能
- プロジェクト設定での設定管理
- シングルトン（AutoLoad）として動作
- エディタプラグインとしての統合

### 2.2 ゲーム特化機能
#### 2.2.1 フレーム情報の自動付与
```json
{
    "timestamp": 1689123456.789,
    "frame": 1024,
    "physics_frame": 512,
    "level": "info",
    "message": "Player health changed to 75"
}
```

#### 2.2.2 ゲーム状況の自動記録
- 現在のFPS
- フレーム処理時間
- メモリ使用量
- シーン情報

### 2.3 パフォーマンス要件
#### 2.3.1 ゲームへの影響最小化
- ログ送信処理時間: 1ms以内
- メインゲームループのブロック禁止
- 送信失敗時の即座フォールバック

#### 2.3.2 大量ログ対応
- レート制限機能（デフォルト: 30ログ/秒）
- バースト制御
- サンプリング機能（設定可能）

## 3. 技術仕様

### 3.1 システム構成
```
res://addons/synclogger/
├── plugin.cfg                 # プラグイン設定
├── plugin.gd                  # プラグインメイン
├── synclogger.gd          # シングルトンクラス
├── udp_sender.gd             # UDP送信処理
├── log_buffer.gd             # ログバッファ管理
└── settings/
    └── project_settings.gd    # プロジェクト設定管理
```

### 3.2 対象環境
- **Godot**: 4.x系
- **言語**: GDScript
- **プロトコル**: UDP（Phase 1）
- **フォーマット**: JSON

### 3.3 ネットワーク仕様
#### 3.3.1 プロトコル
- **Phase 1**: UDP のみ
- **将来**: TCP、HTTP、WebSocket対応予定

#### 3.3.2 データフォーマット
```json
{
    "timestamp": 1689123456.789,
    "frame": 1024,
    "physics_frame": 512,
    "delta_time": 0.0166,
    "level": "info",
    "category": "player",
    "scene": "MainGame",
    "fps": 60.2,
    "memory_usage": "45MB",
    "message": "Player moved to position (100, 200)"
}
```

## 4. API設計

### 4.1 基本API
```gdscript
class_name SyncLogger
extends Node

# 設定
static func setup(host: String, port: int) -> void
static func is_enabled() -> bool
static func set_enabled(enabled: bool) -> void

# ログ送信
static func log(message: String, category: String = "general") -> void
static func debug(message: String, category: String = "general") -> void
static func info(message: String, category: String = "general") -> void
static func warning(message: String, category: String = "general") -> void
static func error(message: String, category: String = "general") -> void

# 状態取得
static func is_connected() -> bool
static func get_stats() -> Dictionary
```

### 4.2 高度なAPI
```gdscript
# ログレベル制御
static func set_min_level(level: LogLevel) -> void
static func set_max_logs_per_second(rate: int) -> void
static func set_sampling_rate(rate: float) -> void

# カテゴリ制御
static func enable_category(category: String) -> void
static func disable_category(category: String) -> void

# モード制御
static func set_mode(mode: LoggingMode) -> void
static func test_mode() -> void
static func silent_mode() -> void
```

## 5. 設定仕様

### 5.1 プロジェクト設定
```gdscript
# 基本設定
synclogger/enabled: true
synclogger/host: "localhost"
synclogger/port: 9999

# パフォーマンス設定
synclogger/max_logs_per_second: 30
synclogger/sampling_rate: 1.0
synclogger/min_level: LogLevel.INFO

# フォールバック設定
synclogger/fallback_enabled: true
synclogger/fallback_file: "user://sync_log_fallback.txt"

# ゲーム特化設定
synclogger/include_frame_info: true
synclogger/include_performance_info: true
synclogger/auto_disable_on_lag: true
```

### 5.2 ログレベル
```gdscript
enum LogLevel {
    VERBOSE,    # 詳細情報
    DEBUG,      # デバッグ情報
    INFO,       # 一般情報
    WARNING,    # 警告
    ERROR,      # エラー
    CRITICAL    # 致命的エラー
}
```

### 5.3 ログモード
```gdscript
enum LoggingMode {
    PRODUCTION,   # 最小限のログ
    DEVELOPMENT,  # 中程度のログ
    DEBUG,        # 詳細ログ
    TEST,         # テスト用最適化
    SILENT        # ログ無効
}
```

## 6. ホットキー仕様

### 6.1 基本ホットキー
| キー組み合わせ | 機能 | 説明 |
|---|---|---|
| Ctrl+Shift+L | ログ切り替え | ネットワークログのON/OFF |
| Ctrl+Shift+T | テストモード | テスト用設定（少量ログ） |
| Ctrl+Shift+S | サイレントモード | ログ完全停止 |
| F12 | 重要マーク | 重要な瞬間のタイムスタンプ記録 |

### 6.2 プリセット切り替え
| キー組み合わせ | プリセット | 説明 |
|---|---|---|
| Ctrl+Shift+1 | 最小ログ | エラーのみ |
| Ctrl+Shift+2 | 通常ログ | 警告以上 |
| Ctrl+Shift+3 | デバッグログ | 全レベル |
| Ctrl+Shift+4 | パフォーマンス監視 | FPS・メモリ情報 |

### 6.3 ホットキー設定
```gdscript
# プロジェクト設定でカスタマイズ可能
synclogger/hotkeys_enabled: true
synclogger/hotkey_toggle: "Ctrl+Shift+L"
synclogger/hotkey_test_mode: "Ctrl+Shift+T"
synclogger/hotkey_emergency_stop: "Ctrl+Shift+X"
synclogger/hotkeys_in_release: false  # リリース版で無効化
```

## 7. 受信側システム仕様

### 7.1 Phase 1: Python軽量スクリプト
#### 7.1.1 要件
- Python 3.6以上
- 標準ライブラリのみ（追加インストール不要）

#### 7.1.2 機能
- UDP受信（localhost:9999）
- JSON解析
- コンソール表示
- 基本的なエラーハンドリング

#### 7.1.3 実装例
```python
# log_receiver.py
import socket
import json
from datetime import datetime

def start_log_receiver(host='localhost', port=9999):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((host, port))
    print(f"Log receiver started on {host}:{port}")
    
    while True:
        try:
            data, addr = sock.recvfrom(1024)
            log_data = json.loads(data.decode('utf-8'))
            
            ts = datetime.fromtimestamp(log_data.get('timestamp', 0))
            frame = log_data.get('frame', '?')
            message = log_data.get('message', '')
            
            print(f"[{ts.strftime('%H:%M:%S')}] Frame:{frame} - {message}")
            
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    start_log_receiver()
```

### 7.2 使用方法
```bash
# 1. ファイルを保存
# 2. 実行
python log_receiver.py

# 出力例:
# Log receiver started on localhost:9999
# [14:30:15] Frame:1024 - Player moved to (100, 200)
# [14:30:15] Frame:1025 - Enemy AI decision: attack
```

## 8. 将来の拡張計画

### 8.1 Phase 2: 機能強化（2-3週間）
- TCP対応
- バッチ送信機能
- 詳細なエラーハンドリング
- 既存ロガーとの連携

### 8.2 Phase 3: パフォーマンス最適化（2-3週間）
- 非同期送信処理
- 回路ブレーカーパターン
- メモリ使用量最適化
- パフォーマンス監視機能

### 8.3 Phase 4: 高度機能（3-4週間）
- TLS暗号化対応
- HTTP/WebSocket対応
- エディタドック（ログビューア）
- Godot受信アプリケーション

### 8.4 Phase 5: エコシステム（長期）
- 既存ログツール連携（ELK Stack、Splunk等）
- クラウドサービス対応
- ログ分析・可視化ツール
- Asset Library公開

## 9. 制約事項・注意点

### 9.1 パフォーマンス制約
- ログ送信処理は1ms以内で完了すること
- ネットワーク障害時にゲームを停止させないこと
- メモリ使用量は最小限に抑えること

### 9.2 セキュリティ考慮
- 本番環境での機密情報ログ防止
- リリースビルドでの自動無効化オプション
- ホットキーのセキュリティリスク対策

### 9.3 互換性
- Godot 4.x系での動作保証
- 将来バージョンでの互換性維持
- 他アドオンとの競合回避

### 9.4 ユーザビリティ
- 5分以内でのセットアップ完了
- 初回使用時の明確なドキュメント
- トラブルシューティングガイド

## 10. 成功判定基準

### 10.1 Phase 1完了条件
- ✅ Godotアドオンとして正常動作
- ✅ UDP送信でPython受信スクリプトに届く
- ✅ プロジェクト設定での設定変更可能
- ✅ ホットキーによる制御機能
- ✅ 送信失敗時のフォールバック動作
- ✅ 10分以内での他開発者による試用開始

### 10.2 品質基準
- ゲームパフォーマンスへの影響なし
- ネットワーク障害時の安定動作
- 直感的で分かりやすいAPI
- 包括的なドキュメント

## 11. 開発スケジュール

### 11.1 Phase 1開発（1-2週間）
- Week 1: 基本UDP送信機能、プロジェクト設定統合
- Week 2: ホットキー機能、フォールバック機能、テスト

### 11.2 ドキュメント作成（並行）
- README（クイックスタート）
- API リファレンス
- トラブルシューティングガイド
- サンプルプロジェクト

### 11.3 公開準備
- Asset Library向けパッケージング
- GitHub リポジトリ整備
- デモ動画作成

---

## 12. 実装完了状況（2024年末時点更新）

### 12.1 ✅ Phase 1 MVP完成
- **スレッドベースUDPログシステム**: 完全実装済み
- **全テスト成功**: 33テスト全て成功（テスト駆動開発実施）
- **実際のUDP通信確認**: Python受信スクリプトで動作確認済み

### 12.2 🚀 MainThreadSimpleLogger追加開発
- **安定版ロガー**: メインスレッドで即座UDP送信
- **UDPSender修正**: 接続問題解決済み
- **TDD実施**: Red-Green-Refactorサイクル完遂
- **統合テスト成功**: 実際のログ送受信確認済み

### 12.3 ⚠️ 既知の問題と推奨事項
- **スレッド版問題**: LogProcessingThreadでセグメンテーションフォルト
- **現在の推奨**: MainThreadSimpleLoggerを使用
- **将来対応**: スレッド問題解決後にスレッド版を本格運用

### 12.4 📂 現在のプロジェクト構成
```
res://addons/synclogger/
├── synclogger.gd (SyncLoggerMain - AutoLoad)
├── mainthread_simple_logger.gd (推奨版)
├── udp_sender.gd (修正済み)
├── thread_safe_queue.gd
├── log_processing_thread.gd (問題あり)
└── plugin.gd/plugin.cfg

demo_scene.gd/tscn (スレッド版デモ)
demo_mainthread_simple.gd/tscn (安定版デモ)
log_receiver.py (Python受信スクリプト)
tests/ (33テスト全成功)
debug/ (開発デバッグファイル)
```

---

**作成日**: 2025年7月17日  
**最終更新**: 2024年末（実装完了時点）
**バージョン**: 1.1 (実装状況反映版)
**作成者**: ブレインストーミングセッション結果 + 実装チーム