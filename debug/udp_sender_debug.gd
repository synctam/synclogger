class_name UDPSenderDebug
extends RefCounted

# デバッグ版UDPSender - 詳細ログ付き

var _udp_socket: PacketPeerUDP
var _host: String = ""
var _port: int = 0
var _is_setup: bool = false
var _is_connected: bool = false

func _init():
	_udp_socket = PacketPeerUDP.new()
	print("UDPSenderDebug: Created new UDP socket")

func setup(host: String, port: int) -> void:
	_host = host
	_port = port
	_is_setup = true
	print("UDPSenderDebug: Setup completed - ", host, ":", port)

func get_host() -> String:
	return _host

func get_port() -> int:
	return _port

func send(data: String) -> bool:
	print("UDPSenderDebug: Send attempt - data length: ", data.length())
	
	if not _is_setup:
		print("UDPSenderDebug: FAIL - Not setup")
		return false

	if _host.is_empty() or _port <= 0:
		print("UDPSenderDebug: FAIL - Invalid host/port")
		return false

	# 接続状態を確認
	print("UDPSenderDebug: Current connection state: ", _is_connected)
	
	# まだ接続していない場合のみ接続
	if not _is_connected:
		print("UDPSenderDebug: Attempting to connect...")
		var result = _udp_socket.connect_to_host(_host, _port)
		print("UDPSenderDebug: Connect result: ", result, " (OK=", OK, ")")
		
		if result != OK:
			print("UDPSenderDebug: FAIL - Connection failed")
			return false
		
		_is_connected = true
		print("UDPSenderDebug: Connection established")
	else:
		print("UDPSenderDebug: Using existing connection")

	var bytes = data.to_utf8_buffer()
	print("UDPSenderDebug: Sending ", bytes.size(), " bytes")
	
	var sent = _udp_socket.put_packet(bytes)
	print("UDPSenderDebug: Send result: ", sent, " (OK=", OK, ")")

	var success = sent == OK
	print("UDPSenderDebug: Final result: ", success)
	return success

func close() -> void:
	print("UDPSenderDebug: Closing connection")
	if _udp_socket:
		_udp_socket.close()
	_is_setup = false
	_is_connected = false