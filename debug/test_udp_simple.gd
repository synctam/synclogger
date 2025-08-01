extends Node

func _ready():
	print("=== Simple UDP Test ===")
	
	var udp_sender = UDPSender.new()
	udp_sender.setup("127.0.0.1", 9998)
	
	var test_data = {
		"timestamp": Time.get_unix_time_from_system(),
		"frame": Engine.get_process_frames(),
		"level": "info",
		"message": "Simple UDP test message"
	}
	
	var json_string = JSON.stringify(test_data)
	var result = udp_sender.send(json_string)
	
	print("UDP send result: ", result)
	print("Message sent: ", json_string)
	
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()