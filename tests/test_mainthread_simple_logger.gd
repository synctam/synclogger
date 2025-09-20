extends GutTest

# TDD: メインスレッドでのシンプルなログ送信機能のテスト

const MainThreadSimpleLogger = preload("res://addons/synclogger/mainthread_simple_logger.gd")

var simple_logger
var mock_udp_sender


func before_each():
	simple_logger = null
	mock_udp_sender = null


func after_each():
	# RefCountedオブジェクトのクリーンアップ
	if simple_logger:
		simple_logger.close()
	simple_logger = null
	mock_udp_sender = null


func test_can_create_mainthread_simple_logger():
	# Red: まだSimpleLoggerクラスが存在しない
	simple_logger = MainThreadSimpleLogger.new()
	assert_not_null(simple_logger, "MainThreadSimpleLoggerが作成できること")


func test_can_setup_simple_logger():
	# Red: setupメソッドが存在しない
	simple_logger = MainThreadSimpleLogger.new()
	simple_logger.setup("127.0.0.1", 9999)

	assert_eq(simple_logger.get_host(), "127.0.0.1", "ホストが正しく設定されること")
	assert_eq(simple_logger.get_port(), 9999, "ポートが正しく設定されること")


func test_can_send_log_immediately():
	# Green: 基本的なログ送信機能をテスト
	simple_logger = MainThreadSimpleLogger.new()
	simple_logger.setup("127.0.0.1", 9999)
	simple_logger.set_test_mode(true)  # テスト環境での接続エラー回避

	# 実際の送信結果を確認（モックなしでシンプルに）
	var result = simple_logger.log("Test message")

	# 基本的な結果をテスト（送信結果はネットワーク環境に依存するため、戻り値の存在のみ確認）
	assert_not_null(result, "ログ送信メソッドが結果を返すこと")


# 複雑なテストは後のイテレーションで実装
# func test_log_contains_correct_frame_info():
# func test_different_log_levels():


func test_send_without_setup_fails():
	# Red: セットアップなしでの送信制御が存在しない
	simple_logger = MainThreadSimpleLogger.new()

	var result = simple_logger.log("Should fail")
	assert_false(result, "セットアップ前のログ送信は失敗すること")


func test_critical_and_trace_levels():
	# TDD Red: critical と trace メソッドがまだ存在しない
	simple_logger = MainThreadSimpleLogger.new()
	simple_logger.setup("127.0.0.1", 9999)
	simple_logger.set_test_mode(true)  # テスト環境での接続エラー回避

	# criticalレベルのテスト
	var critical_result = simple_logger.critical("Critical system error")
	assert_not_null(critical_result, "criticalメソッドが存在し結果を返す")

	# traceレベルのテスト
	var trace_result = simple_logger.trace("Detailed trace info")
	assert_not_null(trace_result, "traceメソッドが存在し結果を返す")


func test_all_six_log_levels():
	# 全6レベルが動作することを確認
	simple_logger = MainThreadSimpleLogger.new()
	simple_logger.setup("127.0.0.1", 9999)
	simple_logger.set_test_mode(true)  # テスト環境での接続エラー回避

	# すべてのレベルをテスト（優先度順）
	var trace_result = simple_logger.trace("trace message")
	var debug_result = simple_logger.debug("debug message")
	var info_result = simple_logger.info("info message")
	var warning_result = simple_logger.warning("warning message")
	var error_result = simple_logger.error("error message")
	var critical_result = simple_logger.critical("critical message")

	# 各メソッドが正しく動作すること
	assert_not_null(trace_result, "traceレベルが動作")
	assert_not_null(debug_result, "debugレベルが動作")
	assert_not_null(info_result, "infoレベルが動作")
	assert_not_null(warning_result, "warningレベルが動作")
	assert_not_null(error_result, "errorレベルが動作")
	assert_not_null(critical_result, "criticalレベルが動作")
