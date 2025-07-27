class_name LogProcessingThread
extends RefCounted

var _thread: Thread
var _queue: ThreadSafeQueue
var _udp_sender: UDPSender
var _should_stop: bool = false
var _is_running: bool = false
var _is_setup: bool = false


func _init():
	_thread = Thread.new()


func setup(queue: ThreadSafeQueue, udp_sender: UDPSender) -> void:
	_queue = queue
	_udp_sender = udp_sender
	_is_setup = true


func get_queue() -> ThreadSafeQueue:
	return _queue


func get_sender() -> UDPSender:
	return _udp_sender


func start() -> bool:
	if not _is_setup:
		return false

	if _is_running:
		return false

	_should_stop = false
	_is_running = true

	var result = _thread.start(_thread_worker)
	if result != OK:
		_is_running = false
		return false

	return true


func stop() -> void:
	if not _is_running:
		return

	_should_stop = true
	if _thread.is_started():
		_thread.wait_to_finish()
	_is_running = false


func is_running() -> bool:
	return _is_running


func _thread_worker() -> void:
	while not _should_stop:
		if _queue and not _queue.is_empty():
			var log_data = _queue.pop()
			if log_data and _udp_sender:
				var json_string = JSON.stringify(log_data)
				_udp_sender.send(json_string)

		# 短時間スリープしてCPU使用率を下げる
		OS.delay_msec(1)
