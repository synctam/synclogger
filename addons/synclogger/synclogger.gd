class_name SyncLoggerMain
extends Node

# SyncLogger - Godot用UDPログ送信システム（Phase 3統一設計）
# 推奨パターン: SyncLogger.setup("127.0.0.1", 9999) → SyncLogger.log("message")

const UDPSender = preload("res://addons/synclogger/udp_sender.gd")
var _udp_sender: UDPSender

# サニタイズ設定
var _sanitize_ansi: bool = true  # デフォルト: ANSI文字を除去
var _sanitize_control_chars: bool = true  # デフォルト: 制御文字を除去

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
	_udp_sender = UDPSender.new()
	_check_logger_support()


func _ready():
	_try_load_config_file()


# Godot 4.5+ Logger機能の可用性チェック（統合版）
func _check_logger_support():
	if ClassDB.class_exists("Logger"):
		_logger_support_available = true
		# TODO: 統合後にGodot Logger統合機能を再実装
		print("SyncLogger: Godot 4.5+ Logger integration enabled")
	else:
		_logger_support_available = false
		print("SyncLogger: Running in compatibility mode (Godot 4.0-4.4)")


func setup(host: String, port: int) -> void:
	# 直接実装: UDPSenderを使用
	_udp_sender.setup(host, port)

	# サニタイズ設定を確実に有効化（ANSI・制御文字除去）
	_sanitize_ansi = true
	_sanitize_control_chars = true

	# システムログキャプチャを自動設定（Godot 4.5+のみ）
	if _logger_support_available:
		_setup_system_log_capture()


func get_host() -> String:
	return _udp_sender.get_host() if _udp_sender != null else ""


func get_port() -> int:
	return _udp_sender.get_port() if _udp_sender != null else 0


func is_setup() -> bool:
	return _udp_sender != null and _udp_sender.is_setup()


func set_test_mode(enabled: bool) -> void:
	"""テスト環境での接続エラー回避モード（テスト専用）"""
	if _udp_sender:
		_udp_sender.set_test_mode(enabled)


# 互換性API（統合・簡素化）
func is_running() -> bool:
	return _udp_sender != null and _udp_sender.is_setup()


func get_queue_size() -> int:
	# キューレス実装のため常に0
	return 0


# 条件チェック統一化（設定ファイル任意化）
func _can_log() -> bool:
	return _udp_sender != null and _udp_sender.is_setup()


# ======== ログAPI - 直接実装（委譲パターン削除） ========

func log(message: String, category: String = "general") -> bool:
	return _send_log(message, "info", category)

func trace(message: String, category: String = "general") -> bool:
	return _send_log(message, "trace", category)

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

# 共通のログ送信処理（MainThreadSimpleLoggerから統合）
func _send_log(message: String, level: String, category: String) -> bool:
	if not _can_log():
		return false

	# JSONコントロール文字問題修正: ANSIエスケープシーケンスを先に除去
	var sanitized_message = _sanitize_message_for_json(message)

	# 改行処理問題修正: サニタイズ後にメッセージをクリーンアップ
	sanitized_message = sanitized_message.strip_edges()

	# サニタイズ後に空メッセージの送信を停止（非常に短いメッセージも除外）
	if sanitized_message.is_empty() or sanitized_message.length() <= 2:
		return false

	var log_data = _create_log_data(sanitized_message, level, category)
	var json_string = JSON.stringify(log_data)
	return _udp_sender.send(json_string)


# ======== サニタイズ機能（MainThreadSimpleLoggerから統合） ========

# サニタイズ設定API
func set_sanitize_ansi(enabled: bool) -> void:
	"""ANSIエスケープシーケンスの除去を設定"""
	_sanitize_ansi = enabled

func set_sanitize_control_chars(enabled: bool) -> void:
	"""制御文字の除去を設定"""
	_sanitize_control_chars = enabled

func is_sanitize_ansi_enabled() -> bool:
	return _sanitize_ansi

func is_sanitize_control_chars_enabled() -> bool:
	return _sanitize_control_chars

# JSONエンコード用メッセージサニタイズ
func _sanitize_message_for_json(message: String) -> String:
	var cleaned = message

	# ANSI文字除去（設定可能）
	if _sanitize_ansi:
		cleaned = _remove_ansi_sequences(cleaned)

	# 制御文字除去（設定可能）
	if _sanitize_control_chars:
		cleaned = _remove_control_characters(cleaned)

	return cleaned

# ANSI エスケープシーケンス除去
func _remove_ansi_sequences(message: String) -> String:
	var cleaned = message

	# 非ESC形式のANSI（GUTで使用される形式）を除去
	var bracket_patterns = [
		"[0m",  # リセット
		"[1m",  # 太字
		"[4m",  # 下線
		"[33m",  # 黄色
		"[31m",  # 赤色
		"[32m",  # 緑色
		"[35m",  # マゼンタ
		"[36m",  # シアン
		"[37m",  # 白色
	]

	# 既知のパターンを除去
	for pattern in bracket_patterns:
		cleaned = cleaned.replace(pattern, "")

	# ESC文字を含む標準ANSI除去
	var esc_char = char(0x1b)  # ESC文字
	var esc_patterns = [
		esc_char + "[0m",  # リセット
		esc_char + "[1m",  # 太字
		esc_char + "[4m",  # 下線
		esc_char + "[33m",  # 黄色
		esc_char + "[31m",  # 赤色
		esc_char + "[32m",  # 緑色
		esc_char + "[35m",  # マゼンタ
		esc_char + "[36m",  # シアン
		esc_char + "[37m",  # 白色
	]

	# 既知のESCパターンを除去
	for pattern in esc_patterns:
		cleaned = cleaned.replace(pattern, "")

	# 正規表現でその他のANSIシーケンスを除去
	var regex = RegEx.new()
	regex.compile("\\x1b\\[[0-9;]*[a-zA-Z]")
	cleaned = regex.sub(cleaned, "", true)

	# 残りのESC文字も除去
	regex.compile("\\x1b.")
	cleaned = regex.sub(cleaned, "", true)

	return cleaned

