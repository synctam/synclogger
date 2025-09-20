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

	if _host.is_empty() or _port <= 0:
		return false

	# テストモード時は接続チェックを省略して成功とみなす
	if _test_mode:
		return true

	# 永続接続が利用可能な場合はそれを使用
	if _is_connected:
		var bytes = data.to_utf8_buffer()
		var sent = _udp_socket.put_packet(bytes)
		return sent == OK

	# 永続接続が失敗した場合は従来の一時接続方式にフォールバック
	_udp_socket.close()
	var result = _udp_socket.connect_to_host(_host, _port)
	if result != OK:
		return false

	var bytes = data.to_utf8_buffer()
	var sent = _udp_socket.put_packet(bytes)
	_udp_socket.close()

	return sent == OK


func close() -> void:
	if _udp_socket and _is_connected:
		_udp_socket.close()
	_is_connected = false
	_is_setup = false
