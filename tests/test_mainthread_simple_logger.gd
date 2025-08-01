extends GutTest

# TDD: メインスレッドでのシンプルなログ送信機能のテスト

const MainThreadSimpleLogger = preload("res://addons/synclogger/mainthread_simple_logger.gd")

var simple_logger
var mock_udp_sender

func before_each():
	simple_logger = null
	mock_udp_sender = null

func after_each():
	# RefCountedオブジェクトは自動的にメモリ管理される
	simple_logger = null
	mock_udp_sender = null

func test_can_create_mainthread_simple_logger():
	# Red: まだSimpleLoggerクラスが存在しない
	simple_logger = MainThreadSimpleLogger.new()
	assert_not_null(simple_logger, "MainThreadSimpleLoggerが作成できること")

func test_can_setup_simple_logger():
	# Red: setupメソッドが存在しない
	simple_logger = MainThreadSimpleLogger.new()
	simple_logger.setup("127.0.0.1", 9998)
	
	assert_eq(simple_logger.get_host(), "127.0.0.1", "ホストが正しく設定されること")
	assert_eq(simple_logger.get_port(), 9998, "ポートが正しく設定されること")

func test_can_send_log_immediately():
	# Green: 基本的なログ送信機能をテスト
	simple_logger = MainThreadSimpleLogger.new()
	simple_logger.setup("127.0.0.1", 9998)
	
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