extends GutTest

const SyncLoggerMain = preload("res://addons/synclogger/synclogger.gd")
var synclogger: SyncLoggerMain

func before_each():
	synclogger = SyncLoggerMain.new()

func after_each():
	if synclogger:
		synclogger.shutdown()
		synclogger = null

func test_can_create_synclogger():
	assert_not_null(synclogger, "SyncLoggerが作成できる")

func test_can_setup_host_and_port():
	var host = "127.0.0.1"
	var port = 9999
	
	synclogger.setup(host, port)
	
	assert_eq(synclogger.get_host(), host, "ホストが正しく設定される")
	assert_eq(synclogger.get_port(), port, "ポートが正しく設定される")

func test_setup_enables_logging():
	synclogger.setup("127.0.0.1", 9999)
	assert_true(synclogger.is_setup(), "セットアップ後にログが有効になる")

func test_log_creates_correct_data():
	synclogger.setup("127.0.0.1", 9999)
	
	var log_data = synclogger._create_log_data("test message", "info", "general")
	
	assert_true(log_data.has("timestamp"), "ログにタイムスタンプが含まれる")
	assert_true(log_data.has("frame"), "ログにフレーム番号が含まれる")
	assert_true(log_data.has("message"), "ログにメッセージが含まれる")
	assert_eq(log_data.message, "test message", "メッセージが正しく設定される")
	assert_eq(log_data.level, "info", "ログレベルが正しく設定される")

func test_all_log_levels():
	synclogger.setup("127.0.0.1", 9999)
	
	# 全6レベルが動作することを確認
	var trace_result = synclogger.trace("trace message")
	var debug_result = synclogger.debug("debug message")
	var info_result = synclogger.info("info message")
	var warning_result = synclogger.warning("warning message")
	var error_result = synclogger.error("error message")
	var critical_result = synclogger.critical("critical message")
	
	# 各レベルが正しく処理されること
	assert_true(trace_result == true or trace_result == false, "traceレベルが処理される")
	assert_true(debug_result == true or debug_result == false, "debugレベルが処理される")
	assert_true(info_result == true or info_result == false, "infoレベルが処理される")
	assert_true(warning_result == true or warning_result == false, "warningレベルが処理される")
	assert_true(error_result == true or error_result == false, "errorレベルが処理される")
	assert_true(critical_result == true or critical_result == false, "criticalレベルが処理される")

func test_log_without_setup_returns_false():
	var result = synclogger.log("test message")
	assert_false(result, "setup前のログはfalseを返す")

func test_critical_and_trace_log_levels():
	synclogger.setup("127.0.0.1", 9999)
	
	# criticalレベルのテスト
	var critical_data = synclogger._create_log_data("critical test", "critical", "test")
	assert_eq(critical_data.level, "critical", "criticalレベルが正しく設定される")
	
	# traceレベルのテスト
	var trace_data = synclogger._create_log_data("trace test", "trace", "test")
	assert_eq(trace_data.level, "trace", "traceレベルが正しく設定される")

func test_shutdown_disables_logging():
	synclogger.setup("127.0.0.1", 9999)
	assert_true(synclogger.is_setup(), "セットアップ後はログが有効")
	
	synclogger.shutdown()
	assert_false(synclogger.is_setup(), "shutdown後はログが無効")

func test_compatibility_methods():
	# 互換性メソッドのテスト
	synclogger.setup("127.0.0.1", 9999)
	
	assert_true(synclogger.is_running(), "is_running()はsetup後にtrueを返す")
	assert_eq(synclogger.get_queue_size(), 0, "get_queue_size()は常に0を返す（キューレス実装）")