# Godot Network Logger 詳細設計書

## 1. はじめに

本ドキュメントは、`network_logger_requirements.md` に基づき、Godot Network Loggerアドオンの具体的な実装に関する詳細設計を定義する。

## 2. 全体アーキテクチャ（改訂案）

パフォーマンス要件（メインループのブロック禁止）を確実に満たすため、ネットワーク送信とファイル書き込みをワーカースレッドで実行するアーキテクチャに変更する。

- **`LogProcessingThread`:** ログの送信とファイル書き込みをバックグラウンドで処理する `Thread`。
- **`ThreadSafeQueue`:** メインスレッドとワーカースレッド間で安全にログデータをやり取りするためのキュー。内部で `Mutex` を使用してスレッドセーフを保証する。

```
+-------------------------+
|      Godot Engine       |
+-------------------------+
|           |             |
|    Game Code (User)     |     +-----------------------+
|           |             |     |   Editor (Plugin GUI)   |
+-----------|-------------+     +-----------|-----------+
            |                           |
            v                           v
+-----------|---------------------------|-----------+
|  `NetworkLogger` (Singleton / AutoLoad) API     |
+---------------------------------------------------+
|  - メインスreadから呼ばれると、ログを        |
|    `ThreadSafeQueue` に追加するだけ。         |
+---------------------|-----------------------------+
                      |
                      v
+---------------------|-----------------------------+
|  `ThreadSafeQueue` (Mutex-protected Array)        |
+---------------------|-----------------------------+
                      |
                      v
+---------------------------------------------------+
|  `LogProcessingThread` (Worker Thread)            |
+---------------------------------------------------+
|  - Queueからログを取得し続けるループ            |
|  - `UDPSender` を使ってネットワーク送信         |
|  - 送信失敗時にファイルへフォールバック         |
+---------------------|-----------------------------+
                      |
                      v
+---------------------------------------------------+
|              Network (UDP)                        |
+---------------------------------------------------+
```

## 3. クラス設計（改訂案）

### 3.1 `NetworkLogger` (network_logger.gd)

**プロパティ:**
- `_log_thread: LogProcessingThread`: ログ処理スレッドのインスタンス。
- `_log_queue: ThreadSafeQueue`: スレッドセーフなログキュー。
- `_enabled: bool`
- `_min_level: LogLevel`
- `_project_settings: ProjectSettings`

**メソッド (Static):**
- `log(message: String, level: LogLevel, category: String)`: メタデータを付与したログ辞書を作成し、`_log_queue.push()` を呼び出してキューに追加する。
- `_notification(what)`: `NOTIFICATION_WM_CLOSE_REQUEST` を検知したら、`_log_thread` を安全に終了させる。

### 3.2 `LogProcessingThread` (log_thread.gd)

`Thread` を継承。バックグラウンドでログを処理する。

**プロパティ:**
- `_queue: ThreadSafeQueue`: 参照するキュー。
- `_sender: UDPSender`: UDP送信クラスのインスタンス。
- `_should_exit: bool`: スレッドを終了させるためのフラグ。
- `_fallback_file_path: String`: フォールバック先のファイルパス。

**メソッド:**
- `run(queue: ThreadSafeQueue, sender: UDPSender)`: スレッドのメインループ。`queue` をポーリングし、ログがあれば `_sender.send()` で送信。送信失敗時はフォールバック処理を行う。
- `stop()`: `_should_exit` を `true` に設定し、スレッドの終了を要求する。

### 3.3 `UDPSender` (udp_sender.gd)

変更なし。ワーカースレッドから呼び出される。

### 3.4 `ThreadSafeQueue` (thread_safe_queue.gd)

`Mutex` を利用してスレッドセーフなキューを実装。

**プロパティ:**
- `_queue: Array`
- `_mutex: Mutex`

**メソッド:**
- `push(item)`: `_mutex.lock()` を呼び出してから `_queue.push_back(item)` を実行し、`_mutex.unlock()` する。
- `pop()`: `_mutex.lock()` を呼び出してから `_queue.pop_front()` を実行し、`_mutex.unlock()` する。`null` を返す可能性あり。
- `is_empty()`: キューが空かどうかを返す。

