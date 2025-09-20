class_name SyncLoggerMain
extends Node

# SyncLogger - Godot用UDPログ送信システム
# MainThreadSimpleLoggerベースの安定実装 + Godot 4.5+ Logger統合（互換性対応）

var _logger: MainThreadSimpleLogger
var _interceptor # SyncLoggerInterceptor or null (Godot 4.5+対応)
var _host: String = ""
var _port: int = 0
var _is_setup: bool = false

# システムログキャプチャ設定（Godot 4.5+のみ有効）
var _system_capture_enabled: bool = true
var _capture_messages: bool = true
var _capture_errors: bool = true
var _logger_registered: bool = false
var _logger_support_available: bool = false

# 設定ファイル機能
var _config_file_enabled: bool = false
const CONFIG_FILENAME = ".synclogger.json"
const DEFAULT_CONFIG = {
	"host": "127.0.0.1",
	"port": 9999,
	"system_capture": true,
	"capture_errors": true,
	"capture_messages": true
}

func _init():
	_logger = MainThreadSimpleLogger.new()
	_check_logger_support()

func _ready():
	_try_load_config_file()

# Godot 4.5+ Logger機能の可用性チェック
func _check_logger_support():
	if ClassDB.class_exists("Logger"):
		_logger_support_available = true
		# Loggerクラスが存在する場合のみInterceptorを作成
		var SyncLoggerInterceptor = load("res://addons/synclogger/logger_interceptor.gd")
		_interceptor = SyncLoggerInterceptor.new(_logger)
		print("SyncLogger: Godot 4.5+ Logger integration enabled")
	else:
		_logger_support_available = false
		_interceptor = null
		print("SyncLogger: Running in compatibility mode (Godot 4.0-4.4)")

func setup(host: String, port: int) -> void:
	_host = host
	_port = port
	_logger.setup(host, port)
	_is_setup = true

	# サニタイズ設定を確実に有効化（ANSI・制御文字除去）
	_logger.set_sanitize_ansi(true)
	_logger.set_sanitize_control_chars(true)

	# システムログキャプチャを自動設定（Godot 4.5+のみ）
	if _logger_support_available:
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
	if not _config_file_enabled or not _is_setup:
		return false
	return _logger.log(message, category)

func trace(message: String, category: String = "general") -> bool:
	if not _config_file_enabled or not _is_setup:
		return false
	return _logger.trace(message, category)

func debug(message: String, category: String = "general") -> bool:
	if not _config_file_enabled or not _is_setup:
		return false
	return _logger.debug(message, category)

func info(message: String, category: String = "general") -> bool:
	if not _config_file_enabled or not _is_setup:
		return false
	return _logger.info(message, category)

func warning(message: String, category: String = "general") -> bool:
	if not _config_file_enabled or not _is_setup:
		return false
	return _logger.warning(message, category)

func error(message: String, category: String = "general") -> bool:
	if not _config_file_enabled or not _is_setup:
		return false
	return _logger.error(message, category)

func critical(message: String, category: String = "general") -> bool:
	if not _config_file_enabled or not _is_setup:
		return false
	return _logger.critical(message, category)

# 内部ヘルパー（互換性のため）
func _create_log_data(message: String, level: String, category: String) -> Dictionary:
	return _logger._create_log_data(message, level, category)

# システムログキャプチャの制御API（Godot 4.5+のみ）
func enable_system_log_capture(enabled: bool) -> void:
	if not _logger_support_available:
		print("SyncLogger: System log capture requires Godot 4.5+")
		return

	_system_capture_enabled = enabled
	if _interceptor:
		_interceptor.set_enabled(enabled)
		if enabled and _is_setup:
			_setup_system_log_capture()
		elif not enabled:
			_cleanup_system_log_capture()

func is_system_capture_enabled() -> bool:
	return _system_capture_enabled and _logger_support_available

func set_capture_errors(enabled: bool) -> void:
	if not _logger_support_available:
		print("SyncLogger: Error capture requires Godot 4.5+")
		return

	_capture_errors = enabled
	if _interceptor:
		_interceptor.set_capture_errors(enabled)

func set_capture_messages(enabled: bool) -> void:
	if not _logger_support_available:
		print("SyncLogger: Message capture requires Godot 4.5+")
		return

	_capture_messages = enabled
	if _interceptor:
		_interceptor.set_capture_messages(enabled)

func is_capture_errors_enabled() -> bool:
	return _capture_errors and _logger_support_available

func is_capture_messages_enabled() -> bool:
	return _capture_messages and _logger_support_available

func get_system_log_stats() -> Dictionary:
	if _interceptor:
		return _interceptor.get_stats()
	return {"logger_support_available": _logger_support_available}

# バージョン情報API
func is_logger_integration_available() -> bool:
	return _logger_support_available

