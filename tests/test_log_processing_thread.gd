extends GutTest

var log_thread: LogProcessingThread
var queue: ThreadSafeQueue
var udp_sender: UDPSender

func before_each():
	queue = ThreadSafeQueue.new()
	udp_sender = UDPSender.new()
	log_thread = LogProcessingThread.new()

func after_each():
	if log_thread:
		log_thread.stop()
		log_thread = null
	queue = null
	if udp_sender:
		udp_sender.close()
		udp_sender = null

func test_can_create_log_processing_thread():
	assert_not_null(log_thread, "LogProcessingThreadが作成できる")

func test_can_setup_queue_and_sender():
	log_thread.setup(queue, udp_sender)
	
	assert_eq(log_thread.get_queue(), queue, "キューが正しく設定される")
	assert_eq(log_thread.get_sender(), udp_sender, "UDPSenderが正しく設定される")

func test_can_start_and_stop_thread():
	log_thread.setup(queue, udp_sender)
	
	var started = log_thread.start()
	assert_true(started, "スレッドが開始できる")
	assert_true(log_thread.is_running(), "スレッドが実行中状態になる")
	
	log_thread.stop()
	await get_tree().process_frame  # スレッド停止を待つ
	assert_false(log_thread.is_running(), "スレッドが停止状態になる")

func test_processes_log_from_queue():
	udp_sender.setup("127.0.0.1", 9999)
	log_thread.setup(queue, udp_sender)
	log_thread.start()
	
	var test_log = {"message": "test", "timestamp": 123456.789}
	queue.push(test_log)
	
	await get_tree().process_frame  # 処理を待つ
	await get_tree().process_frame  # 追加の時間を与える
	
	assert_true(queue.is_empty(), "キューからログが取り出される")
	
	log_thread.stop()

func test_stop_without_setup_does_not_crash():
	log_thread.stop()
	assert_true(true, "setup前のstopでクラッシュしない")

func test_start_without_setup_fails():
	var result = log_thread.start()
	assert_false(result, "setup前のstartは失敗する")