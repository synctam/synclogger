extends GutTest
class_name TestSyncLoggerIntegration

# SyncLogger + Logger Interceptor統合テスト

const SyncLoggerMain = preload("res://addons/synclogger/synclogger.gd")

var _sync_logger: SyncLoggerMain
var _test_host: String = "127.0.0.1"
var _test_port: int = 9998

func before_each():
	_sync_logger = SyncLoggerMain.new()

func after_each():
	if _sync_logger:
		_sync_logger.shutdown()
		_sync_logger = null

func test_synclogger_with_interceptor_setup():
	# テスト: SyncLoggerが Interceptor付きで正常にセットアップできること
	_sync_logger.setup(_test_host, _test_port)

	assert_true(_sync_logger.is_setup(), "SyncLoggerがセットアップされること")
	assert_true(_sync_logger.is_system_capture_enabled(), "システムキャプチャがデフォルト有効であること")

func test_system_log_capture_control():
	# テスト: システムログキャプチャの制御
	_sync_logger.setup(_test_host, _test_port)

	# デフォルト状態確認
	assert_true(_sync_logger.is_system_capture_enabled(), "デフォルトでシステムキャプチャ有効")
	assert_true(_sync_logger.is_capture_errors_enabled(), "デフォルトでエラーキャプチャ有効")
	assert_true(_sync_logger.is_capture_messages_enabled(), "デフォルトでメッセージキャプチャ有効")

	# 無効化
	_sync_logger.enable_system_log_capture(false)
	assert_false(_sync_logger.is_system_capture_enabled(), "システムキャプチャを無効化できること")

	# 再有効化
	_sync_logger.enable_system_log_capture(true)
	assert_true(_sync_logger.is_system_capture_enabled(), "システムキャプチャを再有効化できること")

func test_selective_capture_control():
	# テスト: 選択的キャプチャ制御
	_sync_logger.setup(_test_host, _test_port)

	# エラーのみ無効化
	_sync_logger.set_capture_errors(false)
	assert_false(_sync_logger.is_capture_errors_enabled(), "エラーキャプチャを無効化できること")
	assert_true(_sync_logger.is_capture_messages_enabled(), "メッセージキャプチャは有効のまま")

	# メッセージのみ無効化
	_sync_logger.set_capture_messages(false)
	assert_false(_sync_logger.is_capture_messages_enabled(), "メッセージキャプチャを無効化できること")

func test_system_log_stats():
	# テスト: システムログ統計情報の取得
	_sync_logger.setup(_test_host, _test_port)

	var stats = _sync_logger.get_system_log_stats()
	assert_not_null(stats, "統計情報が取得できること")
	assert_true(stats.has("enabled"), "統計情報にenabledが含まれること")
	assert_true(stats.has("capture_messages"), "統計情報にcapture_messagesが含まれること")
	assert_true(stats.has("capture_errors"), "統計情報にcapture_errorsが含まれること")

func test_traditional_api_still_works():
	# テスト: 従来のAPIが引き続き動作すること
	_sync_logger.setup(_test_host, _test_port)

	# 従来のログメソッドが動作すること
	assert_true(_sync_logger.info("テスト情報"), "infoメソッドが動作すること")
	assert_true(_sync_logger.debug("テストデバッグ"), "debugメソッドが動作すること")
	assert_true(_sync_logger.warning("テスト警告"), "warningメソッドが動作すること")
	assert_true(_sync_logger.error("テストエラー"), "errorメソッドが動作すること")

func test_interceptor_lifecycle():
	# テスト: Interceptorのライフサイクル管理
	_sync_logger.setup(_test_host, _test_port)

	# セットアップ直後はシステムキャプチャが有効
	assert_true(_sync_logger.is_system_capture_enabled(), "セットアップ直後はシステムキャプチャ有効")

	# シャットダウンでクリーンアップされること
	_sync_logger.shutdown()
	assert_false(_sync_logger.is_setup(), "シャットダウン後はsetupが無効になること")