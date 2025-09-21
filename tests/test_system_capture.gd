extends GutTest

var synclogger: SyncLoggerNode


func before_each():
	synclogger = SyncLoggerNode.new()
	# テスト用に親ノードを設定（Orphan回避）
	add_child_autofree(synclogger)
	# テストモードを有効化（UDP接続エラー回避）
	synclogger.set_test_mode(true)


func after_each():
	if synclogger:
		synclogger.stop()
	synclogger = null


# TODO: 統合後に実装される機能のテスト（現在は失敗するはず）
func test_system_capture_availability():
	"""システムログキャプチャ機能の可用性テスト"""
	assert_true(synclogger._logger_support_available, "Logger機能が利用可能である")


func test_can_enable_system_capture():
	"""システムログキャプチャ有効化テスト"""
	synclogger.setup("127.0.0.1", 9999)
	synclogger.start()

	var result = synclogger.enable_system_capture()
	if synclogger._logger_support_available:
		assert_true(result, "システムログキャプチャが正常に有効化される")
		assert_true(synclogger.is_system_capture_enabled(), "システムログキャプチャ状態が正しく報告される")
	else:
		assert_false(result, "Logger未対応環境では無効化される")


func test_can_control_capture_messages():
	"""メッセージキャプチャ制御テスト"""
	synclogger.setup("127.0.0.1", 9999)
	synclogger.start()

	# メッセージキャプチャを無効化
	synclogger.set_capture_messages(false)
	var stats = synclogger.get_system_log_stats()

	if synclogger._logger_support_available:
		assert_false(stats.capture_messages, "メッセージキャプチャが無効化される")

	# メッセージキャプチャを有効化
	synclogger.set_capture_messages(true)
	stats = synclogger.get_system_log_stats()

	if synclogger._logger_support_available:
		assert_true(stats.capture_messages, "メッセージキャプチャが有効化される")


func test_can_control_capture_errors():
	"""エラーキャプチャ制御テスト"""
	synclogger.setup("127.0.0.1", 9999)
	synclogger.start()

	# エラーキャプチャを無効化
	synclogger.set_capture_errors(false)
	var stats = synclogger.get_system_log_stats()

	if synclogger._logger_support_available:
		assert_false(stats.capture_errors, "エラーキャプチャが無効化される")

	# エラーキャプチャを有効化
	synclogger.set_capture_errors(true)
	stats = synclogger.get_system_log_stats()

	if synclogger._logger_support_available:
		assert_true(stats.capture_errors, "エラーキャプチャが有効化される")


func test_system_log_stats_format():
	"""システムログ統計情報の形式テスト"""
	synclogger.setup("127.0.0.1", 9999)
	synclogger.start()

	var stats = synclogger.get_system_log_stats()

	assert_true(stats.has("godot_logger_enabled"), "統計にgodot_logger_enabledが含まれる")
	assert_true(stats.has("capture_messages"), "統計にcapture_messagesが含まれる")
	assert_true(stats.has("capture_errors"), "統計にcapture_errorsが含まれる")
	assert_true(stats.has("logger_support_available"), "統計にlogger_support_availableが含まれる")
	assert_true(stats.has("custom_logger_active"), "統計にcustom_logger_activeが含まれる")


func test_compatibility_info_includes_interceptor():
	"""互換性情報にインターセプター情報が含まれるテスト"""
	var info = synclogger.get_compatibility_info()

	assert_true(info.has("interceptor_active"), "互換性情報にinterceptor_activeが含まれる")

	if synclogger._logger_support_available:
		# Logger対応環境では、インターセプターが動作することを期待
		assert_true(info.has("system_capture_available"), "system_capture_availableが含まれる")


func test_custom_logger_lifecycle():
	"""カスタムLoggerのライフサイクルテスト"""
	synclogger.setup("127.0.0.1", 9999)
	synclogger.start()

	if synclogger._logger_support_available:
		# カスタムLoggerが作成されていることを確認
		var stats = synclogger.get_system_log_stats()
		assert_true(stats.custom_logger_active, "カスタムLoggerが活性化されている")

		# シャットダウン時に適切にクリーンアップされることを確認
		synclogger.stop()
		# 注意: シャットダウン後の状態は実装次第
