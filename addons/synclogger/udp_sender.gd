class_name UDPSender
extends RefCounted

var _udp_socket: PacketPeerUDP
var _host: String = ""
var _port: int = 0
var _is_setup: bool = false


func _init():
	_udp_socket = PacketPeerUDP.new()


func setup(host: String, port: int) -> void:
	_host = host
	_port = port
	_is_setup = true


func get_host() -> String:
	return _host


func get_port() -> int:
	return _port


func send(data: String) -> bool:
	if not _is_setup:
		return false

	if _host.is_empty() or _port <= 0:
		return false

	# UDP接続をリセットして再接続（毎回新しい接続を作成）
	_udp_socket.close()
	
	var result = _udp_socket.connect_to_host(_host, _port)
	if result != OK:
		return false

	var bytes = data.to_utf8_buffer()
	var sent = _udp_socket.put_packet(bytes)
	
	# 送信後に接続をクリーンアップ
	_udp_socket.close()

	return sent == OK


func close() -> void:
	if _udp_socket:
		_udp_socket.close()
	_is_setup = false
