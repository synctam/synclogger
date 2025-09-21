# gdlint: disable=max-public-methods
class_name SyncLoggerNode
extends Node


# 内部カスタムLoggerクラス（システムログキャプチャ用）
class SyncCustomLogger:
	extends Logger

	# ローカル定数（Logger定数との競合回避）
	const LOCAL_ERROR_TYPE_WARNING = 1
	const LOCAL_ERROR_TYPE_ERROR = 0

	var _sync_main: SyncLoggerNode
	var _enabled: bool = true
	var _capture_messages: bool = true
	var _capture_errors: bool = true

	func _init(sync_main: SyncLoggerNode):
		_sync_main = sync_main

	# Logger仮想メソッドの実装
	func _log_message(message: String, error: bool) -> void:
		if not _enabled or not _capture_messages:
			return

		# 安全性チェック: _sync_mainが有効かつ_send_logメソッドが存在するか
		if not _sync_main or not _sync_main.has_method("_send_log"):
			return

		var level = "error" if error else "info"
		_sync_main._send_log(message, level, "godot_system", true)

	func _log_error(
		function: String,
		file: String,
		line: int,
		_code: String,
		rationale: String,
		_editor_notify: bool,
		error_type: int,
		_script_backtraces: Array
	) -> void:
		if not _enabled or not _capture_errors:
			return

		# 安全性チェック: _sync_mainが有効かつ_send_logメソッドが存在するか
		if not _sync_main or not _sync_main.has_method("_send_log"):
			return

		# エラー情報を構造化
		var error_msg = "ERROR in %s:%d (%s): %s" % [file, line, function, rationale]
		var error_level = _convert_error_type(error_type)

		_sync_main._send_log(error_msg, error_level, "godot_error", true)

	# エラータイプをログレベルに変換
	func _convert_error_type(error_type: int) -> String:
		match error_type:
			LOCAL_ERROR_TYPE_WARNING:
				return "warning"
			_:
				return "error"

	# 制御メソッド
	func set_enabled(enabled: bool) -> void:
		_enabled = enabled

	func set_capture_messages(enabled: bool) -> void:
		_capture_messages = enabled

	func set_capture_errors(enabled: bool) -> void:
		_capture_errors = enabled

	func is_enabled() -> bool:
		return _enabled

	func is_capture_messages_enabled() -> bool:
		return _capture_messages

	func is_capture_errors_enabled() -> bool:
		return _capture_errors


# SyncLogger - Godot用UDPログ送信システム（Phase 3統一設計）
# 推奨パターン: SyncLogger.setup("127.0.0.1", 9999) → SyncLogger.log("message")

# 定数定義
const UDPSender = preload("res://addons/synclogger/udp_sender.gd")
const CONFIG_FILENAME = ".synclogger.json"
const DEFAULT_CONFIG = {
	"host": "127.0.0.1",
	"port": 9999,
	"system_capture": true,
	"capture_errors": true,
	"capture_messages": true
}

# 変数定義
var _host: String = "127.0.0.1"  # デフォルトホスト
var _port: int = 9999  # デフォルトポート
var _is_running: bool = false  # 実行状態フラグ
var _udp_sender: UDPSender = null  # UDP送信オブジェクト

# サニタイズ設定
var _sanitize_ansi: bool = true  # デフォルト: ANSI文字を除去
var _sanitize_control_chars: bool = true  # デフォルト: 制御文字を除去

# RegEx最適化: クラス変数として1回だけ初期化
var _ansi_regex: RegEx
var _control_chars_regex: RegEx

# システムログキャプチャ設定（Godot 4.5+のみ有効）
var _system_capture_enabled: bool = true
var _capture_messages: bool = true
var _capture_errors: bool = true
var _logger_registered: bool = false
var _logger_support_available: bool = false
var _custom_logger: SyncCustomLogger

# 設定ファイル機能
var _config_file_enabled: bool = false


func _init():
	# UDP送信オブジェクトは start() 時に作成
	_check_logger_support()

	# RegEx初期化（パフォーマンス最適化）
	_ansi_regex = RegEx.new()
	_ansi_regex.compile("\\x1b\\[[0-9;]*[a-zA-Z]")

	_control_chars_regex = RegEx.new()
	_control_chars_regex.compile("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F-\\x9F]")

	# カスタムLogger初期化
	if _logger_support_available:
		_custom_logger = SyncCustomLogger.new(self)


func _ready():
	_try_load_config_file()


# Godot 4.5+ Logger機能の可用性チェック（統合版）
func _check_logger_support():
	if ClassDB.class_exists("Logger"):
		_logger_support_available = true
	else:
		_logger_support_available = false


func setup(host: String = "127.0.0.1", port: int = 9999) -> void:
	# 設定のみ更新（UDP接続はしない）
	_host = host
	_port = port

	# サニタイズ設定を確実に有効化（ANSI・制御文字除去）
	_sanitize_ansi = true
	_sanitize_control_chars = true


