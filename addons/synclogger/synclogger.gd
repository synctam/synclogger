class_name SyncLoggerMain
extends Node

# SyncLogger - Godot用UDPログ送信システム
# MainThreadSimpleLoggerベースの安定実装 + Godot 4.5 Logger統合

const SyncLoggerInterceptor = preload("res://addons/synclogger/logger_interceptor.gd")

var _logger: MainThreadSimpleLogger
var _interceptor: SyncLoggerInterceptor
var _host: String = ""
var _port: int = 0
var _is_setup: bool = false

# システムログキャプチャ設定
var _system_capture_enabled: bool = true
var _capture_messages: bool = true
var _capture_errors: bool = true
var _logger_registered: bool = false

func _init():
	_logger = MainThreadSimpleLogger.new()
	_interceptor = SyncLoggerInterceptor.new(_logger)

func setup(host: String, port: int) -> void:
	_host = host
	_port = port
	_logger.setup(host, port)
	_is_setup = true

	# システムログキャプチャを自動設定
	_setup_system_log_capture()

func get_host() -> String:
	return _host

func get_port() -> int:
	return _port

func is_setup() -> bool:
	return _is_setup

# 互換性のためのメソッド
func is_running() -> bool:
	return _is_setup

func get_queue_size() -> int:
	# キューレス実装のため常に0を返す
	return 0

# ログAPI - MainThreadSimpleLoggerに委譲
func log(message: String, category: String = "general") -> bool:
	if not _is_setup:
		return false
	return _logger.log(message, category)

func trace(message: String, category: String = "general") -> bool:
	if not _is_setup:
		return false
	return _logger.trace(message, category)

func debug(message: String, category: String = "general") -> bool:
	if not _is_setup:
		return false
	return _logger.debug(message, category)

func info(message: String, category: String = "general") -> bool:
	if not _is_setup:
		return false
	return _logger.info(message, category)

func warning(message: String, category: String = "general") -> bool:
	if not _is_setup:
		return false
	return _logger.warning(message, category)

func error(message: String, category: String = "general") -> bool:
	if not _is_setup:
		return false
	return _logger.error(message, category)

func critical(message: String, category: String = "general") -> bool:
	if not _is_setup:
		return false
	return _logger.critical(message, category)

# 内部ヘルパー（互換性のため）
func _create_log_data(message: String, level: String, category: String) -> Dictionary:
	return _logger._create_log_data(message, level, category)

# システムログキャプチャの制御API
func enable_system_log_capture(enabled: bool) -> void:
	_system_capture_enabled = enabled
	if _interceptor:
		_interceptor.set_enabled(enabled)
		if enabled and _is_setup:
			_setup_system_log_capture()
		elif not enabled:
			_cleanup_system_log_capture()

func is_system_capture_enabled() -> bool:
	return _system_capture_enabled

func set_capture_errors(enabled: bool) -> void:
	_capture_errors = enabled
	if _interceptor:
		_interceptor.set_capture_errors(enabled)

func set_capture_messages(enabled: bool) -> void:
	_capture_messages = enabled
	if _interceptor:
		_interceptor.set_capture_messages(enabled)

func is_capture_errors_enabled() -> bool:
	return _capture_errors

func is_capture_messages_enabled() -> bool:
	return _capture_messages

func get_system_log_stats() -> Dictionary:
	if _interceptor:
		return _interceptor.get_stats()
	return {}

# 内部実装
func _setup_system_log_capture() -> void:
	if _system_capture_enabled and _interceptor and not _logger_registered:
		_interceptor.set_enabled(true)
		_interceptor.set_capture_errors(_capture_errors)
		_interceptor.set_capture_messages(_capture_messages)
		OS.add_logger(_interceptor)
		_logger_registered = true

func _cleanup_system_log_capture() -> void:
	if _interceptor and _logger_registered:
		OS.remove_logger(_interceptor)
		_logger_registered = false

# 終了処理
func shutdown() -> void:
	_cleanup_system_log_capture()
	_is_setup = false
	if _logger:
		_logger.close()
		_logger = null