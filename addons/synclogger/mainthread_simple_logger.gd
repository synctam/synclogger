class_name MainThreadSimpleLogger
extends RefCounted

# TDD GREEN段階: テストを通す最小限の実装
# メインスレッドで即座にUDP送信するシンプルなログ送信機能

var _udp_sender: UDPSender
var _host: String = ""
var _port: int = 0
var _is_setup: bool = false

func _init():
	_udp_sender = UDPSender.new()

# RefCountedなので自動的にメモリ管理される

func setup(host: String, port: int) -> void:
	_host = host
	_port = port
	_udp_sender.setup(host, port)
	_is_setup = true

func get_host() -> String:
	return _host

func get_port() -> int:
	return _port

# リファクタリング: 共通ログ送信ロジックを抽出
func log(message: String, category: String = "general") -> bool:
	return _send_log(message, "info", category)

func debug(message: String, category: String = "general") -> bool:
	return _send_log(message, "debug", category)

func info(message: String, category: String = "general") -> bool:
	return _send_log(message, "info", category)

func warning(message: String, category: String = "general") -> bool:
	return _send_log(message, "warning", category)

func error(message: String, category: String = "general") -> bool:
	return _send_log(message, "error", category)

func critical(message: String, category: String = "general") -> bool:
	return _send_log(message, "critical", category)

func trace(message: String, category: String = "general") -> bool:
	return _send_log(message, "trace", category)

# 共通のログ送信処理
func _send_log(message: String, level: String, category: String) -> bool:
	if not _is_setup:
		return false
	
	var log_data = _create_log_data(message, level, category)
	var json_string = JSON.stringify(log_data)
	return _udp_sender.send(json_string)

func _create_log_data(message: String, level: String, category: String) -> Dictionary:
	return {
		"timestamp": Time.get_unix_time_from_system(),
		"frame": Engine.get_process_frames(),
		"physics_frame": Engine.get_physics_frames(),
		"level": level,
		"category": category,
		"message": message
	}

func close() -> void:
	# 接続をクリーンアップ
	_is_setup = false
	if _udp_sender:
		_udp_sender.close()
		_udp_sender = null