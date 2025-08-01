# Debug Files

このフォルダーにはデバッグとテスト用のファイルが含まれています。

## ファイル説明

### UDPSender関連
- `udp_sender_debug.gd` - UDPSender問題調査用のデバッグ版クラス
- `debug_udp_test.gd/tscn` - UDPSender連続送信問題の詳細調査
- `simple_udp_test.gd/tscn` - 基本的なUDP送信テスト
- `test_udp_simple.gd/tscn` - UDPSender単体テスト

## 使用方法

```bash
# UDPデバッグテスト実行
../bin/godot --headless debug/debug_udp_test.tscn --quit

# シンプルUDP送信テスト
../bin/godot --headless debug/simple_udp_test.tscn --quit
```

## 開発履歴

これらのファイルは以下の問題調査で作成されました：
- UDP送信失敗の原因特定（接続再利用問題）
- UDPSender修正版の動作確認
- スレッド版からメインスレッド版への移行検証