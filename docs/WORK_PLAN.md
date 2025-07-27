# 作業計画書

本ドキュメントは Godot SyncLogger アドオンの開発タスクを管理し、進捗を追跡するためのものです。
完了したタスクには `[x]` を付けます。

## Phase 1: MVP (Minimum Viable Product) の完成

### 1. プロジェクトとアドオンの基本設定
- [ ] `addons/synclogger` ディレクトリ構造の作成
- [ ] `plugin.cfg` ファイルの作成と設定
- [ ] `plugin.gd` の基本構造（`_enter_tree`, `_exit_tree`）を作成
- [ ] `synclogger.gd` をシングルトンとして AutoLoad に登録・解除するロジックを `plugin.gd` に実装
- [ ] **[手動テスト]** Godotエディタでアドオンを有効化・無効化できることを確認

### 2. テスト環境の構築
- [ ] `GUT (Godot Unit Test)` アドオンをプロジェクトに導入
- [ ] GUTの設定を行い、テストが実行できることを確認
- [ ] `tests` ディレクトリを作成し、最初のテストファイル `test_placeholder.gd` を作成してGUTの動作を確認

### 3. 非同期ログ送信機能 (TDD)
- #### 3.1 スレッドセーフなキュー
    - [ ] **[Test]** `ThreadSafeQueue` の `push`, `pop`, `is_empty` がスレッドセーフに動作することを確認するテストを作成 (Red)
    - [ ] **[Impl]** `thread_safe_queue.gd` を `Mutex` を使って実装 (Green)
    - [ ] **[Refactor]** コードをリファクタリング

- #### 3.2 UDP送信クラス
    - [ ] **[Test]** `UDPSender` が指定したホストとポートにデータを送信できることを確認するテストを作成 (Red)
    - [ ] **[Impl]** `udp_sender.gd` に基本的なUDP送信機能を実装 (Green)
    - [ ] **[Refactor]** コードをリファクタリング

- #### 3.3 ログ処理スレッド
    - [ ] **[Test]** `LogProcessingThread` がキューからログを取得し、`UDPSender` を呼び出すことを確認するテストを作成 (Red)
    - [ ] **[Impl]** `log_thread.gd` を `Thread` を使って実装 (Green)
    - [ ] **[Refactor]** コードをリファクタリング

### 4. コアAPIの実装 (TDD)
- [ ] **[Test]** `SyncLogger.log()` を呼び出すと、ログが `ThreadSafeQueue` に追加されることを確認するテストを作成 (Red)
- [ ] **[Impl]** `synclogger.gd` に `setup`, `log`, `info`, `error` 等のAPIを実装 (Green)
- [ ] **[Impl]** `SyncLogger` の初期化時に `LogProcessingThread` を起動する処理を実装
- [ ] **[Refactor]** コードをリファクタリング
- [ ] **[手動テスト]** `log_receiver.py` を作成し、Godotから送信したログが受信できることを確認

### 5. 機能の強化 (TDD)
- #### 5.1 プロジェクト設定
    - [ ] **[Test]** `ProjectSettings` クラスが設定の読み書きを行えることを確認するテストを作成 (Red)
    - [ ] **[Impl]** `settings/project_settings.gd` を実装 (Green)
    - [ ] **[Impl]** `SyncLogger` が起動時に `host` や `port` をプロジェクト設定から読み込むようにする

- #### 5.2 ログレベルとカテゴリ
    - [ ] **[Test]** `min_level` に基づいてログがフィルタリングされることを確認するテストを作成 (Red)
    - [ ] **[Impl]** `SyncLogger` にログレベルのフィルタリング機能を実装 (Green)

- #### 5.3 フォールバック機能
    - [ ] **[Test]** ネットワーク送信失敗時にログがファイルに書き込まれることを確認するテストを作成 (Red)
    - [ ] **[Impl]** `LogProcessingThread` にファイルフォールバック機能を実装 (Green)

### 6. エディタ連携
- [ ] **[Impl]** `plugin.gd` の `_unhandled_input` を使ってホットキー（ログ有効/無効化）を実装
- [ ] **[手動テスト]** ホットキーが正しく動作することを確認

### 7. ドキュメントとリリース準備
- [ ] `README.md` の作成（インストール方法、APIリファレンス、使用方法）
- [ ] `log_receiver.py` をプロジェクトのルートに配置し、使い方をドキュメントに記載
- [ ] すべてのドキュメント（要件定義書、設計書、開発方針）を最終確認
- [ ] サンプルシーンを作成し、アドオンの動作デモを確認
- [ ] Godot Asset Library 提出用の `.zip` パッケージを作成

