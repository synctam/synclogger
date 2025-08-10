class_name SyncLoggerMain
extends Node

# SyncLogger - Godot用UDPログ送信システム
# MainThreadSimpleLoggerベースの安定実装

const MainThreadSimpleLogger = preload("res://addons/synclogger/mainthread_simple_logger.gd")
const UDPSender = preload("res://addons/synclogger/udp_sender.gd")

var _logger: MainThreadSimpleLogger
var _host: String = ""
var _port: int = 0
var _is_setup: bool = false

func _init():
	_logger = MainThreadSimpleLogger.new()

func setup(host: String, port: int) -> void:
	_host = host
	_port = port
	_logger.setup(host, port)
	_is_setup = true

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

# 終了処理
func shutdown() -> void:
	_is_setup = false
	# MainThreadSimpleLoggerは特別な終了処理不要