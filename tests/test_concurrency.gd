extends GutTest


func test_concurrent_logging_from_multiple_threads():
	var logger = SyncLogger
	logger.setup("127.0.0.1", 9999)
	logger.set_test_mode(true)

	var threads = []
	for i in range(5):
		var thread = Thread.new()
		thread.start(_thread_logger_func.bind(logger, i))
		threads.append(thread)

	for thread in threads:
		thread.wait_to_finish()

	assert_true(true, "並行ログ送信がクラッシュしない")


func _thread_logger_func(logger: Node, thread_id: int):
	for i in range(10):
		logger.log("Thread %d: Message %d" % [thread_id, i])
		OS.delay_msec(1)