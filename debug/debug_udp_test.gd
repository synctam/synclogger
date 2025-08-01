extends Node

# UDPSender問題の詳細調査

const UDPSenderDebug = preload("res://addons/synclogger/udp_sender_debug.gd")

func _ready():
	print("=== UDP Sender Debug Test Started ===")
	
	var udp_debug = UDPSenderDebug.new()
	udp_debug.setup("127.0.0.1", 9995)
	
	# 連続送信テスト
	print("\n--- Consecutive Send Test ---")
	for i in range(5):
		var test_message = "Test message #" + str(i)
		print("\n[Test ", i+1, "] Sending: ", test_message)
		var result = udp_debug.send(test_message)
		print("[Test ", i+1, "] Result: ", result)
		
		# 少し待機
		await get_tree().create_timer(0.1).timeout
	
	print("\n=== UDP Sender Debug Test Finished ===")
	get_tree().quit()