func get_compatibility_info() -> Dictionary:
	return {
		"godot_version": Engine.get_version_info(),
		"logger_support": _logger_support_available,
		"interceptor_active": _interceptor != null,
		"system_capture_available": _logger_support_available,
		"config_file_enabled": _config_file_enabled
	}

# 設定ファイル機能API
func is_config_file_enabled() -> bool:
	return _config_file_enabled

func get_config_file_path() -> String:
	return "user://" + CONFIG_FILENAME

# サニタイズ設定API（上位レベル制御）
func set_sanitize_ansi(enabled: bool) -> void:
	"""ANSIエスケープシーケンス除去の設定"""
	if _logger:
		_logger.set_sanitize_ansi(enabled)

func set_sanitize_control_chars(enabled: bool) -> void:
	"""制御文字除去の設定"""
	if _logger:
		_logger.set_sanitize_control_chars(enabled)

func is_sanitize_ansi_enabled() -> bool:
	if _logger:
		return _logger.is_sanitize_ansi_enabled()
	return true

func is_sanitize_control_chars_enabled() -> bool:
	if _logger:
		return _logger.is_sanitize_control_chars_enabled()
	return true

# テスト用の状態リセット機能
func _reset_config_state() -> void:
	"""テスト用: 設定ファイル状態をリセットして再読み込み"""
	_config_file_enabled = false
	_is_setup = false
	_try_load_config_file()

# 内部実装（Godot 4.5+のみ）
func _setup_system_log_capture() -> void:
	if not _logger_support_available:
		return

	if _system_capture_enabled and _interceptor and not _logger_registered:
		_interceptor.set_enabled(true)
		_interceptor.set_capture_errors(_capture_errors)
		_interceptor.set_capture_messages(_capture_messages)
		# 動的呼び出しでGodot 4.4との互換性を保つ
		if OS.has_method("add_logger"):
			OS.call("add_logger", _interceptor)
		_logger_registered = true

func _cleanup_system_log_capture() -> void:
	if not _logger_support_available:
		return

	if _interceptor and _logger_registered:
		# 動的呼び出しでGodot 4.4との互換性を保つ
		if OS.has_method("remove_logger"):
			OS.call("remove_logger", _interceptor)
		_logger_registered = false

# 終了処理
func shutdown() -> void:
	_cleanup_system_log_capture()
	_is_setup = false
	if _logger:
		_logger.close()
		_logger = null

# 設定ファイル機能
func _try_load_config_file() -> void:
	var config_path = "user://" + CONFIG_FILENAME

	if not FileAccess.file_exists(config_path):
		_config_file_enabled = false
		print("SyncLogger: Disabled (no config file at ", config_path, ")")
		return

	# ファイルが存在する場合は必ず有効化を試行
	var config = _load_config_with_fallback(config_path)
	_setup_from_config(config)
	_config_file_enabled = true
	print("SyncLogger: Enabled with config: ", config)

func _load_config_with_fallback(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("SyncLogger: Failed to read config file, using defaults")
		return DEFAULT_CONFIG.duplicate()

	var content = file.get_as_text().strip_edges()
	file.close()

	# 空ファイルの場合：デフォルト設定を書き込み
	if content.is_empty():
		_write_default_config(path)
		print("SyncLogger: Empty config file, created default config")
		return DEFAULT_CONFIG.duplicate()

	# JSON解析を試行
	var json = JSON.new()
	var parse_result = json.parse(content)

	if parse_result != OK:
		print("SyncLogger: Invalid JSON detected, overwriting with defaults")
		_write_default_config(path)
		return DEFAULT_CONFIG.duplicate()

	var parsed_config = json.data
	if not parsed_config is Dictionary:
		print("SyncLogger: Config is not object, overwriting with defaults")
		_write_default_config(path)
		return DEFAULT_CONFIG.duplicate()

	# デフォルト値とマージ
	var final_config = DEFAULT_CONFIG.duplicate()
	for key in parsed_config:
		if final_config.has(key):
			final_config[key] = parsed_config[key]

	print("SyncLogger: Config loaded and merged with defaults")
	return final_config

func _write_default_config(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		print("SyncLogger: Cannot write config file (permission error)")
		return

	# コメント付きJSONで書き込み
	var default_content = """{
	"_comment": "SyncLogger Configuration - Edit as needed",
	"host": "127.0.0.1",
	"port": 9999,
	"system_capture": true,
	"capture_errors": true,
	"capture_messages": true
}"""

	file.store_string(default_content)
	file.close()
	print("SyncLogger: Default config file created at ", path)

func _setup_from_config(config: Dictionary) -> void:
	# 基本設定
	setup(config.get("host", "127.0.0.1"), config.get("port", 9999))

	# システムキャプチャ設定（Godot 4.5+のみ）
	if _logger_support_available:
		if config.has("system_capture"):
			enable_system_log_capture(config.system_capture)
		if config.has("capture_errors"):
			set_capture_errors(config.capture_errors)
		if config.has("capture_messages"):
			set_capture_messages(config.capture_messages)