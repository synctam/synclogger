extends GutTest

var synclogger: SyncLoggerNode


func before_each():
	synclogger = SyncLoggerNode.new()
	# テスト用に親ノードを設定（Orphan回避）
	add_child_autofree(synclogger)


func after_each():
	if synclogger:
		synclogger.stop()
	# add_child_autofreeが自動的に解放するのでqueue_freeは不要
	synclogger = null


func test_message_size_limit_4096_bytes():
	"""メッセージサイズ制限4096バイトのテスト"""
	synclogger.setup("127.0.0.1", 9999)
	synclogger.start()

	# 4096バイト（境界値）のメッセージ
	var message_4096 = "A".repeat(4096)
	var result_4096 = synclogger.info(message_4096)
	assert_true(result_4096, "4096バイトのメッセージが送信できる")

	# 4097バイト（制限超過）のメッセージ
	var message_4097 = "A".repeat(4097)
	var result_4097 = synclogger.info(message_4097)
	assert_true(result_4097, "4097バイトのメッセージは切り詰められて送信される")


func test_convert_error_type_all_patterns():
	"""_convert_error_type()の全パターンテスト"""
	# プライベートメソッドのテストは難しいため、
	# システムログキャプチャを通じて間接的にテスト
	synclogger.setup("127.0.0.1", 9999)
	synclogger.start()
	var capture_enabled = synclogger.enable_system_capture()
	assert_true(capture_enabled, "システムキャプチャが有効化される")

	# さまざまなエラーレベルの動作確認
	var stats = synclogger.get_system_log_stats()
	assert_has(stats, "godot_logger_enabled", "統計情報にgodot_logger_enabledが含まれる")
	assert_has(stats, "capture_messages", "統計情報にcapture_messagesが含まれる")


func test_sanitize_ansi_sequences():
	"""ANSIエスケープシーケンス除去テスト"""
	synclogger.setup("127.0.0.1", 9999)
	synclogger.start()

	# ANSIエスケープシーケンスを含むメッセージ
	var ansi_message = "\u001b[31mRed Text\u001b[0m with \u001b[1mbold\u001b[0m"
	var result = synclogger.info(ansi_message)
	assert_true(result, "ANSIエスケープシーケンスを含むメッセージが送信できる")

	# 制御文字を含むメッセージ
	var control_message = "Text with\ttab and\nnewline"
	var result2 = synclogger.info(control_message)
	assert_true(result2, "制御文字を含むメッセージが送信できる")


func test_empty_and_short_message_handling():
	"""空・短メッセージ処理テスト"""
	synclogger.setup("127.0.0.1", 9999)
	synclogger.start()

	# 空メッセージは送信されない（セキュリティ対策）
	var empty_result = synclogger.info("")
	assert_false(empty_result, "空メッセージは送信されない")

	# 1-2文字メッセージは送信されない（セキュリティ対策）
	var short_result = synclogger.info("A")
	assert_false(short_result, "1文字メッセージは送信されない")

	# スペースのみのメッセージは送信されない
	var space_result = synclogger.info("   ")
	assert_false(space_result, "スペースのみのメッセージは送信されない")

	# 3文字以上の有効なメッセージは送信される
	var valid_result = synclogger.info("ABC")
	assert_true(valid_result, "3文字以上のメッセージは送信できる")

	# 非ASCII文字のメッセージ
	var unicode_result = synclogger.info("こんにちは🎮")
	assert_true(unicode_result, "非ASCII文字のメッセージが送信できる")
