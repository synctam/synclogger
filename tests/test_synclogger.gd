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

func test_setup_starts_background_thread():
	synclogger.setup("127.0.0.1", 9999)
	
	assert_true(synclogger.is_running(), "セットアップ後にバックグラウンドスレッドが起動している")

func test_log_adds_message_to_queue():
	# ワーカースレッドを起動せずにテスト
	synclogger._host = "127.0.0.1"
	synclogger._port = 9999
	synclogger._is_setup = true
	
	var initial_queue_size = synclogger.get_queue_size()
	synclogger.log("test message")
	
	var after_queue_size = synclogger.get_queue_size()
	assert_gt(after_queue_size, initial_queue_size, "ログメッセージがキューに追加される")

func test_log_includes_timestamp_and_frame():
	synclogger.setup("127.0.0.1", 9999)
	
	var log_data = synclogger._create_log_data("test message", "info", "general")
	
	assert_true(log_data.has("timestamp"), "ログにタイムスタンプが含まれる")
	assert_true(log_data.has("frame"), "ログにフレーム番号が含まれる")
	assert_true(log_data.has("message"), "ログにメッセージが含まれる")
	assert_eq(log_data.message, "test message", "メッセージが正しく設定される")
	assert_eq(log_data.level, "info", "ログレベルが正しく設定される")

func test_different_log_levels():
	# ワーカースレッドを起動せずにテスト
	synclogger._host = "127.0.0.1"
	synclogger._port = 9999
	synclogger._is_setup = true
	
	synclogger.debug("debug message")
	synclogger.info("info message")
	synclogger.warning("warning message")
	synclogger.error("error message")
	
	# 4つのメッセージがキューに追加されることを確認
	assert_eq(synclogger.get_queue_size(), 4, "異なるログレベルのメッセージが全て追加される")

func test_log_without_setup_does_nothing():
	var result = synclogger.log("test message")
	
	assert_false(result, "setup前のログは失敗する")
	assert_eq(synclogger.get_queue_size(), 0, "setup前はキューにメッセージが追加されない")

func test_shutdown_stops_background_thread():
	synclogger.setup("127.0.0.1", 9999)
	assert_true(synclogger.is_running(), "セットアップ後はスレッドが動作している")
	
	synclogger.shutdown()
	
	assert_false(synclogger.is_running(), "shutdown後はスレッドが停止している")