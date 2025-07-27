extends Node

func _ready():
	print("=== SyncLogger Demo Started ===")
	
	# SyncLoggerセットアップ
	SyncLogger.setup("127.0.0.1", 9999)
	print("SyncLogger setup completed")
	
	# 各レベルのログを送信
	SyncLogger.debug("This is a debug message")
	SyncLogger.info("Application started successfully")
	SyncLogger.warning("This is a warning message")
	SyncLogger.error("This is an error message")
	
	# カテゴリ付きログ
	SyncLogger.log("Player spawned at position (100, 200)", "gameplay")
	SyncLogger.log("Level loaded: Forest", "level")
	SyncLogger.log("Network connection established", "network")
	
	print("Demo logs sent!")
	print("Check the log_receiver.py output")
	
	# 5秒後にシャットダウン
	await get_tree().create_timer(5.0).timeout
	
	SyncLogger.shutdown()
	print("=== SyncLogger Demo Finished ===")
	
	# プログラム終了
	get_tree().quit()