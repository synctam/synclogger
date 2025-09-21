# SyncLogger

Godot Engine用のリアルタイムUDPログ送信アドオン - ゲームループをブロックせずにネットワーク経由でログを送信

## ✨ 特徴

- 🚀 **ノンブロッキング**: ゲームパフォーマンスに影響せずUDP経由でログ送信
- ⚡ **リアルタイム**: ライブデバッグのための即座のログ転送
- 🎯 **シンプルAPI**: 使いやすいログインターフェース
- 🔧 **設定可能**: JSONコンフィグファイルによる柔軟な設定
- 🛡️ **安定性**: 包括的なテストカバレッジ（60+テスト）
- 🎮 **ゲーム対応**: 自動フレーム番号・タイムスタンプ付与

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

# ログ送信
SyncLogger.info("プレイヤーがスポーン")
SyncLogger.warning("体力低下: %d" % health)
SyncLogger.error("接続失敗")

# クリーンアップ（通常は_exit_tree()内）
await SyncLogger.shutdown()
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
- `setup(host: String, port: int)` - UDP接続を初期化
- `info(message: String)` - infoレベルログを送信
- `debug(message: String)` - debugレベルログを送信
- `warning(message: String)` - warningレベルログを送信
- `error(message: String)` - errorレベルログを送信
- `critical(message: String)` - criticalレベルログを送信
- `shutdown()` - クリーンシャットダウン（awaitableを返す）

### 設定
```gdscript
# オプション: user://.synclogger.json のJSONコンフィグファイル
{
    "host": "127.0.0.1",
    "port": 9999,
    "system_capture": true,
    "capture_errors": true
}
```

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
# 必要に応じてシステムキャプチャを無効化
SyncLogger.set_system_capture_enabled(false)
```

## 🤝 開発

このプロジェクトはClaude（Anthropic）のAI支援により開発されました。

### 貢献
- **Issues**: バグレポートや機能要求
- **Pull Requests**: 貢献歓迎
- **テスト**: GUTフレームワークでテスト実行

## 📄 ライセンス

MIT License - 詳細は[LICENSE](LICENSE)ファイルを参照。

Copyright (c) 2025 synctam (synctam@gmail.com)

---

**📖 Language / 言語**
- [English](README.md)
- [日本語](README_ja.md) （このファイル）