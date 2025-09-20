class_name MainThreadSimpleLogger
extends RefCounted

# TDD GREEN段階: テストを通す最小限の実装
# メインスレッドで即座にUDP送信するシンプルなログ送信機能

var _udp_sender: UDPSender
var _host: String = ""
var _port: int = 0
var _is_setup: bool = false

# サニタイズ設定
var _sanitize_ansi: bool = true    # デフォルト: ANSI文字を除去
var _sanitize_control_chars: bool = true  # デフォルト: 制御文字を除去

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

	# JSONコントロール文字問題修正: ANSIエスケープシーケンスを先に除去
	var sanitized_message = _sanitize_message_for_json(message)

	# 改行処理問題修正: サニタイズ後にメッセージをクリーンアップ
	sanitized_message = sanitized_message.strip_edges()

	# デバッグ: サニタイズ処理の確認（デバッグ時のみ有効化）
	# if message != sanitized_message:
	#	print("SANITIZE DEBUG: '", message, "' → '", sanitized_message, "' (len: ", sanitized_message.length(), ")")

	# 全メッセージをデバッグ
	# print("MESSAGE DEBUG: '", sanitized_message, "' (len: ", sanitized_message.length(), ")")

	# 空文字やホワイトスペースのみの場合もデバッグ
	# if sanitized_message.is_empty() or sanitized_message.length() <= 2:
	#	print("EMPTY MESSAGE DEBUG: '", message, "' → '", sanitized_message, "' → REJECTED (length: ", sanitized_message.length(), ")")

	# サニタイズ後に空メッセージの送信を停止（非常に短いメッセージも除外）
	if sanitized_message.is_empty() or sanitized_message.length() <= 2:
		return false

	var log_data = _create_log_data(sanitized_message, level, category)
	var json_string = JSON.stringify(log_data)
	return _udp_sender.send(json_string)

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
		"[0m",     # リセット
		"[1m",     # 太字
		"[4m",     # 下線
		"[33m",    # 黄色
		"[31m",    # 赤色
		"[32m",    # 緑色
		"[35m",    # マゼンタ
		"[36m",    # シアン
		"[37m",    # 白色
	]

	# 既知のパターンを除去
	for pattern in bracket_patterns:
		cleaned = cleaned.replace(pattern, "")

	# ESC文字を含む標準ANSI除去
	var esc_char = char(0x1b)  # ESC文字
	var esc_patterns = [
		esc_char + "[0m",     # リセット
		esc_char + "[1m",     # 太字
		esc_char + "[4m",     # 下線
		esc_char + "[33m",    # 黄色
		esc_char + "[31m",    # 赤色
		esc_char + "[32m",    # 緑色
		esc_char + "[35m",    # マゼンタ
		esc_char + "[36m",    # シアン
		esc_char + "[37m",    # 白色
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
