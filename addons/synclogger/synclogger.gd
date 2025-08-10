class_name SyncLoggerMain
extends Node

var _queue: ThreadSafeQueue
var _udp_sender: UDPSender
var _log_thread: LogProcessingThread
var _host: String = ""
var _port: int = 0
var _is_setup: bool = false

func _init():
	_queue = ThreadSafeQueue.new()
	_udp_sender = UDPSender.new()
	_log_thread = LogProcessingThread.new()

func setup(host: String, port: int) -> void:
	_host = host
	_port = port
	
	_udp_sender.setup(host, port)
	_log_thread.setup(_queue, _udp_sender)
	_log_thread.start()
	
	_is_setup = true

func get_host() -> String:
	return _host

func get_port() -> int:
	return _port

func is_running() -> bool:
	return _log_thread.is_running()

func get_queue_size() -> int:
	if not _queue:
		return 0
	return _queue.size()

func log(message: String, category: String = "general") -> bool:
	if not _is_setup:
		return false
	
	var log_data = _create_log_data(message, "info", category)
	_queue.push(log_data)
	return true

func debug(message: String, category: String = "general") -> bool:
	if not _is_setup:
		return false
	
	var log_data = _create_log_data(message, "debug", category)
	_queue.push(log_data)
	return true

func info(message: String, category: String = "general") -> bool:
	if not _is_setup:
		return false
	
	var log_data = _create_log_data(message, "info", category)
	_queue.push(log_data)
	return true

func warning(message: String, category: String = "general") -> bool:
	if not _is_setup:
		return false
	
	var log_data = _create_log_data(message, "warning", category)
	_queue.push(log_data)
	return true

func error(message: String, category: String = "general") -> bool:
	if not _is_setup:
		return false
	
	var log_data = _create_log_data(message, "error", category)
	_queue.push(log_data)
	return true

func critical(message: String, category: String = "general") -> bool:
	if not _is_setup:
		return false
	
	var log_data = _create_log_data(message, "critical", category)
	_queue.push(log_data)
	return true

func trace(message: String, category: String = "general") -> bool:
	if not _is_setup:
		return false
	
	var log_data = _create_log_data(message, "trace", category)
	_queue.push(log_data)
	return true

func _create_log_data(message: String, level: String, category: String) -> Dictionary:
	return {
		"timestamp": Time.get_unix_time_from_system(),
		"frame": Engine.get_process_frames(),
		"physics_frame": Engine.get_physics_frames(),
		"level": level,
		"category": category,
		"message": message
	}

func shutdown() -> void:
	if _log_thread and _log_thread.is_running():
		_log_thread.stop()
		# スレッドが完全に停止するまで少し待つ
		await get_tree().process_frame
	_is_setup = false