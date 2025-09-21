class_name UDPSender
extends RefCounted

var _udp_socket: PacketPeerUDP
var _host: String = ""
var _port: int = 0
var _is_setup: bool = false
var _is_connected: bool = false
var _test_mode: bool = false  # テスト環境での接続エラー回避


func _init():
	_udp_socket = PacketPeerUDP.new()


func setup(host: String, port: int) -> void:
	_host = host
	_port = port

	# 既存の接続をクリーンアップ
	if _is_connected:
		_udp_socket.close()
		_is_connected = false

	# 新しい接続を確立
	if not _host.is_empty() and _port > 0:
		var result = _udp_socket.connect_to_host(_host, _port)
		_is_connected = (result == OK)

	_is_setup = true


func get_host() -> String:
	return _host


func get_port() -> int:
	return _port


func set_test_mode(enabled: bool) -> void:
	"""テスト環境での接続エラー回避モード（テスト専用）"""
	_test_mode = enabled


func send(data: String) -> bool:
	if not _is_setup:
		return false

	# テストモード時は接続チェックを省略して成功とみなす
	if _test_mode:
		return true

	# Phase 2最適化: _ensure_connection()を使用
	if not _ensure_connection():
		return false

	var bytes = data.to_utf8_buffer()
	var result = _udp_socket.put_packet(bytes)

	# 送信失敗時は接続を再確立
	if result != OK:
		_is_connected = false
		return _retry_send(data)

	return true


func close() -> void:
	if _udp_socket and _is_connected:
		_udp_socket.close()
	_is_connected = false
	_is_setup = false


# ======== 設定アクセサー（重複プロパティ削除後の代替） ========


func is_setup() -> bool:
	"""設定完了状態を確認"""
	return _is_setup


func is_udp_connected() -> bool:
	"""UDP接続状態を確認（基底クラスのis_connected()との競合回避）"""
	return _is_connected and _udp_socket != null


# ======== Phase 2: UDP接続最適化メソッド ========


func _ensure_connection() -> bool:
	"""接続確立の自動化"""
	if _is_connected:
		return true

	if _host.is_empty() or _port <= 0:
		return false

	var result = _udp_socket.connect_to_host(_host, _port)
	_is_connected = (result == OK)
	return _is_connected


func _retry_send(data: String, retry_count: int = 0) -> bool:
	"""送信失敗時の再試行ロジック"""
	const MAX_RETRIES = 1
	if retry_count >= MAX_RETRIES:
		return false

	if not _ensure_connection():
		return false

	var bytes = data.to_utf8_buffer()
	var result = _udp_socket.put_packet(bytes)
	return result == OK
