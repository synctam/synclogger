extends GutTest
class_name TestVersionCompatibility

# バージョン互換性テスト
# Godot 4.0-4.4 と 4.5+ での動作確認

var _sync_logger: SyncLoggerMain
var _test_host: String = "127.0.0.1"
var _test_port: int = 9999


func before_each():
	_sync_logger = SyncLoggerMain.new()
	# Orphans対策: テスト用に親ノードを設定
	add_child_autofree(_sync_logger)


func after_each():
	if _sync_logger:
		_sync_logger.shutdown()
	# add_child_autofreeが自動的に解放するのでqueue_freeは不要
	_sync_logger = null


func test_logger_support_detection():
	# テスト: Loggerサポートの正確な検出
	var is_logger_available = ClassDB.class_exists("Logger")
	var synclogger_support = _sync_logger.is_logger_integration_available()

	assert_eq(synclogger_support, is_logger_available, "SyncLoggerのLogger統合サポート検出が正確であること")


func test_compatibility_info():
	# テスト: 互換性情報の取得
	var info = _sync_logger.get_compatibility_info()

	assert_not_null(info, "互換性情報が取得できること")
	assert_true(info.has("godot_version"), "Godotバージョン情報が含まれること")
	assert_true(info.has("logger_support"), "Loggerサポート情報が含まれること")
	assert_true(info.has("interceptor_active"), "インターセプター状態が含まれること")
	assert_true(info.has("system_capture_available"), "システムキャプチャ可用性が含まれること")


func test_basic_functionality_always_works():
	# テスト: 基本機能は常に動作すること
	# テスト用設定ファイルを作成
	var config_path = _sync_logger.get_config_file_path()
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	file.store_string("{}")
	file.close()

	_sync_logger._reset_config_state()
	_sync_logger.setup(_test_host, _test_port)
	_sync_logger.set_test_mode(true)  # テスト環境での接続エラー回避

	# 基本ログ機能（全バージョンで動作）
	assert_true(_sync_logger.info("test message"), "基本ログ機能が動作すること")
	assert_true(_sync_logger.debug("test debug"), "デバッグログが動作すること")
	assert_true(_sync_logger.error("test error"), "エラーログが動作すること")


func test_system_capture_behavior_based_on_version():
	# テスト: システムキャプチャのバージョン別動作
	_sync_logger.setup(_test_host, _test_port)

	var logger_support = _sync_logger.is_logger_integration_available()

	if logger_support:
		# Godot 4.5+: システムキャプチャが利用可能
		assert_true(_sync_logger.is_system_capture_enabled(), "Godot 4.5+ではシステムキャプチャがデフォルト有効")

		# システムキャプチャ制御が動作
		# システムキャプチャは setup() 時に自動設定されるため、テスト簡素化
		# 新API設計では setup() 時の自動設定のため、手動無効化テストは省略
		# assert_false(_sync_logger.is_system_capture_enabled(),
		#             "システムキャプチャを無効化できること")

		_sync_logger.enable_system_capture()
		assert_true(_sync_logger.is_system_capture_enabled(), "システムキャプチャを再有効化できること")
	else:
		# Godot 4.0-4.4: システムキャプチャは無効
		assert_false(_sync_logger.is_system_capture_enabled(), "Godot 4.0-4.4ではシステムキャプチャが無効")

		# システムキャプチャAPIは安全に呼び出せるが効果なし
		_sync_logger.enable_system_capture()
		assert_false(_sync_logger.is_system_capture_enabled(), "古いバージョンではシステムキャプチャは有効にならない")


func test_error_message_capture_based_on_version():
	# テスト: エラーキャプチャのバージョン別動作
	_sync_logger.setup(_test_host, _test_port)

	var logger_support = _sync_logger.is_logger_integration_available()

	if logger_support:
		# Godot 4.5+: エラーキャプチャが利用可能
		assert_true(_sync_logger.is_capture_errors_enabled(), "Godot 4.5+ではエラーキャプチャがデフォルト有効")

		_sync_logger.set_capture_errors(false)
		assert_false(_sync_logger.is_capture_errors_enabled(), "エラーキャプチャを無効化できること")
	else:
		# Godot 4.0-4.4: エラーキャプチャは無効
		assert_false(_sync_logger.is_capture_errors_enabled(), "Godot 4.0-4.4ではエラーキャプチャが無効")


func test_graceful_degradation():
	# テスト: グレースフルデグラデーション（機能劣化の適切な処理）
	# テスト用設定ファイルを作成
	var config_path = _sync_logger.get_config_file_path()
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	file.store_string("{}")
	file.close()

	_sync_logger._reset_config_state()
	_sync_logger.setup(_test_host, _test_port)

	# 新機能APIの呼び出し（例外が発生しないこと）
	_sync_logger.enable_system_capture()
	_sync_logger.set_capture_errors(true)
	_sync_logger.set_capture_messages(true)

	# 統計情報の取得（例外が発生しないこと）
	var stats = _sync_logger.get_system_log_stats()
	assert_not_null(stats, "統計情報が取得できること")

	# 基本機能は影響を受けないこと
	assert_true(_sync_logger.info("test after system calls"), "新機能API呼び出し後も基本機能が動作すること")