# 制御文字除去
func _remove_control_characters(message: String) -> String:
	var regex = RegEx.new()
	regex.compile("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F-\\x9F]")
	return regex.sub(message, "", true)

# 内部ヘルパー統合
func _create_log_data(message: String, level: String, category: String) -> Dictionary:
	return {
		"timestamp": Time.get_unix_time_from_system(),
		"frame": Engine.get_process_frames(),
		"physics_frame": Engine.get_physics_frames(),
		"level": level,
		"category": category,
		"message": message
	}


# 任意機能: システムログキャプチャ（Godot 4.5+のみ）
func enable_system_capture() -> bool:
	"""Enable system log capture (Godot 4.5+ only)"""
	if not _logger_support_available:
		print("SyncLogger: System log capture requires Godot 4.5+")
		return false

	_system_capture_enabled = true
	# TODO: 統合後にGodot Logger統合機能を再実装
	return true


func is_system_capture_enabled() -> bool:
	return _system_capture_enabled and _logger_support_available


func set_capture_errors(enabled: bool) -> void:
	if not _logger_support_available:
		print("SyncLogger: Error capture requires Godot 4.5+")
		return

	_capture_errors = enabled
	# TODO: 統合後にGodot Logger統合機能を再実装


func set_capture_messages(enabled: bool) -> void:
	if not _logger_support_available:
		print("SyncLogger: Message capture requires Godot 4.5+")
		return

	_capture_messages = enabled
	# TODO: 統合後にGodot Logger統合機能を再実装


func is_capture_errors_enabled() -> bool:
	return _capture_errors and _logger_support_available


func is_capture_messages_enabled() -> bool:
	return _capture_messages and _logger_support_available


func get_system_log_stats() -> Dictionary:
	# TODO: 統合後にGodot Logger統合機能を再実装
	return {
		"godot_logger_enabled": false,  # 一時的に無効
		"capture_messages": _capture_messages,
		"capture_errors": _capture_errors,
		"logger_support_available": _logger_support_available
	}


# バージョン情報API
func is_logger_integration_available() -> bool:
	return _logger_support_available


func get_compatibility_info() -> Dictionary:
	return {
		"godot_version": Engine.get_version_info(),
		"logger_support": _logger_support_available,
		"interceptor_active": false,  # 一時的に無効
		"system_capture_available": _logger_support_available,
		"config_file_enabled": _config_file_enabled
	}


# 任意機能: 設定ファイル機能
func load_config_file() -> bool:
	"""Manual config file loading (optional)"""
	_try_load_config_file()
	return _config_file_enabled


func is_config_file_enabled() -> bool:
	return _config_file_enabled


func get_config_file_path() -> String:
	return "user://" + CONFIG_FILENAME


# サニタイズ機能は MainThreadSimpleLogger で直接制御
# 重複除去: 上位レベル制御API削除（setupメソッドで自動設定）


# テスト用の状態リセット機能
func _reset_config_state() -> void:
	"""テスト用: 設定ファイル状態をリセットして再読み込み"""
	_config_file_enabled = false
	if _udp_sender:
		_udp_sender.close()
	_try_load_config_file()


# 内部実装（Godot 4.5+のみ）- 統合版
func _setup_system_log_capture() -> void:
	if not _logger_support_available:
		return

	if _system_capture_enabled and not _logger_registered:
		# TODO: 統合後にGodot Logger統合機能を再実装
		_logger_registered = true


func _cleanup_system_log_capture() -> void:
	if not _logger_support_available:
		return

	if _logger_registered:
		# TODO: 統合後にGodot Logger統合機能を再実装
		_logger_registered = false


# 終了処理
func shutdown() -> void:
	_cleanup_system_log_capture()
	if _udp_sender:
		_udp_sender.close()


# 任意機能: 設定ファイル自動読み込み
func _try_load_config_file() -> void:
	var config_path = "user://" + CONFIG_FILENAME
	if FileAccess.file_exists(config_path):
		var config = _load_simple_config(config_path)
		_setup_from_config(config)
		_config_file_enabled = true
		print("SyncLogger: Config loaded and merged with defaults")
	else:
		_config_file_enabled = false
		print("SyncLogger: Disabled (no config file at ", config_path, ")")


func _load_simple_config(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return DEFAULT_CONFIG.duplicate()

	var content = file.get_as_text().strip_edges()
	file.close()

	if content.is_empty():
		_write_default_config(path)
		print("SyncLogger: Empty config file, created default config")
		return DEFAULT_CONFIG.duplicate()

	var json = JSON.new()
	var parse_result = json.parse(content)

	if parse_result != OK or not json.data is Dictionary:
		print("SyncLogger: Invalid JSON detected, overwriting with defaults")
		_write_default_config(path)
		return DEFAULT_CONFIG.duplicate()

	# デフォルト値とマージ
	var final_config = DEFAULT_CONFIG.duplicate()
	for key in json.data:
		if final_config.has(key):
			final_config[key] = json.data[key]

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
			_system_capture_enabled = config.system_capture
			if config.system_capture:
				enable_system_capture()
		if config.has("capture_errors"):
			set_capture_errors(config.capture_errors)
		if config.has("capture_messages"):
			set_capture_messages(config.capture_messages)
