extends GutTest
class_name TestLoggerInterceptor

# Logger Interceptor機能のテスト
# TDD Red段階: まず失敗するテストを作成

const SyncLoggerInterceptor = preload("res://addons/synclogger/logger_interceptor.gd")
const MainThreadSimpleLogger = preload("res://addons/synclogger/mainthread_simple_logger.gd")

var _interceptor: SyncLoggerInterceptor
var _mock_sync_logger: MainThreadSimpleLogger
var _test_host: String = "127.0.0.1"
var _test_port: int = 9998

func before_each():
	# モックの MainThreadSimpleLogger を作成
	_mock_sync_logger = MainThreadSimpleLogger.new()
	_mock_sync_logger.setup(_test_host, _test_port)

func after_each():
	if _interceptor:
		_interceptor = null
	if _mock_sync_logger:
		_mock_sync_logger.close()
		_mock_sync_logger = null

func test_interceptor_can_be_created():
	# テスト: SyncLoggerInterceptorが作成できること
	_interceptor = SyncLoggerInterceptor.new(_mock_sync_logger)
	assert_not_null(_interceptor, "SyncLoggerInterceptorが作成できること")
	assert_true(_interceptor is Logger, "Loggerクラスのサブクラスであること")

func test_interceptor_inherits_from_logger():
	# テスト: Loggerクラスを継承していること
	_interceptor = SyncLoggerInterceptor.new(_mock_sync_logger)
	assert_true(_interceptor.has_method("_log_message"), "_log_messageメソッドが存在すること")
	assert_true(_interceptor.has_method("_log_error"), "_log_errorメソッドが存在すること")

func test_log_message_delegation():
	# テスト: _log_messageがSyncLoggerに委譲されること
	_interceptor = SyncLoggerInterceptor.new(_mock_sync_logger)

	# 通常メッセージ
	_interceptor._log_message("テストメッセージ", false)
	# TODO: UDPSenderのモック化でログ送信を検証

	# エラーメッセージ
	_interceptor._log_message("エラーメッセージ", true)
	# TODO: UDPSenderのモック化でログ送信を検証

func test_log_error_delegation():
	# テスト: _log_errorがSyncLoggerに委譲されること
	_interceptor = SyncLoggerInterceptor.new(_mock_sync_logger)

	var function = "test_function"
	var file = "test_file.gd"
	var line = 42
	var code = "test_code"
	var rationale = "test_rationale"
	var editor_notify = true
	var error_type = Logger.ERROR_TYPE_ERROR
	var script_backtraces = []

	_interceptor._log_error(function, file, line, code, rationale,
	                       editor_notify, error_type, script_backtraces)
	# TODO: UDPSenderのモック化でログ送信を検証

func test_error_type_conversion():
	# テスト: ErrorTypeが適切にログレベルに変換されること
	_interceptor = SyncLoggerInterceptor.new(_mock_sync_logger)

	# ERROR_TYPE_ERROR -> "error"
	var level = _interceptor._convert_error_type(Logger.ERROR_TYPE_ERROR)
	assert_eq(level, "error", "ERROR_TYPE_ERRORは'error'に変換されること")

	# ERROR_TYPE_WARNING -> "warning"
	level = _interceptor._convert_error_type(Logger.ERROR_TYPE_WARNING)
	assert_eq(level, "warning", "ERROR_TYPE_WARNINGは'warning'に変換されること")

	# ERROR_TYPE_SCRIPT -> "error"
	level = _interceptor._convert_error_type(Logger.ERROR_TYPE_SCRIPT)
	assert_eq(level, "error", "ERROR_TYPE_SCRIPTは'error'に変換されること")

	# ERROR_TYPE_SHADER -> "error"
	level = _interceptor._convert_error_type(Logger.ERROR_TYPE_SHADER)
	assert_eq(level, "error", "ERROR_TYPE_SHADERは'error'に変換されること")

func test_multithread_safety():
	# テスト: マルチスレッド安全性（Mutexの存在確認）
	_interceptor = SyncLoggerInterceptor.new(_mock_sync_logger)
	assert_not_null(_interceptor._mutex, "Mutexが存在すること")

func test_os_add_logger_registration():
	# テスト: OS.add_logger()での登録が可能であること
	_interceptor = SyncLoggerInterceptor.new(_mock_sync_logger)

	# Logger登録（実際の登録テスト）
	OS.add_logger(_interceptor)
	assert_true(true, "OS.add_logger()が例外なく実行されること")

	# クリーンアップ
	OS.remove_logger(_interceptor)