func start() -> void:
	if _is_running:
		# 既に実行中の場合は何もしない（サイレント）
		return

	# UDP接続を確立
	_udp_sender = UDPSender.new()
	_udp_sender.setup(_host, _port)
	_is_running = true

	# システムログキャプチャを自動設定（Godot 4.5+のみ）
	if _logger_support_available:
		_setup_system_log_capture()


func stop() -> void:
	if not _is_running:
		return

	# UDP接続を切断
	if _udp_sender:
		_udp_sender.close()
		_udp_sender = null
	_is_running = false

	# システムログキャプチャを無効化
	_cleanup_system_log_capture()


func restart() -> void:
	stop()
	start()


func get_host() -> String:
	return _host


func get_port() -> int:
	return _port


func is_setup() -> bool:
	# 設定がデフォルト以外に設定されているかを確認
	return _host != "" and _port > 0


func set_test_mode(enabled: bool) -> void:
	"""テスト環境での接続エラー回避モード（テスト専用）"""
	if _udp_sender:
		_udp_sender.set_test_mode(enabled)


# 実行状態の確認
func is_running() -> bool:
	return _is_running


func get_queue_size() -> int:
	# キューレス実装のため常に0
	return 0


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
func _send_log(message: String, level: String, category: String, is_system: bool = false) -> bool:
	# 統一された接続チェック
	if not is_running():
		return false

	# システムログの場合は特別なプレフィックスを追加
	var processed_message = message
	if is_system:
		processed_message = "[SYSTEM] " + message

	# メッセージサイズ制限（セキュリティ対策）
	const MAX_MESSAGE_SIZE = 4096
	if processed_message.length() > MAX_MESSAGE_SIZE:
		processed_message = processed_message.left(MAX_MESSAGE_SIZE) + "...[truncated]"

	# JSONコントロール文字問題修正: ANSIエスケープシーケンスを先に除去
	var sanitized_message = _sanitize_message_for_json(processed_message)

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


# ANSI エスケープシーケンス除去（最適化済み）
func _remove_ansi_sequences(message: String) -> String:
	var cleaned = message

	# 効率的なANSI除去: RegExを1回だけ使用
	cleaned = _ansi_regex.sub(cleaned, "", true)

	# ESC文字の除去
	var esc_char = char(0x1b)
	cleaned = cleaned.replace(esc_char, "")

	return cleaned


# 制御文字除去（最適化済み）
func _remove_control_characters(message: String) -> String:
	return _control_chars_regex.sub(message, "", true)


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
		# System log capture requires Godot 4.5+
		return false

	_system_capture_enabled = true
	_setup_system_log_capture()
	return true


func is_system_capture_enabled() -> bool:
	return _system_capture_enabled and _logger_support_available


func set_capture_errors(enabled: bool) -> void:
	if not _logger_support_available:
		# Error capture requires Godot 4.5+
		return

	_capture_errors = enabled
	if _custom_logger:
		_custom_logger.set_capture_errors(enabled)


func set_capture_messages(enabled: bool) -> void:
	if not _logger_support_available:
		# Message capture requires Godot 4.5+
		return

	_capture_messages = enabled
	if _custom_logger:
		_custom_logger.set_capture_messages(enabled)


func is_capture_errors_enabled() -> bool:
	return _capture_errors and _logger_support_available


func is_capture_messages_enabled() -> bool:
	return _capture_messages and _logger_support_available


func get_system_log_stats() -> Dictionary:
	return {
		"godot_logger_enabled": _logger_registered,
		"capture_messages": _capture_messages,
		"capture_errors": _capture_errors,
		"logger_support_available": _logger_support_available,
		"custom_logger_active": _custom_logger != null
	}


# バージョン情報API
func is_logger_integration_available() -> bool:
	return _logger_support_available


func get_compatibility_info() -> Dictionary:
	return {
		"godot_version": Engine.get_version_info(),
		"logger_support": _logger_support_available,
		"interceptor_active": _logger_registered,
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
		_custom_logger.set_enabled(true)
		_custom_logger.set_capture_errors(_capture_errors)
		_custom_logger.set_capture_messages(_capture_messages)

		# 重要: OS.add_logger()でGodotエンジンに登録
		OS.add_logger(_custom_logger)
		_logger_registered = true


func _cleanup_system_log_capture() -> void:
	if not _logger_support_available:
		return

	if _custom_logger and _logger_registered:
		OS.remove_logger(_custom_logger)
		_logger_registered = false


# 任意機能: 設定ファイル自動読み込み
func _try_load_config_file() -> void:
	var config_path = "user://" + CONFIG_FILENAME
	if FileAccess.file_exists(config_path):
		var config = _load_simple_config(config_path)
		_setup_from_config(config)
		_config_file_enabled = true
	else:
		_config_file_enabled = false

func _load_simple_config(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return DEFAULT_CONFIG.duplicate()

	var content = file.get_as_text().strip_edges()
	file.close()

	if content.is_empty():
		_write_default_config(path)
		return DEFAULT_CONFIG.duplicate()

	var json = JSON.new()
	var parse_result = json.parse(content)

	if parse_result != OK or not json.data is Dictionary:
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
