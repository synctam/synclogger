extends GutTest


func test_log_processing_under_1ms():
	var logger = SyncLogger
	logger.setup("127.0.0.1", 9999)
	logger.set_test_mode(true)

	var start_time = Time.get_ticks_usec()
	for i in range(10):
		logger.log("Performance test message %d" % i)
	var elapsed = Time.get_ticks_usec() - start_time
	var avg_time_ms = elapsed / 10000.0  # 10メッセージの平均時間（ミリ秒）

	assert_lt(avg_time_ms, 1.0, "ログ処理は1ms以内に完了すべき")


func test_high_frequency_logging():
	# 30+ logs/秒のテスト
	var logger = SyncLogger
	logger.setup("127.0.0.1", 9999)
	logger.set_test_mode(true)

	var start_time = Time.get_ticks_msec()
	for i in range(35):
		logger.log("High frequency test %d" % i)
	var elapsed = Time.get_ticks_msec() - start_time

	assert_lte(elapsed, 1000, "35ログが1秒以内に処理されるべき")


func test_memory_leak_on_long_run():
	var logger = SyncLogger
	logger.setup("127.0.0.1", 9999)
	logger.set_test_mode(true)

	var initial_memory = OS.get_static_memory_usage()

	for i in range(1000):
		logger.log("Memory test message %d" % i)
		if i % 100 == 0:
			await get_tree().process_frame

	await logger.stop()
	await get_tree().process_frame

	var final_memory = OS.get_static_memory_usage()
	var memory_growth = final_memory - initial_memory

	# 1000メッセージで1MB以上増加していたら警告
	assert_lt(memory_growth, 1048576, "メモリリークの可能性")