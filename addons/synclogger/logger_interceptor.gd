class_name SyncLoggerInterceptor
extends Logger

# Godot 4.5 Logger統合のためのインターセプター
# システムのprint(), エラー, 警告を自動的にSyncLoggerに転送

var _sync_logger: MainThreadSimpleLogger
var _mutex: Mutex
var _enabled: bool = true
var _capture_messages: bool = true
var _capture_errors: bool = true

func _init(sync_logger: MainThreadSimpleLogger):
	_sync_logger = sync_logger
	_mutex = Mutex.new()

# Logger仮想メソッドの実装
func _log_message(message: String, error: bool) -> void:
	if not _enabled or not _capture_messages:
		return

	_mutex.lock()

	var level = "error" if error else "info"
	_sync_logger._send_log(message, level, "godot_system")

	_mutex.unlock()

func _log_error(function: String, file: String, line: int, code: String,
               rationale: String, editor_notify: bool, error_type: int,
               script_backtraces: Array) -> void:
	if not _enabled or not _capture_errors:
		return

	_mutex.lock()

	# エラー情報を構造化
	var error_msg = "ERROR in %s:%d (%s): %s" % [file, line, function, rationale]
	var error_level = _convert_error_type(error_type)

	_sync_logger._send_log(error_msg, error_level, "godot_error")

	_mutex.unlock()

# エラータイプをログレベルに変換
func _convert_error_type(error_type: int) -> String:
	match error_type:
		Logger.ERROR_TYPE_ERROR:
			return "error"
		Logger.ERROR_TYPE_WARNING:
			return "warning"
		Logger.ERROR_TYPE_SCRIPT:
			return "error"
		Logger.ERROR_TYPE_SHADER:
			return "error"
		_:
			return "error"

# 制御メソッド
func set_enabled(enabled: bool) -> void:
	_mutex.lock()
	_enabled = enabled
	_mutex.unlock()

func is_enabled() -> bool:
	_mutex.lock()
	var result = _enabled
	_mutex.unlock()
	return result

func set_capture_messages(enabled: bool) -> void:
	_mutex.lock()
	_capture_messages = enabled
	_mutex.unlock()

func set_capture_errors(enabled: bool) -> void:
	_mutex.lock()
	_capture_errors = enabled
	_mutex.unlock()

func is_capture_messages_enabled() -> bool:
	_mutex.lock()
	var result = _capture_messages
	_mutex.unlock()
	return result

func is_capture_errors_enabled() -> bool:
	_mutex.lock()
	var result = _capture_errors
	_mutex.unlock()
	return result

# 統計情報
func get_stats() -> Dictionary:
	return {
		"enabled": _enabled,
		"capture_messages": _capture_messages,
		"capture_errors": _capture_errors,
		"has_sync_logger": _sync_logger != null
	}