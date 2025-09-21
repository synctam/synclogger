# SyncLogger

Godot Engine用のリアルタイムUDPログ送信アドオン - ゲームループをブロックせずにネットワーク経由でログを送信

## ✨ 特徴

- 🚀 **ノンブロッキング**: ゲームパフォーマンスに影響せずUDP経由でログ送信
- ⚡ **リアルタイム**: ライブデバッグのための即座のログ転送
- 🎯 **シンプルAPI**: 使いやすいログインターフェース
- 🔧 **設定可能**: start/stop APIによる柔軟な設定
- 🛡️ **安定性**: 包括的なテストカバレッジ（60+テスト）
- 🎮 **ゲーム対応**: プロセス・物理フレーム番号の自動追跡

## 📦 インストール

### Godot Asset Library経由（推奨）
1. Godotプロジェクト設定を開く
2. "AssetLib"タブに移動
3. "SyncLogger"を検索
4. ダウンロード・インストール

### 手動インストール
1. このリポジトリをダウンロード
2. `addons/synclogger/`をプロジェクトの`addons/`フォルダにコピー
3. プロジェクト設定 > プラグインで"SyncLogger"を有効化

## 🚀 クイックスタート

### 基本的な使用方法
```gdscript
# セットアップ（通常は_ready()内）
SyncLogger.setup("127.0.0.1", 9999)
SyncLogger.start()  # ログ開始

# ログ送信
SyncLogger.info("プレイヤーがスポーン")
SyncLogger.warning("体力低下: %d" % health)
SyncLogger.error("接続失敗")

# ログ停止（通常は_exit_tree()内）
SyncLogger.stop()

# オプション: ログ再開
SyncLogger.restart()
```

### ログレシーバー

**🚀 クイックスタート**
```bash
# 基本的な使用方法（サンプル実装）
python sample_receiver.py

# 機能付き
python sample_receiver.py --timestamp --save logs.txt

# サンプルスクリプト使用（オプション）
sample_receiver.bat    # Windows
./sample_receiver.sh   # Linux/macOS
```

**📋 機能**
- ✨ **カラー表示**: ログレベル別の色分け（trace, debug, info, warning, error, critical）
- ⏰ **タイムスタンプ表示**: マイクロ秒精度
- 💾 **ファイル保存**: 自動ANSIコード除去
- 🎯 **JSON解析**: 構造化ログ表示
- 🛡️ **エラー処理**: 不正メッセージ耐性

## 📚 API リファレンス

### コアメソッド
- `setup(host: String = "127.0.0.1", port: int = 9999)` - 接続設定を構成（接続はしない）
- `start()` - UDP接続を開始しログを有効化
- `stop()` - UDP接続を停止しログを無効化
- `restart()` - 接続を再起動（stop + start）
- `info(message: String, category: String = "general")` - infoレベルログを送信
- `debug(message: String, category: String = "general")` - debugレベルログを送信
- `warning(message: String, category: String = "general")` - warningレベルログを送信
- `error(message: String, category: String = "general")` - errorレベルログを送信
- `critical(message: String, category: String = "general")` - criticalレベルログを送信
- `trace(message: String, category: String = "general")` - traceレベルログを送信

### セキュリティ機能
```gdscript
# 安全なstart/stop API - 明示的に開始するまでネットワーク通信なし
SyncLogger.setup("127.0.0.1", 9999)  # 設定のみ（接続なし）
SyncLogger.start()                    # 明示的なネットワーク開始
# ... ログ処理 ...
SyncLogger.stop()                     # 完全なネットワーク停止
```

### フレーム情報
すべてのログにゲームデバッグ用の精密なフレーム追跡が自動付与されます：

```json
{
  "timestamp": 1722556800.123,
  "frame": 12345,           // プロセスフレーム番号
  "physics_frame": 6789,    // 物理フレーム番号
  "level": "info",
  "category": "gameplay",
  "message": "プレイヤーがスポーン"
}
```

**ゲーム開発での利点：**
- 🎯 **フレーム精密デバッグ**: ログを特定のゲームフレームと関連付け
- ⏱️ **パフォーマンス分析**: フレームタイミング問題の追跡
- 🔍 **物理デバッグ**: プロセスと物理フレームの分離追跡
- 📊 **タイムライン再構築**: 正確なゲーム状態進行の再現

## 📋 要件

- **Godot**: 4.4.1以降
- **プラットフォーム**: Windows, macOS, Linux
- **ネットワーク**: UDP通信機能
- **オプション**: ログレシーバー用Python 3.x

## ⚡ パフォーマンス

- **ログ処理**: 1メッセージあたり1ms未満
- **高頻度対応**: 30+ログ/秒をサポート
- **メモリ効率**: メモリリーク無し
- **スレッドセーフ**: 並行ログ対応

## 🔧 トラブルシューティング

### よくある問題

**ログが表示されない**
- ネットワーク接続を確認
- ホスト/ポート設定を確認
- ファイアウォールがUDPトラフィックを許可しているか確認

**パフォーマンス影響**
- 本番環境ではログ頻度を削減
- 開発時のみデバッグビルドを使用

**システムログキャプチャ（Godot 4.5+）**
```gdscript
# システムキャプチャはstart()で自動有効化
# 手動で無効にする場合：
SyncLogger.set_capture_errors(false)
SyncLogger.set_capture_messages(false)
```

## 🤝 開発

このプロジェクトはClaude（Anthropic）のAI支援により開発されました。

### 開発環境（devブランチ）
- **テストフレームワーク**: GUT (Godot Unit Test)
- **テストスイート**: 60+の包括的テスト
- **ドキュメント**: `docs/` ディレクトリに配置
- **リリースワークフロー**: `docs/RELEASE_WORKFLOW.md` を参照

### 開発コマンド
```bash
# 全テスト実行
../bin/godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

# コード品質チェック
gdlint addons/synclogger/ tests/
```

### 貢献
- **Issues**: バグレポートや機能要求
- **Pull Requests**: 貢献歓迎
- **テスト**: マージ前に全テスト合格必須
- **ドキュメント**: 機能追加時は関連ドキュメントも更新

## 📄 ライセンス

MIT License - 詳細は[LICENSE](LICENSE)ファイルを参照。

Copyright (c) 2025 synctam (synctam@gmail.com)

---

**📖 Language / 言語**
- [English](README.md)
- [日本語](README_ja.md) （このファイル）