### 3.5 `NetworkLoggerPlugin` (plugin.gd)

**メソッド:**
- `_unhandled_input(event: InputEvent)`: ホットキー処理を `_input` からこちらに変更。ゲーム内UIとの競合を避ける。

## 4. データフロー（改訂案）

1.  **ユーザーコード**が `NetworkLogger.info("...")` を呼び出す。
2.  `NetworkLogger` はログ辞書を作成し、`ThreadSafeQueue.push()` でキューに追加する。**（メインスレッドの処理はここで完了）**
3.  **`LogProcessingThread`** は自身のループ内で `ThreadSafeQueue.pop()` を呼び出し、ログを取得する。
4.  取得したログを `UDPSender.send()` に渡してネットワーク送信を試みる。
5.  送信に失敗した場合、ワーカースレッド内で直接フォールバックファイルに書き込む。

## 5. フォールバック処理（改訂案）

- `LogProcessingThread` 内で `UDPSender.send()` が失敗した場合、同スレッド内でファイル書き込み処理を行う。これにより、ファイルI/Oがメインスレッドをブロックすることはない。

## 6. ログモードとログレベルの関係

`LoggingMode` は、`min_level`（最小ログレベル）を自動で設定するためのプリセットとして機能する。この関係を明確にする。

- **`PRODUCTION` モード:** `min_level` を `LogLevel.ERROR` に設定。
- **`DEVELOPMENT` モード:** `min_level` を `LogLevel.INFO` に設定。
- **`DEBUG` モード:** `min_level` を `LogLevel.VERBOSE` に設定。
- **`TEST` モード:** `min_level` を `LogLevel.DEBUG` に設定。
- **`SILENT` モード:** `NetworkLogger.set_enabled(false)` と等価。

このマッピングは `NetworkLogger.set_mode()` が呼び出された際に適用される。

## 7. 受信側スクリプトの考慮事項

- **注記:** READMEドキュメントに「デフォルトの受信バッファサイズは1024バイトです。これを超える非常に長いログメッセージは、受信側で切り捨てられる可能性があります」と明記する。

## 6. ファイル構造

```
res://addons/network_logger/
├── plugin.cfg
├── plugin.gd
├── network_logger.gd
├── udp_sender.gd
├── log_buffer.gd
└── settings/
    └── project_settings.gd
```

## 7. 実装ステップ (Phase 1)

1.  **ファイル作成**: 上記ファイル構造に従い、空のGDScriptファイルを作成する。
2.  **`plugin.cfg` 設定**: 要件定義書通りに設定する。
3.  **`plugin.gd` 実装**: `_enter_tree` と `_exit_tree` の基本的なロジックを実装し、アドオンがGodotエディタで有効/無効にできることを確認する。
4.  **`NetworkLogger` シングルトン設定**: `_enable_plugin` で `NetworkLogger` をAutoLoadに登録する処理を実装する。
5.  **`UDPSender` 実装**: `setup` と `send` の基本的なUDP送信機能を実装する。
6.  **`NetworkLogger` API実装**: `setup` と `log` 系の基本的な関数を実装する。この段階では、`log` は直接 `UDPSender.send` を呼び出すシンプルな実装で良い。
7.  **テスト**: Godotプロジェクトから `NetworkLogger.setup()` と `NetworkLogger.log()` を呼び出し、`log_receiver.py` でログが受信できることを確認する。
8.  **`LogBuffer` 実装**: レート制限機能を持つ `LogBuffer` を実装する。
9.  **`NetworkLogger` と `LogBuffer` の統合**: `NetworkLogger` が `LogBuffer` を経由してログを送信するように修正する。
10. **プロジェクト設定**: `ProjectSettings` クラスを実装し、`NetworkLogger` が `host` や `port` をプロジェクト設定から読み込めるようにする。
11. **ホットキー実装**: `plugin.gd` の `_input` でホットキーを処理し、ログの有効/無効を切り替えられるようにする。
12. **ドキュメントとテスト**: READMEを作成し、最終テストを行う。
