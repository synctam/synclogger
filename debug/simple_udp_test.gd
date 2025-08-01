extends Node

# 最小限のUDP送信テスト

func _ready():
	print("=== Simple UDP Test ===")
	
	var udp_sender = UDPSender.new()
	udp_sender.setup("127.0.0.1", 9997)
	
	# 単一メッセージ送信
	var test_message = '{"message":"Hello UDP", "timestamp":1234567890}'
	print("Sending: ", test_message)
	
	var result = udp_sender.send(test_message)
	print("Send result: ", result)
	
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()